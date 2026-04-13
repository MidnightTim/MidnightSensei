--------------------------------------------------------------------------------
-- Midnight Sensei: Core.lua
-- Spec database, event bus, ticks, SavedVariables, slash commands
-- Display name: "Midnight Sensei" (with space) everywhere in UI strings
-- Lua identifiers remain MidnightSensei (no space) for API compatibility
--------------------------------------------------------------------------------

MidnightSensei             = MidnightSensei             or {}
MidnightSensei.Core        = MidnightSensei.Core        or {}
MidnightSensei.Analytics   = MidnightSensei.Analytics   or {}
MidnightSensei.UI          = MidnightSensei.UI          or {}
MidnightSensei.Utils       = MidnightSensei.Utils       or {}
MidnightSensei.CombatLog   = MidnightSensei.CombatLog   or {}
MidnightSensei.Leaderboard = MidnightSensei.Leaderboard or {}
MidnightSensei.BossBoard   = MidnightSensei.BossBoard   or {}

local MS   = MidnightSensei
local Core = MS.Core

-- Read version from TOC at runtime. GetAddOnInfo(name) returns:
-- name, title, notes, enabled, loadable, reason, security, newVersion
-- The TOC ## Version: field is returned by C_AddOns.GetAddOnMetadata.
-- GetAddOnInfo does NOT return version; we try both known APIs safely.
do
    local ver = nil
    -- Midnight 12.0+
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ok, v = pcall(C_AddOns.GetAddOnMetadata, "MidnightSensei", "Version")
        if ok and v and v ~= "" then ver = v end
    end
    -- Legacy / fallback
    if not ver and GetAddOnMetadata then
        local ok, v = pcall(GetAddOnMetadata, "MidnightSensei", "Version")
        if ok and v and v ~= "" then ver = v end
    end
    Core.VERSION = ver or "1.4.0"
end
Core.DISPLAY_NAME = "Midnight Sensei"   -- always use this in UI strings
Core.TAGLINE      = "Combat performance coaching for all 13 classes - grade your fights A+ to F."

--------------------------------------------------------------------------------
-- Nil-safe cross-module calls
--------------------------------------------------------------------------------
local function Call(mod, fn, ...)
    local f = mod and mod[fn]
    if type(f) == "function" then return f(...) end
end
Core.Call = Call

--------------------------------------------------------------------------------
-- Internal Event Bus
--------------------------------------------------------------------------------
Core.EVENTS = {
    COMBAT_START     = "COMBAT_START",
    COMBAT_END       = "COMBAT_END",
    ABILITY_USED     = "ABILITY_USED",
    SPEC_CHANGED     = "SPEC_CHANGED",
    SESSION_READY    = "SESSION_READY",
    SETTINGS_CHANGED = "SETTINGS_CHANGED",
    CD_UPDATE        = "CD_UPDATE",
    GRADE_CALCULATED = "GRADE_CALCULATED",
    BUFF_APPLIED     = "BUFF_APPLIED",
    BUFF_REMOVED     = "BUFF_REMOVED",
    DOT_APPLIED      = "DOT_APPLIED",
    DOT_REMOVED      = "DOT_REMOVED",
    BOSS_START       = "BOSS_START",
    BOSS_END         = "BOSS_END",
}

-- Boss encounter state (set by ENCOUNTER_START/END WoW events)
Core.CurrentEncounter = { isBoss = false, name = nil, id = nil, difficultyID = nil }

local listeners = {}
function Core.On(event, fn)
    if not listeners[event] then listeners[event] = {} end
    table.insert(listeners[event], fn)
end
function Core.Emit(event, ...)
    local fns = listeners[event]
    if not fns then return end
    for i = 1, #fns do
        local ok, err = pcall(fns[i], ...)
        if not ok and Core.GetSetting and Core.GetSetting("debugMode") then
            print("|cffFF4444Midnight Sensei Error [" .. event .. "]:|r " .. tostring(err))
        end
    end
end

--------------------------------------------------------------------------------
-- Shared Tick System
--------------------------------------------------------------------------------
local tickFrame     = CreateFrame("Frame", "MidnightSenseiTickFrame", UIParent)
local tickSubs      = {}
local masterElapsed = 0

function Core.RegisterTick(key, interval, fn)
    tickSubs[key] = { interval = interval, fn = fn, lastCall = 0 }
end
function Core.UnregisterTick(key)
    tickSubs[key] = nil
end

tickFrame:SetScript("OnUpdate", function(_, elapsed)
    masterElapsed = masterElapsed + elapsed
    for _, sub in pairs(tickSubs) do
        if masterElapsed - sub.lastCall >= sub.interval then
            sub.lastCall = masterElapsed
            local ok, err = pcall(sub.fn, elapsed)
            if not ok and Core.GetSetting and Core.GetSetting("debugMode") then
                print("|cff888888MS tick error:|r " .. tostring(err))
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- SavedVariables  (schema v3)
-- MidnightSenseiDB     = account-wide: guild leaderboard, friend list, debug log
-- MidnightSenseiCharDB = per-character: encounters history, HUD settings
--------------------------------------------------------------------------------
local SCHEMA_VERSION = 3

function Core.InitSavedVariables()
    -- Account-wide DB
    MidnightSenseiDB = MidnightSenseiDB or {}
    local db = MidnightSenseiDB
    db.leaderboard      = db.leaderboard      or {}
    db.debugLog         = db.debugLog         or {}
    -- Shared Boss Board snapshots — guild/friend all-time bests, account-wide
    -- Always stores the higher score when updated. Keyed by "Name-Realm|bossID"
    db.bossBoardShared  = db.bossBoardShared  or {}

    -- Per-character DB — settings and encounters are character-specific
    MidnightSenseiCharDB = MidnightSenseiCharDB or {}
    local cdb = MidnightSenseiCharDB
    cdb.encounters = cdb.encounters or {}
    cdb.settings   = cdb.settings   or {}
    cdb.bests      = cdb.bests      or {
        -- All-time bests (never reset)
        allTimeBest     = 0,
        dungeonBest     = 0,
        raidBest        = 0,
        delveBest       = 0,
        -- Weekly bests per content type (reset each WoW week)
        weekKey         = "",
        weeklyAvg       = 0,   -- mixed all-boss avg for overall leaderboard sort
        weekScores      = {},
        weeklyDungeonBest  = 0,
        weeklyRaidBest     = 0,
        weeklyDelveBest    = 0,
    }
    -- Spell and talent snapshots — populated on SPELLS_CHANGED / PLAYER_TALENT_UPDATE
    -- nil until first snapshot is taken; no DB bloat until actually triggered
    -- cdb.spellSnapshot  = { timestamp, spec, spells[] }
    -- cdb.talentSnapshot = { timestamp, spec, talents[] }
    local s = cdb.settings
    local function def(k, v) if s[k] == nil then s[k] = v end end
    def("hudVisibility",    "always")
    def("showPostFight",    true)
    def("gradeStyle",       "encouraging")
    def("trackHealing",     true)
    def("trackDPS",         true)
    def("anchorX",          0)
    def("anchorY",          -200)
    def("lockWindow",       false)
    def("minimumFight",     15)
    def("encounterAdjust",  true)
    def("debugMode",        false)
end

-- Schema v2 → v3 migration: move encounters from account-wide DB to CharDB.
-- Runs at SESSION_READY so UnitName("player") is guaranteed available.
-- Safe to call multiple times — exits immediately if nothing to migrate.
function Core.MigrateEncounters()
    local db  = MidnightSenseiDB
    local cdb = MidnightSenseiCharDB
    if not db or not db.encounters or #db.encounters == 0 then return end
    if cdb.encounters and #cdb.encounters > 0 then return end  -- already migrated

    local myName  = UnitName("player") or ""
    local myRealm = GetRealmName()     or ""
    if myName == "" then return end  -- not in world yet, skip

    local migrated = {}
    for _, enc in ipairs(db.encounters) do
        if (enc.charName or "") == myName and (enc.realmName or "") == myRealm then
            table.insert(migrated, enc)
        end
    end
    if #migrated > 0 then
        cdb.encounters = migrated
        if Core.GetSetting("debugMode") then
            print("|cff888888MS:|r Migrated " .. #migrated .. " encounters to CharDB for " .. myName)
        end
    end
    -- Leave db.encounters intact — other characters migrate their own slice on login
end

function Core.GetSetting(key)
    return MidnightSenseiCharDB and MidnightSenseiCharDB.settings and MidnightSenseiCharDB.settings[key]
end
function Core.SetSetting(key, value)
    if MidnightSenseiCharDB and MidnightSenseiCharDB.settings then
        MidnightSenseiCharDB.settings[key] = value
        Core.Emit(Core.EVENTS.SETTINGS_CHANGED, key, value)
    end
end

--------------------------------------------------------------------------------
-- Role types
--------------------------------------------------------------------------------
Core.ROLE = { DPS = "DPS", HEALER = "HEALER", TANK = "TANK" }

--------------------------------------------------------------------------------
-- Grade Definitions  (encouraging labels)
--------------------------------------------------------------------------------
Core.GRADES = {
    { letter = "A+", min = 95, color = {0.20, 0.90, 0.20}, label = "Exceptional"     },
    { letter = "A",  min = 90, color = {0.30, 0.85, 0.30}, label = "Excellent"       },
    { letter = "A-", min = 85, color = {0.40, 0.80, 0.35}, label = "Great work"      },
    { letter = "B+", min = 80, color = {0.50, 0.80, 0.40}, label = "Strong"          },
    { letter = "B",  min = 75, color = {0.70, 0.80, 0.30}, label = "On track"        },
    { letter = "B-", min = 70, color = {0.85, 0.80, 0.25}, label = "Solid"           },
    { letter = "C+", min = 65, color = {0.95, 0.75, 0.20}, label = "Good foundation" },
    { letter = "C",  min = 60, color = {1.00, 0.70, 0.15}, label = "Room to grow"    },
    { letter = "C-", min = 55, color = {1.00, 0.60, 0.10}, label = "Keep practicing" },
    { letter = "D+", min = 50, color = {1.00, 0.50, 0.10}, label = "Building habits" },
    { letter = "D",  min = 45, color = {1.00, 0.40, 0.10}, label = "Learning curve"  },
    { letter = "D-", min = 40, color = {1.00, 0.30, 0.10}, label = "Early days"      },
    { letter = "F",  min = 0,  color = {1.00, 0.20, 0.20}, label = "Fresh start"     },
}

function Core.GetGrade(score)
    score = score or 0
    for _, g in ipairs(Core.GRADES) do
        if score >= g.min then return g.letter, g.color, g.label end
    end
    return "F", {1.00, 0.20, 0.20}, "Fresh start"
end

--------------------------------------------------------------------------------
-- Attribution
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- RACIAL_COOLDOWNS
-- Active combat racials tracked in fight scoring.
-- Only racials with a meaningful combat window (offensive/defensive/heal).
-- All go through IsPlayerSpell() at fight start — wrong-race entries ignored.
--------------------------------------------------------------------------------
Core.RACIAL_COOLDOWNS = {
    { id = 33702,  label = "Blood Fury",       race = "Orc",                 category = "offensive" },
    { id = 26297,  label = "Berserking",        race = "Troll",               category = "offensive" },
    { id = 265221, label = "Fireblood",         race = "Dark Iron Dwarf",     category = "offensive" },
    { id = 255647, label = "Light's Judgment",  race = "Lightforged Draenei", category = "offensive" },
    { id = 274738, label = "Ancestral Call",    race = "Mag'har Orc",         category = "offensive" },
    { id = 312411, label = "Bag of Tricks",     race = "Vulpera",             category = "offensive" },
    { id = 69041,  label = "Rocket Barrage",    race = "Goblin",              category = "offensive" },
    { id = 20594,  label = "Stoneform",         race = "Dwarf",               category = "defensive" },
    { id = 7744,   label = "Will of Forsaken",  race = "Undead",              category = "defensive" },
    { id = 59752,  label = "Will to Survive",   race = "Human",               category = "defensive" },
    { id = 59542,  label = "Gift of the Naaru", race = "Draenei",             category = "heal"      },
    { id = 291944, label = "Regeneratin'",      race = "Zandalari Troll",     category = "heal"      },
    { id = 312924, label = "Hyper Organic",     race = "Mechagnome",          category = "heal"      },
}

-- Returns racial cooldowns relevant to the current player's role.
-- Offensive always included; defensive for tanks+healers; heal for healers.
function Core.GetRacialCooldowns()
    local spec = Core.ActiveSpec
    if not spec then return {} end
    local result = {}
    for _, r in ipairs(Core.RACIAL_COOLDOWNS) do
        local include = (r.category == "offensive")
            or (r.category == "defensive" and (spec.role == Core.ROLE.TANK or spec.role == Core.ROLE.HEALER))
            or (r.category == "heal" and spec.role == Core.ROLE.HEALER)
        if include then
            table.insert(result, { id = r.id, label = r.label .. " (racial)", expectedUses = "on CD" })
        end
    end
    return result
end

Core.CREDITS = {
    { source = "Wowhead",         url = "https://www.wowhead.com",         desc = "Spell data and talent information"         },
    { source = "SimulationCraft", url = "https://www.simulationcraft.org", desc = "DPS baseline methodology and APL concepts" },
    { source = "WoWAnalyzer",     url = "https://wowanalyzer.com",         desc = "Performance analysis patterns and metrics" },
    { source = "Warcraft Logs",   url = "https://www.warcraftlogs.com",    desc = "Community performance benchmarks"          },
}

Core.CHANGELOG = {
    {
        version = "1.4.0",
        tagline = "Class Tuning & Refinement — Full Spec Database Audit",
        date    = "April 2026",
        changes = {
            -- Spec DB methodology
            "Full talent tree PASSIVE audit completed across all 13 classes — passive spells can no longer be accidentally tracked as castable abilities",
            "Talent snapshot tool upgraded — now captures ALL nodes (ACTIVE and INACTIVE), adds PASSIVE column, entryID, rank/maxRank, and summary counts",
            "Debug talent export now shows Total/ACTIVE/INACTIVE/PASSIVE counts in header — passive entries flagged inline to prevent future spec DB errors",
            "Cross-spec contamination check run against all uploaded snapshots — one misattribution (Red Moon in Guardian) found and corrected",
            "isInterrupt flag added to spec DB — interrupt abilities tracked but never penalised; informational note appended at bottom of feedback",
            -- Warlock
            "Affliction: Malevolence corrected to 442726, Dark Harvest corrected to 1257052, Phantom Singularity and Vile Taint removed (pruned in Midnight 12.0)",
            "Affliction: Wither (445468) added as talentGated CD — confirmed non-PASSIVE nodeID 94840",
            "Affliction: Unstable Affliction, Drain Soul (686), Seed of Corruption added to rotational",
            "Affliction: Drain Soul 388667 removed — confirmed PASSIVE nodeID 72045; 686 baseline covers tracking",
            "Affliction: Nightfall added to procBuffs (VERIFY C_UnitAuras)",
            "Demonology: Full PASSIVE audit — Diabolic Ritual, Summon Vilefiend, Reign of Tyranny, Doom all confirmed PASSIVE and removed",
            "Demonology: Hand of Gul'dan corrected to 105174 (talent cast ID); 172 baseline removed — was silently never matching",
            "Demonology: Grimoire: Fel Ravager marked isInterrupt — DPS summon + interrupt, not penalised if unused",
            "Demonology: Demonbolt, Dark Harvest added to rotational; Summon Doomguard added to majorCooldowns",
            "Destruction: Malevolence corrected to 442726, Havoc removed (not in Destruction tree), Immolate removed (not in spell list)",
            "Destruction: Incinerate corrected to 686 (spec-variant baseline), Diabolic Ritual and Devastation removed (confirmed PASSIVE)",
            "Destruction: Conflagrate, Shadowburn, Rain of Fire added to rotational",
            -- Demon Hunter
            "Havoc: Fel Barrage removed (not in Midnight 12.0), Chaos Strike corrected to 344862 (spec-variant)",
            "Havoc: Essence Break and Felblade added to rotational — confirmed non-PASSIVE ACTIVE",
            "Havoc: Furious Gaze and Unbound Chaos proc buffs flagged VERIFY — not confirmed in any snapshot",
            "Vengeance: Metamorphosis corrected to 191427, Demon Spikes corrected to 203720, Fracture to 344859, Soul Cleave to 344862",
            "Vengeance: Soul Barrier removed (not in Midnight 12.0), Spirit Bomb and Felblade added to rotational",
            "Vengeance: Sigil of Spite added to majorCooldowns — confirmed non-PASSIVE ACTIVE",
            "Devourer: Full PASSIVE audit — Impending Apocalypse, Demonsurge, Midnight, Eradicate all confirmed PASSIVE and removed",
            "Devourer: Soul Immolation retained as sole majorCooldown — only confirmed non-PASSIVE trackable CD in the tree",
            "Devourer: scoreWeights adjusted to reflect reduced CD tracking (cooldownUsage 30 -> 25, activity 35 -> 40)",
            "Lua brace error fixed — duplicate unclosed stub in Havoc entry caused entire Demon Hunter class to be one depth level too deep",
            -- Shaman
            "Elemental: Tempest removed — confirmed PASSIVE nodeID 94892",
            "Enhancement: Feral Spirit, Ascendance, Primordial Wave all removed — confirmed PASSIVE or not in Midnight 12.0",
            "Enhancement: Maelstrom Weapon procBuff corrected to 187880 (was 344179 — wrong ID)",
            "Enhancement: Surging Totem added to majorCooldowns, Crash Lightning, Lava Lash, Voltaic Blaze added to rotational",
            "Restoration Shaman: Call of the Ancestors removed — confirmed PASSIVE nodeID 94888",
            -- Evoker
            "Devastation: Pyre added to rotational, Quell added as isInterrupt",
            "Preservation: Emerald Communion removed (not in tree), Tip the Scales corrected to 370553 (was 374348 — Renewing Blaze)",
            "Preservation: Time Dilation added to majorCooldowns, Temporal Anomaly and Echo added to rotational",
            "Augmentation: Eruption corrected to 395160 (was 359618 — wrong ID), Time Skip and Blistering Scales added to majorCooldowns",
            "Augmentation: Quell added as isInterrupt",
            -- Druid
            "Balance: Starfall moved from majorCooldowns to rotational (spender not a burst CD), Force of Nature and Fury of Elune added",
            "Balance: Wrath added to rotational — primary AP generator filler was missing",
            "Feral: Shred added to rotational (primary CP builder was missing), Convoke the Spirits added as talentGated CD",
            "Feral: Incarnation: Avatar of Ashamane removed (not in Feral talent tree), Predatory Swiftness removed (unconfirmed)",
            "Feral: Frantic Frenzy, Feral Frenzy added as talentGated CDs, Primal Wrath added to rotational",
            "Guardian: Moonfire added to rotational (priority #1), Maul added to rotational, Lunar Beam added to majorCooldowns",
            "Guardian: Survival Instincts removed (not in rotation guide priority list)",
            "Guardian: Red Moon correctly identified as Balance-only — removed from Guardian after cross-spec audit",
            "Restoration Druid: Incarnation: Tree of Life and Flourish removed (not in talent tree or spell list)",
            "Restoration Druid: Wild Growth moved from majorCooldowns to rotational, Convoke the Spirits added as talentGated CD",
            "Restoration Druid: Ironbark, Nature's Swiftness, Innervate added to majorCooldowns, Lifebloom added to rotational",
            -- Feedback
            "Interrupt note moved to always appear at the very bottom of feedback — never competes with scored items",
            "Interrupt note appended after the 8-item cap so it is always visible regardless of feedback volume",
        },
    },
    {
        version = "1.3.10",
        tagline = "HUD Overhaul, Boss Board Feedback, Demonology Pass & Quality of Life",
        date    = "April 2026",
        changes = {
            -- HUD
            "HUD: gear icon added to title strip using WoW native UI-OptionsButton texture — opens context menu on click, replaces right-click handler",
            "HUD: X button added to title strip — hides HUD on click, turns red on hover",
            "HUD: Review Fight button moved to center zone above separator, appears only after a fight completes, centered at 90px wide",
            "HUD: Review Fight now toggles — first click opens Fight Complete panel, second click closes it",
            "HUD: Boss Board button added to bottom-left permanent position replacing Review Fight",
            "HUD: bottom row is now Boss Board (left) and Leaderboard (right) — both always visible",
            -- Boss Board
            "Boss Board: description text added below title — explains individual highest scores per boss in Midnight",
            "Boss Board: rows are now clickable — left-click opens Encounter Detail popup showing feedback and component scores for that best run",
            "Boss Board: bestFeedback, bestComponents, bestDuration, bestGradeLabel now stored permanently in bossBests — never lost to encounter cap rollover",
            "Boss Board: feedback stored at fight time in Analytics, not just on ingest — new bests always capture feedback permanently",
            "Boss Board: ingest backfills feedback from existing encounters; updated and skipped paths both store feedback fields",
            "Boss Board: BB.RepairIdentity() added — /ms debug bossboard repair patches ? identity on all entries without score comparison",
            "Boss Board: Core.DetectSpec() called at ingest start to ensure spec fallback is populated before identity resolution",
            "Boss Board: updated path now applies identity fallback for nil fields (was only applying for explicit enc values)",
            -- Window behaviour
            "Windows: Fight Complete strata raised to DIALOG — now always renders above Grade History and Leaderboard",
            "Windows: Fight Complete anchors to right of HUD frame on first open, falls back to CENTER +160, +60 if HUD hidden",
            "Windows: default positions spread across screen — History CENTER -340, BossBoard CENTER +80, Leaderboard CENTER +380",
            "Windows: History and Leaderboard buttons inside Fight Complete now close it before opening the target panel",
            -- Toggle fixes
            "Fix: Boss Board and Leaderboard required two clicks to open — explicit f:Hide() added to CreateBossBoardFrame, Toggle rewired to reference module-level frame directly",
            "Fix: Leaderboard Toggle had same double-call pattern as Boss Board — same fix applied",
            "Fix: Review Fight toggle used a permanently-nil upvalue due to Lua declaration order — replaced with _G[\"MidnightSenseiResult\"] lookup at click time",
            -- Clear History
            "Clear History button removed from Grade History panel — was too easy to misclick with no confirmation",
            "Clear Fight History moved to Debug Tools Recovery Tools section with red-tinted styling and blocking confirmation dialog",
            -- Demonology Warlock
            "Demonology: Malevolence ID corrected 458355 to 442726 — confirmed in Midnight 12.0 spell list",
            "Demonology: Summon Vilefiend (264119) removed — not present in Midnight 12.0",
            "Demonology: Power Siphon (264170) removed — not present in Midnight 12.0",
            "Demonology: Summon Doomguard (1276672) added to majorCooldowns — confirmed nodeID 101917",
            "Demonology: Grimoire: Fel Ravager (1276467) added as talentGated cooldown — confirmed nodeID 110197",
            "Demonology: Diabolic Ritual (428514) added as talentGated cooldown — confirmed nodeID 94855",
            "Demonology: Hand of Gul'dan (172) added to rotationalSpells — core shard spender was missing entirely",
            "Demonology: Demonbolt (264178) added to rotationalSpells — Demonic Core consumer",
            "Demonology: Doom (460551) added as talentGated rotational — confirmed nodeID 110200",
            "Demonology: Dark Harvest (1257052) added as talentGated rotational",
            -- Level gate notification
            "Login: sub-level 80 characters now receive a warning that fight tracking is disabled until level 80",
        },
    },
    {
        version = "1.3.9",
        tagline = "Boss Board, Spell/Talent Snapshot System & Debug Overhaul",
        date    = "April 2026",
        changes = {
            -- Boss Board
            "Boss Board added — personal all-time boss best leaderboard with Dungeons, Raids, and Delves tabs",
            "Boss Board columns: Date (MM/DD/YYYY), Character, Spec, Diff/Boss, Score — all five sortable, click again to toggle direction",
            "Boss Board tracks highest score per boss encounter ID (bossID) — all-time only, never resets",
            "Boss Board ingest: /ms debug bossboard ingest seeds bossBests from existing encounter history",
            "Boss Board ingest: fallback identity resolution for legacy encounters missing charName/specName/className",
            "Boss Board ingest: skipped entries now patched with identity data if previously stored as '?'",
            "Boss Board: shared snapshot stored in MidnightSenseiDB.bossBoardShared keyed by Name-Realm|bossID — always keeps higher score, updated at login and after each boss fight",
            "Boss Board: live refresh if board is open when a boss fight completes",
            "Boss Board: per-row hover tooltip shows boss name, instance, grade, date, and kill count",
            "Boss Board: class-coloured character names",
            "Boss Board accessible via /ms bossboard, /ms bb, right-click HUD context menu, Ctrl+Right-click minimap",
            -- Context menu
            "HUD right-click context menu: Boss Board added between Leaderboard and Options",
            -- Minimap
            "Minimap: Ctrl+Right-click opens Boss Board",
            "Minimap: tooltip updated to document Ctrl+Right-click binding",
            -- Analytics
            "Analytics: bossBests entries now store charName, specName, className, keystoneLevel — previously missing, required for Boss Board display",
            -- Debug window
            "Debug Tools: Boss Board Ingest button added to Recovery Tools section",
            -- Spell/talent snapshots (carried forward from 1.3.8 development)
            "Debug: persistent spell snapshot built on SPELLS_CHANGED and login — reads from CharDB via Spells Export button",
            "Debug: persistent talent snapshot built on PLAYER_TALENT_UPDATE and login — reads from CharDB via Talent Export button",
            "Debug Tools: Talent Export and Spells Export added under Class Debugging section",
            "Debug Tools: X button rendering fixed — was a box due to Unicode outside FRIZQT__.TTF coverage",
            "Debug Tools: section labels added — Class Debugging (cyan) and Recovery Tools (orange)",
            -- Grade history
            "Grade History: All Characters filter removed — was silently identical to This Character due to per-character SavedVariables split",
        },
    },
    {
        version = "1.3.8",
        tagline = "Shaman Pass, Spell/Talent Snapshots, Debug Overhaul & Level Gate",
        date    = "April 2026",
        changes = {
            -- Level gate
            "Analytics: fights below level 80 are no longer recorded or broadcast — prevents leveling kills, old-world farming, and timewalking alts from polluting history and averages",
            -- Elemental Shaman
            "Elemental: Flame Shock rotational ID corrected from 188196 (Lightning Bolt) to 470411 (confirmed Midnight 12.0 Elemental Spell List)",
            "Elemental: 60103 removed from rotationalSpells — confirmed Lava Lash (Enhancement), not a Lava Burst variant",
            "Elemental: Fire Elemental (198067) removed — no longer a manual summon in Midnight 12.0; auto-generated by Ascendance",
            "Elemental: Primordial Wave (375982) removed — pruned from Elemental in Midnight 12.0; merged into Voltaic Blaze",
            "Elemental: Earthquake (462620) added as talentGated rotational — confirmed nodeID 80985",
            "Elemental: Elemental Blast (117014) added as talentGated rotational — confirmed nodeID 80984",
            "Elemental: Voltaic Blaze (470057) added as talentGated rotational — confirmed nodeID 81007",
            "Elemental: Tempest (454009) added as talentGated rotational — confirmed nodeID 94892 (VERIFY cast ID)",
            -- Restoration Shaman
            "Restoration: Cloudburst Totem (157153) removed — pruned from Restoration in Midnight 12.0",
            "Restoration: Ancestral Guidance (108281) removed — removed from game in patch 11.1.0 (Feb 25 2025)",
            "Restoration: Healing Tide Totem (108280) removed — confirmed removed from Restoration in Midnight 12.0",
            "Restoration: Surging Totem (444995) added to majorCooldowns — new Midnight 12.0 talent, nodeID 94877; replaces Cloudburst role",
            "Restoration: Unleash Life (73685) added to majorCooldowns — confirmed nodeID 92677; pre-heal amplifier",
            "Restoration: Call of the Ancestors (443450) added as talentGated cooldown — confirmed nodeID 94888 (VERIFY)",
            "Restoration: rotationalSpells added for the first time — Riptide (61295), Chain Heal (1064), Healing Rain (73920)",
            "Restoration: Healing Rain moved from majorCooldowns to rotationalSpells — rotational maintenance, not a burst CD",
            -- Spell and talent snapshot system
            "Debug: persistent spell and talent snapshot system added — captures full spellbook and active talent tree on login, spec change, and SPELLS_CHANGED; stored in CharDB",
            "Debug: snapshots rebuilt automatically on SPELLS_CHANGED (debounced 1s), PLAYER_TALENT_UPDATE, and SESSION_READY (2s delay)",
            "Debug: Talent Export reads from persisted talentSnapshot — includes spellID, nodeID, name, rank, spec, and capture timestamp",
            "Debug: Spells Export reads from persisted spellSnapshot — includes spellID, name, subName, spec, and capture timestamp; uses C_SpellBook.GetSpellBookItemInfo",
            -- Debug window
            "Debug Tools: X button fixed — was rendering as a box due to Unicode character outside FRIZQT__.TTF coverage",
            "Debug Tools: Talent Export and Spells Export moved into new 'Class Debugging' section (accent coloured separator)",
            "Debug Tools: Backfill M+ Keys and Clean Payload remain in 'Recovery Tools' section",
            "Debug Tools: section label helper added — reusable coloured separator with label for future sections",
            -- Grade history
            "Grade History: All Characters filter removed — was silently showing only current character data due to per-character SavedVariables split in schema v3",
        },
    },
    {
        version = "1.3.7",
        tagline = "Leaderboard Overhaul, Minimap Button & Keystone Detection",
        date    = "April 2026",
        changes = {
            -- Leaderboard display
            "Leaderboard: frame widened to 720px — long boss/instance names no longer break across lines",
            "Leaderboard: split right column into LATEST and WK AVG — grade letter and score shown in each",
            "Leaderboard: four clickable sort headers — PLAYER (A-Z), RECENT DIFF/BOSS (timestamp), LATEST (score), WK AVG (weekly avg)",
            "Leaderboard: per-content-type location fields added — LFR no longer bleeds into the Dungeons tab",
            "Leaderboard: raidAvg and dungeonAvg now computed for self-entry from local history — WK AVG column was showing -- for own raids",
            -- Keystone
            "Keystone: GetActiveKeystoneInfo now used instead of GetSlottedKeystoneInfo — key level was nil during combat since the key is consumed before PLAYER_REGEN_DISABLED fires",
            "Keystone: /ms debug backfill keys command added — retroactively patches Mythic dungeon history using season best data from GetSeasonBestForMap; /ms debug backfill keys clear to revert",
            -- Grade History
            "Grade History: SPEC column renamed SPEC / DIFF and widened — difficulty label and M+ level now visible without truncation",
            "Grade History: truncation limit raised from 22 to 28 characters",
            -- UI cosmetic
            "UI: _final key filtered from component scores display — no longer shows as a raw row in Fight Complete and Encounter Detail panels",
            -- Minimap
            "Minimap: LibDBIcon minimap button added — left-click toggles HUD, right-click toggles Leaderboard, Shift+right-click opens Options",
            "Minimap: collapses and hides correctly with Minimap Map Icons and all LDB manager addons",
            "Minimap: uses logo.tga as icon; position persists across sessions",
            -- Slash / FAQ
            "/ms versions help text corrected — was misleadingly labelled 'Ping' when passive collection is the only supported method",
            "FAQ: leaderboard section updated — per-tab location accuracy, M+ key level display, one-new-run caveat for peers documented",
            -- Libraries
            "LibStub, LibDataBroker-1.1, LibDBIcon-1.0 bundled in libs\\ folder and added to TOC load order",
            "TOC: ## IconTexture added — logo.tga now appears in the WoW AddOns panel",
        },
    },
    {
        version = "1.3.6",
        tagline = "Feedback Depth, Devourer Fixes & Leaderboard Stability",
        date    = "April 2026",
        changes = {
            -- Devourer
            "Devourer: Collapsing Star spell ID corrected to 1221150 (castable spell) from 1221167 (talent node) — confirmed via MidnightTim debug tool session export",
            "Devourer: Collapsing Star minFightSeconds lowered from 90 to 45 — spell appears ~23s into Void Metamorphosis window; old threshold suppressed feedback on most fights",
            "Devourer: Collapsing Star no longer triggers never-used feedback when combatGated — Void Metamorphosis window may not have opened",
            -- Feedback improvements
            "Feedback: activity threshold lowered from 80 to 85 — players at 80-84% activity now receive a lighter cast-count nudge instead of silence",
            "Feedback: nothing-flagged fallback now tier-aware — 95+ scores receive specific next-step advice, 90-94 names the weakest scoring category, lower scores retain existing hints",
            "Feedback: rotational spell tracking now supports cdSec field — specs can define a cooldown duration to enable 'could have cast X more' feedback for high-scoring players",
            "Feedback: combatGated flag stored on rotational tracking entries — gates both never-used and cast-count feedback correctly",
            "Feedback: finalScore passed into GenerateFeedback as scores._final — enables score-tier branching in fallback without a second score calculation",
            -- Leaderboard
            "Leaderboard: SyncGuildOnlineStatus nil crash fixed — local function was defined after OnAddonMessage and resolved as a nil global at the call site; forward declaration added",
            "Leaderboard: Delve tab no longer shows player count in the tab label — count is not meaningful for local character history",
            "Leaderboard: Delve tab online dots now reflect actual online status — were incorrectly forced to green because delve data is local history, not live presence",
        },
    },
    {
        version = "1.3.4",
        tagline = "Spec Isolation, Detection Fixes & Feedback Overhaul",
        date    = "April 2026",
        changes = {
            -- Devourer
            "Devourer: validSpells whitelist added — fully isolated from Havoc and Vengeance spell detection",
            "Devourer: Immolation Aura, Eye Beam, The Hunt and all Havoc/Vengeance abilities hard-blocked",
            "Devourer: Collapsing Star now correctly detected — fired CHANNEL_START not SUCCEEDED; both events now registered",
            "Devourer: Collapsing Star spell ID corrected to 1221150 (castable spell) from 1221167 (talent node) — confirmed via debug tool session data",
            "Devourer: Collapsing Star minFightSeconds lowered to 45 — spell appears ~23s into Void Metamorphosis window, 90s threshold was too high",
            "Devourer: Collapsing Star no longer triggers never-used feedback when combatGated — window may not have opened during the fight",
            "All specs: UNIT_SPELLCAST_CHANNEL_START registered — all channeled spells now tracked correctly",
            -- Vengeance
            "Vengeance: Demon Spikes uptime was never correctly measured — UpdateUptime was only called on application, never on drop; fixed",
            -- Feedback
            "Feedback: cooldown messages now role-aware — tanks, healers, and DPS each receive contextually appropriate coaching",
            "Feedback: downtime message now shows exact casts lost and labels severity (moderate vs significant)",
            "Feedback: underused cooldowns now include fight duration so the expected-use math is transparent",
            "Feedback: mitigation feedback shows actual vs target percentage with point gap and application count",
            "Feedback: resource overcap includes per-minute rate and names the exact cap threshold",
            "Feedback: proc feedback labels severity (delayed vs critically delayed) with exact hold time vs budget",
            "Feedback: rotational spell message is role-aware — survival/threat for tanks, healing throughput for healers",
            "Feedback: healer overheal shows both actual and target percentages with specific corrective advice",
            "Feedback: fallback no longer says 'build on this foundation' when scores are mediocre — names what to fix",
            -- Versions
            "/ms versions command added — shows addon versions passively collected this session, outdated players flagged",
        },
    },
    {
        version = "1.3.3",
        tagline = "Offline Score Persistence",
        date    = "April 2026",
        changes = {
            "Friend scores now persist to SavedVariables — last known data survives logout and reload",
            "Friends tab shows offline members with grey dot and last known scores until they come back online",
            "Friend scores cleared from SavedVariables when player is removed from the friend list",
            "Guild member scores already persisted — confirmed working across sessions",
        },
    },
    {
        version = "1.3.2",
        tagline = "Friends Leaderboard, Multi-Character Safety & Stability",
        date    = "April 2026",
        changes = {
            -- Friends system
            "Friends tab fully enabled — manual friend list persists across reloads and logouts",
            "Add friends via + button in leaderboard or /ms friend add Name-Realm (cap: 20)",
            "Right-click any friend row to remove; friends tab count excludes self",
            "On login, all friends are queried automatically 6 seconds after SESSION_READY",
            "Refresh on Friends tab queries each friend individually via REQD whisper",
            "Friend query result prints Name (Online) - Updated or (Offline) - Not updated",
            "8-second timeout before offline message so slow responses aren't marked failed",
            "Self always appears in Friends tab for comparison",
            -- Leaderboard data integrity
            "Checksum validation disabled — formula diverged between versions causing false failures",
            "GUILD channel addon messages now whispered directly to online members as fallback",
            "Old-format payload detection: encType inferred from diffLabel for pre-1.3.0 clients",
            "Delve-specific location (diffLabel, instanceName, bossName) stored separately — no bleed from dungeon broadcasts",
            "Content isolation hardened: dungeon data never shows in Raids tab and vice versa",
            "No raids/dungeons/delves recorded shown consistently including self-entry",
            "Self always visible in Delve tab even with no boss delve encounters",
            "JoinLabel now filters junk values (0, World) from location display",
            -- Multi-character support
            "SavedVariablesPerCharacter introduced: encounters and settings are now per-character",
            "Guild leaderboard and friend list remain account-wide (shared across all characters)",
            "Schema v2 to v3 migration runs automatically on first login — no data loss",
            "GetLastEncounter now returns current character's last fight, not any alt's",
            "HUD position and settings no longer shared between characters",
            -- Debug tooling
            "Debug Tools window added — right-click HUD to open, buttons for every debug command",
            "/ms debug guild — shows guild DB entries, roster, and score history",
            "/ms debug guild broadcast — re-broadcasts best score per content type with whisper fallback",
            "/ms debug guild inject — sends synthetic test score to verify the full receive pipeline",
            "/ms debug guild ping/receive — channel connectivity test between two clients",
            "/ms debug self — shows delve encounter history and boss count",
            "/ms debug zone — renamed from debug delve; shows instance type, diffID, encType",
            "/ms clean payload — recovery tool: purges ghost entries, re-broadcasts all best scores",
            -- Stability
            "UnitPower wrapped in pcall — taint errors in combat no longer surface as BugSack errors",
            "Tick frame subscribers wrapped in pcall — runtime errors suppressed in normal mode",
            "GUILD channel trusted implicitly for SCORE and HELLO routing — roster sync not required",
            "Rate limit raised to 100 per session for pilot testing",
            "Midnight 12.0 raid encounters (The Voidspire, March on Quel'Danas, The Dreamrift) auto-detected via ENCOUNTER_START",
        },
    },
    {
        version = "1.3.0",
        tagline = "Leaderboard Data Integrity & Direct Friend Queries",
        date    = "April 2026",
        changes = {
            "instanceName now broadcast in SCORE messages — peers see dungeon/raid name, not just difficulty",
            "bossName and instanceName now stored on all three data routes (party, guild, friends)",
            "lastEnc selection now prefers boss encounters — leaderboard shows boss name, not trash pull",
            "Refresh button wait extended to 3s so peer responses arrive before the leaderboard redraws",
            "Added /ms friend Name-Realm — whisper-based direct score query, no BNet API required",
            "REQD message protocol added — peers with 1.3.0+ auto-respond to direct queries via whisper",
            "5-second timeout with clear message if target is offline, missing addon, or needs update",
            "Score query result prints to chat with grade colour, score, and location context",
            "Core.On hardened across all files — load-order race no longer causes EVENTS nil crash",
            "/ms update now opens the Changelog tab in the Credits panel instead of printing to chat",
            "lb fix beta command fully removed — was silently clearing encounter history on /ms lb debug",
            "FAQ updated: rotational spell tracking, leaderboard persistence, right-click remove, current commands",
            "GRM references removed from all user-facing text",
        },
    },
    {
        version = "1.2.9",
        tagline = "Spec Coverage & Feedback Accuracy",
        date    = "April 2026",
        changes = {
            "Added Devourer Demon Hunter spec (Midnight 12.0 new spec, specIdx 3)",
            "Fixed multi-character delve leaderboard overwrite — each alt now gets its own row",
            "Rotational spell tracking added for all 39 specs across all 13 classes",
            "Feedback fires only when fight is long enough to reasonably expect the spell",
            "Talent-gated rotational spells (e.g. Power Siphon) now correctly skipped via IsPlayerSpell",
            "Enemy debuffs removed from uptimeBuffs across all affected specs — were scoring silently as zero",
            "Duration guards added: neverUsed CD feedback requires 30s+, underused requires 90s+",
            "Leaderboard right-click remove fixed — now uses exact db.guild key, no fuzzy matching",
            "Added /ms lb debug to print all stored guild DB keys for diagnostics",
            "Added /ms verify and /ms verify report — in-game spell ID and aura verification tool",
            "Verify report opens in a scrollable copy-paste export window for GitHub issues",
            "/ms bare now prints a short usage hint; /ms show and /ms hide are explicit commands",
            "/ms help prints the command list inline; /ms faq opens the FAQ panel",
        },
    },
    {
        version = "1.2.8",
        tagline = "Shaman & Warlock Spec Pass",
        date    = "April 2026",
        changes = {
            "All three Shaman specs updated: Flame Shock removed from uptimeBuffs (enemy debuff)",
            "Elemental: Primordial Wave added to majorCooldowns",
            "Enhancement: Primordial Wave and Sundering added; Maelstrom Weapon kept in procBuffs",
            "Restoration: Cloudburst Totem and Ancestral Guidance added to majorCooldowns",
            "Affliction: DoT uptimeBuffs removed; Haunt added to rotationalSpells",
            "Demonology: Implosion moved from majorCooldowns to rotationalSpells; Power Siphon added as talent-gated",
            "Destruction: Immolate removed from uptimeBuffs; rotationalSpells added",
        },
    },
    {
        version = "1.2.7",
        tagline = "Tracking Architecture Overhaul",
        date    = "April 2026",
        changes = {
            "rotationalSpells bucket introduced — tracks important non-cooldown abilities via ABILITY_USED",
            "Feedback generated only when spell never used and fight exceeded per-spell minFightSeconds threshold",
            "talentGated flag added — talent-dependent spells gated by IsPlayerSpell at fight start",
            "Roll the Bones duplicate fixed in Outlaw — was tracked in both majorCooldowns and procBuffs",
            "Fire Mage Ignite removed from uptimeBuffs (enemy debuff)",
            "Unholy DK Blood Plague removed from uptimeBuffs (enemy debuff)",
            "Fury Warrior scoreWeights corrected: Enrage is a player self-buff, not a debuff",
            "Augmentation Evoker scoreWeights corrected: Ebon Might is a player self-buff",
        },
    },
    {
        version = "1.2.6",
        tagline = "Spec Database Accuracy Pass",
        date    = "April 2026",
        changes = {
            "Enemy debuffs removed from uptimeBuffs for Arms Warrior, all Rogues, Shadow Priest, both Druids, all Hunters",
            "scoreWeights corrected on all affected specs to remove debuffUptime weight with no trackable data",
            "Colossus Smash, Rupture, Garrote, Find Weakness, SW:Pain, VT, Moonfire, Sunfire, Rip, Rake all moved to priorityNotes",
            "All 39 specs verified for correct player-aura-only uptimeBuffs",
        },
    },
    {
        version = "1.2.5",
        tagline = "Racial Cooldowns & Version Detection",
        date    = "April 2026",
        changes = {
            "13 combat racial cooldowns added and scored per role via IsPlayerSpell gate",
            "Version broadcast on login, group join, and guild roster update",
            "Runtime version detection via C_AddOns.GetAddOnMetadata with hardcoded fallback",
            "New version notification: 'A new version is available. Check Github for latest update.'",
        },
    },
    {
        version = "1.2.1",
        tagline = "Grading & Feedback Refinements",
        date    = "April 2026",
        changes = {
            "inferSimplified behavioral inference added — internal tone modifier, never modifies score",
            "GenerateFeedback rewritten: up to 8 messages, Biggest Gain labeled in-place",
            "Healer feedback separated from DPS/tank feedback paths",
            "Overcap feedback edge-triggered — fires once per overcap entry, not every tick",
            "ScoreHealerEfficiency returns nil when no healing done, excluded from weighted score",
        },
    },
    {
        version = "1.2.0",
        tagline = "Leaderboard Overhaul & Delve Support",
        date    = "April 2026",
        changes = {
            "Leaderboard redesigned with three independent rows: Social (Party/Guild/Friends), Content (Delves/Dungeons/Raids), and Sort (Week Avg/All-Time)",
            "Delve tab shows personal delve run history with tier labels and timestamps",
            "Weekly average is now boss-encounters-only; trash pulls and dummies excluded",
            "Weekly average fixed -- was silently failing to persist across reloads",
            "Weekly reset correctly aligned to Tuesday 7am PDT (Blizzard weekly reset)",
            "BNet friends now receive score broadcasts via direct whisper",
            "Party channel spam fixed for LFD and instance groups",
            "Play Style setting removed: grading is now fully behavior-driven",
            "Registered in WoW Game Options -> AddOns panel",
            "Credits panel split into About and Sources tabs",
            "os.time() crash fixed (Blizzard does not expose the os library)",
            "Backward-compatible SCORE message parsing (12-part legacy format supported)",
        },
    },
    {
        version = "1.1.0",
        tagline = "Social Leaderboard & Boss Tracking",
        date    = "April 2026",
        changes = {
            "Social leaderboard with Party, Guild, and Friends tabs",
            "Boss fight detection via ENCOUNTER_START/END WoW events",
            "Difficulty labels for all content: LFR/Normal/Heroic/Mythic for raids, Normal/Heroic/Mythic/M+N for dungeons, Tier N for delves",
            "Checksum-based integrity system on all leaderboard broadcasts",
            "Syncs across guild members — recover your scores after a reinstall",
            "Player appears in their own Guild tab immediately (self-entry injection)",
            "Review Fight button works on login/reload (DB fallback fixed)",
        },
    },
    {
        version = "1.0.0",
        tagline = "Initial Release",
        date    = "March 2026",
        changes = {
            "Fight grading A+ through F for all 13 classes and 39 specs",
            "Talent-aware cooldown scoring: only scores abilities you have equipped",
            "Per-role scoring weights: DPS activity, healer efficiency, tank mitigation",
            "Grade history panel with trend sparkline and per-encounter detail view",
            "HUD with post-fight review button and right-click context menu",
            "Midnight 12.0 compatible: UNIT_AURA replaces the restricted CLEU API",
            "Actionable coaching feedback with spec-specific language",
        },
    },
}

--------------------------------------------------------------------------------
-- SPEC_DATABASE
-- All 13 classes / 39 specs.
-- Spell IDs: verified against 11.x / Midnight 12.0 where noted.
-- IDs marked "-- VERIFY" should be confirmed with /eventtrace in-game.
--
-- uptimeBuffs : buffs/debuffs scored by uptime %
-- procBuffs   : short-window procs that should be consumed quickly
-- majorCooldowns: tracked for usage-rate scoring
--------------------------------------------------------------------------------
Core.SPEC_DATABASE = {

    ----------------------------------------------------------------------------
    -- 1 · WARRIOR
    ----------------------------------------------------------------------------
    [1] = {
        className = "Warrior",

        -- Arms
        -- Removed:  Colossus Smash (208086) from uptimeBuffs — enemy debuff, not a player aura
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Mortal Strike (12294), Execute (163201)
        [1] = {
            name = "Arms", role = "DPS",
            resourceType = 1, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 227847, label = "Bladestorm",   expectedUses = "on CD"    },
                { id = 107574, label = "Avatar",       expectedUses = "on CD"    },
                { id = 262161, label = "Warbreaker",   expectedUses = "on CD"    },
            },
            -- uptimeBuffs empty: Colossus Smash is an enemy debuff, not trackable via C_UnitAuras
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 12294,  label = "Mortal Strike", minFightSeconds = 30 },
                { id = 163201, label = "Execute",       minFightSeconds = 45 },  -- execute phase spell
            },
            priorityNotes = {
                "Apply Colossus Smash / Warbreaker to maximize damage windows (not directly tracked)",
                "Mortal Strike on cooldown — primary damage and healing debuff",
                "Execute during execute phase (< 20% health) — replaces Mortal Strike",
                "Pool Rage for Colossus Smash windows — spend with Overpower and Mortal Strike",
                "Stack Bladestorm inside Avatar for maximum burst",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Arms Warrior guide",
        },

        -- Fury
        [2] = {
            name = "Fury", role = "DPS",
            resourceType = 1, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 1719,   label = "Recklessness", expectedUses = "on CD"          },
                { id = 315720, label = "Onslaught",    expectedUses = "Enrage windows" },
            },
            -- Enrage IS a player self-buff — kept in uptimeBuffs
            uptimeBuffs = {
                { id = 184362, label = "Enrage", targetUptime = 60 },
            },
            rotationalSpells = {
                -- Bloodthirst is the primary builder; Rampage is the primary spender
                { id = 23881, label = "Bloodthirst", minFightSeconds = 20 },
                { id = 184367, label = "Rampage",    minFightSeconds = 30 },
            },
            priorityNotes = {
                "Keep Enrage active — Bloodthirst on cooldown procs it",
                "Rampage to refresh Enrage and spend Rage — primary spender",
                "Onslaught during Enrage windows for massive damage",
                "Recklessness to align with Enrage and trinkets for burst",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 25, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Fury Warrior guide",
        },

        -- Protection
        [3] = {
            name = "Protection", role = "TANK",
            resourceType = 1, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 871,    label = "Shield Wall",   expectedUses = "big hits"      },
                { id = 12975,  label = "Last Stand",    expectedUses = "emergency"     },
                { id = 107574, label = "Avatar",        expectedUses = "on CD"         },
                { id = 190456, label = "Ignore Pain",   expectedUses = "physical hits" },
            },
            uptimeBuffs = {
                { id = 2565, label = "Shield Block", targetUptime = 50 },
            },
            rotationalSpells = {
                { id = 6343,  label = "Thunder Clap",  minFightSeconds = 20 },
                { id = 23922, label = "Shield Slam",   minFightSeconds = 20 },
            },
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Maintain Shield Block for physical mitigation (tracked via uptimeBuffs)",
                "Shield Slam on cooldown — primary Rage generator and damage",
                "Thunder Clap on cooldown — AoE damage and slowing",
                "Ignore Pain to absorb incoming physical hits",
                "Shield Wall / Last Stand for true emergencies only",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Protection Warrior guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 2 · PALADIN
    ----------------------------------------------------------------------------
    [2] = {
        className = "Paladin",

        -- Holy
        [1] = {
            name = "Holy", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 31884,  label = "Avenging Wrath",        expectedUses = "burst damage phases"  },
                { id = 375576, label = "Divine Toll",           expectedUses = "on CD"                },
                { id = 6940,   label = "Blessing of Sacrifice", expectedUses = "tank busters"         },
                { id = 86659,  label = "Guardian of Anc. Kings",expectedUses = "emergency throughput" },
            },
            uptimeBuffs = {
                { id = 53563, label = "Beacon of Light", targetUptime = 95 },
            },
            rotationalSpells = {
                { id = 20473, label = "Holy Shock",    minFightSeconds = 20 },
                { id = 85673, label = "Word of Glory", minFightSeconds = 30 },
            },
            healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
            priorityNotes = {
                "Beacon of Light on the tank — never let it drop (tracked via uptimeBuffs)",
                "Holy Shock on cooldown — primary Holy Power generator and healing",
                "Use Holy Words as they come off cooldown — massive healing value",
                "Word of Glory to spend Holy Power efficiently",
                "Divine Toll for burst AoE Holy Power and healing on cooldown",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Holy Paladin guide",
        },

        -- Protection
        [2] = {
            name = "Protection", role = "TANK",
            resourceType = 9, resourceLabel = "HOLY POWER", overcapAt = 5,
            majorCooldowns = {
                { id = 31850,  label = "Ardent Defender",        expectedUses = "dangerous windows"   },
                { id = 86659,  label = "Guardian of Anc. Kings", expectedUses = "emergency"           },
                { id = 31935,  label = "Avenger's Shield",       expectedUses = "on CD"               },
            },
            uptimeBuffs = {
                { id = 132403, label = "Shield of the Righteous", targetUptime = 50 },
            },
            rotationalSpells = {
                { id = 53600, label = "Shield of the Righteous", minFightSeconds = 20 },
                { id = 35395, label = "Crusader Strike",         minFightSeconds = 20 },
            },
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Shield of the Righteous to spend Holy Power — core mitigation (tracked via uptimeBuffs)",
                "Avenger's Shield on cooldown — primary damage and threat",
                "Crusader Strike / Hammer of the Righteous for Holy Power generation",
                "Ardent Defender for sustained dangerous phases — do not hold it",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Protection Paladin guide",
        },

        -- Retribution
        [3] = {
            name = "Retribution", role = "DPS",
            resourceType = 9, resourceLabel = "HOLY POWER", overcapAt = 5,
            majorCooldowns = {
                { id = 231895, label = "Crusade",            expectedUses = "on CD"           },
                { id = 31884,  label = "Avenging Wrath",     expectedUses = "on CD"           },
                { id = 255937, label = "Wake of Ashes",      expectedUses = "on CD / 0 HP"    },
                { id = 343527, label = "Execution Sentence", expectedUses = "on CD (talent)"  },
            },
            rotationalSpells = {
                { id = 85256,  label = "Templar's Verdict", minFightSeconds = 20 },
                { id = 20271,  label = "Judgment",          minFightSeconds = 20 },
            },
            priorityNotes = {
                "Build to 5 Holy Power before spending — don't cap",
                "Templar's Verdict (single target) / Divine Storm (AoE) as Holy Power spenders",
                "Judgment on cooldown — amplifies next finisher damage",
                "Wake of Ashes: generates 3 Holy Power on CD",
                "Align Crusade / Avenging Wrath with trinkets for burst",
            },
            scoreWeights = { cooldownUsage = 35, activity = 30, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Adapted from Icy Veins Retribution Paladin guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 3 · HUNTER
    ----------------------------------------------------------------------------
    [3] = {
        className = "Hunter",

        -- Beast Mastery
        -- Removed:  Barbed Shot DoT (259277) from uptimeBuffs — enemy debuff on pet, not a player aura
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Kill Command (34026), Barbed Shot (217200)
        -- Kept:     Thrill of the Hunt in procBuffs — needs in-game C_UnitAuras verification (VERIFY)
        [1] = {
            name = "Beast Mastery", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 19574,  label = "Bestial Wrath",    expectedUses = "on CD"   },
                { id = 359844, label = "Call of the Wild", expectedUses = "on CD"   },
            },
            -- uptimeBuffs empty: Barbed Shot DoT is an enemy/pet debuff, not a player self-aura
            uptimeBuffs = {},
            rotationalSpells = {
                -- Kill Command is the primary builder; Barbed Shot maintains Frenzy
                { id = 34026,  label = "Kill Command",  minFightSeconds = 30 },
                { id = 217200, label = "Barbed Shot",   minFightSeconds = 30 },
            },
            procBuffs = {
                { id = 246152, label = "Thrill of the Hunt", maxStackTime = 12 },  -- VERIFY C_UnitAuras
            },
            priorityNotes = {
                "Keep Barbed Shot rolling to maintain Frenzy stacks on your pet (not directly tracked)",
                "Kill Command on cooldown — primary Focus spender and damage",
                "Bestial Wrath on cooldown — aligns with pet Frenzy stacks",
                "Call of the Wild for coordinated burst with trinkets",
                "Never overcap Focus — use Cobra Shot as filler",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 20, activity = 30, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Beast Mastery Hunter guide",
        },

        -- Marksmanship
        [2] = {
            name = "Marksmanship", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 288613, label = "Trueshot",   expectedUses = "on CD"     },
                { id = 257044, label = "Rapid Fire", expectedUses = "on CD"     },
                { id = 260243, label = "Volley",     expectedUses = "AoE on CD" },
            },
            rotationalSpells = {
                { id = 19434, label = "Aimed Shot", minFightSeconds = 20 },
            },
            procBuffs = {
                { id = 342776, label = "Precise Shots", maxStackTime = 15 },  -- VERIFY C_UnitAuras
            },
            priorityNotes = {
                "Aimed Shot on cooldown — primary Focus spender and damage",
                "Rapid Fire on cooldown — empowered volley of shots",
                "Spend Precise Shots procs on Arcane Shot / Multi-Shot immediately",
                "Trueshot for burst — align with trinkets and lust",
                "Volley for AoE on cooldown at 3+ targets",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Marksmanship Hunter guide",
        },

        -- Survival
        -- Removed:  Serpent Sting (118253) from uptimeBuffs — enemy debuff, not a player aura
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Kill Command (34026), Mongoose Bite (259387)
        [3] = {
            name = "Survival", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 360952, label = "Coordinated Assault", expectedUses = "burst windows" },
                { id = 259495, label = "Wildfire Bomb",       expectedUses = "on CD"         },
            },
            -- uptimeBuffs empty: Serpent Sting is an enemy debuff, not a player self-aura
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 34026,  label = "Kill Command",   minFightSeconds = 30 },
                { id = 259387, label = "Mongoose Bite",  minFightSeconds = 30 },  -- core melee ability
            },
            priorityNotes = {
                "Maintain Serpent Sting on all targets for damage and Focus generation (not directly tracked)",
                "Kill Command on cooldown — primary builder",
                "Wildfire Bomb on cooldown — highest damage ability",
                "Stack Mongoose Bite charges during Aspect of the Eagle for burst",
                "Coordinated Assault for burst with trinkets and lust",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Survival Hunter guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 4 · ROGUE
    ----------------------------------------------------------------------------
    [4] = {
        className = "Rogue",

        -- Assassination
        -- Removed:  Rupture (1943), Garrote (703) from uptimeBuffs — enemy debuffs, not player auras
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Rupture (1943), Garrote (703), Envenom (32645)
        [1] = {
            name = "Assassination", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 360194, label = "Deathmark", expectedUses = "on CD"               },
                { id = 385627, label = "Kingsbane", expectedUses = "on CD (if talented)" },
                { id = 79140,  label = "Vendetta",  expectedUses = "on CD"               },
            },
            -- uptimeBuffs empty: Rupture and Garrote are enemy debuffs, not player self-auras
            uptimeBuffs = {},
            rotationalSpells = {
                -- Critical rotation abilities tracked for presence — never should be zero in a real fight
                { id = 1943,  label = "Rupture",  minFightSeconds = 20 },  -- core bleed, applied immediately
                { id = 703,   label = "Garrote",  minFightSeconds = 20 },  -- opener, should always be used
                { id = 32645, label = "Envenom",  minFightSeconds = 30 },  -- primary finisher
            },
            priorityNotes = {
                "Maintain Rupture and Garrote on all targets — core bleed damage (not directly tracked)",
                "Keep Envenom active for the damage amplification buff",
                "Spend at 4-5 combo points — do not sit on max CP",
                "Deathmark doubles all bleeds — use with Kingsbane and other CDs",
                "Fan of Knives / Shuriken Storm for AoE — keep bleeds on multiple targets",
            },
            scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Adapted from Icy Veins Assassination Rogue guide",
        },

        -- Outlaw
        -- Fixed:    Roll the Bones removed from procBuffs — same ID as majorCooldowns entry
        --           which caused double-tracking. It is a cooldown, not a proc buff.
        -- Added:    rotationalSpells: Between the Eyes (199804), Dispatch (2098)
        [2] = {
            name = "Outlaw", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 13750,  label = "Adrenaline Rush", expectedUses = "on CD"          },
                { id = 315508, label = "Roll the Bones",  expectedUses = "keep refreshed" },
                { id = 13877,  label = "Blade Flurry",    expectedUses = "AoE on CD"      },
            },
            rotationalSpells = {
                { id = 199804, label = "Between the Eyes", minFightSeconds = 30 },
                { id = 2098,   label = "Dispatch",         minFightSeconds = 30 },
            },
            priorityNotes = {
                "Keep Roll the Bones active — reroll if only one buff procs",
                "Between the Eyes on cooldown during Adrenaline Rush for burst",
                "Sinister Strike / Pistol Shot to build combo points",
                "Dispatch / Eviscerate at 5+ combo points — primary finisher",
                "Blade Flurry for any 2+ target situation",
            },
            scoreWeights = { cooldownUsage = 35, activity = 35, resourceMgmt = 20, procUsage = 10 },
            sourceNote = "Adapted from Icy Veins Outlaw Rogue guide",
        },

        -- Subtlety
        -- Removed:  Find Weakness (121733) from uptimeBuffs — enemy debuff, not a player aura
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Shadowstrike (185438), Eviscerate (196819), Nightblade (195452)
        [3] = {
            name = "Subtlety", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 185313, label = "Shadow Dance",     expectedUses = "burst windows" },
                { id = 212283, label = "Symbols of Death", expectedUses = "on CD"         },
                { id = 121471, label = "Shadow Blades",    expectedUses = "on CD"         },
            },
            -- uptimeBuffs empty: Find Weakness is an enemy debuff, not a player self-aura
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 185438, label = "Shadowstrike",  minFightSeconds = 30 },
                { id = 196819, label = "Eviscerate",    minFightSeconds = 30 },
                { id = 195452, label = "Nightblade",    minFightSeconds = 30 },  -- damage amp, should apply early
            },
            priorityNotes = {
                "Shadow Dance for burst — use Shadowstrike charges immediately",
                "Symbols of Death on cooldown — amplifies all damage and generates CP",
                "Maintain Nightblade on target for the damage amplification (not directly tracked)",
                "Shadow Blades for sustained burst — aligns with Symbols of Death",
                "Backstab / Shadowstrike to build combo points outside of Dance",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Subtlety Rogue guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 5 · PRIEST
    ----------------------------------------------------------------------------
    [5] = {
        className = "Priest",

        -- Discipline
        [1] = {
            name = "Discipline", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                -- Choice node: Ultimate Penitence OR Power Word: Barrier (not both)
                -- IsPlayerSpell at fight start will only register whichever is talented
                { id = 421453, label = "Ultimate Penitence",  expectedUses = "ramp windows"       }, -- 4-min CD
                { id = 62618,  label = "Power Word: Barrier", expectedUses = "stacked damage"     }, -- choice node alt
                { id = 33206,  label = "Pain Suppression",    expectedUses = "tank busters"       },
                { id = 246287, label = "Evangelism",          expectedUses = "ramp windows"       },
                { id = 47536,  label = "Rapture",             expectedUses = "high damage phases" },
                { id = 204263, label = "Schism",              expectedUses = "on CD for ramp amp" }, -- VERIFY ID
            },
            uptimeBuffs = {
                { id = 194384, label = "Atonement", targetUptime = 0 },
            },
            healerMetrics = { targetOverheal = 20, targetActivity = 90, targetManaEnd = 5 },
            priorityNotes = {
                "Ramp Atonements before damage with PWS and Shadow Mend",
                "Evangelism extends Atonements for big damage windows",
                "Maintain Purge the Wicked / SW:Pain for Atonement healing",
                "Schism on cooldown during damage windows",
                "Pain Suppression for tank busters, Barrier for stacks",
            },
            scoreWeights = { cooldownUsage = 30, efficiency = 25, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Discipline Priest guide",
        },

        -- Holy
        [2] = {
            name = "Holy", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 64843,  label = "Divine Hymn",       expectedUses = "1-2 per fight"        },
                { id = 200183, label = "Apotheosis",        expectedUses = "high damage phases"   },
                { id = 33076,  label = "Prayer of Mending", expectedUses = "on CD"                },
            },
            healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
            priorityNotes = {
                "Keep Prayer of Mending bouncing at all times",
                "Holy Words on cooldown  -  they reduce each other's CD",
                "Divine Hymn for raid-wide burst damage",
                "Circle of Healing on cooldown for efficiency",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Holy Priest guide",
        },

        -- Shadow
        -- Removed:  Shadow Word: Pain (589), Vampiric Touch (34914) from uptimeBuffs — enemy debuffs
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Shadow Word: Pain (589), Vampiric Touch (34914),
        --           Devouring Plague (335467), Mind Blast (8092)
        [3] = {
            name = "Shadow", role = "DPS",
            resourceType = 13, resourceLabel = "INSANITY", overcapAt = 90,
            majorCooldowns = {
                { id = 228260,  label = "Voidform",        expectedUses = "on CD", minFightSeconds = 60 },  -- renamed from Void Eruption in 12.0
                { id = 10060,   label = "Power Infusion",  expectedUses = "on CD", minFightSeconds = 60, talentGated = true },  -- class talent, sync with Voidform
                { id = 263165,  label = "Void Torrent",    expectedUses = "on CD", talentGated = true },    -- Voidweaver only
                { id = 1227280, label = "Tentacle Slam",   expectedUses = "on CD", talentGated = true },    -- renamed from Shadow Crash in 12.0
            },
            -- uptimeBuffs empty: SW:Pain and Vampiric Touch are enemy debuffs, not player self-auras
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 589,    label = "Shadow Word: Pain", minFightSeconds = 15,
                  suppressIfTalent = 238558 },  -- Misery (238558): VT auto-applies SW:Pain passively
                { id = 34914,  label = "Vampiric Touch", minFightSeconds = 15,
                  suppressIfTalent = 1227280 },  -- Tentacle Slam auto-applies VT to up to 6 targets
                { id = 335467, label = "Shadow Word: Madness", minFightSeconds = 20 },
                { id = 8092,   label = "Mind Blast",        minFightSeconds = 20 },
            },
            priorityNotes = {
                "Cast Vampiric Touch to apply Shadow Word: Pain automatically (Misery talent)",
                "Without Misery: manually cast Shadow Word: Pain as opener DoT",
                "Tentacle Slam applies Vampiric Touch to up to 6 targets automatically (talent)",
                "Without Tentacle Slam: manually cast Vampiric Touch as opener DoT",
                "Enter Voidform on cooldown — primary damage cooldown in Midnight 12.0",
                "Power Infusion on cooldown — sync with Voidform for maximum burst",
                "Shadow Word: Madness to spend Insanity — never overcap at 90",
                "Mind Blast on cooldown for Insanity generation",
                "Void Torrent on cooldown (Voidweaver) — strong channel, do not cancel",
                "Tentacle Slam on cooldown (talent) — applies Vampiric Touch to up to 6 targets",
            },
            scoreWeights = { cooldownUsage = 25, activity = 35, resourceMgmt = 25, procUsage = 15 },
            sourceNote = "Adapted from Icy Veins Shadow Priest guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 6 · DEATH KNIGHT
    ----------------------------------------------------------------------------
    [6] = {
        className = "Death Knight",

        -- Blood
        [1] = {
            name = "Blood", role = "TANK",
            resourceType = 6, resourceLabel = "RUNIC POWER", overcapAt = 100,
            majorCooldowns = {
                { id = 49028,  label = "Dancing Rune Weapon", expectedUses = "on CD"           },
                { id = 55233,  label = "Vampiric Blood",      expectedUses = "big damage"      },
                { id = 383269, label = "Abomination Limb",    expectedUses = "on CD"           },
                { id = 194844, label = "Bonestorm",           expectedUses = "grouped enemies" },
            },
            uptimeBuffs = {
                { id = 77535, label = "Blood Shield", targetUptime = 40 },
            },
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Death Strike is your healing  -  use on incoming damage",
                "Dancing Rune Weapon on cooldown for parry and runes",
                "Vampiric Blood for sustained dangerous phases",
                "Crimson Scourge procs = free Death and Decay",
                "Bone Shield stacks = core mitigation, keep it up",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Blood Death Knight guide",
        },

        -- Frost
        [2] = {
            name = "Frost", role = "DPS",
            resourceType = 6, resourceLabel = "RUNIC POWER", overcapAt = 100,
            majorCooldowns = {
                { id = 51271,  label = "Pillar of Frost",     expectedUses = "on CD"         },
                { id = 47568,  label = "Empower Rune Weapon", expectedUses = "on CD"         },
                { id = 279302, label = "Frostwyrm's Fury",    expectedUses = "burst windows" },
            },
            rotationalSpells = {
                { id = 49020,  label = "Obliterate",  minFightSeconds = 15 },  -- primary damage, used constantly
                { id = 49143,  label = "Frost Strike", minFightSeconds = 20 },  -- Runic Power dump
            },
            procBuffs = {
                { id = 59052,  label = "Killing Machine",      maxStackTime = 10 },
                { id = 51124,  label = "Rime (Howling Blast)", maxStackTime = 15 },
            },
            priorityNotes = {
                "Spend Killing Machine procs with Obliterate immediately",
                "Spend Rime procs with Howling Blast — do not sit on them",
                "Obliterate on cooldown — primary damage and proc driver",
                "Frost Strike to dump Runic Power — avoid overcapping at 100",
                "Pillar of Frost for burst — align with Empower Rune Weapon and trinkets",
            },
            scoreWeights = { cooldownUsage = 25, procUsage = 30, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Frost Death Knight guide",
        },

        -- Unholy
        [3] = {
            name = "Unholy", role = "DPS",
            resourceType = 6, resourceLabel = "RUNIC POWER", overcapAt = 100,
            majorCooldowns = {
                { id = 275699, label = "Apocalypse",          expectedUses = "on CD"            },
                { id = 42650,  label = "Army of the Dead",    expectedUses = "pre-pull / burst" },
                { id = 207289, label = "Unholy Assault",      expectedUses = "burst windows"    },
                { id = 63560,  label = "Dark Transformation", expectedUses = "on CD"            },
            },
            -- uptimeBuffs empty: Blood Plague is an enemy debuff, not a player self-aura
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 85092,  label = "Festering Strike", minFightSeconds = 15 },  -- wound builder
                { id = 55090,  label = "Scourge Strike",   minFightSeconds = 15 },  -- wound popper
                { id = 47541,  label = "Death Coil",       minFightSeconds = 20 },  -- Runic Power dump
            },
            priorityNotes = {
                "Apply Blood Plague and Festering Wounds with Festering Strike (not directly tracked)",
                "Pop Festering Wounds with Scourge Strike in batches of 4-8",
                "Apocalypse requires 8 Festering Wounds — build before using",
                "Dark Transformation on cooldown — empowers ghoul for burst",
                "Death Coil to dump Runic Power — avoid overcapping at 100",
            },
            scoreWeights = { cooldownUsage = 25, activity = 35, resourceMgmt = 25, procUsage = 15 },
            sourceNote = "Adapted from Icy Veins Unholy Death Knight guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 7 · SHAMAN
    ----------------------------------------------------------------------------
    [7] = {
        className = "Shaman",

        -- Elemental (Midnight 12.0 pass — April 2026)
        -- Removed:  Primordial Wave (375982) — pruned in Midnight 12.0; functionality merged into
        --           Voltaic Blaze which handles AoE Flame Shock automatically
        -- Removed:  Fire Elemental (198067) — no longer a manual summon in Midnight 12.0;
        --           auto-generated by Ascendance as part of Stormbringer design
        -- Removed:  60103 from rotationalSpells — this is Lava Lash (Enhancement), not Lava Burst
        -- Fixed:    Flame Shock rotational ID corrected from 188196 (Lightning Bolt) to 470411
        --           (confirmed in Midnight 12.0 Elemental Spell List)
        -- Added:    Earthquake (462620) as talentGated rotational — confirmed Elemental Talent nodeID 80985
        -- Added:    Elemental Blast (117014) as talentGated rotational — confirmed Elemental Talent nodeID 80984
        -- Added:    Voltaic Blaze (470057) as talentGated rotational — confirmed Elemental Talent nodeID 81007
        --           replaces Primordial Wave AoE Flame Shock role
        -- Added:    Tempest (454009) as talentGated rotational — confirmed Elemental Talent nodeID 94892 -- VERIFY aura
        -- Not added: Lava Surge (77756) to procBuffs — confirmed in Elemental Spell List as player aura
        --            but needs in-game C_UnitAuras.GetPlayerAuraBySpellID verification before adding
        -- Kept:     Stormkeeper (191634), Ascendance (114050) confirmed in Elemental Talents
        [1] = {
            name = "Elemental", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 90,
            majorCooldowns = {
                { id = 191634, label = "Stormkeeper", expectedUses = "on CD"         },  -- confirmed nodeID 80988
                { id = 114050, label = "Ascendance",  expectedUses = "burst windows" },  -- confirmed nodeID 80989; auto-summons Fire Elemental in Midnight 12.0
            },
            -- uptimeBuffs intentionally empty: Flame Shock is a target debuff,
            -- not detectable via C_UnitAuras.GetPlayerAuraBySpellID.
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 470411, label = "Flame Shock",     minFightSeconds = 15 },                          -- confirmed spell list; opener DoT
                { id = 51505,  label = "Lava Burst",      minFightSeconds = 15 },                          -- non-PASSIVE ACTIVE nodeID 103598
                { id = 462620, label = "Earthquake",      minFightSeconds = 30, talentGated = true },      -- non-PASSIVE ACTIVE nodeID 80985
                { id = 117014, label = "Elemental Blast", minFightSeconds = 20, talentGated = true },      -- non-PASSIVE ACTIVE nodeID 80984
                { id = 470057, label = "Voltaic Blaze",   minFightSeconds = 20, talentGated = true },      -- non-PASSIVE ACTIVE nodeID 81007
                -- Tempest (454009) removed — confirmed PASSIVE nodeID 94892
            },
            priorityNotes = {
                "Maintain Flame Shock on all targets for Lava Surge procs (not directly tracked)",
                "Lava Burst on cooldown — always consume Lava Surge procs immediately",
                "Stormkeeper before empowered Lightning Bolt casts for maximum burst",
                "Spend Maelstrom with Earth Shock (single target) or Earthquake (AoE) — avoid overcap at 90",
                "Ascendance for burst — automatically summons Fire Elemental in Midnight 12.0",
                "Voltaic Blaze for AoE Flame Shock spread when talented",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Elemental talent tree 108 nodes (April 2026)",
        },

        -- Enhancement (Midnight 12.0 PASSIVE audit — April 2026)
        -- Feral Spirit: was 51533 — talent tree confirms 469314 PASSIVE. Removed entirely.
        -- Ascendance: was 114051 — not in Enhancement talent tree at all. Removed.
        -- Primordial Wave (375982): not in Enhancement talent tree or spell list. Removed.
        -- Maelstrom Weapon procBuff: was 344179 — spell list confirms 187880. Corrected.
        -- Surging Totem (444995) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 94877
        -- Crash Lightning (187874) added to rotational — non-PASSIVE ACTIVE nodeID 80974
        -- Lava Lash (60103) added to rotational — non-PASSIVE ACTIVE nodeID 109389
        -- Voltaic Blaze (470057) added as talentGated rotational — non-PASSIVE ACTIVE nodeID 80954
        [2] = {
            name = "Enhancement", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 140,
            majorCooldowns = {
                { id = 384352, label = "Doom Winds",    expectedUses = "burst windows",  talentGated = true },  -- non-PASSIVE ACTIVE nodeID 80959
                { id = 197214, label = "Sundering",     expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 80975
                { id = 444995, label = "Surging Totem", expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 94877
                -- Feral Spirit (51533/469314) removed — PASSIVE
                -- Ascendance (114051) removed — not in Enhancement talent tree
                -- Primordial Wave (375982) removed — not in Midnight 12.0
            },
            uptimeBuffs = {},
            procBuffs = {
                { id = 187880, label = "Maelstrom Weapon", maxStackTime = 20 },  -- confirmed spell list (was 344179)
            },
            rotationalSpells = {
                { id = 187874, label = "Crash Lightning", minFightSeconds = 15 },                     -- non-PASSIVE ACTIVE nodeID 80974
                { id = 60103,  label = "Lava Lash",       minFightSeconds = 15 },                     -- non-PASSIVE ACTIVE nodeID 109389
                { id = 470057, label = "Voltaic Blaze",   minFightSeconds = 20, talentGated = true }, -- non-PASSIVE ACTIVE nodeID 80954
            },
            priorityNotes = {
                "Maintain Flame Shock on targets for Hot Hand procs and Lava Lash damage (not directly tracked)",
                "Spend Maelstrom Weapon at 5+ stacks — spend at 10 before any cap",
                "Stormstrike on cooldown — primary builder and damage source",
                "Lava Lash to spread Flame Shock in multi-target and spend Maelstrom stacks",
                "Crash Lightning before AoE pulls to apply the ground effect",
                "Doom Winds at peak Maelstrom / burst window when talented",
                "Surging Totem on cooldown when talented — significant throughput increase",
                "Avoid Maelstrom Weapon overcap — spend with Lightning Bolt or Elemental Blast",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Enhancement talent tree 102 nodes (April 2026)",
        },

        -- Restoration (Midnight 12.0 pass — April 2026)
        -- Removed:  Cloudburst Totem (157153) — pruned from Restoration in Midnight 12.0
        --           as part of spec simplification removing high-timing-skill buttons
        -- Removed:  Ancestral Guidance (108281) — removed from game in Midnight (patch 11.1.0 / Feb 25 2025)
        -- Removed:  Healing Tide Totem (108280) — confirmed removed from Resto in Midnight 12.0
        -- Also pruned by Blizzard (not tracked): Earthen Wall Totem, Ancestral Protection Totem,
        --           Wellspring, High Tide, Tidebringer, Undulation, Master of the Elements,
        --           Mana Tide, Tide Turner, Spiritwalker's Tidal Totem
        -- Added:    Surging Totem (444995) — new Midnight 12.0 talent, confirmed Resto Talent nodeID 94877
        --           replaces Cloudburst Totem as the signature throughput cooldown
        -- Added:    Unleash Life (73685) to majorCooldowns — confirmed Resto Talent nodeID 92677
        --           pre-heal amplifier, strong on-cooldown usage
        -- Added:    Call of the Ancestors (443450) as talentGated cooldown — confirmed nodeID 94888
        -- Added:    rotationalSpells: Riptide, Chain Heal, Healing Rain — all confirmed in Resto files
        -- Kept:     Spirit Link Totem (98008) confirmed nodeID 81041
        --           Ascendance (114052) confirmed nodeID 81032
        --           Healing Rain (73920) moved to rotationalSpells (maintained on CD, not a burst CD)
        [3] = {
            name = "Restoration", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 98008,  label = "Spirit Link Totem", expectedUses = "dangerous health disparities" },  -- non-PASSIVE ACTIVE nodeID 81041
                { id = 444995, label = "Surging Totem",     expectedUses = "before damage windows"        },  -- non-PASSIVE ACTIVE nodeID 94877
                { id = 73685,  label = "Unleash Life",      expectedUses = "on CD — pre-heal amplifier"   },  -- non-PASSIVE ACTIVE nodeID 92675
                { id = 114052, label = "Ascendance",        expectedUses = "emergency throughput"         },  -- non-PASSIVE ACTIVE nodeID 81032
                -- Call of the Ancestors (443450) removed — confirmed PASSIVE nodeID 94888
            },
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 61295,  label = "Riptide",      minFightSeconds = 15 },  -- confirmed nodeID 81027; core maintenance HoT
                { id = 1064,   label = "Chain Heal",   minFightSeconds = 20 },  -- confirmed in Resto files; primary group heal
                { id = 73920,  label = "Healing Rain",  minFightSeconds = 30 },  -- confirmed nodeID 81040; high efficiency on stacked groups
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Riptide rolling on 2-3 injured targets at all times — primary HoT maintenance",
                "Surging Totem before predictable raid damage windows for burst throughput",
                "Unleash Life on cooldown — pre-heal amplifier, use before Chain Heal or Healing Rain",
                "Healing Rain on stacked groups — keep it active, high mana efficiency",
                "Chain Heal for group damage when multiple targets are injured",
                "Spirit Link Totem to equalize dangerous health imbalances across the raid",
                "Ascendance for emergency throughput — not a maintenance cooldown",
                "Avoid excessive overheal — cast slightly later on targets above 70% health",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Restoration talent tree 110 nodes (April 2026)",
        },
    },

    ----------------------------------------------------------------------------
    -- 8 · MAGE
    ----------------------------------------------------------------------------
    [8] = {
        className = "Mage",

        -- Arcane
        [1] = {
            name = "Arcane", role = "DPS",
            resourceType = 0,
            majorCooldowns = {
                { id = 365350, label = "Arcane Surge",      expectedUses = "on CD"    },
                { id = 210824, label = "Touch of the Magi", expectedUses = "on CD"    },
                { id = 12051,  label = "Evocation",         expectedUses = "low mana" },
            },
            rotationalSpells = {
                { id = 30451, label = "Arcane Blast",   minFightSeconds = 20 },
                { id = 44425, label = "Arcane Barrage", minFightSeconds = 30 },
            },
            procBuffs = {
                { id = 276743, label = "Clearcasting", maxStackTime = 15 },
            },
            priorityNotes = {
                "Build to 4 Arcane Charges with Arcane Blast before spending",
                "Arcane Barrage to dump charges and reset for mana conservation",
                "Arcane Surge at 4 charges — primary burst window",
                "Touch of the Magi on cooldown to detonate the damage window",
                "Spend Clearcasting procs on Arcane Missiles immediately",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 25, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Arcane Mage guide",
        },

        -- Fire
        [2] = {
            name = "Fire", role = "DPS",
            resourceType = 0,
            majorCooldowns = {
                { id = 190319, label = "Combustion",     expectedUses = "burst windows"  },
                { id = 257541, label = "Phoenix Flames", expectedUses = "on CD"          },
                { id = 153561, label = "Meteor",         expectedUses = "on CD (talent)" },
            },
            -- uptimeBuffs empty: Ignite is an enemy debuff, not a player self-aura
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 133,    label = "Fireball",   minFightSeconds = 15 },  -- primary builder, used constantly
                { id = 108853, label = "Fire Blast", minFightSeconds = 15 },  -- instant Hot Streak proc
            },
            procBuffs = {
                { id = 48108, label = "Hot Streak", maxStackTime = 10 },
            },
            priorityNotes = {
                "Build Hot Streak with Fireball + Fire Blast crits — Ignite spreads passively",
                "Spend Hot Streak procs on Pyroblast immediately — do not sit on them",
                "Combustion for burst — align with trinkets and lust",
                "Phoenix Flames during Combustion to guarantee crits",
                "Fire Blast on cooldown to extend Hot Streak or guarantee a crit",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Fire Mage guide",
        },

        -- Frost
        [3] = {
            name = "Frost", role = "DPS",
            resourceType = 0,
            majorCooldowns = {
                { id = 12472, label = "Icy Veins",  expectedUses = "once per 2 min" },
                { id = 84714, label = "Frozen Orb", expectedUses = "on CD"          },
            },
            rotationalSpells = {
                { id = 30455,  label = "Ice Lance", minFightSeconds = 15 },  -- proc consumer, used constantly
                { id = 44614,  label = "Flurry",    minFightSeconds = 15 },  -- Brain Freeze consumer
            },
            procBuffs = {
                { id = 190446, label = "Brain Freeze",     maxStackTime = 15 },
                { id = 44544,  label = "Fingers of Frost", maxStackTime = 15 },
            },
            priorityNotes = {
                "Spend Brain Freeze procs with Flurry immediately — before Ice Lance for shatter",
                "Spend Fingers of Frost with Ice Lance — do not let them expire",
                "Frozen Orb on cooldown for proc generation",
                "Icy Veins during burst windows — aligns with trinkets",
                "Avoid munching procs — never cast Flurry without Brain Freeze",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Frost Mage guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 9 · WARLOCK
    ----------------------------------------------------------------------------
    [9] = {
        className = "Warlock",

        -- Affliction (PASSIVE audit complete — April 2026)
        -- Verified against full Affliction talent tree snapshot 103 nodes
        -- Wither (445468): nodeID 94840 confirmed non-PASSIVE ACTIVE ✅
        -- Drain Soul 388667: nodeID 72045 confirmed PASSIVE — removed from rotational
        --   686 (baseline) remains as the trackable cast ID
        -- All other entries confirmed non-PASSIVE from talent snapshot
        [1] = {
            name = "Affliction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 205180,  label = "Summon Darkglare", expectedUses = "on CD"           },  -- nodeID 72034 non-PASSIVE ACTIVE
                { id = 442726,  label = "Malevolence",      expectedUses = "on CD"           },  -- nodeID 94842 non-PASSIVE ACTIVE
                { id = 1257052, label = "Dark Harvest",     expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 109860 non-PASSIVE ACTIVE
                { id = 445468,  label = "Wither",           expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 94840 non-PASSIVE ACTIVE confirmed
            },
            rotationalSpells = {
                { id = 48181,   label = "Haunt",               minFightSeconds = 20 },  -- nodeID 72032 non-PASSIVE ACTIVE
                { id = 1259790, label = "Unstable Affliction",  minFightSeconds = 15 },  -- nodeID 109862 non-PASSIVE ACTIVE
                { id = 686,     label = "Drain Soul",           minFightSeconds = 15 },  -- baseline spell list; 388667 removed (PASSIVE nodeID 72045)
                { id = 27243,   label = "Seed of Corruption",   minFightSeconds = 30 },  -- nodeID 72050 non-PASSIVE ACTIVE
            },
            uptimeBuffs = {},
            procBuffs = {
                { id = 108558, label = "Nightfall", maxStackTime = 12 },  -- nodeID 72047 PASSIVE ACTIVE — proc aura, VERIFY C_UnitAuras
            },
            priorityNotes = {
                "Maintain Agony, Corruption, and Unstable Affliction on all targets (not directly tracked)",
                "Haunt on cooldown for the damage amp window",
                "Drain Soul as primary filler — generates Soul Shards on kill",
                "Pool Soul Shards before burst windows — avoid overcapping",
                "Align Malevolence and Dark Harvest with Darkglare for stacked burst",
                "Malefic Rapture to spend Soul Shards during Darkglare windows",
                "Seed of Corruption for AoE — spreads Corruption to all nearby targets",
                "Spend Nightfall procs immediately on Shadow Bolt",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 15, activity = 30, resourceMgmt = 20 },
            sourceNote = "Midnight 12.0 verified against full Affliction talent tree snapshot 103 nodes (April 2026)",
        },

        -- Demonology (Full talent tree pass — April 2026)
        -- Verified against full talent tree snapshot (104 nodes, ACTIVE + INACTIVE)
        -- Hand of Gul'dan: talent version is 105174 (nodeID 101891) — tracking both
        --   172 (baseline) and 105174 (talent empowered) for full coverage
        -- Summon Vilefiend: correct Midnight 12.0 ID confirmed as 1251778 (nodeID 109252)
        --   was previously 264119 (wrong) then removed — now restored with correct ID
        -- Reign of Tyranny: INACTIVE in this build — added as talentGated CD (nodeID 110201)
        -- Dark Harvest 1257052: not in talent tree — baseline/granted spell, no change
        -- Demonbolt 264178: not in talent tree — baseline spell, no change
        [2] = {
            name = "Demonology", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 265187,  label = "Summon Demonic Tyrant",  expectedUses = "on CD"           },  -- nodeID 101905 — not PASSIVE
                { id = 442726,  label = "Malevolence",            expectedUses = "on CD"           },  -- nodeID 94842 — not PASSIVE
                { id = 104316,  label = "Call Dreadstalkers",     expectedUses = "on CD"           },  -- nodeID 101894 — not PASSIVE
                { id = 1276672, label = "Summon Doomguard",       expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 101917 — not PASSIVE
                { id = 1276467, label = "Grimoire: Fel Ravager",  expectedUses = "situational",    talentGated = true, isInterrupt = true },  -- nodeID 110197 — not PASSIVE; summon + interrupt
                -- Removed (confirmed PASSIVE via talent snapshot):
                -- Diabolic Ritual 428514 — PASSIVE
                -- Summon Vilefiend 1251778 — PASSIVE (nodeID 109252)
                -- Reign of Tyranny 1276748 — PASSIVE (nodeID 110201)
            },
            rotationalSpells = {
                { id = 196277,  label = "Implosion",       minFightSeconds = 15 },                          -- nodeID 101893
                { id = 105174,  label = "Hand of Gul'dan", minFightSeconds = 15, talentGated = true },      -- nodeID 101891; confirmed cast ID in Demonology
                { id = 264178,  label = "Demonbolt",       minFightSeconds = 20 },                          -- baseline; Demonic Core spender
                -- Doom (460551) removed — appears as damage tick in logs but not directly cast via UNIT_SPELLCAST_SUCCEEDED
                -- Applied automatically; cannot be tracked via cast detection. Re-add if confirmed castable via /ms verify.
                { id = 1257052, label = "Dark Harvest",    minFightSeconds = 30, talentGated = true },      -- confirmed spell list
            },
            procBuffs = {
                { id = 267102, label = "Demonic Core", maxStackTime = 20 },  -- confirmed spell list
            },
            priorityNotes = {
                "Stack demons before Demonic Tyrant — Tyrant extends all active pet durations",
                "Use Implosion at 6+ Wild Imps for maximum damage",
                "Call Dreadstalkers on cooldown — core damage and imp generation",
                "Hand of Gul'dan to summon imps and enable Implosion windows — primary shard spender",
                "Spend Demonic Core procs on Demonbolt — don't sit on stacks",
                "Summon Doomguard on cooldown — major burst CD when talented",
                "Avoid Soul Shard overcap — spend with Hand of Gul'dan",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 25, activity = 25, resourceMgmt = 15 },
            sourceNote = "Midnight 12.0 verified against full talent tree passive audit (April 2026)",
        },

        -- Destruction (Full talent tree pass — April 2026)
        -- Verified against full talent tree (103 nodes) and spell snapshot
        -- Malevolence: corrected 458355 → 442726 (nodeID 94842 ACTIVE)
        -- Havoc (80240) removed — not in Destruction talent tree or spell list in Midnight 12.0
        -- Immolate (348) removed from rotational — not in Destruction spell list or talent tree
        -- Incinerate: spell list shows 686 as "Incinerate" for Destruction (spec-variant baseline)
        -- Diabolic Ritual (428514) added as talentGated CD — nodeID 94855 ACTIVE
        -- Devastation (454735) added as talentGated CD — nodeID 110281 ACTIVE rank 2/2
        -- Conflagrate (17962) added to rotational — nodeID 72068 ACTIVE; core builder
        -- Shadowburn (17877) added to rotational — nodeID 72060 ACTIVE; execute finisher
        -- Rain of Fire (5740) added as talentGated rotational — nodeID 72069 ACTIVE
        [3] = {
            name = "Destruction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 1122,   label = "Summon Infernal",  expectedUses = "on CD"           },  -- nodeID 71985 — not PASSIVE
                { id = 442726, label = "Malevolence",      expectedUses = "on CD"           },  -- nodeID 94842 — not PASSIVE
                { id = 152108, label = "Cataclysm",        expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 71974 — not PASSIVE
                -- Removed (confirmed PASSIVE via talent snapshot):
                -- Diabolic Ritual 428514 — PASSIVE (nodeID 94855)
                -- Devastation 454735 — PASSIVE (nodeID 110281)
            },
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 686,    label = "Incinerate",   minFightSeconds = 15 },                      -- spell list confirmed; primary filler
                { id = 116858, label = "Chaos Bolt",   minFightSeconds = 20 },                      -- nodeID 110282 ACTIVE; primary spender
                { id = 17962,  label = "Conflagrate",  minFightSeconds = 15 },                      -- nodeID 72068 ACTIVE; core builder
                { id = 17877,  label = "Shadowburn",   minFightSeconds = 20, talentGated = true },  -- nodeID 72060 ACTIVE; execute finisher
                { id = 5740,   label = "Rain of Fire", minFightSeconds = 30, talentGated = true },  -- nodeID 72069 ACTIVE; AoE
            },
            priorityNotes = {
                "Maintain Immolate on all targets for shard generation (not directly tracked)",
                "Conflagrate on cooldown — generates Backdraft charges for Incinerate",
                "Do not waste Backdraft — cast Incinerate or Chaos Bolt while active",
                "Chaos Bolt is the primary shard spender — align with Summon Infernal and Malevolence",
                "Cataclysm on cooldown for AoE shard generation and Immolate spread when talented",
                "Shadowburn on low-health targets when talented — execute replacement",
                "Avoid Soul Shard overcap — spend with Chaos Bolt",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Midnight 12.0 verified against full Destruction talent tree snapshot 103 nodes (April 2026)",
        },
    },

    ----------------------------------------------------------------------------
    -- 10 · MONK
    ----------------------------------------------------------------------------
    [10] = {
        className = "Monk",

        -- Brewmaster
        [1] = {
            name = "Brewmaster", role = "TANK",
            resourceType = 1, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 132578, label = "Invoke Niuzao",   expectedUses = "burst damage" },
                { id = 322507, label = "Celestial Brew",  expectedUses = "big hits"     },
                { id = 115203, label = "Fortifying Brew", expectedUses = "emergency"    },
            },
            uptimeBuffs = {
                { id = 215479, label = "Ironskin Brew", targetUptime = 60 },
            },
            rotationalSpells = {
                { id = 121253, label = "Keg Smash",       minFightSeconds = 20 },
                { id = 119582, label = "Purifying Brew",  minFightSeconds = 30 },
            },
            tankMetrics = { targetMitigationUptime = 60 },
            priorityNotes = {
                "Maintain Ironskin Brew for stagger reduction at 60%+ uptime (tracked via uptimeBuffs)",
                "Purifying Brew to clear Heavy or Severe Stagger — don't let it sit",
                "Keg Smash on cooldown — primary Brew generator and damage",
                "Celestial Brew for absorb shield before predictable big hits",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Brewmaster Monk guide",
        },

        -- Mistweaver
        [2] = {
            name = "Mistweaver", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 115310, label = "Revival",           expectedUses = "raid emergency" },
                { id = 322118, label = "Invoke Yu'lon",     expectedUses = "sustained AoE"  },
                { id = 116680, label = "Thunder Focus Tea", expectedUses = "on CD"          },
            },
            rotationalSpells = {
                { id = 119611, label = "Renewing Mist",  minFightSeconds = 20 },
                { id = 107428, label = "Rising Sun Kick", minFightSeconds = 20 },
            },
            healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
            priorityNotes = {
                "Keep Renewing Mist rolling on as many injured targets as possible",
                "Rising Sun Kick on cooldown — damage amp and healing bonus",
                "Vivify to proc Renewing Mist bouncing to other targets",
                "Thunder Focus Tea on cooldown — empowers next major heal",
                "Revival for emergency full-group healing — do not hold it",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Mistweaver Monk guide",
        },

        -- Windwalker
        -- Added:    rotationalSpells: Fists of Fury (113656), Rising Sun Kick (107428)
        --           Both are high-priority abilities with short CDs, not true burst cooldowns
        [3] = {
            name = "Windwalker", role = "DPS",
            resourceType = 12, resourceLabel = "CHI", overcapAt = 6,
            majorCooldowns = {
                { id = 137639, label = "Storm, Earth and Fire", expectedUses = "on CD"          },
                { id = 123904, label = "Invoke Xuen",           expectedUses = "burst windows"  },
                { id = 152173, label = "Serenity",              expectedUses = "burst (talent)" },
            },
            rotationalSpells = {
                -- Short-CD high-priority abilities; tracked for presence not frequency
                { id = 113656, label = "Fists of Fury",   minFightSeconds = 15 },  -- highest damage CD ~12s
                { id = 107428, label = "Rising Sun Kick",  minFightSeconds = 15 },  -- ~10s CD
            },
            procBuffs = {
                { id = 116768, label = "Combo Breaker: BoK", maxStackTime = 15 },
            },
            priorityNotes = {
                "Fists of Fury on cooldown — highest single-target damage ability",
                "Rising Sun Kick on cooldown — damage and Mortal Wounds debuff",
                "Storm, Earth and Fire on cooldown — sustained DPS, not a burst CD",
                "Blackout Kick as filler to generate Chi and trigger Combo Breaker",
                "Serenity / Invoke Xuen for burst — align with trinkets and lust",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 20, activity = 30, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Windwalker Monk guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 11 · DRUID
    ----------------------------------------------------------------------------
    [11] = {
        className = "Druid",

        -- Balance (Midnight 12.0 rotation guide pass — April 2026)
        -- Rotation priority sourced from Icy Veins / Wowhead Balance Druid guide
        -- Starfall moved from majorCooldowns to rotationalSpells — it's a spender, not a burst CD
        -- Force of Nature (205636) added as talentGated CD — appears in both hero talent priority lists
        -- Fury of Elune (202770) added to rotational — high priority during Eclipse in both priority lists
        -- Wrath (5176) added to rotational — baseline filler, primary AP generator
        -- Hero talent builds differ (Incarnation vs Celestial Alignment) — both tracked as talentGated
        [1] = {
            name = "Balance", role = "DPS",
            resourceType = 8, resourceLabel = "ASTRAL POWER", overcapAt = 90,
            majorCooldowns = {
                { id = 194223, label = "Celestial Alignment",          expectedUses = "on CD",           talentGated = true },  -- hero talent build 1
                { id = 102560, label = "Incarnation: Chosen of Elune", expectedUses = "on CD (talent)",  talentGated = true },  -- hero talent build 2
                { id = 205636, label = "Force of Nature",              expectedUses = "on CD (talent)",  talentGated = true },  -- priority #3-5 in both builds
            },
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 8921,   label = "Moonfire",      minFightSeconds = 15 },                      -- priority #1 — maintain DoT
                { id = 93402,  label = "Sunfire",       minFightSeconds = 15 },                      -- priority #2 — maintain DoT
                { id = 202770, label = "Fury of Elune", minFightSeconds = 20, talentGated = true },  -- priority #3 — use during Eclipse
                { id = 191034, label = "Starfall",      minFightSeconds = 20 },                      -- priority #8 — AoE AP spender
                { id = 78674,  label = "Starsurge",     minFightSeconds = 20 },                      -- priority #9 — main ST spender
                { id = 5176,   label = "Wrath",         minFightSeconds = 15 },                      -- priority #10 — AP generator filler
            },
            priorityNotes = {
                "Maintain Moonfire and Sunfire on all targets — refresh within pandemic (not directly tracked)",
                "Fury of Elune during Eclipse or before Force of Nature when talented",
                "Force of Nature when not in Eclipse and about to enter Solar Eclipse",
                "Celestial Alignment / Incarnation as burst window — use Force of Nature first",
                "Starfall to consume Starweaver's Warp procs and for AoE",
                "Starsurge as main spender — use on movement, near AP cap, or Starweaver's Weft procs",
                "Wrath to generate Astral Power — never overcap at 90",
            },
            scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Midnight 12.0 verified against Icy Veins Balance Druid rotation guide (April 2026)",
        },

        -- Feral (PASSIVE audit — April 2026)
        -- Incarnation: Avatar of Ashamane (102543) removed — not in Feral talent tree
        -- Predatory Swiftness (69369) removed from procBuffs — not in talent tree or spell list, VERIFY never confirmed
        -- Frantic Frenzy (1243807) added as talentGated CD — non-PASSIVE ACTIVE nodeID 82111, confirmed spell list
        -- Feral Frenzy (274837) added as talentGated CD — non-PASSIVE ACTIVE nodeID 82112, confirmed spell list
        -- Primal Wrath (285381) added as talentGated rotational — non-PASSIVE ACTIVE nodeID 82120; AoE finisher
        [2] = {
            name = "Feral", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 5217,   label = "Tiger's Fury",       expectedUses = "on CD"          },  -- non-PASSIVE ACTIVE nodeID 82124
                { id = 106951, label = "Berserk",             expectedUses = "burst windows"  },  -- non-PASSIVE ACTIVE nodeID 82101
                { id = 391528, label = "Convoke the Spirits", expectedUses = "burst windows",  talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82114
                { id = 1243807, label = "Frantic Frenzy",    expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82111
                { id = 274837, label = "Feral Frenzy",        expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82112
                -- Incarnation: Avatar of Ashamane (102543) removed — not in Feral talent tree
            },
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 1079,   label = "Rip",            minFightSeconds = 15 },                      -- non-PASSIVE ACTIVE nodeID 82222
                { id = 1822,   label = "Rake",           minFightSeconds = 15 },                      -- non-PASSIVE ACTIVE nodeID 82199
                { id = 22568,  label = "Ferocious Bite", minFightSeconds = 20 },                      -- baseline confirmed spell list
                { id = 5221,   label = "Shred",          minFightSeconds = 15 },                      -- baseline confirmed spell list; primary CP builder
                { id = 285381, label = "Primal Wrath",   minFightSeconds = 20, talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82120; AoE finisher
            },
            priorityNotes = {
                "Ferocious Bite on Apex Predator's Craving procs — highest priority",
                "Maintain Rip at 4+ combo points with Tiger's Fury active when possible",
                "Ferocious Bite at 5 CP with Berserk active, 4 CP without",
                "Sync Berserk and Convoke the Spirits with Tiger's Fury for burst",
                "Tiger's Fury on cooldown — Energy refill and damage buff",
                "Maintain Rake — refresh in pandemic, prioritise Tiger's Fury snapshots",
                "Shred to generate combo points — primary filler",
                "Primal Wrath as AoE finisher when talented — replaces Ferocious Bite on multi-target",
            },
            scoreWeights = { cooldownUsage = 25, procUsage = 15, activity = 35, resourceMgmt = 25 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Feral talent tree 114 nodes (April 2026)",
        },

        -- Guardian (PASSIVE audit — April 2026)
        -- Maul/Raze (6807) added to rotational — non-PASSIVE ACTIVE nodeID 82127; Rage spender
        --   Note: 6807 shows as "Raze" in Guardian spell list (spec-variant)
        -- Lunar Beam (204066) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 92587
        -- Red Moon: confirmed in Balance spell list only — NOT present in Guardian files, not tracked
        -- Catform spells excluded — Bear form only for Guardian
        [3] = {
            name = "Guardian", role = "TANK",
            resourceType = 8, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 102558, label = "Incarnation: Guardian", expectedUses = "on CD"           },  -- non-PASSIVE ACTIVE nodeID 82136
                { id = 22812,  label = "Barkskin",              expectedUses = "magic damage"    },  -- baseline confirmed spell list
                { id = 22842,  label = "Frenzied Regeneration", expectedUses = "low health"      },  -- non-PASSIVE ACTIVE nodeID 82220
                { id = 204066, label = "Lunar Beam",            expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 92587
            },
            uptimeBuffs = {
                { id = 192081, label = "Ironfur", targetUptime = 70 },  -- non-PASSIVE ACTIVE nodeID 82227
            },
            rotationalSpells = {
                { id = 8921,    label = "Moonfire",  minFightSeconds = 15 },                      -- baseline; rotation priority #1
                { id = 33917,   label = "Mangle",    minFightSeconds = 15 },                      -- baseline; rotation priority #4
                { id = 77758,   label = "Thrash",    minFightSeconds = 15 },                      -- baseline; rotation priority #5
                { id = 6807,    label = "Maul",      minFightSeconds = 20 },                      -- non-PASSIVE ACTIVE nodeID 82127; Rage spender
                { id = 213764,  label = "Swipe",     minFightSeconds = 20 },                      -- non-PASSIVE ACTIVE nodeID 82223; filler only
                -- Red Moon (1252871) removed — confirmed in Balance spell list only, not Guardian
            },
            tankMetrics = { targetMitigationUptime = 70 },
            priorityNotes = {
                "Maintain Moonfire on your primary target at all times",
                "Keep Ironfur active — spend Rage for 70%+ uptime (tracked via uptimeBuffs)",
                "Mangle on cooldown — primary Rage generator",
                "Thrash on cooldown — maintain 3-5 stacks",
                "Spend Rage on Ironfur defensively or Maul offensively",
                "Lunar Beam on cooldown when talented — healing and damage",
                "Frenzied Regeneration when health dips low — reactive self-heal",
                "Barkskin and Incarnation on cooldown — use as frequently as possible",
                "Swipe as a filler only — never delay Mangle or Thrash for it",
            },
            scoreWeights = { cooldownUsage = 25, mitigationUptime = 40, activity = 20, resourceMgmt = 15 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Guardian talent tree 116 nodes (April 2026)",
        },

        -- Restoration (PASSIVE audit — April 2026)
        -- Incarnation: Tree of Life (33891) removed — not in Restoration talent tree
        -- Flourish (197721) removed — not in Restoration talent tree or spell list
        -- Wild Growth moved from majorCooldowns to rotational — it's a maintenance spell, not a burst CD
        -- Convoke the Spirits (391528) added as talentGated CD — non-PASSIVE ACTIVE nodeID 82064
        -- Ironbark (102342) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 82082; external defensive
        -- Nature's Swiftness (132158) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 82050; instant cast CD
        -- Lifebloom (33763) added to rotational — non-PASSIVE ACTIVE nodeID 82049; core HoT
        -- Innervate (29166) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 82244; mana CD
        [4] = {
            name = "Restoration", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 740,    label = "Tranquility",       expectedUses = "heavy damage windows"  },  -- non-PASSIVE ACTIVE nodeID 82054
                { id = 102342, label = "Ironbark",          expectedUses = "tank busters"          },  -- non-PASSIVE ACTIVE nodeID 82082
                { id = 132158, label = "Nature's Swiftness", expectedUses = "emergency instant"    },  -- non-PASSIVE ACTIVE nodeID 82050
                { id = 29166,  label = "Innervate",         expectedUses = "mana recovery",        talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82244
                { id = 391528, label = "Convoke the Spirits", expectedUses = "burst throughput",   talentGated = true },  -- non-PASSIVE ACTIVE nodeID 82064
                -- Incarnation: Tree of Life (33891) removed — not in talent tree
                -- Flourish (197721) removed — not in talent tree or spell list
            },
            rotationalSpells = {
                { id = 774,   label = "Rejuvenation",  minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 82217
                { id = 18562, label = "Swiftmend",     minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 82047
                { id = 33763, label = "Lifebloom",     minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 82049; core single-target HoT
                { id = 48438, label = "Wild Growth",   minFightSeconds = 30 },  -- non-PASSIVE ACTIVE nodeID 82205; AoE HoT
            },
            healerMetrics = { targetOverheal = 35, targetActivity = 75, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Rejuvenation rolling on injured targets — core HoT foundation",
                "Maintain Lifebloom on the tank — primary single-target HoT",
                "Wild Growth for efficient AoE healing on grouped targets",
                "Swiftmend for emergency instant healing",
                "Nature's Swiftness for an instant cast of any spell in an emergency",
                "Ironbark on the tank for heavy physical damage",
                "Innervate during heavy casting phases to recover mana when talented",
                "Tranquility for heavy sustained raid damage — hold for peak damage",
                "Convoke the Spirits for burst throughput when talented",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Restoration talent tree 119 nodes (April 2026)",
        },
    },

    ----------------------------------------------------------------------------
    -- 12 · DEMON HUNTER
    ----------------------------------------------------------------------------
    [12] = {
        className = "Demon Hunter",

        -- Havoc (Midnight 12.0 pass — April 2026)
        -- Verified against full talent tree (123 nodes, PASSIVE column) and spell snapshot
        -- Fel Barrage (258925) removed — not in Midnight 12.0 talent tree or spell list
        -- Chaos Strike: spell list confirms 344862 (spec-variant); was 162794 — corrected
        -- The Hunt: tracking both 370965 and 1246167 (both in spell list)
        -- Essence Break (258860) added to rotational — non-PASSIVE ACTIVE nodeID 91033
        -- Felblade (232893) added to rotational — non-PASSIVE ACTIVE nodeID 91008
        [1] = {
            name = "Havoc", role = "DPS",
            resourceType = 17, resourceLabel = "FURY", overcapAt = 100,
            validSpells = {
                [191427]=true,  -- Metamorphosis
                [198013]=true,  -- Eye Beam
                [370965]=true,  -- The Hunt
                [1246167]=true, -- The Hunt (spec-variant confirmed spell snapshot)
                [188499]=true,  -- Blade Dance
                [344862]=true,  -- Chaos Strike (spec-variant confirmed — was 162794)
                [258920]=true,  -- Immolation Aura
                [188501]=true,  -- Spectral Sight
                [198793]=true,  -- Vengeful Retreat
                [179057]=true,  -- Chaos Nova (non-PASSIVE nodeID 90993)
                [232893]=true,  -- Felblade (non-PASSIVE nodeID 91008)
                [258860]=true,  -- Essence Break (non-PASSIVE nodeID 91033)
                [344865]=true,  -- Fel Rush (confirmed spell snapshot)
                [185164]=true,  -- Mastery: Demonic Presence
                [255260]=true,  -- Chaos Brand
                [278326]=true,  -- Consume Magic
                [196718]=true,  -- Darkness
                [183752]=true,  -- Disrupt
                [196055]=true,  -- Double Jump
                [131347]=true,  -- Glide
                [217832]=true,  -- Imprison
                [207684]=true,  -- Sigil of Misery
                [185123]=true,  -- Throw Glaive
                [185245]=true,  -- Torment
                [337567]=true,  -- Furious Gaze proc
                [389860]=true,  -- Unbound Chaos proc
            },
            majorCooldowns = {
                { id = 191427, label = "Metamorphosis", expectedUses = "burst windows"           },  -- non-PASSIVE confirmed
                { id = 198013, label = "Eye Beam",      expectedUses = "on CD"                  },  -- non-PASSIVE nodeID 91018
                { id = 370965, label = "The Hunt",      expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE nodeID 90921
                -- Fel Barrage (258925) removed — not in Midnight 12.0
            },
            rotationalSpells = {
                { id = 188499, label = "Blade Dance",     minFightSeconds = 15 },
                { id = 344862, label = "Chaos Strike",    minFightSeconds = 15 },              -- spec-variant (was 162794)
                { id = 258920, label = "Immolation Aura", minFightSeconds = 15 },
                { id = 258860, label = "Essence Break",   minFightSeconds = 20, talentGated = true },  -- non-PASSIVE ACTIVE nodeID 91033
                { id = 232893, label = "Felblade",        minFightSeconds = 15, talentGated = true },  -- non-PASSIVE ACTIVE nodeID 91008
            },
            procBuffs = {
                { id = 337567, label = "Furious Gaze",  maxStackTime = 8  },   -- VERIFY C_UnitAuras — not in Havoc talent or spell snapshot
                { id = 389860, label = "Unbound Chaos", maxStackTime = 12 },   -- VERIFY C_UnitAuras — not in Havoc talent or spell snapshot
            },
            priorityNotes = {
                "Immolation Aura on cooldown — primary Fury generator",
                "Eye Beam on cooldown — core damage and Fury dump",
                "Blade Dance on cooldown — highest priority spender",
                "Essence Break before Chaos Strike when talented — amplifies damage",
                "Chaos Strike to spend Fury — never overcap at 100",
                "Metamorphosis for burst — align with trinkets and lust",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 20, activity = 30, resourceMgmt = 20 },
            sourceNote = "Midnight 12.0 verified against full Havoc talent tree 123 nodes (April 2026)",
        },

        -- Vengeance (Midnight 12.0 pass — April 2026)
        -- Verified against spell snapshot and talent tree
        -- Metamorphosis: was 187827, both spell snapshots confirm 191427 — corrected
        -- Demon Spikes: was 203819 in uptimeBuffs, spell list confirms 203720 — corrected
        -- Fracture: was 210152, spell list confirms 344859 (spec-variant) — corrected
        -- Soul Barrier (263648) removed — not in Midnight 12.0 spell list or talent tree
        -- Soul Cleave: was 228477, spell list confirms 344862 (spec-variant) — corrected
        -- Spirit Bomb (247454) added to rotational — confirmed spell list, non-PASSIVE ACTIVE nodeID 90990
        [2] = {
            name = "Vengeance", role = "TANK",
            resourceType = 17, resourceLabel = "FURY", overcapAt = 100,
            validSpells = {
                [191427]=true,  -- Metamorphosis (confirmed spell snapshot — was 187827)
                [204021]=true,  -- Fiery Brand (confirmed spell snapshot)
                [212084]=true,  -- Fel Devastation (confirmed spell snapshot)
                [203720]=true,  -- Demon Spikes (confirmed spell snapshot — was 203819)
                [258920]=true,  -- Immolation Aura
                [344862]=true,  -- Soul Cleave (spec-variant confirmed — was 228477)
                [344859]=true,  -- Fracture (spec-variant confirmed — was 210152)
                [247454]=true,  -- Spirit Bomb (confirmed spell snapshot)
                [278386]=true,  -- Demonic Wards
                [206478]=true,  -- Demonic Appetite
                [255260]=true,  -- Chaos Brand
                [278326]=true,  -- Consume Magic
                [196718]=true,  -- Darkness
                [183752]=true,  -- Disrupt
                [196055]=true,  -- Double Jump
                [131347]=true,  -- Glide
                [217832]=true,  -- Imprison
                [207684]=true,  -- Sigil of Misery
                [185123]=true,  -- Throw Glaive
                [185245]=true,  -- Torment
                -- Soul Barrier (263648) removed — not in Midnight 12.0
            },
            majorCooldowns = {
                { id = 191427, label = "Metamorphosis",   expectedUses = "emergency mitigation" },  -- non-PASSIVE confirmed
                { id = 204021, label = "Fiery Brand",     expectedUses = "tank busters"         },  -- non-PASSIVE ACTIVE nodeID 90951
                { id = 212084, label = "Fel Devastation", expectedUses = "on CD"                },  -- non-PASSIVE ACTIVE nodeID 90991
                { id = 390163, label = "Sigil of Spite",  expectedUses = "on CD (talent)", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 90978
                -- Soul Barrier (263648/1265924) removed — PASSIVE confirmed
            },
            uptimeBuffs = {
                { id = 203720, label = "Demon Spikes", targetUptime = 50 },
            },
            rotationalSpells = {
                { id = 247454, label = "Spirit Bomb", minFightSeconds = 20 },                      -- non-PASSIVE ACTIVE nodeID 90990
                { id = 344859, label = "Fracture",    minFightSeconds = 15 },                      -- spec-variant; generates Soul Fragments
                { id = 232893, label = "Felblade",    minFightSeconds = 15, talentGated = true },  -- non-PASSIVE ACTIVE nodeID 108722
            },
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Maintain Demon Spikes for physical mitigation",
                "Immolation Aura on cooldown for Fury and damage",
                "Fracture to generate Soul Fragments",
                "Spirit Bomb with 4-5 Soul Fragments for healing and damage",
                "Fiery Brand for magic damage or tank busters",
                "Fel Devastation on cooldown for sustained damage and healing",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Midnight 12.0 verified against Vengeance spell snapshot and talent tree (April 2026)",
        },

        -- Devourer (Midnight 12.0 PASSIVE audit — April 2026)
        -- Full talent tree snapshot (112 nodes, PASSIVE column) confirmed the following:
        -- PASSIVE — removed from majorCooldowns: Impending Apocalypse (1227707), Demonsurge (452402), Midnight (1250094)
        -- PASSIVE — removed from rotational: Eradicate (1226033)
        -- PASSIVE — removed from validSpells: 471306 (talent node), 1221167 (talent node), 1250094
        -- Soul Immolation (1241937) confirmed non-PASSIVE ACTIVE nodeID 107344 — retained as sole majorCD
        -- Void Metamorphosis castable: 191427 confirmed in spellbook, non-passive — retained in rotational
        -- Collapsing Star: 1221150 (castable) not in talent tree — retained via combatGated, no change
        [3] = {
            name = "Devourer", role = "DPS",
            resourceType = 17, resourceLabel = "FURY", overcapAt = 100,
            -- Strict whitelist — hard-blocks all Havoc/Vengeance abilities
            validSpells = {
                [191427]=true,  -- Void Metamorphosis (castable, confirmed spellbook, non-PASSIVE)
                -- 471306 removed — PASSIVE talent node
                [1221150]=true, -- Collapsing Star (castable — confirmed via debug session)
                -- 1221167 removed — PASSIVE talent node
                [344862]=true,  -- Reap (confirmed spell snapshot)
                [344859]=true,  -- Consume (confirmed spell snapshot)
                [344865]=true,  -- Shift (confirmed spell snapshot)
                [473728]=true,  -- Void Ray (non-PASSIVE ACTIVE nodeID 107336)
                [1245412]=true, -- Voidblade (non-PASSIVE ACTIVE nodeID 108723)
                [1234195]=true, -- Void Nova (non-PASSIVE ACTIVE nodeID 107347)
                [1241937]=true, -- Soul Immolation (non-PASSIVE ACTIVE nodeID 107344)
                -- 1227707 Impending Apocalypse removed — PASSIVE
                -- 1226033 Eradicate removed — PASSIVE INACTIVE
                -- 1250094 Midnight removed — PASSIVE INACTIVE
                -- 452402  Demonsurge removed — PASSIVE
                [1260008]=true, -- Grim Focus (confirmed spell snapshot)
                [198589]=true,  -- Blur
                [1238855]=true, -- Mastery: Monster Within
                [1227619]=true, -- Shattered Souls
                [255260]=true,  -- Chaos Brand
                [278326]=true,  -- Consume Magic (non-PASSIVE ACTIVE nodeID 91006)
                [196718]=true,  -- Darkness (non-PASSIVE ACTIVE nodeID 91002)
                [183752]=true,  -- Disrupt
                [196055]=true,  -- Double Jump
                [131347]=true,  -- Glide
                [217832]=true,  -- Imprison (non-PASSIVE ACTIVE nodeID 91007)
                [207684]=true,  -- Sigil of Misery (non-PASSIVE ACTIVE nodeID 90946)
                [185123]=true,  -- Throw Glaive
                [185245]=true,  -- Torment
            },
            majorCooldowns = {
                -- Only Soul Immolation survived the PASSIVE audit as a trackable CD
                { id = 1241937, label = "Soul Immolation", expectedUses = "on CD", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 107344
                -- Removed (confirmed PASSIVE via talent snapshot):
                -- Impending Apocalypse 1227707, Demonsurge 452402, Midnight 1250094
            },
            rotationalSpells = {
                { id = 191427,  label = "Void Metamorphosis", minFightSeconds = 30 },                    -- castable, non-PASSIVE, confirmed spellbook
                { id = 1221150, label = "Collapsing Star",    minFightSeconds = 45, combatGated = true }, -- inside Void Metamorphosis window only
                { id = 344862,  label = "Reap",               minFightSeconds = 20 },                    -- confirmed spell snapshot
                { id = 473728,  label = "Void Ray",           minFightSeconds = 15 },                    -- non-PASSIVE ACTIVE nodeID 107336
                { id = 1245412, label = "Voidblade",          minFightSeconds = 15, talentGated = true }, -- non-PASSIVE ACTIVE nodeID 108723
                { id = 1234195, label = "Void Nova",          minFightSeconds = 20, talentGated = true }, -- non-PASSIVE ACTIVE nodeID 107347
                -- Eradicate (1226033) removed — PASSIVE INACTIVE
            },
            priorityNotes = {
                "Build Soul Fragments to trigger Void Metamorphosis windows",
                "Use Collapsing Star inside Void Metamorphosis for maximum damage",
                "Cast Void Ray to generate Souls and Fury outside Void Metamorphosis",
                "Voidblade as primary Fury spender when talented — use on cooldown",
                "Void Nova for burst AoE — use inside Void Metamorphosis windows when talented",
                "Soul Immolation on cooldown when talented — major burst window",
                "Pool Fury before entering Void Metamorphosis for burst spending",
            },
            scoreWeights = { cooldownUsage = 25, activity = 40, resourceMgmt = 20, procUsage = 15 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full talent tree 112 nodes (April 2026)",
        },
    },

    ----------------------------------------------------------------------------
    -- 13 · EVOKER
    ----------------------------------------------------------------------------
    [13] = {
        className = "Evoker",

        -- Devastation (Midnight 12.0 PASSIVE audit — April 2026)
        -- All majorCooldowns confirmed non-PASSIVE or baseline (Fire Breath, Deep Breath not in talent tree — baseline spells)
        -- Pyre (357211) added to rotational — non-PASSIVE ACTIVE nodeID 93334
        -- Quell (351338) added as isInterrupt — non-PASSIVE ACTIVE nodeID 93332
        -- VERIFY resource enum: resourceType 17 pending in-game confirmation
        [1] = {
            name = "Devastation", role = "DPS",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,  -- VERIFY resource enum
            majorCooldowns = {
                { id = 375087, label = "Dragonrage",     expectedUses = "on CD"         },  -- non-PASSIVE ACTIVE nodeID 93331
                { id = 357208, label = "Fire Breath",    expectedUses = "on CD"         },  -- baseline confirmed spell list
                { id = 359073, label = "Eternity Surge", expectedUses = "on CD"         },  -- non-PASSIVE ACTIVE nodeID 93275
                { id = 357210, label = "Deep Breath",    expectedUses = "burst windows" },  -- baseline confirmed spell list
                { id = 351338, label = "Quell",          expectedUses = "situational",   isInterrupt = true },  -- non-PASSIVE ACTIVE nodeID 93332
            },
            rotationalSpells = {
                { id = 361469, label = "Living Flame",  minFightSeconds = 20 },  -- baseline confirmed spell list
                { id = 356995, label = "Disintegrate",  minFightSeconds = 20 },  -- baseline confirmed spell list
                { id = 357211, label = "Pyre",          minFightSeconds = 20, talentGated = true },  -- non-PASSIVE ACTIVE nodeID 93334; AoE spender
            },
            priorityNotes = {
                "Fire Breath and Eternity Surge on cooldown — highest priority empowered spells",
                "Dragonrage for burst — maximize empowered cast rate inside window",
                "Disintegrate as primary filler — strong sustained channel",
                "Living Flame as filler when moving — do not cap Essence",
                "Pyre for AoE when talented — replaces Living Flame in cleave",
                "Deep Breath for AoE on stacked targets",
            },
            scoreWeights = { cooldownUsage = 35, activity = 30, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Devastation talent tree 122 nodes (April 2026)",
        },

        -- Preservation (Midnight 12.0 PASSIVE audit — April 2026)
        -- Emerald Communion (370960) removed — not in Preservation talent tree or spell list
        -- Tip the Scales: was 374348 (Renewing Blaze in spell list) — corrected to 370553 (nodeID 93350 non-PASSIVE)
        -- Time Dilation (357170) added — non-PASSIVE ACTIVE nodeID 93336
        -- Temporal Anomaly (373861) added to rotational — non-PASSIVE ACTIVE nodeID 93257
        -- Echo (364343) added to rotational — non-PASSIVE ACTIVE nodeID 93339; core mechanic
        [2] = {
            name = "Preservation", role = "HEALER",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,
            majorCooldowns = {
                { id = 363534, label = "Rewind",          expectedUses = "emergency"     },  -- non-PASSIVE ACTIVE nodeID 93337
                { id = 355936, label = "Dream Breath",    expectedUses = "on CD AoE"     },  -- non-PASSIVE ACTIVE nodeID 93240
                { id = 370553, label = "Tip the Scales",  expectedUses = "burst ramp"    },  -- non-PASSIVE ACTIVE nodeID 93350 (was 374348 — wrong)
                { id = 357170, label = "Time Dilation",   expectedUses = "emergency HoT" },  -- non-PASSIVE ACTIVE nodeID 93336
                -- Emerald Communion (370960) removed — not in Preservation talent tree or spell list
            },
            rotationalSpells = {
                { id = 366155, label = "Reversion",        minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 93338
                { id = 355913, label = "Emerald Blossom",  minFightSeconds = 30 },  -- baseline confirmed spell list
                { id = 373861, label = "Temporal Anomaly", minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 93257
                { id = 364343, label = "Echo",             minFightSeconds = 15 },  -- non-PASSIVE ACTIVE nodeID 93339; core mechanic
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 10 },
            priorityNotes = {
                "Reversion on cooldown — primary single-target HoT filler",
                "Emerald Blossom for group healing efficiency",
                "Dream Breath on cooldown — primary AoE healing",
                "Echo before high-throughput spells to amplify effect",
                "Temporal Anomaly for group HoT spread",
                "Tip the Scales for instant empowered cast during burst",
                "Rewind is a true emergency — save for near-wipes only",
                "Time Dilation to extend a teammate's HoT in critical moments",
            },
            scoreWeights = { cooldownUsage = 30, efficiency = 30, activity = 25, responsiveness = 15 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Preservation talent tree 123 nodes (April 2026)",
        },

        -- Augmentation (Midnight 12.0 PASSIVE audit — April 2026)
        -- Eruption: was 359618 — talent tree confirms 395160 (nodeID 93200 non-PASSIVE). Corrected.
        -- Time Skip (404977) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 93232
        -- Blistering Scales (360827) added to majorCooldowns — non-PASSIVE ACTIVE nodeID 93209; party defensive
        -- Quell (351338) added as isInterrupt — non-PASSIVE ACTIVE nodeID 93199
        [3] = {
            name = "Augmentation", role = "DPS",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,
            majorCooldowns = {
                { id = 403631, label = "Breath of Eons",    expectedUses = "burst windows"     },  -- non-PASSIVE ACTIVE nodeID 93234
                { id = 395152, label = "Ebon Might",        expectedUses = "on CD"             },  -- non-PASSIVE ACTIVE nodeID 93198
                { id = 409311, label = "Prescience",        expectedUses = "pre-burst"         },  -- non-PASSIVE ACTIVE nodeID 93358
                { id = 404977, label = "Time Skip",         expectedUses = "on CD",            talentGated = true },  -- non-PASSIVE ACTIVE nodeID 93232
                { id = 360827, label = "Blistering Scales", expectedUses = "party mitigation", talentGated = true },  -- non-PASSIVE ACTIVE nodeID 93209
                { id = 351338, label = "Quell",             expectedUses = "situational",      isInterrupt = true },  -- non-PASSIVE ACTIVE nodeID 93199
            },
            uptimeBuffs = {
                { id = 395152, label = "Ebon Might", targetUptime = 70 },
            },
            rotationalSpells = {
                { id = 396286, label = "Upheaval",  minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 93203
                { id = 395160, label = "Eruption",  minFightSeconds = 20 },  -- non-PASSIVE ACTIVE nodeID 93200 (was 359618 — wrong)
            },
            priorityNotes = {
                "Ebon Might on cooldown — core party amplification buff (tracked via uptimeBuffs)",
                "Prescience before burst cooldowns to amplify allies",
                "Upheaval and Eruption for personal damage contribution",
                "Breath of Eons for peak burst — aligns with lust",
                "Time Skip on cooldown when talented — significant throughput increase",
                "Blistering Scales on the most targeted ally when talented",
                "Maintain Ebon Might uptime at 70%+ for maximum support value",
            },
            scoreWeights = { cooldownUsage = 35, mitigationUptime = 30, activity = 25, resourceMgmt = 10 },
            sourceNote = "Midnight 12.0 PASSIVE audit against full Augmentation talent tree 114 nodes (April 2026)",
        },
    },
}

--------------------------------------------------------------------------------
-- Spec Detection
--------------------------------------------------------------------------------
Core.ActiveSpec = nil

local function DetectSpec()
    local classID = select(3, UnitClass("player"))
    local specIdx = GetSpecialization()
    if not classID or not specIdx then Core.ActiveSpec = nil ; return end
    local classData = Core.SPEC_DATABASE[classID]
    if not classData then Core.ActiveSpec = nil ; return end
    local specData = classData[specIdx]
    if not specData then Core.ActiveSpec = nil ; return end

    Core.ActiveSpec           = specData
    Core.ActiveSpec.className = classData.className or "Unknown"
    Core.ActiveSpec.classID   = classID
    Core.ActiveSpec.specIdx   = specIdx
    Core.Emit(Core.EVENTS.SPEC_CHANGED, Core.ActiveSpec)
end
Core.DetectSpec = DetectSpec

--------------------------------------------------------------------------------
-- Combat State
--------------------------------------------------------------------------------
Core.InCombat    = false
Core.CombatStart = 0
Core.CombatEnd   = 0

--------------------------------------------------------------------------------
-- Version Broadcast  (prefix "MS_VER")
--------------------------------------------------------------------------------
local VER_PREFIX          = "MS_VER"
local hasBroadcast        = false
local notifiedThisSession = false

local function ParseVer(v)
    local s = tostring(v):match("^([%d%.]+)") or "0"
    local a, b, c = s:match("^(%d+)%.?(%d*)%.?(%d*)")
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end
local function IsNewer(theirs, mine)
    local tA,tB,tC = ParseVer(theirs)
    local mA,mB,mC = ParseVer(mine)
    if tA ~= mA then return tA > mA end
    if tB ~= mB then return tB > mB end
    return tC > mC
end

local function BroadcastVersion()
    if hasBroadcast then return end
    local msg = "VERSION|" .. Core.VERSION
    if IsInGuild()  then C_ChatInfo.SendAddonMessage(VER_PREFIX, msg, "GUILD") end
    if IsInRaid()   then C_ChatInfo.SendAddonMessage(VER_PREFIX, msg, "RAID")
    elseif IsInGroup() then C_ChatInfo.SendAddonMessage(VER_PREFIX, msg, "PARTY") end
    hasBroadcast = true
end

--------------------------------------------------------------------------------
-- Encounter Condition Adjustments
--------------------------------------------------------------------------------
Core.ENCOUNTER_ADJUSTMENTS = {
    highMovement  = { dpsMultiplier = 0.85, description = "Movement-heavy fight"      },
    intermissions = { dpsMultiplier = 0.90, description = "Intermission phases"       },
    targetSwitch  = { dpsMultiplier = 0.92, description = "Target switching required" },
    spread        = { dpsMultiplier = 0.88, description = "Spread mechanics"          },
    patchwerk     = { dpsMultiplier = 1.00, description = "Stand-and-deliver"         },
}

--------------------------------------------------------------------------------
-- Event Frame
--------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame", "MidnightSenseiEventFrame", UIParent)

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Core.InitSavedVariables()
        DetectSpec()
        C_Timer.After(3.0, BroadcastVersion)
        C_Timer.After(1.0, function() Core.MigrateEncounters() end)
        Core.Emit(Core.EVENTS.SESSION_READY)
        print("|cff00D1FFMidnight Sensei|r v" .. Core.VERSION ..
              " loaded.  Type |cffFFD700/ms|r for commands.")
        -- Level check — delayed so UnitLevel is accurate after world load
        C_Timer.After(2.0, function()
            local level = UnitLevel("player") or 0
            if level > 0 and level < 80 then
                print("|cffFFAA00Midnight Sensei:|r This addon is designed for level 80+ content." ..
                      " Fight tracking and grading are |cffFF4444disabled|r until you reach level 80.")
            end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        DetectSpec()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        DetectSpec()
        Core.ScheduleSnapshots()

    elseif event == "SPELLS_CHANGED" then
        Core.ScheduleSnapshots()

    elseif event == "PLAYER_REGEN_DISABLED" then
        Core.InCombat    = true
        Core.CombatStart = GetTime()
        -- Snapshot full instance context at fight start
        -- (GetInstanceInfo is valid now; may change mid-fight for open-world)
        local instName, instType, diffID, diffName,
              maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()
        Core.CombatInstanceContext = {
            instanceName = instName  or "",
            instanceType = instType  or "none",
            difficultyID = diffID    or 0,
            difficultyName = diffName or "",
        }
        Core.Emit(Core.EVENTS.COMBAT_START)

    elseif event == "PLAYER_REGEN_ENABLED" then
        Core.InCombat  = false
        Core.CombatEnd = GetTime()
        Core.Emit(Core.EVENTS.COMBAT_END, Core.CombatEnd - Core.CombatStart)

    elseif event == "ENCOUNTER_START" then
        local encID, encName, diffID = ...
        Core.CurrentEncounter = { isBoss = true, name = encName, id = encID, difficultyID = diffID }
        Core.Emit(Core.EVENTS.BOSS_START, encID, encName, diffID)

    elseif event == "ENCOUNTER_END" then
        local encID, encName, diffID, numGroups, success = ...
        Core.CurrentEncounter = { isBoss = false, name = nil, id = nil, difficultyID = nil }
        Core.Emit(Core.EVENTS.BOSS_END, encID, encName, diffID, success)

    elseif event == "UNIT_AURA" then
        local unit = ...
        if MS.CombatLog and MS.CombatLog.ProcessUnitAura then
            MS.CombatLog.ProcessUnitAura(unit)
        end
        -- Verify mode: check all spec aura IDs when player auras change
        if Core.VerifyMode and unit == "player" and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local spec = Core.ActiveSpec
            if spec then
                Core.VerifySeenAuras = Core.VerifySeenAuras or {}
                for _, a in ipairs(spec.procBuffs   or {}) do
                    if C_UnitAuras.GetPlayerAuraBySpellID(a.id) then
                        Core.VerifySeenAuras[a.id] = true
                    end
                end
                for _, a in ipairs(spec.uptimeBuffs or {}) do
                    if C_UnitAuras.GetPlayerAuraBySpellID(a.id) then
                        Core.VerifySeenAuras[a.id] = true
                    end
                end
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID then
            Core.Emit(Core.EVENTS.ABILITY_USED, spellID, GetTime())
            if Core.VerifyMode then
                Core.VerifySeenSpells = Core.VerifySeenSpells or {}
                Core.VerifySeenSpells[spellID] = (Core.VerifySeenSpells[spellID] or 0) + 1
            end
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        -- Channeled spells (e.g. Collapsing Star) fire CHANNEL_START, not SUCCEEDED.
        -- Emit ABILITY_USED so they register in cdTracking and rotationalTracking.
        local unit, _, spellID = ...
        if unit == "player" and spellID then
            Core.Emit(Core.EVENTS.ABILITY_USED, spellID, GetTime())
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        BroadcastVersion()

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, payload, _, sender = ...
        if prefix ~= VER_PREFIX then return end
        local sname = (sender:match("^([^%-]+)") or sender)
        if sname == UnitName("player") then return end

        local theirVer = payload:match("^VERSION|(.+)$")
        if theirVer then
            -- Store version for /ms versions report
            Core.seenVersions = Core.seenVersions or {}
            Core.seenVersions[sname] = theirVer
            -- Notify once per session if someone has a newer version
            if IsNewer(theirVer, Core.VERSION) and not notifiedThisSession then
                notifiedThisSession = true
                print("|cff00D1FFMidnight Sensei:|r A new version is available. Check Github for latest update.")
                Call(MS.UI, "ShowUpdateToast", sname, theirVer)
            end
        elseif payload == "VPING" then
            -- Legacy: ignore pings from older clients that used active pinging
            return
        end
    end
end)

-- These events are safe to register at file scope
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("SPELLS_CHANGED")

-- UNIT_AURA is dispatched to CombatLog for buff/debuff uptime tracking

C_ChatInfo.RegisterAddonMessagePrefix(VER_PREFIX)

--------------------------------------------------------------------------------
-- Spell & Talent Snapshot System
-- Captures the player's full spellbook and active talent tree on login and
-- whenever spells/talents change. Stored in CharDB so the export window can
-- read from persistent data rather than requiring a live API call.
--
-- spellSnapshot:  { timestamp, specName, className, spells[]  }
-- talentSnapshot: { timestamp, specName, className, talents[] }
--
-- Both are contributor/pilot tooling — not surfaced to end users.
--------------------------------------------------------------------------------
local snapshotPending = false  -- debounce rapid SPELLS_CHANGED / TALENT_UPDATE floods

local function BuildSpellSnapshot()
    if not MidnightSenseiCharDB then return end
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return end

    local spec    = Core.ActiveSpec
    local spells  = {}
    local seen    = {}

    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, numLines do
        local okL, skillLine = pcall(C_SpellBook.GetSpellBookSkillLineInfo, i)
        if okL and skillLine then
            local offset   = skillLine.itemIndexOffset  or 0
            local numItems = skillLine.numSpellBookItems or 0
            for j = offset + 1, offset + numItems do
                local okI, info = pcall(C_SpellBook.GetSpellBookItemInfo, j,
                                        Enum.SpellBookSpellBank.Player)
                if okI and info and info.itemType == Enum.SpellBookItemType.Spell then
                    local spellID = info.actionID or info.spellID
                    if spellID and spellID > 0 and not seen[spellID] then
                        seen[spellID] = true
                        local name, subName = "", ""
                        if C_SpellBook.GetSpellBookItemName then
                            local okN, n, s = pcall(C_SpellBook.GetSpellBookItemName,
                                                    j, Enum.SpellBookSpellBank.Player)
                            if okN then name = n or "" ; subName = s or "" end
                        end
                        table.insert(spells, { spellID = spellID, name = name, subName = subName })
                    end
                end
            end
        end
    end

    table.sort(spells, function(a, b) return a.spellID < b.spellID end)

    MidnightSenseiCharDB.spellSnapshot = {
        timestamp = time(),
        specName  = spec and spec.name      or "?",
        className = spec and spec.className or "?",
        spells    = spells,
    }
end

local function BuildTalentSnapshot()
    if not MidnightSenseiCharDB then return end
    if not (C_Traits and C_Traits.GetNodeInfo and
            C_ClassTalents and C_ClassTalents.GetActiveConfigID) then return end

    local spec    = Core.ActiveSpec
    local talents = {}

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end
    local okC, config = pcall(C_Traits.GetConfigInfo, configID)
    if not okC or not config or not config.treeIDs then return end

    for _, treeID in ipairs(config.treeIDs) do
        local okN, nodes = pcall(C_Traits.GetTreeNodes, treeID)
        if okN and nodes then
            for _, nodeID in ipairs(nodes) do
                local okI, node = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                if okI and node then
                    local activeRank = node.activeRank or 0
                    local maxRank    = node.maxRanks   or 1

                    -- Walk all entries on this node (choice nodes have multiple)
                    local entries = node.entries or {}
                    if #entries == 0 and node.activeEntry then
                        entries = { node.activeEntry }
                    end

                    for _, entry in ipairs(entries) do
                        if entry and entry.entryID then
                            local okD, def = pcall(C_Traits.GetEntryInfo, configID, entry.entryID)
                            if okD and def and def.definitionID then
                                local okF, defInfo = pcall(C_Traits.GetDefinitionInfo, def.definitionID)
                                if okF and defInfo and defInfo.spellID then
                                    local name = "unknown"
                                    if C_Spell and C_Spell.GetSpellName then
                                        local okSN, n = pcall(C_Spell.GetSpellName, defInfo.spellID)
                                        if okSN and n then name = n end
                                    end
                                    -- status: ACTIVE (taken), INACTIVE (not taken)
                                    -- rank shown as activeRank/maxRank for multi-rank nodes
                                    local status = activeRank > 0 and "ACTIVE" or "INACTIVE"
                                    -- Passive detection — IsSpellPassive or C_Spell.IsSpellPassive
                                    local isPassive = false
                                    if C_Spell and C_Spell.IsSpellPassive then
                                        local okP, p = pcall(C_Spell.IsSpellPassive, defInfo.spellID)
                                        if okP then isPassive = p end
                                    elseif IsPassiveSpell then
                                        local okP, p = pcall(IsPassiveSpell, defInfo.spellID)
                                        if okP then isPassive = p end
                                    end
                                    table.insert(talents, {
                                        spellID   = defInfo.spellID,
                                        nodeID    = nodeID,
                                        entryID   = entry.entryID,
                                        name      = name,
                                        rank      = activeRank,
                                        maxRank   = maxRank,
                                        status    = status,
                                        isPassive = isPassive,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(talents, function(a, b) return a.nodeID < b.nodeID end)

    MidnightSenseiCharDB.talentSnapshot = {
        timestamp = time(),
        specName  = spec and spec.name      or "?",
        className = spec and spec.className or "?",
        talents   = talents,
    }
end

-- Debounced builder — SPELLS_CHANGED and PLAYER_TALENT_UPDATE can fire
-- rapidly in bursts; wait 1s after the last event before writing.
local function ScheduleSnapshots()
    if snapshotPending then return end
    snapshotPending = true
    C_Timer.After(1.0, function()
        snapshotPending = false
        BuildSpellSnapshot()
        BuildTalentSnapshot()
    end)
end

-- Hook into existing event handler
Core.On(Core.EVENTS.SESSION_READY, function()
    -- Delay to ensure SPELLS_CHANGED has fired and spellbook is fully loaded
    C_Timer.After(2.0, function()
        BuildSpellSnapshot()
        BuildTalentSnapshot()
    end)
end)
Core.On(Core.EVENTS.SPEC_CHANGED, function()
    ScheduleSnapshots()
end)

-- Expose for event frame
Core.ScheduleSnapshots = ScheduleSnapshots

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------
SLASH_MIDNIGHTSENSEI1 = "/ms"
SLASH_MIDNIGHTSENSEI2 = "/midnightsensei"

local function MSSlashHandler(msg)
    msg = (msg or ""):lower():trim()
    if msg == "" then
        print("|cff00D1FFMidnight Sensei:|r Type |cffFFFFFF/ms show|r to open the HUD  ·  |cffFFFFFF/ms hide|r to close it  ·  |cffFFFFFF/ms help|r for all commands.")
    elseif msg == "show" then
        Call(MS.UI, "ShowMainFrame")
    elseif msg == "hide" then
        Call(MS.UI, "HideMainFrame")
    elseif msg == "options" or msg == "config" then Call(MS.UI, "OpenOptions")
    elseif msg == "help"    or msg == "?"      then
        print("|cff00D1FFMidnight Sensei Commands:|r")
        print("  /ms show          Show the HUD")
        print("  /ms hide          Hide the HUD")
        print("  /ms history       Grade history & trends")
        print("  /ms lb            Social leaderboard")
        print("  /ms bossboard     Personal boss best leaderboard  (alias: /ms bb)")
        print("  /ms options       Settings panel")
        print("  /ms faq           Help & FAQ panel")
        print("  /ms credits       Credits & about")
        print("  /ms report        Report a bug on GitHub")
        print("  /ms reset         Clear fight history")
        print("  /ms update        Show changelog")
        print("  /ms versions      Show addon versions passively collected this session")
        print("  /ms debug         Current spec / class IDs")
        print("  /ms debug guild         Diagnose guild score routing")
        print("  /ms debug guild inject  Send a test score to guild (pipeline test)")
        print("  /ms debug guild broadcast  Re-broadcast all your best scores")
        print("  /ms debug self    Diagnose your delve encounter history")
        print("  /ms debug zone    Show current instance/zone context and diffID")
        print("  /ms friend <Name> Query a player's last score directly (addon whisper)")
        print("  /ms verify report Print verify findings for current spec")
    elseif msg == "faq"                        then Call(MS.UI, "ShowFAQ")
    elseif msg == "credits"                    then Call(MS.UI, "ShowCredits")
    elseif msg == "report"                     then Call(MS.UI, "ShowReportPopup")
    elseif msg == "history"                    then Call(MS.UI, "ShowHistory")
    elseif msg == "leaderboard" or msg == "lb" then Call(MS.Leaderboard, "Toggle")
    elseif msg == "lb debug" then
        local db = MidnightSenseiDB and MidnightSenseiDB.leaderboard
        local guild = db and db.guild
        if not guild or not next(guild) then
            print("|cff00D1FFMidnight Sensei:|r Guild DB is empty.")
        else
            print("|cff00D1FFMidnight Sensei — Guild DB keys:|r")
            for k, v in pairs(guild) do
                print(string.format("  |cffFFFFFF%s|r  name=%s  score=%s",
                      k, tostring(v.name), tostring(v.score)))
            end
        end
    elseif msg:sub(1, 11) == "friend add " then
        local target = msg:sub(12)
        Call(MS.Leaderboard, "AddFriend", target)
    elseif msg:sub(1, 14) == "friend remove " then
        local target = msg:sub(15)
        Call(MS.Leaderboard, "RemoveFriend", target)
    elseif msg:sub(1, 7) == "friend " then
        local target = msg:sub(8)
        Call(MS.Leaderboard, "QueryFriend", target)
    elseif msg == "friend" then
        print("|cff00D1FFMidnight Sensei:|r Usage: /ms friend Name  or  /ms friend add Name  or  /ms friend remove Name")
    elseif msg:sub(1, 10) == "lb remove " then
        local name = msg:sub(11)
        if name and name ~= "" then
            Call(MS.Leaderboard, "RemoveGuildEntry", name)
        else
            print("|cff00D1FFMidnight Sensei:|r Usage: /ms lb remove <PlayerName>")
        end
    elseif msg == "update" then
        Call(MS.UI, "ShowChangelog")
    elseif msg == "versions" then
        Core.seenVersions = Core.seenVersions or {}
        local count = 0
        for _ in pairs(Core.seenVersions) do count = count + 1 end
        if count == 0 then
            print("|cff00D1FFMidnight Sensei:|r No version data yet — versions are collected automatically when players log in or join your group.")
            return
        end
        print("|cff00D1FFMidnight Sensei — Versions seen this session:|r")
        print("  |cffFFFFFF" .. (UnitName("player") or "You") .. "|r  v" .. Core.VERSION .. "  |cff00FF00(you)|r")
        local byVersion = {}
        for name, ver in pairs(Core.seenVersions) do
            byVersion[ver] = byVersion[ver] or {}
            table.insert(byVersion[ver], name)
        end
        for ver, names in pairs(byVersion) do
            table.sort(names)
            local color = (ver == Core.VERSION) and "|cff00FF00" or "|cffFF8800"
            local flag  = (ver == Core.VERSION) and "" or "  |cffFF8800(outdated)|r"
            print("  " .. color .. "v" .. ver .. "|r — " .. table.concat(names, ", ") .. flag)
        end
    elseif msg == "debuglog" then
        local buf = MidnightSenseiDB and MidnightSenseiDB.debugLog
        if not buf or #buf == 0 then
            print("|cff00D1FFMidnight Sensei:|r Debug log is empty. Enable Debug Mode in /ms options then fight.")
        else
            print("|cff00D1FFMidnight Sensei Debug Log (" .. #buf .. " entries):|r")
            for _, line in ipairs(buf) do print("  " .. line) end
        end
    elseif msg == "debuglog clear" then
        if MidnightSenseiDB then MidnightSenseiDB.debugLog = {} end
        print("|cff00D1FFMidnight Sensei:|r Debug log cleared.")
    elseif msg == "debug rotational" then
        print("|cff00D1FFMidnight Sensei - Rotational Spell Debug:|r")
        local spec = Core.ActiveSpec
        if spec and spec.rotationalSpells then
            print("  Spec rotationalSpells defined: " .. #spec.rotationalSpells)
            for _, rs in ipairs(spec.rotationalSpells) do
                print("  id=" .. rs.id .. " label=" .. rs.label ..
                      " minFight=" .. (rs.minFightSeconds or 60) .. "s" ..
                      (rs.suppressIfTalent and " suppressIfTalent=" .. rs.suppressIfTalent or "") ..
                      (rs.talentGated and " talentGated=true" or ""))
            end
        else
            print("  No rotationalSpells defined for current spec.")
        end
        if spec and spec.majorCooldowns then
            print("  Spec majorCooldowns defined: " .. #spec.majorCooldowns)
            for _, cd in ipairs(spec.majorCooldowns) do
                print("  id=" .. cd.id .. " label=" .. cd.label ..
                      (cd.minFightSeconds and " minFight=" .. cd.minFightSeconds .. "s" or "") ..
                      (cd.talentGated and " talentGated=true" or ""))
            end
        end
        -- Show last result if available
        local last = MS.Analytics and MS.Analytics.GetLastEncounter and MS.Analytics.GetLastEncounter()
        if last and last.feedback then
            print("  Last fight feedback (" .. #last.feedback .. " lines):")
            for i, fb in ipairs(last.feedback) do
                print("  " .. i .. ". " .. fb)
            end
        else
            print("  No fight result available yet.")
        end
    elseif msg == "verify" then
        Core.VerifyMode = not Core.VerifyMode
        Core.VerifySeenSpells  = Core.VerifySeenSpells  or {}
        Core.VerifySeenAuras   = Core.VerifySeenAuras   or {}
        if Core.VerifyMode then
            Core.VerifySeenSpells = {}
            Core.VerifySeenAuras  = {}
            print("|cff00D1FFMidnight Sensei Verify Mode: ON|r")
            print("|cff888888Cast your spells normally. After combat type /ms verify report.|r")
        else
            print("|cff00D1FFMidnight Sensei Verify Mode: OFF|r")
        end

    elseif msg == "verify report" then
        local spec = Core.ActiveSpec
        if not spec then
            print("|cff00D1FFMidnight Sensei:|r No spec loaded.")
        else
            local lines = {}
            local function L(s) table.insert(lines, s) end

            L("Midnight Sensei — Verify Report")
            L("Spec: " .. (spec.className or "?") .. " / " .. (spec.name or "?"))
            L("Version: " .. Core.VERSION)
            L(string.rep("-", 50))

            L("SPELL ID CHECK (majorCooldowns + rotationalSpells)")
            local allTracked = {}
            for _, cd in ipairs(spec.majorCooldowns or {}) do
                allTracked[cd.id] = { label = cd.label, bucket = "majorCooldowns" }
            end
            for _, rs in ipairs(spec.rotationalSpells or {}) do
                allTracked[rs.id] = { label = rs.label, bucket = "rotationalSpells" }
            end

            local seen = Core.VerifySeenSpells or {}
            for id, info in pairs(allTracked) do
                local fired = seen[id]
                if fired then
                    L(string.format("  PASS  %-30s id=%-8d fired=%dx  [%s]",
                      info.label, id, fired, info.bucket))
                else
                    L(string.format("  FAIL  %-30s id=%-8d NOT SEEN    [%s]",
                      info.label, id, info.bucket))
                end
            end

            L("")
            L("AURA CHECK (procBuffs + uptimeBuffs)")
            local allAuras = {}
            for _, a in ipairs(spec.procBuffs   or {}) do allAuras[a.id] = { label=a.label, bucket="procBuffs"   } end
            for _, a in ipairs(spec.uptimeBuffs or {}) do allAuras[a.id] = { label=a.label, bucket="uptimeBuffs" } end

            if not next(allAuras) then
                L("  (no auras defined for this spec)")
            else
                for id, info in pairs(allAuras) do
                    local active, seenVia = false, (Core.VerifySeenAuras or {})[id]
                    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
                        local ok, r = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
                        if ok and r then active = true end
                    end
                    if active then
                        L(string.format("  PASS  %-30s id=%-8d ACTIVE NOW       [%s]", info.label, id, info.bucket))
                    elseif seenVia then
                        L(string.format("  SEEN  %-30s id=%-8d seen not active   [%s]", info.label, id, info.bucket))
                    else
                        L(string.format("  FAIL  %-30s id=%-8d NOT DETECTED      [%s]", info.label, id, info.bucket))
                    end
                end
            end

            L("")
            local unknownCasts = {}
            for id, count in pairs(Core.VerifySeenSpells or {}) do
                if not allTracked[id] then table.insert(unknownCasts, {id=id, count=count}) end
            end
            if #unknownCasts > 0 then
                table.sort(unknownCasts, function(a,b) return a.count > b.count end)
                L("OTHER SPELLS CAST THIS SESSION (top 10 by count)")
                for i = 1, math.min(10, #unknownCasts) do
                    local e = unknownCasts[i]
                    local spellName = "unknown"
                    if C_Spell and C_Spell.GetSpellName then
                        local ok, n = pcall(C_Spell.GetSpellName, e.id)
                        if ok and n then spellName = n end
                    end
                    L(string.format("    id=%-8d  %-30s  x%d", e.id, spellName, e.count))
                end
            end

            L("")
            L("-- paste into a GitHub comment: https://github.com/MidnightTim/MidnightSensei/issues")

            local fullText = table.concat(lines, "\n")
            if MS.UI and MS.UI.ShowVerifyExport then
                MS.UI.ShowVerifyExport(fullText)
            else
                for _, line in ipairs(lines) do print(line) end
            end
        end

    elseif msg == "debug talents" then
        local snap = MidnightSenseiCharDB and MidnightSenseiCharDB.talentSnapshot
        local lines = {}
        local function L(s) table.insert(lines, s) end

        if not snap or not snap.talents or #snap.talents == 0 then
            print("|cff00D1FFMidnight Sensei:|r No talent snapshot yet — one is built automatically on login and spec change. If this is your first session, type |cffFFFFFF/reload|r and try again.")
            return
        end

        local active   = 0
        local inactive = 0
        local passive  = 0
        for _, t in ipairs(snap.talents) do
            if t.status == "ACTIVE" then active = active + 1
            else inactive = inactive + 1 end
            if t.isPassive then passive = passive + 1 end
        end

        L("Midnight Sensei — Full Talent Tree Snapshot")
        L("Spec:      " .. (snap.className or "?") .. " / " .. (snap.specName or "?"))
        L("Captured:  " .. date("%Y-%m-%d %H:%M:%S", snap.timestamp))
        L("Version:   " .. Core.VERSION)
        L(string.rep("-", 80))
        L(string.format("Total nodes: %d  |  ACTIVE: %d  |  INACTIVE: %d  |  PASSIVE: %d",
            #snap.talents, active, inactive, passive))
        L(string.format("%-10s %-10s %-8s %-35s %-6s %-8s %s",
            "spellID", "nodeID", "entryID", "name", "rank", "passive", "status"))
        L(string.rep("-", 80))
        for _, t in ipairs(snap.talents) do
            L(string.format("%-10d %-10d %-8d %-35s %-6s %-8s %s",
                t.spellID, t.nodeID, t.entryID or 0,
                t.name,
                (t.rank or 0) .. "/" .. (t.maxRank or 1),
                t.isPassive and "PASSIVE" or "",
                t.status))
        end
        L("")
        L("-- ACTIVE = talented, INACTIVE = available but not taken")
        L("-- PASSIVE = spell is passive, do not add to majorCooldowns or rotationalSpells")
        L("-- Cross-reference against spec DB with /ms verify report")

        if MS.UI and MS.UI.ShowVerifyExport then
            MS.UI.ShowVerifyExport(table.concat(lines, "\n"))
        else
            for _, line in ipairs(lines) do print(line) end
        end

    elseif msg == "debug spells" then
        local snap = MidnightSenseiCharDB and MidnightSenseiCharDB.spellSnapshot
        local lines = {}
        local function L(s) table.insert(lines, s) end

        if not snap or not snap.spells or #snap.spells == 0 then
            print("|cff00D1FFMidnight Sensei:|r No spell snapshot yet — one is built automatically on login. If this is your first session, type |cffFFFFFF/reload|r and try again.")
            return
        end

        L("Midnight Sensei — Spell Snapshot")
        L("Spec:      " .. (snap.className or "?") .. " / " .. (snap.specName or "?"))
        L("Captured:  " .. date("%Y-%m-%d %H:%M:%S", snap.timestamp))
        L("Version:   " .. Core.VERSION)
        L(string.rep("-", 60))
        L(string.format("Known spells: %d", #snap.spells))
        L(string.format("%-10s %-35s %s", "spellID", "name", "subName"))
        L(string.rep("-", 60))
        for _, s in ipairs(snap.spells) do
            L(string.format("%-10d %-35s %s", s.spellID, s.name, s.subName))
        end
        L("")
        L("-- Cross-reference against spec DB with /ms verify report")

        if MS.UI and MS.UI.ShowVerifyExport then
            MS.UI.ShowVerifyExport(table.concat(lines, "\n"))
        else
            for _, line in ipairs(lines) do print(line) end
        end

    elseif msg == "debug version" then
        print("|cff00D1FFMidnight Sensei Version Debug:|r")
        print("  Core.VERSION = " .. tostring(Core.VERSION))
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            local ok, v = pcall(C_AddOns.GetAddOnMetadata, "MidnightSensei", "Version")
            print("  C_AddOns.GetAddOnMetadata: ok=" .. tostring(ok) .. " v=" .. tostring(v))
        else
            print("  C_AddOns.GetAddOnMetadata: unavailable")
        end
        if GetAddOnMetadata then
            local ok, v = pcall(GetAddOnMetadata, "MidnightSensei", "Version")
            print("  GetAddOnMetadata: ok=" .. tostring(ok) .. " v=" .. tostring(v))
        else
            print("  GetAddOnMetadata: unavailable")
        end
    elseif msg == "clean payload" then
        -- ── PILOT RECOVERY TOOL — REMOVE BEFORE PUBLIC RELEASE ──────────────
        -- Rebuilds and re-broadcasts all local encounters in the current payload
        -- format so peers receive correct checksums and encType values.
        -- Also purges ghost guild entries (score=0, no category data).
        -- Run this once after updating to 1.3.0+ to fix cross-client data issues.
        print("|cff00D1FFMidnight Sensei - Payload Cleanup:|r Starting...")
        -- Reset rate limits so incoming re-broadcasts aren't silently dropped
        if MS.Leaderboard and MS.Leaderboard.ResetRateLimits then
            MS.Leaderboard.ResetRateLimits()
        end
        -- Whisper current spec (HELLO) to online guild members so stale
        -- class/spec data (e.g. showing wrong class) is corrected immediately
        if MS.Leaderboard and MS.Leaderboard.BroadcastHelloToGuild then
            MS.Leaderboard.BroadcastHelloToGuild()
        end

        local db = MidnightSenseiDB
        if not db then
            print("|cffFF4444Midnight Sensei:|r No saved data found.")
        else
            local fixed = 0

            -- 1. Purge ghost guild entries (populated by HELLO but no score ever received)
            local lbDB = db.leaderboard and db.leaderboard.guild
            if lbDB then
                local toRemove = {}
                for key, entry in pairs(lbDB) do
                    local hasData = (entry.score or 0) > 0
                                 or (entry.allTimeBest or 0) > 0
                                 or (entry.dungeonBest or 0) > 0
                                 or (entry.raidBest    or 0) > 0
                                 or (entry.delveBest   or 0) > 0
                    if not hasData then
                        table.insert(toRemove, key)
                    end
                end
                for _, key in ipairs(toRemove) do
                    lbDB[key] = nil
                    fixed = fixed + 1
                    print("|cff888888  Removed ghost guild entry: " .. key .. "|r")
                end
            end

            -- 2. Clear debug log so bad checksum entries don't persist
            local oldLogSize = db.debugLog and #db.debugLog or 0
            db.debugLog = {}
            if oldLogSize > 0 then
                print("|cff888888  Cleared " .. oldLogSize .. " debug log entries.|r")
            end

            -- 3. Re-broadcast best encounter per encType in current payload format.
            -- This overwrites peers' stale/bad data with correctly formatted messages.
            local encounters = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
            if encounters and #encounters > 0 then
                local best = {}  -- [encType] = highest scoring eligible encounter
                for _, enc in ipairs(encounters) do
                    if enc.finalScore then
                        local t = enc.encType or "normal"
                        -- Delves are eligible without isBoss; all others require isBoss=true
                        local eligible = (t == "delve") or enc.isBoss
                        if eligible then
                            if not best[t] or enc.finalScore > best[t].finalScore then
                                best[t] = enc
                            end
                        end
                    end
                end
                local delay = 0
                for encType, enc in pairs(best) do
                    delay = delay + 0.6
                    C_Timer.After(delay, function()
                        Call(MS.Leaderboard, "BroadcastEncounterToGuild", enc)
                        print("|cff00D1FFMidnight Sensei:|r  Broadcast " .. encType ..
                              " (" .. enc.finalScore .. ") — " ..
                              (enc.diffLabel or "") .. " " ..
                              (enc.instanceName or ""))
                    end)
                    fixed = fixed + 1
                end
                if delay == 0 then
                    print("|cff888888  No boss encounters found to broadcast.|r")
                end
            else
                print("|cff888888  No encounter history found.|r")
            end

            if fixed > 0 then
                print("|cff00D1FFMidnight Sensei:|r Cleanup done — " ..
                      fixed .. " action(s). Peers will receive updated scores shortly.")
            else
                print("|cff00D1FFMidnight Sensei:|r Nothing to clean.")
            end

            if MS.Leaderboard and MS.Leaderboard.RefreshUI then
                MS.Leaderboard.RefreshUI()
            end
        end
        -- ── END PILOT RECOVERY TOOL ──────────────────────────────────────────

    elseif msg == "debug guild inject" then
        -- Send a synthetic SCORE message to the guild channel.
        -- Uses a real checksum so it passes validation on the receiver.
        -- This tests the full receive → MergeEntry → display pipeline.
        if not IsInGuild() then
            print("|cffFF4444Midnight Sensei:|r Not in a guild.")
        else
            local spec = Core.ActiveSpec
            local className = spec and spec.className or "Mage"
            local specName  = spec and spec.name      or "Frost"
            local role      = spec and spec.role      or "DPS"
            local score     = 77
            local duration  = 120
            local encType   = "dungeon"
            local charName  = UnitName("player") or "?"
            -- Compute real checksum so receiver accepts it
            local a = (score * 7) % 251
            local b = (math.floor(duration) * 11) % 251
            local c = (#encType * 17) % 251
            local cs = string.format("%03d", (a + b + c) % 251)
            local payload = table.concat({
                "SCORE", Core.VERSION,
                className, specName, role,
                "B",                          -- grade
                tostring(score),
                tostring(duration),
                "1",                          -- isBoss
                "TEST_BOSS",                  -- bossName
                encType,
                cs,
                "TEST_Difficulty",            -- diffLabel
                "0",                          -- keystoneLevel
                charName,
                "TEST_Dungeon",               -- instanceName
            }, "|")
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                local ok, err = pcall(C_ChatInfo.SendAddonMessage, "MS_LB", payload, "GUILD")
                if ok then
                    print("|cff00D1FFMidnight Sensei:|r Injected test dungeon score (" ..
                          score .. ") to GUILD. Check Polkatron's leaderboard.")
                else
                    print("|cffFF4444Midnight Sensei:|r Send failed: " .. tostring(err))
                end
            end
        end

    elseif msg == "debug guild ping" then
        -- Send a PING to GUILD channel and check if we receive it back
        print("|cff00D1FFMidnight Sensei:|r Sending PING to GUILD channel...")
        local myGuild = GetGuildInfo("player")
        print("  Your guild: " .. tostring(myGuild))
        if not IsInGuild() then
            print("  |cffFF4444Not in a guild — GUILD channel unavailable.|r")
        else
            local ok, err = pcall(C_ChatInfo.SendAddonMessage, "MS_LB",
                                  "PING|" .. Core.VERSION, "GUILD")
            if ok then
                print("  Send succeeded. Ask a guildie to run /ms debug guild receive")
                print("  to confirm they receive it. You will NOT see your own message.")
            else
                print("  |cffFF4444Send FAILED: " .. tostring(err) .. "|r")
                print("  This means the GUILD channel is blocked or unavailable.")
            end
        end

    elseif msg == "debug guild receive" then
        print("|cff00D1FFMidnight Sensei - Last Received SCOREs:|r")
        local myGuild = GetGuildInfo("player")
        print("  Your guild: " .. tostring(myGuild))
        -- Check prefix registration
        local regOk = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered
                      and C_ChatInfo.IsAddonMessagePrefixRegistered("MS_LB")
        print("  Prefix MS_LB registered: " .. tostring(regOk))
        local log = MS.Leaderboard and MS.Leaderboard.GetReceivedScoreLog
                    and MS.Leaderboard.GetReceivedScoreLog()
        if not log or #log == 0 then
            print("  No SCORE messages received yet this session.")
            print("  If prefix=true above, ask sender to /ms debug guild broadcast")
            print("  If prefix=false, the addon message system is not receiving — try /reload")
        else
            for i, entry in ipairs(log) do
                print(string.format("  [%d] from=%-12s ch=%-8s score=%-4s encType=%-8s isBoss=%s",
                      i, entry.sender, entry.channel, entry.score,
                      entry.encType, tostring(entry.isBoss)))
                if entry.diffLabel ~= "" or entry.instanceName ~= "" then
                    print(string.format("       diff=%-15s inst=%s",
                          entry.diffLabel, entry.instanceName))
                end
            end
        end

    elseif msg == "debug guild" then
        print("|cff00D1FFMidnight Sensei - Guild Routing Debug:|r")
        print("  IsInGuild(): " .. tostring(IsInGuild()))
        print("  GetNumGuildMembers(): " .. tostring(GetNumGuildMembers()))
        local db = MidnightSenseiDB and MidnightSenseiDB.leaderboard
        local guild = db and db.guild
        if guild and next(guild) then
            print(string.format("  db.guild entries:"))
            for k, v in pairs(guild) do
                print(string.format("    key=%-20s score=%-4s dungeonBest=%-4s delveBest=%-4s online=%s",
                      k, tostring(v.score), tostring(v.dungeonBest),
                      tostring(v.delveBest), tostring(v.online)))
            end
        else
            print("  db.guild is EMPTY — no scores received from guildmates")
        end
        -- Test IsGuildMember for each online member
        local n = GetNumGuildMembers()
        if n > 0 then
            print("  Guild roster sample (first 5):")
            for i = 1, math.min(5, n) do
                local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
                print(string.format("    [%d] %-20s online=%s", i, tostring(name), tostring(online)))
            end
        else
            print("  Guild roster empty — GetNumGuildMembers() = 0")
            print("  This is the routing bug: GUILD channel messages may still arrive correctly")
        end
        -- Show last encounter for broadcast test
        local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter and MS.Analytics.GetLastEncounter()
        if lastEnc then
            print(string.format("  Last encounter: score=%s encType=%s isBoss=%s diffLabel=%s",
                  tostring(lastEnc.finalScore), tostring(lastEnc.encType),
                  tostring(lastEnc.isBoss), tostring(lastEnc.diffLabel)))
            print("  NOTE: Only isBoss=true encounters update weeklyAvg on the leaderboard")
            print("  Type /ms debug guild broadcast to re-broadcast ALL content type bests")
        else
            print("  No encounter in history — fight something first")
        end

    elseif msg == "debug guild broadcast" then
        local lastEnc = MS.Analytics and MS.Analytics.GetLastEncounter and MS.Analytics.GetLastEncounter()
        if not lastEnc then
            print("|cffFF4444Midnight Sensei:|r No encounter to broadcast.")
        else
            -- Broadcast the last encounter of each type so all category bests update
            local db = MidnightSenseiDB
            local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
            local best = {}  -- [encType] = highest score encounter
            if history then
                for _, enc in ipairs(history) do
                    local t = enc.encType or "normal"
                    if not best[t] or (enc.finalScore or 0) > (best[t].finalScore or 0) then
                        best[t] = enc
                    end
                end
            end
            local count = 0
            for encType, enc in pairs(best) do
                if enc.finalScore then
                    C_Timer.After(count * 0.5, function()
                        Call(MS.Leaderboard, "BroadcastEncounterToGuild", enc)
                    end)
                    print("|cff00D1FFMidnight Sensei:|r Broadcasting " .. encType ..
                          " score (" .. enc.finalScore .. ") to guild.")
                    count = count + 1
                end
            end
            if count == 0 then
                print("|cffFF4444Midnight Sensei:|r No encounters to broadcast.")
            end
        end

    elseif msg == "debug self" then
        print("|cff00D1FFMidnight Sensei - Self Delve Debug:|r")
        print("  UnitName('player'): " .. tostring(UnitName("player")))
        local db = MidnightSenseiDB
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        if not history or #history == 0 then
            print("  No encounter history found in SavedVariables")
        else
            print("  Total encounters: " .. #history)
            local delveCount = 0
            local delveBoss  = 0
            for _, enc in ipairs(history) do
                if enc.encType == "delve" then
                    delveCount = delveCount + 1
                    if enc.isBoss then delveBoss = delveBoss + 1 end
                end
            end
            print("  Delve encounters: " .. delveCount .. " (boss: " .. delveBoss .. ")")
            if delveBoss == 0 then
                print("  |cffFF4444No delve BOSS encounters — Delve tab requires isBoss=true|r")
                print("  The encounter must be triggered by ENCOUNTER_START/END inside a delve")
            end
            -- Show last delve encounter
            for i = #history, 1, -1 do
                local enc = history[i]
                if enc.encType == "delve" then
                    print(string.format("  Last delve enc: isBoss=%s score=%s charName=%s encType=%s",
                          tostring(enc.isBoss), tostring(enc.finalScore),
                          tostring(enc.charName), tostring(enc.encType)))
                    print("  diffLabel: " .. tostring(enc.diffLabel))
                    print("  instanceName: " .. tostring(enc.instanceName))
                    break
                end
            end
        end

    elseif msg == "debug zone" then
        local instName, instType, diffID, diffName,
              maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()
        print("|cff00D1FFMidnight Sensei - Instance Debug:|r")
        print("  instName: " .. tostring(instName))
        print("  instType: " .. tostring(instType))
        print("  diffID:   " .. tostring(diffID))
        print("  diffName: " .. tostring(diffName))
        print("  mapID:    " .. tostring(instMapID))
        -- Check if our DELVE_DIFF_IDS table covers this diffID
        local ctx = MS.Leaderboard and MS.Leaderboard.GetInstanceContext
                    and MS.Leaderboard.GetInstanceContext()
        if ctx then
            print("  encType:   " .. tostring(ctx.encType))
            print("  diffLabel: " .. tostring(ctx.diffLabel))
            print("  instLabel: " .. tostring(ctx.instanceName))
        end
        if instType == "raid" then
            print("  |cff00D1FFRAID detected|r — if diffLabel shows numeric diffID,")
            print("  add [" .. tostring(diffID) .. "] = \"" .. tostring(diffName) .. "\" to RAID_DIFF table")
        end
        print("  Note: C_Delves is nil in Midnight 12.0 — tier level not available via API.")
        -- Also print the last saved encounter for comparison
        local db = MidnightSenseiDB
        local last = db and db.encounters and db.encounters[#db.encounters]
        if last then
            print("  Last enc encType:   " .. tostring(last.encType))
            print("  Last enc diffLabel: " .. tostring(last.diffLabel))
            print("  Last enc isBoss:    " .. tostring(last.isBoss))
        end
        if Core.ActiveSpec then
            print("|cff00D1FFMidnight Sensei Debug:|r")
            print("  Class:   " .. (Core.ActiveSpec.className or "?"))
            print("  Spec:    " .. (Core.ActiveSpec.name      or "?"))
            print("  Role:    " .. (Core.ActiveSpec.role      or "?"))
            print("  ClassID: " .. tostring(Core.ActiveSpec.classID))
            print("  SpecIdx: " .. tostring(Core.ActiveSpec.specIdx))
        else
            print("|cff00D1FFMidnight Sensei:|r No spec loaded for current specialization.")
        end
    elseif msg == "debug friends" then
        print("|cff00D1FFMidnight Sensei - Friend Detection Debug:|r")
        local ok, num = pcall(BNGetNumFriends)
        print("  BNGetNumFriends: ok=" .. tostring(ok) .. " n=" .. tostring(num))
        if ok and type(num) == "number" and num > 0 then
            for i = 1, math.min(5, num) do
                local okN, n = pcall(BNGetFriendNumGameAccounts, i)
                print("  Friend[" .. i .. "] numAccounts=" .. tostring(n) ..
                      " (ok=" .. tostring(okN) .. ")")
                if okN and type(n) == "number" and n > 0 then
                    for j = 1, n do
                        local ok2, _, _, _, _, _, _, _, _, _, _,
                              realmName, _, _, isOnline, charName =
                            pcall(BNGetFriendGameAccountInfo, i, j)
                        print("    [" .. j .. "] charName=" .. tostring(charName) ..
                              " realm=" .. tostring(realmName) ..
                              " online=" .. tostring(isOnline))
                    end
                end
            end
        end
        print("  friendsData entries:")
        local fd = MS.Leaderboard and MS.Leaderboard.GetFriendsData and MS.Leaderboard.GetFriendsData()
        if fd then
            local count = 0
            for k in pairs(fd) do count = count + 1 ; print("    " .. k) end
            if count == 0 then print("    (empty)") end
        end
    elseif msg == "debug backfill keys" then
        print("|cff00D1FFMidnight Sensei - Keystone Backfill:|r")

        -- Step 1: Probe available APIs and report what we find
        print("  Probing available APIs...")
        local hasMapTable      = C_ChallengeMode and C_ChallengeMode.GetMapTable ~= nil
        local hasMapUIInfo     = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo ~= nil
        local hasRecentRuns    = C_MythicPlus    and C_MythicPlus.GetRecentRunsForMap ~= nil
        local hasSeasonBest    = C_MythicPlus    and C_MythicPlus.GetSeasonBestAffixScoreInfoForMap ~= nil
        local hasRatingSummary = C_PlayerInfo    and C_PlayerInfo.GetPlayerMythicPlusRatingSummary ~= nil
        local hasActiveInfo    = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo ~= nil
        local hasBestForMap    = C_MythicPlus    and C_MythicPlus.GetSeasonBestForMap ~= nil
        print("  C_ChallengeMode.GetMapTable:                     " .. tostring(hasMapTable))
        print("  C_ChallengeMode.GetMapUIInfo:                    " .. tostring(hasMapUIInfo))
        print("  C_MythicPlus.GetRecentRunsForMap:                " .. tostring(hasRecentRuns))
        print("  C_MythicPlus.GetSeasonBestAffixScoreInfoForMap:  " .. tostring(hasSeasonBest))
        print("  C_MythicPlus.GetSeasonBestForMap:                " .. tostring(hasBestForMap))
        print("  C_PlayerInfo.GetPlayerMythicPlusRatingSummary:   " .. tostring(hasRatingSummary))
        print("  C_ChallengeMode.GetActiveKeystoneInfo:           " .. tostring(hasActiveInfo))

        -- Step 2: Try to enumerate maps and dump raw data from whatever works
        local nameToLevel = {}  -- instanceName (lower) → highest known key level

        -- Path A: GetMapTable + GetSeasonBestForMap
        if hasMapTable and hasBestForMap then
            print("  Trying Path A: GetMapTable + GetSeasonBestForMap...")
            local ok, maps = pcall(C_ChallengeMode.GetMapTable)
            if ok and maps then
                for _, mapID in ipairs(maps) do
                    local okN, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                    local okB, best = pcall(C_MythicPlus.GetSeasonBestForMap, mapID)
                    if okN and name and okB and best then
                        local level = (type(best) == "table") and (best.level or best.keystoneLevel or 0)
                                      or (type(best) == "number" and best or 0)
                        if level > 0 then
                            nameToLevel[name:lower()] = level
                            print("    " .. name .. " -> M+" .. level)
                        end
                    end
                end
            end
        end

        -- Path B: GetPlayerMythicPlusRatingSummary
        if hasRatingSummary and not next(nameToLevel) then
            print("  Trying Path B: GetPlayerMythicPlusRatingSummary...")
            local ok, summary = pcall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, "player")
            if ok and summary then
                print("  Summary type: " .. type(summary))
                if type(summary) == "table" then
                    for k, v in pairs(summary) do
                        print("    key=" .. tostring(k) .. " val=" .. tostring(v))
                    end
                    local runs = summary.runs or summary.mapScores or {}
                    for _, run in ipairs(runs) do
                        local mapID = run.mapChallengeModeID or run.mapID
                        local level = run.level or run.keystoneLevel or 0
                        if mapID and level > 0 then
                            local okN, name = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                            if okN and name then
                                nameToLevel[name:lower()] = math.max(nameToLevel[name:lower()] or 0, level)
                                print("    " .. name .. " -> M+" .. level)
                            end
                        end
                    end
                end
            else
                print("  Path B failed: " .. tostring(summary))
            end
        end

        -- Path C: GetMapTable + GetSeasonBestAffixScoreInfoForMap
        if hasMapTable and hasSeasonBest and not next(nameToLevel) then
            print("  Trying Path C: GetSeasonBestAffixScoreInfoForMap...")
            local ok, maps = pcall(C_ChallengeMode.GetMapTable)
            if ok and maps then
                for _, mapID in ipairs(maps) do
                    local okN, name   = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                    local okS, scores = pcall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, mapID)
                    if okN and name and okS and scores then
                        -- scores is a table of { score, level, ... } per affix combo
                        local best = 0
                        if type(scores) == "table" then
                            for _, s in ipairs(scores) do
                                best = math.max(best, s.level or 0)
                            end
                        end
                        if best > 0 then
                            nameToLevel[name:lower()] = best
                            print("    " .. name .. " -> M+" .. best)
                        end
                    end
                end
            end
        end

        -- Step 3: Report what we gathered
        local gathered = 0
        for _ in pairs(nameToLevel) do gathered = gathered + 1 end
        print("  Maps with level data: " .. gathered)

        if gathered == 0 then
            print("  |cffFF4444No M+ data could be retrieved from available APIs.|r")
            print("  This build may require a different API. Raw probe data above may help.")
            return
        end

        -- Step 4: Apply to history
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        if not history or #history == 0 then
            print("  No encounter history found.")
            return
        end
        local candidates, patched, unmatched = 0, 0, 0
        for i, enc in ipairs(history) do
            if enc.encType == "dungeon"
            and (enc.keystoneLevel == nil or enc.keystoneLevel == 0)
            and (enc.diffLabel == "Mythic" or enc.diffLabel == "") then
                candidates = candidates + 1
                local instKey = enc.instanceName and enc.instanceName:lower() or ""
                local level   = nameToLevel[instKey]
                if level then
                    enc.keystoneLevel = level
                    enc.diffLabel     = "M+" .. level .. " (inferred)"
                    patched = patched + 1
                    print(string.format("  |cff00FF00Patched|r  [%d] %s -> M+%d (inferred)",
                          i, enc.instanceName or "?", level))
                else
                    unmatched = unmatched + 1
                    print(string.format("  |cff888888No match|r [%d] %s — not in season best data",
                          i, enc.instanceName or "?"))
                end
            end
        end
        print("  Candidates: " .. candidates ..
              "  Patched: " .. patched ..
              "  Unmatched: " .. unmatched)
        if patched > 0 then
            print("  |cffFFD700Note:|r Levels inferred from season best — not the specific run.")
            print("  To revert: |cffFFFFFF/ms debug backfill keys clear|r")
            if MS.Leaderboard and MS.Leaderboard.RefreshUI then MS.Leaderboard.RefreshUI() end
            if MS.UI and MS.UI.RefreshHistory then MS.UI.RefreshHistory() end
        end

    elseif msg == "debug backfill keys clear" then
        -- Revert all encounters patched by the backfill — removes "(inferred)" labels
        -- and clears keystoneLevel so they revert to plain "Mythic".
        local history = MidnightSenseiCharDB and MidnightSenseiCharDB.encounters
        if not history then
            print("|cff00D1FFMidnight Sensei:|r No history found.")
            return
        end
        local cleared = 0
        for _, enc in ipairs(history) do
            if enc.diffLabel and enc.diffLabel:find("%(inferred%)") then
                enc.diffLabel     = "Mythic"
                enc.keystoneLevel = nil
                cleared = cleared + 1
            end
        end
        print("|cff00D1FFMidnight Sensei:|r Cleared " .. cleared .. " inferred keystone patches.")
        if MS.UI and MS.UI.RefreshHistory then MS.UI.RefreshHistory() end

    elseif msg == "bossboard" or msg == "bb" then
        if MS.BossBoard and MS.BossBoard.Toggle then
            MS.BossBoard.Toggle()
        else
            print("|cff00D1FFMidnight Sensei:|r Boss Board not loaded.")
        end

    elseif msg == "debug bossboard ingest" then
        if MS.BossBoard and MS.BossBoard.IngestFromHistory then
            MS.BossBoard.IngestFromHistory()
        else
            print("|cff00D1FFMidnight Sensei:|r Boss Board not loaded.")
        end

    elseif msg == "debug bossboard repair" then
        if MS.BossBoard and MS.BossBoard.RepairIdentity then
            MS.BossBoard.RepairIdentity()
        else
            print("|cff00D1FFMidnight Sensei:|r Boss Board not loaded.")
        end

    else
        print("|cff00D1FFMidnight Sensei:|r Unknown command. Type |cffFFFFFF/ms help|r for a list of commands.")
    end
end

SlashCmdList["MIDNIGHTSENSEI"] = MSSlashHandler
Core.SlashHandler = MSSlashHandler  -- exposed for debug window buttons

function Core.GetSpecInfoString()
    if not Core.ActiveSpec then return "No spec loaded" end
    return Core.ActiveSpec.className .. "  -  " .. Core.ActiveSpec.name
end
