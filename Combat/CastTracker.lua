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
local totalGCDs          = 0
local activeGCDs         = 0
local fightActive        = false

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
                    known = IsTalentActive(cd.id, true)
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
end)

Core.On(Core.EVENTS.COMBAT_END, function()
    fightActive = false
end)

-- ── Ability used hook ────────────────────────────────────────────────────────
-- Increments GCD counters, CD use counts, and rotational spell use counts.
Core.On(Core.EVENTS.ABILITY_USED, function(spellID, timestamp)
    if not fightActive then return end

    totalGCDs  = totalGCDs  + 1
    activeGCDs = activeGCDs + 1

    local cd = cdTracking[spellID]
    if cd then
        cd.lastUsed = timestamp
        cd.useCount = cd.useCount + 1
    end

    local rs = rotationalTracking[spellID]
    if rs then
        rs.useCount = rs.useCount + 1
    end
end)
