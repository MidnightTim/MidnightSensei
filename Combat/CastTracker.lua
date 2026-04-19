--------------------------------------------------------------------------------
-- Midnight Sensei: Combat/CastTracker.lua
-- Tracks spell casts, cooldown usage, rotational spell counts, and GCD activity.
--
-- Moved from Analytics/Engine.lua (OnCombatStart setup + ABILITY_USED handler).
-- All state is private.  Engine.lua reads via getters on fight end (BuildState).
--
-- Exposes on MS.CombatLog:
--   GetCdTracking()          → [spellID] = { lastUsed, useCount, label, ... }
--   GetRotationalTracking()  → [spellID] = { useCount, label, minFightSeconds, ... }
--   GetTotalGCDs()           → number
--   GetActiveGCDs()          → number
--------------------------------------------------------------------------------

MidnightSensei        = MidnightSensei        or {}
MidnightSensei.Combat = MidnightSensei.Combat or {}

local MS   = MidnightSensei
local Core = MS.Core
local CL   = MS.CombatLog

-- ── Private fight state ──────────────────────────────────────────────────────
local cdTracking         = {}
local rotationalTracking = {}
local altIdMap           = {}   -- altId → primary rotational spellID
local totalGCDs          = 0
local activeGCDs         = 0
local fightActive        = false

-- Pre-combat cast buffer — opener spells (e.g. Frozen Orb used to pull) fire
-- UNIT_SPELLCAST_SUCCEEDED before PLAYER_REGEN_DISABLED, so cdTracking doesn't
-- exist yet.  Buffer casts outside combat and replay them at COMBAT_START.
local preCombatBuffer   = {}
local PRE_COMBAT_WINDOW = 5   -- seconds before combat start to credit

-- ── Public getters ───────────────────────────────────────────────────────────
function CL.GetCdTracking()         return cdTracking         end
function CL.GetRotationalTracking() return rotationalTracking end
function CL.GetTotalGCDs()          return totalGCDs          end
function CL.GetActiveGCDs()         return activeGCDs         end

-- ── Talent detection ─────────────────────────────────────────────────────────
-- C_Traits node-walk, with optional strict mode (skips IsPlayerSpell fallback).
-- strict=true: used for talentGated spells where grayed cross-spec spells appear
-- in the spellbook and IsPlayerSpell returns true even when not talented.
local function IsTalentActive(spellID, strict)
    if C_Traits and C_Traits.GetNodeInfo then
        local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID
                         and C_ClassTalents.GetActiveConfigID()
        if configID then
            local config = C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
            if config and config.treeIDs then
                for _, treeID in ipairs(config.treeIDs) do
                    local nodes = C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeID)
                    if nodes then
                        for _, nodeID in ipairs(nodes) do
                            local node = C_Traits.GetNodeInfo(configID, nodeID)
                            if node and node.activeRank and node.activeRank > 0 then
                                local entry = node.activeEntry
                                if entry then
                                    local def = C_Traits.GetEntryInfo
                                                and C_Traits.GetEntryInfo(configID, entry.entryID)
                                    if def and def.definitionID then
                                        local defInfo = C_Traits.GetDefinitionInfo
                                                        and C_Traits.GetDefinitionInfo(def.definitionID)
                                        if defInfo and defInfo.spellID == spellID then
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if strict then return false end
    return IsPlayerSpell and IsPlayerSpell(spellID) or false
end

-- ── Combat start ─────────────────────────────────────────────────────────────
Core.On(Core.EVENTS.COMBAT_START, function()
    fightActive        = true
    cdTracking         = {}
    rotationalTracking = {}
    totalGCDs          = 0
    activeGCDs         = 0

    local spec = Core.ActiveSpec
    if not spec then return end

    -- Pre-populate CD tracking for spells the player has this fight.
    if spec.majorCooldowns then
        for _, cd in ipairs(spec.majorCooldowns) do
            -- Enforce validSpells whitelist if present
            if spec.validSpells and not spec.validSpells[cd.id] then
                -- not whitelisted for this spec — skip
            elseif cd.displayOnly then
                -- shapeshift / display-only — not trackable via UNIT_SPELLCAST_SUCCEEDED
            elseif cd.suppressIfTalent and IsTalentActive(cd.suppressIfTalent) then
                -- talent makes this CD passive — skip
            else
                local known
                if cd.talentGated then
                    -- Require both checks: IsTalentActive(strict) blocks grayed cross-spec
                    -- spells (IsPlayerSpell=true but not really talented), while IsPlayerSpell
                    -- blocks passive prereq nodes that are "active" in C_Traits but not
                    -- castable (e.g. Frostfire Bolt in the Frostfire hero talent path).
                    known = IsTalentActive(cd.id, true)
                        and (IsPlayerSpell and IsPlayerSpell(cd.id) or false)
                else
                    known = (IsPlayerSpell and IsPlayerSpell(cd.id))
                           or IsTalentActive(cd.id)
                end
                if known then
                    cdTracking[cd.id] = {
                        lastUsed        = 0,
                        useCount        = 0,
                        expectedUses    = cd.expectedUses,
                        label           = cd.label,
                        minFightSeconds = cd.minFightSeconds,
                    }
                end
            end
        end
    end

    -- Add racial cooldowns — IsPlayerSpell filters to the player's actual race
    if Core.GetRacialCooldowns then
        for _, cd in ipairs(Core.GetRacialCooldowns()) do
            if IsPlayerSpell and IsPlayerSpell(cd.id) then
                cdTracking[cd.id] = {
                    lastUsed     = 0,
                    useCount     = 0,
                    expectedUses = cd.expectedUses,
                    label        = cd.label,
                }
            end
        end
    end

    -- Pre-populate rotational spell tracking.
    -- combatGated spells always included (no spellbook entry at fight start).
    -- talentGated spells: strict C_Traits check only.
    -- suppressIfTalent: skip when a replacing talent is active.
    if spec.rotationalSpells then
        for _, rs in ipairs(spec.rotationalSpells) do
            if spec.validSpells and not spec.validSpells[rs.id] then
                -- not whitelisted — skip
            else
                local include = true
                if rs.combatGated then
                    include = true  -- always include; minFightSeconds gates feedback
                elseif rs.talentGated then
                    include = IsTalentActive(rs.id, true)
                        and (IsPlayerSpell and IsPlayerSpell(rs.id) or false)
                end
                if include and rs.suppressIfTalent then
                    if IsTalentActive(rs.suppressIfTalent) then
                        include = false
                    end
                end
                if include then
                    rotationalTracking[rs.id] = {
                        useCount        = 0,
                        label           = rs.label,
                        minFightSeconds = rs.minFightSeconds or 60,
                        combatGated     = rs.combatGated or false,
                        cdSec           = rs.cdSec or nil,
                        orGroup         = rs.orGroup or nil,
                    }
                end
            end
        end
    end

    -- Build reverse map: altId → primary rotational spellID.
    -- Covers cases where the game fires a different ID for the same ability
    -- (e.g. Healing Rain 73920 → 456366 when Surging Totem hero talent is active).
    altIdMap = {}
    if spec.rotationalSpells then
        for _, rs in ipairs(spec.rotationalSpells) do
            if rs.altIds and rotationalTracking[rs.id] then
                for _, altId in ipairs(rs.altIds) do
                    altIdMap[altId] = rs.id
                end
            end
        end
    end

    -- Replay pre-combat opener casts against the freshly-built tracking tables.
    -- Covers spells used to pull (e.g. Frozen Orb) that fired UNIT_SPELLCAST_SUCCEEDED
    -- before PLAYER_REGEN_DISABLED — those casts would otherwise count as zero uses.
    local now = GetTime()
    for _, cast in ipairs(preCombatBuffer) do
        if (now - cast.timestamp) <= PRE_COMBAT_WINDOW then
            local cd = cdTracking[cast.spellID]
            if cd then
                cd.lastUsed = cast.timestamp
                cd.useCount = cd.useCount + 1
            end
            local rsId = altIdMap[cast.spellID] or cast.spellID
            local rs = rotationalTracking[rsId]
            if rs then
                rs.useCount = rs.useCount + 1
            end
            totalGCDs  = totalGCDs  + 1
            activeGCDs = activeGCDs + 1
        end
    end
    preCombatBuffer = {}
end)

Core.On(Core.EVENTS.COMBAT_END, function()
    fightActive     = false
    preCombatBuffer = {}
    altIdMap        = {}
end)

-- ── Ability used hook ────────────────────────────────────────────────────────
-- Increments GCD counters, CD use counts, and rotational spell use counts.
-- Outside combat: buffer the cast so opener spells used to pull are credited
-- when COMBAT_START fires and tracking tables are built.
Core.On(Core.EVENTS.ABILITY_USED, function(spellID, timestamp)
    if not fightActive then
        -- Buffer and trim to PRE_COMBAT_WINDOW
        table.insert(preCombatBuffer, { spellID = spellID, timestamp = timestamp })
        local cutoff = timestamp - PRE_COMBAT_WINDOW
        while #preCombatBuffer > 0 and preCombatBuffer[1].timestamp < cutoff do
            table.remove(preCombatBuffer, 1)
        end
        return
    end

    totalGCDs  = totalGCDs  + 1
    activeGCDs = activeGCDs + 1

    local cd = cdTracking[spellID]
    if cd then
        cd.lastUsed = timestamp
        cd.useCount = cd.useCount + 1
    end

    local rsId = altIdMap[spellID] or spellID
    local rs = rotationalTracking[rsId]
    if rs then
        rs.useCount = rs.useCount + 1
    end
end)
