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
    Core.VERSION = ver or "1.4.15"
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
        version = "1.4.15",
        tagline = "Patch Compatibility Update",
        date    = "April 2026",
        changes = {
            "Updated TOC interface version to 120005 for new patch compatibility",
        },
    },
    {
        version = "1.4.14",
        tagline = "Frost Mage & Vengeance DH Spell Coverage",
        date    = "April 2026",
        changes = {
            -- Frost Mage
            "Frost Mage: Mirror Image added as tracked cooldown",
            "Frost Mage: Supernova added to rotational spells",
            "Frost Mage: Frostbolt id=228597 counted as alternate cast alongside id=116",
            -- Vengeance Demon Hunter
            "Vengeance: Immolation Aura (258920) added to rotational spells",
            "Vengeance: Demon Spikes added to majorCooldowns — cast usage now scored alongside buff uptime",
            "Vengeance: Fracture added to rotational (three variant IDs 225919/263642/225921 consolidated)",
            "Vengeance: Infernal Strike (189110) added to rotational spells",
            "Vengeance: Felblade alt ID 213243 credited to existing Felblade (232893) entry",
        },
    },
    {
        version = "1.4.13",
        tagline = "Warlock Fel Ravager Interrupt, Evoker Time Skip Gate, CD altIds Infrastructure",
        date    = "April 2026",
        changes = {
            -- Demonology Warlock
            "Demonology: Grimoire: Fel Ravager now credited when Fel Ravager pet uses Spell Lock (id=132409)",
            -- Augmentation Evoker
            "Augmentation: Time Skip suppressed when Interwoven Threads (id=412713) is talented — passive replacement",
            -- Infrastructure
            "CastTracker: altIdMap now covers majorCooldowns entries in addition to rotationalSpells",
            "Verify report: majorCooldown alt IDs now excluded from OTHER SPELLS list",
        },
    },
    {
        version = "1.4.12",
        tagline = "Resto Shaman Fixes, Verify Alt-ID Support, Debug Aura Scanner",
        date    = "April 2026",
        changes = {
            -- Resto Shaman
            "Resto Shaman: Healing Rain (73920) now credited when Surging Totem hero talent fires alternate id=456366",
            "Resto Shaman: Wind Shear added as tracked interrupt (no penalty)",
            "Resto Shaman: Purify Spirit added as tracked utility (no penalty)",
            -- Verify system
            "Verify report: spells fired via alt ID now show PASS with '(via alt id=X)' note instead of FAIL",
            "Verify report: registered alt IDs excluded from OTHER SPELLS list",
            -- Feedback
            "Fixed: generic healer low-activity note referenced 'Atonement value' — Disc Priest language removed",
            -- Debug
            "/ms debug auras — new command; dumps all active player buff IDs for aura identification",
        },
    },
    {
        version = "1.4.11",
        tagline = "Kill/Wipe Tracking, History Cleanup, Kill-Only Bests",
        date    = "April 2026",
        changes = {
            -- Kill/Wipe tracking
            "Fight history now distinguishes boss kills [K] from wipes [W] — non-boss fights are always treated as kills",
            "Grade History stats (Avg/Best/Worst) now computed from kills only; wipe count shown when present in current filter",
            "Personal bests (all-time, content, weekly) and Boss Board now record kill scores only — wipes excluded",
            "Weekly avg used by leaderboard now counts boss kills only",
            -- Cleanup
            "One-time legacy cleanup auto-runs on first login: retroactively marks M+/Delve boss wipes in existing history (same boss within 20 min = earlier attempt flagged as wipe)",
            "Cleanup also rebuilds all bests and Boss Board from corrected kill-only data",
            "Manual: /ms debug cleanup history (dry run) and /ms debug cleanup history confirm (apply)",
        },
    },
    {
        version = "1.4.10",
        tagline = "healerConditional Scoring, Elemental Shaman Farseer Support, Mage Data Corrections",
        date    = "April 2026",
        changes = {
            -- Scoring / Engine
            "New healerConditional flag: fight-reactive healer CDs (Spirit Link, Lay on Hands, Tranquility, etc.) now award 90% credit when unused on a successful fight instead of 0%",
            "Engine: BOSS_END success flag now captured — boss wipes correctly score unused conditional CDs at 0%",
            -- Healer specs
            "healerConditional applied to all 7 healer specs: Resto Shaman, Disc/Holy Priest, Mistweaver, Holy Paladin, Preservation Evoker, Resto Druid",
            -- Elemental Shaman
            "Elemental Shaman: Earth Elemental (198103) added to majorCooldowns — live-verified fired=1x",
            "Elemental Shaman: Ancestral Swiftness (443454) added as Farseer talentGated CD — live-verified fired=1x",
            -- Resto Shaman
            "Resto Shaman: Healing Wave (77472) added to rotational — live-verified fired=6x; was missing entirely",
            "Resto Shaman: Healing Stream Totem (5394) added to rotational — live-verified fired=3x",
            "Resto Shaman: Surging Totem now correctly marked talentGated (Totem hero path)",
            -- Mage
            "Fire Mage: Fireball corrected id=116 → id=133 — live-verified id=133 fired=10x; id=116 is Arcane Blast",
            "Fire Mage: Scorch removed from rotational tracking — situational movement spell; tracking penalised correct play",
            "Frost Mage: id=228597 confirmed as passive auto-cast from Glacial Spike Icicle mechanic — not a player cast; do not track",
        },
    },
    {
        version = "1.4.9",
        tagline = "Spell List AND-Gate Fix, Shadow Priest Spells, Mage Utility, Leaderboard Delve Tab",
        date    = "April 2026",
        changes = {
            -- UI / Spell List
            "Spell List: talentGated entries now require BOTH IsTalentActive AND IsPlayerSpell — passive prereq nodes in hero talent paths no longer cause wrong-spec spells to appear",
            -- Shadow Priest
            "Shadow Priest: Mind Flay (15407), Shadow Word: Death (32379), Void Blast (450983), Void Volley (1242173) added to rotational — all four were missing",
            -- Mage
            "Mage: Counterspell (2139) added as isInterrupt on all 3 specs — tracked but never penalised",
            "Mage: Spellsteal (30449) added as isUtility on all 3 specs — tracked but never penalised",
            "Mage: Arcane Intellect (1459) added as infoOnly uptimeBuff on all 3 specs — uptime noted if missing, never scored",
            -- Infrastructure
            "isUtility flag added: utility abilities tracked but never penalised; shown in Spell List under Interrupt & Utility",
            "infoOnly flag added to uptimeBuffs: uptime tracked for detection but excluded from score",
            "AuraTracker: initial scan at COMBAT_START ensures pre-pull buffs accumulate uptime from fight start",
            -- Leaderboard
            "Leaderboard Delve tab: Lua scoping bug fixed (activeTab was nil inside GetDelveData); three explicit guild/party/friends branches added",
        },
    },
    {
        version = "1.4.8",
        tagline = "Feral Druid suppressIfTalent Fix + Full Cross-Spec Audit",
        date    = "April 2026",
        changes = {
            -- Feral Druid
            "Feral Druid: Feral Frenzy (274837) — suppressIfTalent = 1243807 (Frantic Frenzy) added; hero talent replacement pair now correctly shows only one at a time",
            "Frantic Frenzy / Feral Frenzy: IsTalentActive returns true on both due to shared prereq node — suppressIfTalent resolves the double-tracking",
            -- Audit
            "Full suppressIfTalent audit across all 13 classes and 39 specs — no additional gaps found",
        },
    },
    {
        version = "1.4.7",
        tagline = "Combat Module Refactor + Full Midnight 12.0 Spec Audit",
        date    = "April 2026",
        changes = {
            -- Structural
            "Combat tracking split into Combat/ module group: CombatLog, CastTracker, AuraTracker, ProcTracker, ResourceTracker, HealingTracker",
            "All 13 class spec definitions extracted from Core.lua into individual Specs/*.lua files",
            "AuraTracker and ProcTracker now correctly implemented — aura uptime and proc tracking silently returned fallbacks in all prior releases",
            -- Demon Hunter / Devourer (live-verified)
            "Devourer: Consume corrected 344859 → 473662; Reap corrected 344862 → 1226019 — snapshot IDs were damage event IDs not cast IDs",
            "Devourer: Void Metamorphosis corrected 191427 → 1217605; marked displayOnly (shapeshift fires UPDATE_SHAPESHIFT_FORM)",
            "Devourer: Devour (1217610) and Cull (1245453) added — both live-verified; were missing entirely",
            "Devourer: Impending Apocalypse, Demonsurge, Midnight, Eradicate removed — confirmed PASSIVE",
            -- Death Knight
            "Blood DK: rotationalSpells was empty — Marrowrend, Heart Strike, Blood Boil, Death Strike all added",
            "Unholy DK: Dark Transformation corrected 63560 → 1233448; Festering Strike corrected 85092 → 316239",
            -- Other specs
            "Paladin: Templar's Verdict 85256 → Final Verdict 383328 (Midnight 12.0 rename)",
            "Evoker: Tip the Scales corrected 374348 → 370553; Zenith and Time Skip added to Augmentation CDs",
            "Full PASSIVE audit: passive talents removed from tracked sets across all 13 classes",
        },
    },
    {
        version = "1.4.6",
        tagline = "Verify Report SKIP Status, Weekly Reset Fix, Leaderboard Stability",
        date    = "April 2026",
        changes = {
            -- Verify report
            "/ms verify report: added SKIP status for untalented/suppressed spells — was incorrectly showing FAIL for spells not in your current build",
            "SKIP: talentGated spells with IsPlayerSpell=false; suppressIfTalent spells when suppressing talent is active",
            -- Leaderboard weekly reset
            "Self-entry WK AVG: (prev) label now appears correctly after weekly reset — was not matching guild/friend entry behavior",
            "Root cause: GetWeekKey() timezone edge case caused post-reset fights to appear as current-week, blocking (prev) flag",
            "Fix: replaced GetWeekKey() for self-entry week detection with GetWeekStartEpoch() (epoch-based, no timezone assumptions)",
            -- Leaderboard messaging
            "Offline spam fix: queued login whispers now re-check roster before sending — 'Player not found' messages eliminated",
            "HELLO whisper loop fix: each sender receives at most one HELLO reply per session via helloWhisperReplied table",
            -- Debug
            "/ms debug guild: added self-entry weekly avg diagnostic output for week-key and (prev) diagnosis",
        },
    },
    {
        version = "1.4.5",
        tagline = "Balance Druid Hero Talent Fixes, Shapeshift Audit, Analytics Gate Fixes",
        date    = "April 2026",
        changes = {
            -- Balance Druid
            "Balance Druid: Incarnation: Chosen of Elune removed from majorCooldowns — shapeshift fires UPDATE_SHAPESHIFT_FORM, not UNIT_SPELLCAST_SUCCEEDED",
            "Balance Druid: Celestial Alignment false 'never pressed' fixed — suppressIfTalent = 102560 (Incarnation) added; talentGated CDs now use IsPlayerSpell only",
            "Balance Druid: Wrath false 'never used' fixed — suppressIfTalent = 429523 (Lunar Calling) added",
            "Balance Druid: Starfire (194153) added as talentGated rotational — primary filler for Elune's Chosen was missing entirely",
            "Balance Druid: Starsurge false 'never used' fixed — suppressIfTalent = 1271206 (Star Cascade) added; auto-fires passively",
            -- Shapeshift audit
            "Full 39-spec shapeshift audit completed using v1.4.3 description snapshots",
            "Incarnation: Guardian of Ursoc (102558) removed from Guardian majorCooldowns — confirmed shapeshift",
            -- Analytics gates
            "IsTalentActive: IsPlayerSpell fast path added; C_Traits walk now iterates node.entryIDs instead of node.activeEntry only",
            "Empty cdTracking else branch: now applies suppressIfTalent and talentGated checks instead of reporting all spec CDs as 'never pressed'",
            -- CLEU
            "COMBAT_LOG_EVENT_UNFILTERED confirmed fully protected in Midnight 12.0 — ADDON_ACTION_FORBIDDEN on all registration attempts; reverted",
        },
    },
    {
        version = "1.4.4",
        tagline = "Full Spec DB Audit — All 39 Specs Verified Against v1.4.3 Talent Snapshots",
        date    = "April 2026",
        changes = {
            -- Demon Hunter
            "Havoc: Chaos Strike (344862/162794/188499) removed — IDs not in Havoc talent tree; Blade Dance (188499) retained as baseline; Chaos Nova (179057) and Sigil of Misery (207684/isInterrupt) added",
            "Vengeance: Metamorphosis (191427), Soul Cleave (228477/344862), Fracture (344859) removed — wrong IDs or shapeshifting; Sigil of Silence/Misery added as isInterrupt; Chaos Nova and Sigil of Spite added as CDs",
            "Devourer: Reap (344862) removed — confirmed not in Devourer talent tree; The Hunt (1246167) added as talentGated CD",
            -- Warrior
            "Arms: Shockwave (46968) added as talentGated CD — confirmed non-PASSIVE",
            "Fury: Shockwave (46968), Champion's Spear (376079) added as talentGated CDs; Rend (772) added as talentGated rotational",
            "Protection: Rend (772) added as talentGated rotational",
            -- Rogue
            "Outlaw: Killing Spree (51690) added as talentGated CD — nodeID 94565",
            "Subtlety: Goremaw's Bite (426591) added as talentGated CD; Gloomblade (200758) added as talentGated rotational with suppressIfTalent on Backstab (1752) — choice node, only one tracks at a time",
            -- Mage
            "Arcane: Touch of the Magi corrected 210824 → 321507 (correct tree ID, nodeID 102468); Arcane Orb (153626) and Arcane Pulse (1241462) added as talentGated CDs",
            "Fire: Flamestrike (1254851) added as talentGated rotational — Fire spec-variant nodeID 109409",
            -- Death Knight
            "Blood: Consumption (1263824) added as talentGated CD — nodeID 102244",
            -- Monk
            "Mistweaver: Sheilun's Gift (399491) added as CD — nodeID 101120 non-PASSIVE ACTIVE; was missing entirely",
            "Windwalker: Slicing Winds (1217413) added as talentGated CD — nodeID 102250",
            -- Warlock
            "Destruction: Wither (445468) added as talentGated CD — confirmed non-PASSIVE ACTIVE; shared node with Affliction, was missing from Destruction",
            -- Shaman (Enhancement)
            "Enhancement: suppressIfTalent audit complete via v1.4.3 snapshot — no changes needed; spec DB confirmed clean",
            -- Priest
            "Shadow: Halo (120644) added as talentGated rotational — Shadow spec-variant (different ID from Holy's 120517); nodeID 94697 non-PASSIVE ACTIVE",
            -- Debug tool
            "/ms debug talents: spell descriptions now captured and printed below each talent row",
            "/ms debug talents: keywords Replaces/Grants/Transforms/Causes/Activates flagged with >>> prefix — identifies suppressIfTalent and talentGated candidates",
            "/ms debug talents: FLAGGED count added to header; description text stored in snapshot for all future audits",
            -- suppressIfTalent for majorCooldowns
            "Analytics: suppressIfTalent now checked during majorCooldowns tracking setup — was previously only applied to rotationalSpells",
            -- All sourceNotes
            "All 39 spec sourceNotes updated to reflect v1.4.3 snapshot verification with node counts",
        },
    },
    {
        version = "1.4.3",
        tagline = "Version Watermark, Feedback Version Snapshot & Devourer Fixes",
        date    = "April 2026",
        changes = {
            -- Version watermark
            "Fight Complete window: version number shown bottom-right above button row — small (8pt), dimmed at 50% opacity, unobtrusive",
            "Version label now reflects the addon version that generated that specific feedback, not the currently running version",
            "addonVersion field added to result struct — stored permanently with each encounter going forward",
            -- Debug tool
            "/ms debug talents: spell descriptions now captured and printed below each talent row",
            "/ms debug talents: keywords Replaces/Grants/Transforms/Causes/Activates flagged with >>> prefix — identifies suppressIfTalent and talentGated candidates at a glance",
            "/ms debug talents: FLAGGED count added to header summary",
            -- Devourer
            "Devourer: Void Metamorphosis (191427) removed from rotationalSpells — shapeshifting spell fires UPDATE_SHAPESHIFT_FORM not UNIT_SPELLCAST_SUCCEEDED; useCount permanently 0, false 'never used' feedback eliminated",
            "Devourer: Soul Immolation (1241937) — castable by default; Spontaneous Immolation (258920) talent replaces it with a passive version; suppressIfTalent = 258920 added so it is excluded when that talent is taken",
            "Analytics: suppressIfTalent now checked during majorCooldowns setup — previously only applied to rotationalSpells",
            "Devourer: Reap (344862) flagged VERIFY — useCount stays 0 despite casts in damage meter; game likely fires different runtime ID",
        },
    },
    {
        version = "1.4.2",
        tagline = "Class Tuning — Paladin, Death Knight, Mage, Rogue, Monk + UX Polish",
        date    = "April 2026",
        changes = {
            -- UX
            "Login message: replaced 'Type /ms for commands' with direct '/ms show · /ms help' hint",
            "/ms bare now prints compact command strip instead of redirecting to /ms help",
            "/ms help and FAQ panel: removed reset, debug, verify entries; added versions and friend",
            "debug guild inject handler removed entirely — not appropriate for public release",
            -- Paladin / Holy
            "Holy Paladin: resourceType corrected 0 → 9 (Holy Power); Beacon of Light removed from uptimeBuffs (applied to target not self)",
            "Holy Paladin: Blessing of Sacrifice marked talentGated (INACTIVE this build); Aura Mastery, Lay on Hands, Holy Bulwark added as CDs",
            "Holy Paladin: Light of Dawn added to rotational",
            -- Paladin / Protection
            "Protection Paladin: Avenging Wrath and Divine Toll added as CDs (both missing); Rebuke added as isInterrupt",
            "Protection Paladin: Crusader Strike label corrected to Blessed Hammer (Prot spec-variant); Consecration and Holy Shock added to rotational",
            "Protection Paladin: Shield of the Righteous uptime aura 132403 flagged VERIFY",
            -- Paladin / Retribution
            "Retribution: Crusade (231895) removed — PASSIVE modifier node, not castable",
            "Retribution: Templar's Verdict 85256 → Final Verdict 383328 (Midnight 12.0 rename); Divine Toll and Rebuke (isInterrupt) added",
            "Retribution: Execution Sentence marked talentGated; Blade of Justice, Divine Storm added to rotational",
            "Retribution: Art of War added to procBuffs (VERIFY C_UnitAuras); Hammer of Light not tracked — not in tree/spell list",
            -- Death Knight / Blood
            "Blood DK: Abomination Limb (383269) and Bonestorm (194844) removed — not in Blood tree/spell list",
            "Blood DK: Blood Shield (77535) removed from uptimeBuffs — proc absorb, not a persistent aura",
            "Blood DK: Reaper's Mark and Mind Freeze (isInterrupt) added; entire rotationalSpells block added (Marrowrend, Heart Strike, Blood Boil, Death Strike — all missing)",
            -- Death Knight / Frost
            "Frost DK: Breath of Sindragosa and Reaper's Mark added as CDs; Mind Freeze added as isInterrupt",
            "Frost DK: Howling Blast and Frostscythe added to rotational; Killing Machine and Rime procBuff IDs flagged VERIFY (old aura IDs)",
            -- Death Knight / Unholy
            "Unholy DK: Apocalypse (275699) and Unholy Assault (207289) removed — not in Unholy tree/spell list",
            "Unholy DK: Dark Transformation corrected 63560 → 1233448 (Unholy spec-variant); Outbreak and Soul Reaper added as CDs; Mind Freeze added as isInterrupt",
            "Unholy DK: Festering Strike corrected 85092 → 316239 (Unholy spec-variant); Putrefy added to rotational",
            -- Mage / Arcane
            "Arcane: Touch of the Magi (210824) and Evocation (12051) removed — not in Arcane tree/spell list",
            "Arcane: Arcane Blast corrected 30451 → 116 (Arcane spec-variant); Arcane Barrage corrected 44425 → 319836",
            "Arcane: Alter Time added as CD; Arcane Missiles and Arcane Explosion added to rotational; Clearcasting procBuff corrected 276743 → 79684",
            -- Mage / Fire
            "Fire: Phoenix Flames (257541) removed — not in Fire tree/spell list",
            "Fire: Fireball corrected 133 → 116 (Fire spec-variant); Supernova and Frostfire Bolt added as talentGated CDs",
            "Fire: Pyroblast and Scorch added to rotational; Hot Streak procBuff 48108 flagged VERIFY",
            -- Mage / Frost
            "Frost Mage: Icy Veins (12472) removed — not in Frost tree/spell list",
            "Frost Mage: Flurry, Frostfire Bolt, Ray of Frost, Dragon's Breath added as CDs",
            "Frost Mage: Frostbolt (116) added to rotational — primary filler was missing entirely; Brain Freeze and Fingers of Frost procBuff IDs flagged VERIFY",
            -- Rogue / Assassination
            "Assassination: Vendetta (79140) removed — not in tree/spell list; Kick added as isInterrupt",
            "Assassination: Envenom corrected 32645 → 196819 (Assassination spec-variant); Mutilate and Crimson Tempest added to rotational",
            -- Rogue / Outlaw
            "Outlaw: Roll the Bones corrected 315508 → 1214909; Between the Eyes corrected 199804 → 315341; Dispatch corrected 2098 → 196819",
            "Outlaw: Blade Rush and Keep It Rolling added as talentGated CDs; Kick added as isInterrupt",
            "Outlaw: Sinister Strike and Pistol Shot added to rotational — both missing entirely",
            -- Rogue / Subtlety
            "Subtlety: Symbols of Death (212283) removed — not in Subtlety tree/spell list; Kick added as isInterrupt",
            "Subtlety: Nightblade (195452) removed from rotational — not in tree/spell list",
            "Subtlety: Backstab and Shuriken Storm added to rotational",
            -- Monk / Brewmaster
            "Brewmaster: Celestial Brew (322507) removed — not in tree/spell list; Ironskin Brew (215479) removed from uptimeBuffs",
            "Brewmaster: Exploding Keg, Celestial Infusion added as CDs; Spear Hand Strike added as isInterrupt",
            "Brewmaster: Breath of Fire, Tiger Palm, Blackout Kick added to rotational — all missing entirely",
            -- Monk / Mistweaver
            "Mistweaver: Invoke Yu'lon (322118) removed — not in tree/spell list; Invoke Chi-Ji added (correct Mistweaver invoke)",
            "Mistweaver: Renewing Mist corrected 119611 → 115151 (wrong ID); Life Cocoon, Celestial Conduit added as CDs; Spear Hand Strike added as isInterrupt",
            "Mistweaver: Enveloping Mist added to rotational",
            -- Monk / Windwalker
            "Windwalker: Storm, Earth and Fire (137639) and Serenity (152173) removed — not in tree/spell list",
            "Windwalker: Zenith added as CD; Spear Hand Strike added as isInterrupt; Combo Breaker:BoK (116768) removed from procBuffs",
            "Windwalker: Tiger Palm, Blackout Kick, Whirling Dragon Punch added to rotational — Tiger Palm and Blackout Kick were missing entirely",
        },
    },
    {
        version = "1.4.1",
        tagline = "Class Tuning — Warrior, Hunter, Priest",
        date    = "April 2026",
        changes = {
            -- Warrior / Arms
            "Arms: Bladestorm (227847) removed — not in Arms talent tree; Fury-only spell",
            "Arms: Warbreaker (262161) removed — not in Arms talent tree or spell list",
            "Arms: Ravager (228920) added as talentGated CD — nodeID 90441 non-PASSIVE ACTIVE",
            "Arms: Demolish (436358) added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE",
            "Arms: Colossus Smash (167105) added to rotational — nodeID 90290 non-PASSIVE ACTIVE",
            "Arms: Overpower (7384) added to rotational — nodeID 90271 non-PASSIVE ACTIVE",
            "Arms: Rend (772) added to rotational — nodeID 109391 non-PASSIVE ACTIVE",
            -- Warrior / Fury
            "Fury: Onslaught (315720) removed — not in Fury talent tree or spell list",
            "Fury: Avatar (107574) added to majorCooldowns — nodeID 90415 non-PASSIVE ACTIVE",
            "Fury: Odyn's Fury (385059) added as talentGated CD — nodeID 110203 non-PASSIVE ACTIVE",
            "Fury: Demolish (436358) added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE",
            "Fury: Raging Blow (85288) added to rotational — nodeID 90396 non-PASSIVE ACTIVE",
            "Fury: Berserker Stance (386196) added to rotational — nodeID 90325 non-PASSIVE ACTIVE",
            "Fury: Enrage uptime aura 184362 retained with VERIFY flag",
            -- Warrior / Protection
            "Protection: Last Stand (12975) removed — confirmed PASSIVE nodeID 107575",
            "Protection: Demoralizing Shout (1160) added to majorCooldowns — nodeID 90305 non-PASSIVE ACTIVE",
            "Protection: Demolish (436358) added as talentGated CD — nodeID 94818 non-PASSIVE ACTIVE",
            "Protection: Disrupting Shout (386071) added as isInterrupt — nodeID 107579 non-PASSIVE ACTIVE",
            "Protection: Revenge (6572) added to rotational — nodeID 90298 non-PASSIVE ACTIVE",
            -- Hunter / Beast Mastery
            "BM Hunter: Call of the Wild (359844) removed — not in BM talent tree or spell list",
            "BM Hunter: Thrill of the Hunt (246152) removed from procBuffs — not in talent tree or spell list",
            "BM Hunter: Counter Shot (147362) added as isInterrupt — nodeID 102292 non-PASSIVE ACTIVE",
            "BM Hunter: Cobra Shot (193455) added to rotational — nodeID 102354 non-PASSIVE ACTIVE; primary Focus dump",
            "BM Hunter: Black Arrow (466930) added as talentGated rotational — nodeID 109961 non-PASSIVE ACTIVE",
            "BM Hunter: Wild Thrash (1264359) added as talentGated rotational — nodeID 102363 non-PASSIVE ACTIVE",
            -- Hunter / Marksmanship
            "MM Hunter: Precise Shots (342776) removed from procBuffs — not in MM talent tree or spell list",
            "MM Hunter: Counter Shot (147362) added as isInterrupt — nodeID 102402 non-PASSIVE ACTIVE",
            "MM Hunter: Arcane Shot (185358) added to rotational — baseline confirmed spell list; Focus spender was missing",
            -- Hunter / Survival
            "Survival: Coordinated Assault (360952) removed — not in Survival talent tree or spell list",
            "Survival: Kill Command corrected 34026 (BM spec-variant) → 259489 — nodeID 102255 non-PASSIVE ACTIVE",
            "Survival: Mongoose Bite (259387) removed — not in Survival talent tree or spell list",
            "Survival: Muzzle (187707) added as isInterrupt — nodeID 79837 non-PASSIVE ACTIVE",
            "Survival: Raptor Strike (186270) added to rotational — nodeID 102262 non-PASSIVE ACTIVE",
            "Survival: Takedown (1250646) added as talentGated rotational — nodeID 109323 non-PASSIVE ACTIVE",
            "Survival: Boomstick (1261193) added as talentGated rotational — nodeID 109324 non-PASSIVE ACTIVE",
            -- Priest / Discipline
            "Discipline: Power Word: Barrier (62618) removed — not in Discipline talent tree or spell list",
            "Discipline: Evangelism ID corrected 246287 → 472433 — nodeID 82577 non-PASSIVE ACTIVE",
            "Discipline: Rapture (47536) removed — not in Discipline talent tree or spell list",
            "Discipline: Schism (204263) removed — not in Discipline talent tree or spell list",
            "Discipline: Atonement (194384) removed from uptimeBuffs — applied to others not self; not in tree/spell list",
            "Discipline: Power Infusion (10060) added to majorCooldowns — nodeID 82556 non-PASSIVE ACTIVE",
            "Discipline: Penance (47540) added to rotational — baseline confirmed spell list",
            "Discipline: Power Word: Radiance (194509) added to rotational — nodeID 82593 non-PASSIVE ACTIVE",
            "Discipline: Mind Blast (8092) added to rotational — nodeID 82713 non-PASSIVE ACTIVE",
            "Discipline: Shadow Word: Death (32379) added to rotational — nodeID 82712 non-PASSIVE ACTIVE",
            -- Priest / Holy
            "Holy: Prayer of Mending corrected 33076 (Disc spec-variant) → 17 — confirmed Holy spell list",
            "Holy: Power Infusion (10060) added to majorCooldowns — nodeID 82556 non-PASSIVE ACTIVE",
            "Holy: Guardian Spirit (47788) added to majorCooldowns — nodeID 82637 non-PASSIVE ACTIVE",
            "Holy: Holy Word: Serenity (2050) added to rotational — nodeID 82638 non-PASSIVE ACTIVE",
            "Holy: Holy Word: Sanctify (34861) added to rotational — nodeID 82631 non-PASSIVE ACTIVE",
            "Holy: Holy Fire (14914) added to rotational — nodeID 108730 non-PASSIVE ACTIVE; CDR filler",
            "Holy: Halo (120517) added as talentGated rotational — nodeID 108724 non-PASSIVE ACTIVE",
            -- Priest / Shadow
            "Shadow: Full PASSIVE audit — all IDs confirmed against 114-node talent snapshot; no changes required",
        },
    },
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
            "/ms debug auras — dumps all active player buff IDs; use while a proc/buff is active to find its spellID",
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
-- Spec data lives in Specs/*.lua — each file calls Core.RegisterSpec(classID, block)
-- at load time. By the time CombatLog/Analytics load, the database is fully populated.
Core.SPEC_DATABASE = {}

function Core.RegisterSpec(classID, classBlock)
    Core.SPEC_DATABASE[classID] = classBlock
end

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

-- Grace period for brief combat drops (training dummy evade cycles, brief de-aggro).
-- PLAYER_REGEN_ENABLED can fire mid-fight for 1-3 seconds before the player
-- re-aggros.  Delaying COMBAT_END by this window lets PLAYER_REGEN_DISABLED cancel
-- the pending end so the fight continues with no data reset.
-- 3 seconds covers dummy evade cycles.  Does NOT delay the Fight Complete window
-- for normal fights because duration is captured at PLAYER_REGEN_ENABLED time,
-- not at timer-fire time.
local pendingCombatEnd  = nil
local COMBAT_END_GRACE  = 3   -- seconds

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
              " loaded.  |cffFFFFFF/ms show|r to open the HUD  ·  |cffFFFFFF/ms help|r for commands.")
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
        if pendingCombatEnd then
            -- Re-entering combat within the grace window — resume the existing fight.
            -- Cancel the deferred end; do NOT emit COMBAT_START or reset CombatStart.
            -- All tracker fightActive flags are still true (COMBAT_END never fired).
            pendingCombatEnd:Cancel()
            pendingCombatEnd = nil
            Core.InCombat    = true
            return
        end
        Core.InCombat    = true
        Core.CombatStart = GetTime()
        -- Snapshot full instance context at fight start
        -- (GetInstanceInfo is valid now; may change mid-fight for open-world)
        local instName, instType, diffID, diffName,
              maxPlayers, dynDiff, isDynamic, instMapID = GetInstanceInfo()
        Core.CombatInstanceContext = {
            instanceName   = instName  or "",
            instanceType   = instType  or "none",
            difficultyID   = diffID    or 0,
            difficultyName = diffName  or "",
        }
        Core.Emit(Core.EVENTS.COMBAT_START)

    elseif event == "PLAYER_REGEN_ENABLED" then
        Core.InCombat  = false
        Core.CombatEnd = GetTime()
        -- Capture duration now (at the real combat-end moment) so the deferred
        -- timer fires with the correct value even after the grace delay.
        local endedAt  = Core.CombatEnd
        local startedAt = Core.CombatStart
        if pendingCombatEnd then pendingCombatEnd:Cancel() end
        pendingCombatEnd = C_Timer.NewTimer(COMBAT_END_GRACE, function()
            pendingCombatEnd = nil
            Core.Emit(Core.EVENTS.COMBAT_END, endedAt - startedAt)
        end)

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
                                    -- Spell description — captures "Replaces X", "Grants Y",
                                    -- "Transforms", etc. for proactive suppressIfTalent discovery.
                                    local desc = ""
                                    if C_Spell and C_Spell.GetSpellDescription then
                                        local okD2, d = pcall(C_Spell.GetSpellDescription, defInfo.spellID)
                                        if okD2 and d and d ~= "" then
                                            -- Strip colour codes and newlines for clean single-line storage
                                            desc = d:gsub("|c%x%x%x%x%x%x%x%x", "")
                                                    :gsub("|r", "")
                                                    :gsub("[\n\r]+", " ")
                                                    :gsub("%s+", " ")
                                                    :match("^%s*(.-)%s*$") or ""
                                        end
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
                                        desc      = desc,
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
        print("|cff00D1FFMidnight Sensei:|r  |cffFFFFFF/ms show|r  ·  |cffFFFFFF/ms hide|r  ·  |cffFFFFFF/ms history|r  ·  |cffFFFFFF/ms lb|r  ·  |cffFFFFFF/ms options|r  ·  |cffFFFFFF/ms help|r")
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
        print("  /ms update        Show changelog")
        print("  /ms versions      Show addon versions seen this session")
        print("  /ms friend <n>    Query a player's last score directly")
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
    elseif msg == "debug rotational" or msg == "tracker" then
        -- Open the Rotation Tracker UI window; fall back to chat print if UI not loaded
        if MS.UI and MS.UI.ShowRotationalTracker then
            MS.UI.ShowRotationalTracker()
        else
            print("|cff00D1FFMidnight Sensei:|r UI not loaded — run |cffFFFFFF/ms tracker|r after the addon finishes loading.")
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
            local altIdOwner = {}  -- altId → primary id, so altIds are excluded from OTHER SPELLS
            for _, cd in ipairs(spec.majorCooldowns or {}) do
                allTracked[cd.id] = { label = cd.label, bucket = "majorCooldowns",
                    talentGated = cd.talentGated, suppressIfTalent = cd.suppressIfTalent, combatGated = cd.combatGated,
                    altIds = cd.altIds }
                if cd.altIds then
                    for _, altId in ipairs(cd.altIds) do altIdOwner[altId] = cd.id end
                end
            end
            for _, rs in ipairs(spec.rotationalSpells or {}) do
                allTracked[rs.id] = { label = rs.label, bucket = "rotationalSpells",
                    talentGated = rs.talentGated, suppressIfTalent = rs.suppressIfTalent, combatGated = rs.combatGated,
                    altIds = rs.altIds }
                if rs.altIds then
                    for _, altId in ipairs(rs.altIds) do altIdOwner[altId] = rs.id end
                end
            end

            local seen = Core.VerifySeenSpells or {}
            for id, info in pairs(allTracked) do
                -- Count fire from primary ID or any registered altId
                local fired = seen[id]
                if not fired and info.altIds then
                    for _, altId in ipairs(info.altIds) do
                        if seen[altId] then fired = seen[altId]; break end
                    end
                end
                -- Check whether this spell is gated out of the current build
                local skipReason
                if info.talentGated and not info.combatGated then
                    if not IsPlayerSpell(id) then
                        skipReason = "not talented"
                    end
                end
                if not skipReason and info.suppressIfTalent then
                    if IsPlayerSpell(info.suppressIfTalent) or IsTalentActive(info.suppressIfTalent) then
                        local suppressName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(info.suppressIfTalent) or tostring(info.suppressIfTalent)
                        skipReason = "suppressed by " .. (suppressName or tostring(info.suppressIfTalent))
                    end
                end
                if fired then
                    local firedViaAlt = not seen[id] and info.altIds
                    local altNote = ""
                    if firedViaAlt then
                        for _, altId in ipairs(info.altIds) do
                            if seen[altId] then altNote = " (via alt id=" .. altId .. ")"; break end
                        end
                    end
                    L(string.format("  PASS  %-30s id=%-8d fired=%dx  [%s]%s",
                      info.label, id, fired, info.bucket, altNote))
                elseif skipReason then
                    L(string.format("  SKIP  %-30s id=%-8d %s  [%s]",
                      info.label, id, skipReason, info.bucket))
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
                if not allTracked[id] and not altIdOwner[id] then table.insert(unknownCasts, {id=id, count=count}) end
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
        local flagged  = 0
        -- Keywords that indicate a talent modifies spell availability:
        -- "Replaces"  → suppressIfTalent candidate (spell becomes passive or is replaced)
        -- "Grants"    → talentGated candidate (talent creates a new castable spell)
        -- "Transforms"→ suppressIfTalent candidate
        -- "Causes"    → may create secondary castable abilities
        -- "Activates" → may unlock a new ability
        local KEYWORDS = { "Replaces", "Grants", "Transforms", "Causes", "Activates" }
        local function GetFlag(desc)
            if not desc or desc == "" then return nil end
            for _, kw in ipairs(KEYWORDS) do
                if desc:find(kw) then return kw end
            end
            return nil
        end

        for _, t in ipairs(snap.talents) do
            if t.status == "ACTIVE" then active = active + 1
            else inactive = inactive + 1 end
            if t.isPassive then passive = passive + 1 end
            if GetFlag(t.desc) then flagged = flagged + 1 end
        end

        L("Midnight Sensei — Full Talent Tree Snapshot")
        L("Spec:      " .. (snap.className or "?") .. " / " .. (snap.specName or "?"))
        L("Captured:  " .. date("%Y-%m-%d %H:%M:%S", snap.timestamp))
        L("Version:   " .. Core.VERSION)
        L(string.rep("-", 80))
        L(string.format("Total nodes: %d  |  ACTIVE: %d  |  INACTIVE: %d  |  PASSIVE: %d  |  FLAGGED: %d",
            #snap.talents, active, inactive, passive, flagged))
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
            -- Print description on a continuation line if present
            -- Flag lines that contain spell-relationship keywords with >>>
            if t.desc and t.desc ~= "" then
                local flag = GetFlag(t.desc)
                local prefix = flag and ("  >>> [" .. flag .. "] ") or "  -- "
                -- Wrap at 78 chars to keep the export clean
                local text = prefix .. t.desc
                while #text > 78 do
                    local cut = text:sub(1, 78):match("^(.*%s)") or text:sub(1, 78)
                    L(cut)
                    text = "     " .. text:sub(#cut + 1)
                end
                if text and text ~= "" then L(text) end
            end
        end
        L("")
        L("-- ACTIVE = talented, INACTIVE = available but not taken")
        L("-- PASSIVE = spell is passive, do not add to majorCooldowns or rotationalSpells")
        L("-- >>> [Replaces]  = suppressIfTalent candidate — talent makes a spell passive")
        L("-- >>> [Grants]    = talentGated candidate — talent creates a new castable spell")
        L("-- >>> [Transforms]= suppressIfTalent candidate — talent changes spell behaviour")
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

    elseif msg == "debug auras" then
        -- Dump all active player auras so untracked buff IDs can be identified.
        -- Use while a proc/buff is active to find its spellID.
        if not C_UnitAuras then
            print("|cff00D1FFMidnight Sensei:|r C_UnitAuras not available.")
        else
            local found = 0
            print("|cff00D1FFMidnight Sensei — Active Player Auras:|r")
            for i = 1, 40 do
                local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
                if ok and aura and aura.spellId then
                    print(string.format("  [%d] id=%-8d %s", i, aura.spellId, aura.name or "?"))
                    found = found + 1
                else
                    break
                end
            end
            if found == 0 then print("  (no active buffs found)") end
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
        -- Self-entry weekly avg debug
        print("  --- Self-entry weekly avg state ---")
        local cb2 = MidnightSenseiCharDB and MidnightSenseiCharDB.bests
        local wk2 = MS.Leaderboard and MS.Leaderboard.GetWeekKey and MS.Leaderboard.GetWeekKey()
        print("  GetWeekKey(): " .. tostring(wk2))
        if cb2 then
            print("  cb.weekKey:   " .. tostring(cb2.weekKey))
            print("  cb.weeklyAvg: " .. tostring(cb2.weeklyAvg))
            print("  cb.weekKey==wk: " .. tostring(cb2.weekKey == wk2))
        else
            print("  CharDB.bests: nil")
        end
        -- Pull the actual self-entry from GetGuildData and show key fields
        if MS.Leaderboard and MS.Leaderboard.GetGuildData then
            local gdata = MS.Leaderboard.GetGuildData()
            local selfName = UnitName("player") .. "-" .. (GetRealmName() or "")
            local se = gdata and gdata[selfName]
            if se then
                print("  selfEntry.weekKey:    " .. tostring(se.weekKey))
                print("  selfEntry.weeklyAvg:  " .. tostring(se.weeklyAvg))
                print("  selfEntry.dungeonAvg: " .. tostring(se.dungeonAvg))
                print("  selfEntry.raidAvg:    " .. tostring(se.raidAvg))
                print("  selfEntry.dungeonBest:" .. tostring(se.dungeonBest))
                print("  selfEntry.prevWeek:   " .. tostring(se.prevWeek))
                local prevFires = (se.weekKey and se.weekKey ~= wk2) or (se.isSelf and se.prevWeek)
                print("  (prev) would fire: " .. tostring(prevFires))
            else
                print("  selfEntry not found in GetGuildData() under key: " .. tostring(selfName))
                -- Print available keys for diagnosis
                if gdata then
                    print("  Available keys:")
                    for k in pairs(gdata) do print("    " .. tostring(k)) end
                end
            end
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

    elseif msg == "debug bossboard restore" then
        if MS.BossBoard and MS.BossBoard.RestoreFromSnapshot then
            MS.BossBoard.RestoreFromSnapshot()
        else
            print("|cff00D1FFMidnight Sensei:|r Boss Board not loaded.")
        end

    elseif msg == "debug cleanup history" then
        if MS.BossBoard and MS.BossBoard.CleanupHistory then
            MS.BossBoard.CleanupHistory(true)  -- dry run
        else
            print("|cff00D1FFMidnight Sensei:|r Boss Board not loaded.")
        end

    elseif msg == "debug cleanup history confirm" then
        if MS.BossBoard and MS.BossBoard.CleanupHistory then
            MS.BossBoard.CleanupHistory(false)  -- apply
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
