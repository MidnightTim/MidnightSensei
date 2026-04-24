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
    local neverUsed          = {}
    local underused          = {}
    local interruptNeverUsed = {}   -- informational only — never penalised
    local utilityNeverUsed   = {}   -- informational only — never penalised

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
                elseif cd.isUtility then
                    -- Utility spells: track but never penalise — surface as informational note
                    if data.useCount == 0 and duration >= minSecs then
                        table.insert(utilityNeverUsed, label)
                    end
                elseif data.useCount == 0 and duration >= minSecs then
                    table.insert(neverUsed, label)
                elseif data.useCount < expectedMult and duration >= minSecs then
                    table.insert(underused,
                        label .. " (" .. data.useCount .. "/" .. expectedMult .. ")")
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
        local action = isTank   and "use on tank busters or high damage windows"
                    or isHealer and "align with high incoming damage windows"
                    or             "align these with burst windows"
        if inferSimplified then
            AddGain(40, "You lost value from unused cooldowns" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. ". Even consistent pressing helps.")
        else
            AddGain(40, "Never pressed" .. ctx .. ": " ..
                table.concat(neverUsed, ", ") .. " — " .. action .. ".")
        end
    end

    -- ── Activity / Downtime ──────────────────────────────────────────────────
    if actScore < 85 and totalGCDs > 0 then
        local targetGPM   = isHealer and 25 or isTank and 30 or 40
        local targetTotal = math.floor((duration / 60) * targetGPM)
        local pct         = math.floor((activeGCDs / math.max(1, targetTotal)) * 100)
        local lost        = targetTotal - activeGCDs
        if inferSimplified then
            AddGain(30, "Your rotation is consistent, but gaps between casts (" ..
                pct .. "% activity) are the next thing to tighten up.")
        elseif actScore >= 80 then
            AddGain(15, "Activity at " .. pct .. "% — roughly " .. lost ..
                " cast(s) left on the table. Queue your next spell before the current one lands.")
        else
            local severity = pct < 60 and "significant" or "moderate"
            AddGain(30, "Activity: " .. activeGCDs .. "/" .. targetTotal ..
                " GCDs (" .. pct .. "%) — " .. severity .. " downtime, approximately " ..
                lost .. " casts lost. Find your next spell before the current one finishes.")
        end
    end

    -- ── Underused CDs ───────────────────────────────────────────────────────
    if #underused > 0 and duration >= 90 then
        table.sort(underused)
        local fightMins = string.format("%.1f", duration / 60)
        AddGain(20, "Used less than expected in a " .. fightMins .. "min fight: " ..
            table.concat(underused, ", ") ..
            " — target 1 use per 2 minutes of fight time.")
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
            local context = isTank   and "survival and threat rotation"
                         or isHealer and "healing throughput"
                         or             "damage output"
            AddGain(25, "Rotational spell(s) never used: " ..
                table.concat(unused, ", ") ..
                " — these are core to your " .. context .. ".")
        end
        if #lowUsed > 0 then
            table.sort(lowUsed)
            AddGain(10, "Could have cast more: " .. table.concat(lowUsed, ", ") ..
                " — press these on every available GCD when your primary spenders are on cooldown.")
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
                        local severity = avgHeld > maxTime * 0.8 and "critically delayed" or "delayed"
                        AddGain(15, (proc.label or "Proc") .. " consumption is " .. severity ..
                            " — held " .. heldStr .. "s on average (budget: " .. maxTime ..
                            "s). Consume procs immediately when they appear.")
                    end
                end
            end
        end

        -- Resource overcap
        local rmScore = scores.resourceMgmt or 100
        if rmScore < 80 then
            local rate = string.format("%.1f", overcapEvents / math.max(1, duration / 60))
            AddGain(15, "Overcapped " .. (spec.resourceLabel or "resource") .. " " ..
                overcapEvents .. " time(s) (" .. rate .. "/min) — spend " ..
                (spec.resourceLabel or "resource") ..
                " before reaching " .. (spec.overcapAt or 100) ..
                " to avoid wasted generation.")
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
                        AddGain(35, label .. " was never activated — press it on cooldown " ..
                            "every time it is available to reduce physical damage taken.")
                    elseif actual < target * 0.6 then
                        local gap = target - actual
                        AddGain(30, label .. ": " .. actual .. "% uptime vs " .. target ..
                            "% target (" .. gap .. "pt gap, " .. apps ..
                            " application(s)) — you have large windows of unmitigated " ..
                            "physical damage. Press it the moment it comes off cooldown.")
                    elseif actual < target * 0.8 then
                        local gap = target - actual
                        AddGain(20, label .. ": " .. actual .. "% uptime vs " .. target ..
                            "% target (" .. gap .. "pt gap) — small gaps are adding up. " ..
                            "Use it preemptively on heavy melee sequences, not reactively.")
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
                        AddGain(20, (buff.label or "Buff") .. ": " ..
                            math.floor(data.actualPct) .. "% uptime vs " ..
                            data.targetUptime .. "% target (" .. gap ..
                            "pt gap) — reapply before it expires, not after.")
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
                            (buff.label or "Buff") .. " (group buff — ensure it's active before combat)")
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
                    AddGain(25, string.format(
                        "Overheal at %.1f%% (target: <%d%%) — you are spending mana on " ..
                        "targets that do not need healing. Cast slightly later or " ..
                        "switch to reactive spells on targets actively taking damage.",
                        overpct, target))
                elseif overpct > target + 10 then
                    Add(string.format(
                        "Overheal: %.1f%% (target: <%d%%) — slightly elevated. " ..
                        "Hold casts on targets above 70%% health and prioritise " ..
                        "HoTs over direct heals on stable groups.",
                        overpct, target))
                end
            end
        end
        if actScore < 70 and totalGCDs > 0 then
            Add("When the group is stable, fill downtime with damage spells " ..
                "to maintain throughput.")
        end
    end

    -- ── Behavior tone fallback ───────────────────────────────────────────────
    if inferSimplified and #feedback == 0 then
        Add("Your rotation is consistent and well-paced. " ..
            "Tightening burst window timing is the next performance step.")
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
                table.insert(nextSteps, "pre-position defensives before predictable spike damage")
            elseif isHealer then
                table.insert(nextSteps, "overlap cooldowns with incoming damage casts rather than reacting")
            else
                table.insert(nextSteps, "align burst windows with enemy vulnerability phases")
            end
            table.insert(nextSteps, "reduce time between the GCD ending and your next cast to sub-0.2s")
            Add("Near-perfect execution. The remaining gains are: " ..
                table.concat(nextSteps, "; ") .. ".")
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
            Add("Strong execution overall. Your lowest category is " ..
                catHint .. " — that is where the next points come from.")
        elseif cdScore < 80 or mitScore < 80 then
            local hints = {}
            if cdScore < 80 then
                table.insert(hints, isTank
                    and "use defensive cooldowns on tank busters"
                    or  "press major cooldowns more consistently")
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
                table.insert(hints, "increase mitigation uptime by pressing " .. mitAbility .. " more frequently")
            end
            Add("Good foundation — focus next on: " .. table.concat(hints, "; ") .. ".")
        else
            Add("Solid performance — tighten up cooldown timing to push higher.")
        end
    end

    -- Cap at 8 — enough room for all meaningful coaching points
    while #feedback > 8 do table.remove(feedback) end

    -- Interrupt note always appended last — friendly reminder, never penalised, never buried
    if #interruptNeverUsed > 0 then
        table.insert(feedback, "Note: " .. table.concat(interruptNeverUsed, ", ") ..
            " — this is your interrupt. Not used this fight — no penalty.")
    end

    -- Utility note — informational, never penalised (Spellsteal, missing group buffs, etc.)
    if #utilityNeverUsed > 0 then
        table.insert(feedback, "Note: " .. table.concat(utilityNeverUsed, "; ") ..
            " — not used or detected this fight. No penalty.")
    end

    return feedback
end
