--------------------------------------------------------------------------------
-- Midnight Sensei: Analytics/Feedback.lua
-- Human-readable coaching feedback generation.
-- Called by Engine.lua via Feedback.Generate(scores, duration, inferSimplified, state).
--
-- State snapshot passed by Engine:
--   state.spec               — Core.ActiveSpec
--   state.cdTracking         — [spellID] = { useCount, label, ... }
--   state.rotationalTracking — [spellID] = { useCount, label, minFightSeconds, ... }
--   state.overcapEvents      — distinct overcap entries this fight
--   state.totalGCDs          — total GCDs cast
--   state.activeGCDs         — non-idle GCDs cast
--   state.currentBossContext — { name, id, difficultyID } or nil
--   state.CL                 — MS.CombatLog module reference
--------------------------------------------------------------------------------

MidnightSensei                    = MidnightSensei                    or {}
local L = MidnightSensei.L
MidnightSensei.Analytics          = MidnightSensei.Analytics          or {}
MidnightSensei.Analytics.Feedback = MidnightSensei.Analytics.Feedback or {}

local MS       = MidnightSensei
local Core     = MS.Core
local Feedback = MS.Analytics.Feedback

--------------------------------------------------------------------------------
-- Feedback.Generate
-- inferSimplified: soft behavioral inference — affects tone only, never score.
-- Returns a list of coaching strings (up to 8, plus optional interrupt note).
--------------------------------------------------------------------------------
function Feedback.Generate(scores, duration, inferSimplified, state)
    local feedback = {}
    local spec     = state.spec
    if not spec then return feedback end

    local cdTracking         = state.cdTracking
    local rotationalTracking = state.rotationalTracking
    local overcapEvents      = state.overcapEvents
    local totalGCDs          = state.totalGCDs
    local activeGCDs         = state.activeGCDs
    local currentBossContext = state.currentBossContext
    local CL                 = state.CL

    local function Add(msg) table.insert(feedback, msg) end
    local bossName     = currentBossContext and currentBossContext.name
    local isHealer     = spec.role == Core.ROLE.HEALER
    local isTank       = spec.role == Core.ROLE.TANK
    local expectedMult = math.max(1, math.floor(duration / 120))
    local actScore     = scores.activity or 100

    local topGainImpact = 0
    local topGainMsg    = nil
    local function AddGain(impact, msg)
        Add(msg)
        if impact > topGainImpact then
            topGainImpact = impact
            topGainMsg    = msg
        end
    end

    -- ── Cooldown Usage ──────────────────────────────────────────────────────
    local neverUsed             = {}
    local underused             = {}
    local interruptNeverUsed    = {}   -- informational only — never penalised
    local utilityNeverUsed      = {}   -- informational only — never penalised
    local combatUtilityNeverUsed = {}  -- informational only — utility + stun/damage, never penalised

    if next(cdTracking) then
        for _, cd in ipairs(spec.majorCooldowns or {}) do
            local data = cdTracking[cd.id]
            if data then
                local minSecs = cd.minFightSeconds or 30
                local label   = data.label or cd.label or ("Spell "..cd.id)
                if cd.isInterrupt then
                    -- Interrupts: track but never penalise — surface as informational note
                    if data.useCount == 0 and duration >= minSecs then
                        table.insert(interruptNeverUsed, label)
                    end
                elseif cd.isUtility and cd.hasCombatValue then
                    -- Combat utility: stuns/damages as well as utility — separate note
                    if data.useCount == 0 and duration >= minSecs then
                        table.insert(combatUtilityNeverUsed, label)
                    end
                elseif cd.isUtility then
                    -- Utility spells: track but never penalise — surface as informational note
                    if data.useCount == 0 and duration >= minSecs then
                        table.insert(utilityNeverUsed, label)
                    end
                elseif data.useCount == 0 and duration >= minSecs then
                    if not (cd.healerConditional and state.fightSuccess) then
                        table.insert(neverUsed, label)
                    end
                elseif data.useCount < expectedMult and duration >= minSecs then
                    if not (cd.healerConditional and state.fightSuccess) then
                        table.insert(underused,
                            label .. " (" .. data.useCount .. "/" .. expectedMult .. ")")
                    end
                end
            end
        end
    else
        -- cdTracking empty — no detectable CDs this build (all talentGated unlearned,
        -- all displayOnly, etc.).  Apply same gates as setup loop.
        if duration >= 30 then
            for _, cd in ipairs(spec.majorCooldowns or {}) do
                if not cd.isInterrupt and not cd.isUtility and not cd.displayOnly
                and not cd.talentGated and not cd.suppressIfTalent
                and cd.label then
                    table.insert(neverUsed, cd.label)
                end
            end
        end
    end

    if #neverUsed > 0 and duration >= 30 then
        table.sort(neverUsed)
        local ctx    = bossName and (" during " .. bossName) or ""
        local action = isTank   and L["FB_ACTION_TANK"]
                    or isHealer and L["FB_ACTION_HEALER"]
                    or             L["FB_ACTION_DPS"]
        if inferSimplified then
            AddGain(40, string.format(L["FB_NEVER_PRESSED_SIMP"], ctx, table.concat(neverUsed, ", ")))
        else
            AddGain(40, string.format(L["FB_NEVER_PRESSED"], ctx, table.concat(neverUsed, ", "), action))
        end
    end

    -- ── Activity / Downtime ──────────────────────────────────────────────────
    if actScore < 85 and totalGCDs > 0 then
        local targetGPM   = isHealer and 25 or isTank and 30 or 40
        local targetTotal = math.floor((duration / 60) * targetGPM)
        local pct         = math.floor((activeGCDs / math.max(1, targetTotal)) * 100)
        local lost        = targetTotal - activeGCDs
        if inferSimplified then
            AddGain(30, string.format(L["FB_ACTIVITY_SIMPLIFIED"], pct))
        elseif actScore >= 80 then
            AddGain(15, string.format(L["FB_ACTIVITY_MODERATE"], pct, lost))
        else
            local severity = pct < 60 and L["FB_DOWNTIME_SIGNIFICANT"] or L["FB_DOWNTIME_MODERATE"]
            AddGain(30, string.format(L["FB_ACTIVITY_LOW"], activeGCDs, targetTotal, pct, severity, lost))
        end
    end

    -- ── Underused CDs ───────────────────────────────────────────────────────
    if #underused > 0 and duration >= 90 then
        table.sort(underused)
        local fightMins = string.format("%.1f", duration / 60)
        AddGain(20, string.format(L["FB_UNDERUSED"], fightMins, table.concat(underused, ", ")))
    end

    -- ── Rotational spell cast count ─────────────────────────────────────────
    -- Surfaces "never used" and "used but below potential" for rotational spells.
    -- combatGated spells (e.g. Collapsing Star) generate feedback just like any
    -- other spell — the minFightSeconds gate handles fights where the window didn't open.
    if next(rotationalTracking) then
        -- Pre-compute orGroup state: which groups had a cast, and a combined label
        -- ("Wrath / Starfire") for groups where nothing was cast.
        local orGroupUsed     = {}
        local orGroupLabels   = {}
        local orGroupReported = {}
        for _, rs in pairs(rotationalTracking) do
            if rs.orGroup then
                if rs.useCount > 0 then
                    orGroupUsed[rs.orGroup] = true
                end
                -- Build combined label sorted so output is deterministic
                if not orGroupLabels[rs.orGroup] then
                    orGroupLabels[rs.orGroup] = { rs.label }
                else
                    table.insert(orGroupLabels[rs.orGroup], rs.label)
                    table.sort(orGroupLabels[rs.orGroup])
                end
            end
        end

        local unused  = {}
        local lowUsed = {}
        for id, rs in pairs(rotationalTracking) do
            if rs.useCount == 0 and duration >= rs.minFightSeconds then
                if rs.orGroup then
                    if orGroupUsed[rs.orGroup] then
                        -- a sibling was cast — not a miss
                    elseif not orGroupReported[rs.orGroup] then
                        -- neither cast — report once as combined "Wrath / Starfire"
                        orGroupReported[rs.orGroup] = true
                        local labels = orGroupLabels[rs.orGroup]
                        table.insert(unused, table.concat(labels, " / "))
                    end
                else
                    table.insert(unused, rs.label)
                end
            elseif rs.useCount > 0 then
                local cdSec = rs.cdSec
                if cdSec and cdSec > 0 and duration >= rs.minFightSeconds then
                    local potential = math.max(1, math.floor(duration / cdSec))
                    local missed    = potential - rs.useCount
                    if missed >= 2 then
                        table.insert(lowUsed, rs.label ..
                            " (" .. rs.useCount .. "/" .. potential .. ")")
                    end
                end
            end
        end
        if #unused > 0 then
            table.sort(unused)
            local context = isTank   and L["FB_ROT_CONTEXT_TANK"]
                         or isHealer and L["FB_ROT_CONTEXT_HEALER"]
                         or             L["FB_ROT_CONTEXT_DPS"]
            AddGain(25, string.format(L["FB_ROT_NEVER_USED"], table.concat(unused, ", "), context))
        end
        if #lowUsed > 0 then
            table.sort(lowUsed)
            AddGain(10, string.format(L["FB_ROT_LOW_USED"], table.concat(lowUsed, ", ")))
        end
    end

    -- ── Non-healer: Procs, Resources, Mitigation, Buffs ─────────────────────
    if not isHealer then

        -- Procs
        if scores.procUsage and CL and CL.GetAllProcs then
            local procData = CL.GetAllProcs()
            for _, proc in ipairs(spec.procBuffs or {}) do
                local data = procData[proc.id]
                if data and data.gained and data.gained > 0 then
                    local maxTime = proc.maxStackTime or 10
                    local avgHeld = data.totalActiveTime / data.gained
                    if avgHeld > maxTime * 0.5 then
                        local heldStr  = string.format("%.1f", avgHeld)
                        local severity = avgHeld > maxTime * 0.8 and L["FB_PROC_CRITICALLY"] or L["FB_PROC_DELAYED"]
                        AddGain(15, string.format(L["FB_PROC_MSG"], proc.label or "Proc", severity, heldStr, maxTime))
                    end
                end
            end
        end

        -- Resource overcap
        local rmScore = scores.resourceMgmt or 100
        if rmScore < 80 then
            local rate = string.format("%.1f", overcapEvents / math.max(1, duration / 60))
            AddGain(15, string.format(L["FB_OVERCAP"],
                spec.resourceLabel or "resource",
                overcapEvents, rate,
                spec.resourceLabel or "resource",
                spec.overcapAt or 100))
        end

        -- Tank: mitigation uptime
        if isTank and scores.mitigationUptime and CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0 then
                    local actual = math.floor(data.actualPct)
                    local target = data.targetUptime
                    local apps   = data.appCount or 0
                    local label  = buff.label or "Mitigation"
                    if apps == 0 then
                        AddGain(35, string.format(L["FB_MIT_NEVER_ACTIVATED"], label))
                    elseif actual < target * 0.6 then
                        local gap = target - actual
                        AddGain(30, string.format(L["FB_MIT_LOW_UPTIME"], label, actual, target, gap, apps))
                    elseif actual < target * 0.8 then
                        local gap = target - actual
                        AddGain(20, string.format(L["FB_MIT_SMALL_GAPS"], label, actual, target, gap))
                    end
                end
            end
        end

        -- DPS: self-buff uptime
        if not isTank and scores.debuffUptime and CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                local data = uptimeData[buff.id]
                if data and data.targetUptime and data.targetUptime > 0
                and data.appCount and data.appCount > 0 then
                    if data.actualPct < data.targetUptime * 0.8 then
                        local gap = data.targetUptime - math.floor(data.actualPct)
                        AddGain(20, string.format(L["FB_BUFF_LOW_UPTIME"],
                            buff.label or "Buff",
                            math.floor(data.actualPct),
                            data.targetUptime, gap))
                    end
                end
            end
        end

        -- Info-only buffs (e.g. group buffs cast pre-combat): note if never detected.
        -- appCount=0 means AuraTracker never saw it applied, so Scoring skips it.
        -- actualPct=0 means it wasn't active at combat start either.
        if CL and CL.GetAllUptimes then
            local uptimeData = CL.GetAllUptimes(duration)
            for _, buff in ipairs(spec.uptimeBuffs or {}) do
                if buff.infoOnly then
                    local data = uptimeData[buff.id]
                    if data and data.actualPct < 5 and duration >= 20 then
                        table.insert(utilityNeverUsed,
                            (buff.label or "Buff") .. " " .. L["FB_GROUP_BUFF_NOTE"])
                    end
                end
            end
        end
    end

    -- ── Healer feedback ──────────────────────────────────────────────────────
    if isHealer then
        if CL and CL.GetHealingData then
            local hd = CL.GetHealingData()
            if hd.done > 0 then
                local overpct = (hd.overheal / (hd.done + hd.overheal)) * 100
                local target  = (spec.healerMetrics and spec.healerMetrics.targetOverheal) or 30
                if overpct > target + 20 then
                    AddGain(25, string.format(L["FB_OVERHEAL_HIGH"], overpct, target))
                elseif overpct > target + 10 then
                    Add(string.format(L["FB_OVERHEAL_ELEVATED"], overpct, target))
                end
            end
        end
        if actScore < 70 and totalGCDs > 0 then
            Add(L["FB_HEALER_FILL_DOWNTIME"])
        end
    end

    -- ── Behavior tone fallback ───────────────────────────────────────────────
    if inferSimplified and #feedback == 0 then
        Add(L["FB_SIMPLIFIED_FALLBACK"])
    end

    -- ── Nothing flagged ──────────────────────────────────────────────────────
    if #feedback == 0 then
        local cdScore    = scores.cooldownUsage    or 100
        local mitScore   = scores.mitigationUptime or 100
        local allHigh    = actScore >= 90 and cdScore >= 90
                        and (not isTank or mitScore >= 90)
        local finalScore = scores._final or 0

        if allHigh and finalScore >= 95 then
            local nextSteps = {}
            if isTank then
                table.insert(nextSteps, L["FB_NEXT_TANK_PREPOS"])
            elseif isHealer then
                table.insert(nextSteps, L["FB_NEXT_HEALER_OVERLAP"])
            else
                table.insert(nextSteps, L["FB_NEXT_DPS_ALIGN"])
            end
            table.insert(nextSteps, L["FB_NEXT_GCD_TIMING"])
            Add(string.format(L["FB_NEAR_PERFECT"], table.concat(nextSteps, "; ")))
        elseif allHigh then
            local weakest   = nil
            local weakScore = 100
            for cat, val in pairs(scores) do
                if cat ~= "_final" and type(val) == "number" and val < weakScore then
                    weakScore = val
                    weakest   = cat
                end
            end
            local catHint = weakest and weakest:gsub("(%l)(%u)", "%1 %2"):lower() or "cooldown timing"
            Add(string.format(L["FB_STRONG_EXECUTION"], catHint))
        elseif cdScore < 80 or mitScore < 80 then
            local hints = {}
            if cdScore < 80 then
                table.insert(hints, isTank
                    and L["FB_HINT_TANK_CDS"]
                    or  L["FB_HINT_PRESS_CDS"])
            end
            if isTank and mitScore < 80 then
                local MIT_ABILITY = {
                    ["Blood"]        = "Death Strike",
                    ["Vengeance"]    = "Demon Spikes",
                    ["Guardian"]     = "Frenzied Regeneration",
                    ["Brewmaster"]   = "Ironskin Brew",
                    -- Protection uses className to distinguish Warrior vs Paladin
                }
                local mitAbility = MIT_ABILITY[spec.name]
                if not mitAbility and spec.name == "Protection" then
                    mitAbility = (spec.className == "Warrior") and "Shield Block" or "Shield of the Righteous"
                end
                mitAbility = mitAbility or "defensive abilities"
                table.insert(hints, string.format(L["FB_HINT_MIT_UPTIME"], mitAbility))
            end
            Add(string.format(L["FB_GOOD_FOUNDATION"], table.concat(hints, "; ")))
        else
            Add(L["FB_SOLID"])
        end
    end

    -- Cap at 8 — enough room for all meaningful coaching points
    while #feedback > 8 do table.remove(feedback) end

    -- Interrupt note always appended last — friendly reminder, never penalised, never buried
    if #interruptNeverUsed > 0 then
        table.insert(feedback, string.format(L["FB_NOTE_INTERRUPT"], table.concat(interruptNeverUsed, ", ")))
    end

    -- Utility note — informational, never penalised (Spellsteal, missing group buffs, etc.)
    if #utilityNeverUsed > 0 then
        table.insert(feedback, string.format(L["FB_NOTE_UTILITY"], table.concat(utilityNeverUsed, "; ")))
    end

    -- Combat utility note — stuns/damages in addition to utility; situational by design
    if #combatUtilityNeverUsed > 0 then
        table.insert(feedback, string.format(L["FB_NOTE_COMBAT_UTILITY"], table.concat(combatUtilityNeverUsed, ", ")))
    end

    return feedback
end
