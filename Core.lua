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
    Core.VERSION = ver or "1.2.6"
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
            sub.fn(elapsed)
        end
    end
end)

--------------------------------------------------------------------------------
-- SavedVariables  (schema v2 — preserves encounters + leaderboard on bump)
--------------------------------------------------------------------------------
local SCHEMA_VERSION = 2

function Core.InitSavedVariables()
    MidnightSenseiDB = MidnightSenseiDB or {}
    if (MidnightSenseiDB.schemaVersion or 0) < SCHEMA_VERSION then
        local oldEnc = MidnightSenseiDB.encounters
        local oldLB  = MidnightSenseiDB.leaderboard
        MidnightSenseiDB = { schemaVersion = SCHEMA_VERSION }
        MidnightSenseiDB.encounters  = oldEnc or {}
        MidnightSenseiDB.leaderboard = oldLB  or {}
    end
    local db = MidnightSenseiDB
    db.encounters  = db.encounters  or {}
    db.settings    = db.settings    or {}
    db.stats       = db.stats       or {}
    db.leaderboard = db.leaderboard or {}

    local s = db.settings
    local function def(k, v) if s[k] == nil then s[k] = v end end
    def("hudVisibility",    "always")   -- "always" | "combat" | "hide"
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
    -- playStyle removed: grading is now behavior-driven only (no user selection)
end

function Core.GetSetting(key)
    return MidnightSenseiDB and MidnightSenseiDB.settings and MidnightSenseiDB.settings[key]
end
function Core.SetSetting(key, value)
    if MidnightSenseiDB and MidnightSenseiDB.settings then
        MidnightSenseiDB.settings[key] = value
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
            "GRM-style peer sync -- recover your scores after a reinstall via guild members",
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
                { id = 163201, label = "Execute",       minFightSeconds = 60 },
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
                { id = 259387, label = "Mongoose Bite",  minFightSeconds = 45 },
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
                { id = 1943,  label = "Rupture",  minFightSeconds = 30 },
                { id = 703,   label = "Garrote",  minFightSeconds = 30 },
                { id = 32645, label = "Envenom",  minFightSeconds = 45 },
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
                { id = 195452, label = "Nightblade",    minFightSeconds = 45 },
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
                { id = 228260, label = "Void Eruption",   expectedUses = "on CD"          },
                { id = 391109, label = "Dark Ascension",  expectedUses = "on CD (talent)" },
                { id = 263165, label = "Void Torrent",    expectedUses = "on CD"          },
                { id = 205385, label = "Shadow Crash",    expectedUses = "on CD"          },
            },
            -- uptimeBuffs empty: SW:Pain and Vampiric Touch are enemy debuffs, not player self-auras
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 589,    label = "Shadow Word: Pain", minFightSeconds = 20 },
                { id = 34914,  label = "Vampiric Touch",    minFightSeconds = 20 },
                { id = 335467, label = "Devouring Plague",  minFightSeconds = 30 },
                { id = 8092,   label = "Mind Blast",        minFightSeconds = 30 },
            },
            priorityNotes = {
                "Maintain Shadow Word: Pain and Vampiric Touch on all targets (not directly tracked)",
                "Enter Voidform (Void Eruption) or Dark Ascension on cooldown",
                "Devouring Plague to spend Insanity — never overcap at 90",
                "Mind Blast on cooldown for Insanity generation",
                "Void Torrent on cooldown — strong channel, do not cancel",
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
                { id = 49020,  label = "Obliterate",  minFightSeconds = 20 },
                { id = 49143,  label = "Frost Strike", minFightSeconds = 20 },
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
                { id = 85092,  label = "Festering Strike", minFightSeconds = 20 },
                { id = 55090,  label = "Scourge Strike",   minFightSeconds = 20 },
                { id = 47541,  label = "Death Coil",       minFightSeconds = 20 },
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

        -- Elemental
        -- Added:    Primordial Wave (375982) to majorCooldowns (significant burst CD, common build)
        -- Removed:  Flame Shock (188389) from uptimeBuffs — target debuff, not a player self-aura,
        --           not detectable via C_UnitAuras.GetPlayerAuraBySpellID
        -- Removed:  debuffUptime from scoreWeights (no trackable uptimeBuffs remain)
        -- Moved to priorityNotes: Flame Shock maintenance with "not directly tracked" caveat,
        --           Lava Surge proc reaction, burst alignment
        -- Not added: Lava Surge (77762) to procBuffs — real player aura but needs in-game
        --            verification via C_UnitAuras before adding. Omitted until confirmed.
        --            Master of the Elements, Stormkeeper buff — same, needs verification.
        --            Liquid Magma Totem, Storm Elemental — build-dependent, omitted.
        -- Reason:   Aligns spec with player-aura-only tracking model.
        [1] = {
            name = "Elemental", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 90,
            majorCooldowns = {
                { id = 191634, label = "Stormkeeper",       expectedUses = "on CD"           },
                { id = 198067, label = "Fire Elemental",    expectedUses = "on CD (2.5 min)" },
                { id = 375982, label = "Primordial Wave",   expectedUses = "on CD (talent)"  },
                { id = 114050, label = "Ascendance",        expectedUses = "burst windows"   },
            },
            -- uptimeBuffs intentionally empty: Flame Shock is a target debuff,
            -- not detectable via C_UnitAuras.GetPlayerAuraBySpellID.
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 188196, label = "Flame Shock",  minFightSeconds = 20 },
                { id = 51505,  label = "Lava Burst",   minFightSeconds = 20 },
                { id = 60103,  label = "Lava Burst",   minFightSeconds = 20 },  -- empowered variant
            },
            priorityNotes = {
                "Maintain Flame Shock on all targets for Lava Surge procs (not directly tracked)",
                "Lava Burst on cooldown — always use Lava Surge procs immediately",
                "Stormkeeper before empowered Lightning Bolt casts for maximum burst",
                "Spend Maelstrom with Earth Shock (single target) or Earthquake (AoE) — avoid overcap",
                "Align Fire Elemental with Bloodlust and Primordial Wave for stacked burst",
                "Ascendance for heavy burst phases or when Fire Elemental is on CD",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Elemental Shaman guide",
        },

        -- Enhancement
        -- Added:    Primordial Wave (375982), Sundering (197214) to majorCooldowns
        -- Removed:  Flame Shock (188389) from uptimeBuffs — target debuff, not trackable
        -- Removed:  debuffUptime from scoreWeights (no trackable uptimeBuffs remain)
        -- Kept:     Maelstrom Weapon (344179) in procBuffs (confirmed player self-buff)
        --           Feral Spirit (51533), Ascendance (114051), Doom Winds (384352) in majorCooldowns
        -- Moved to priorityNotes: Flame Shock with "not directly tracked" caveat, expanded
        --           Maelstrom spending guidance, Crash Lightning, Primordial Wave, Doom Winds burst
        -- Not added: Hot Hand — player aura exists but needs in-game C_UnitAuras verification.
        --            Legacy of the Frost Witch — same, needs verification. Omitted until confirmed.
        -- Reason:   Aligns spec with player-aura-only tracking model.
        [2] = {
            name = "Enhancement", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 140,
            majorCooldowns = {
                { id = 51533,  label = "Feral Spirit",    expectedUses = "on CD"          },
                { id = 114051, label = "Ascendance",      expectedUses = "burst windows"  },
                { id = 375982, label = "Primordial Wave", expectedUses = "on CD (talent)" },
                { id = 197214, label = "Sundering",       expectedUses = "on CD (talent)" },
                { id = 384352, label = "Doom Winds",      expectedUses = "on CD (talent)" },
            },
            -- uptimeBuffs intentionally empty: Flame Shock is a target debuff,
            -- not detectable via C_UnitAuras.GetPlayerAuraBySpellID.
            uptimeBuffs = {},
            procBuffs = {
                { id = 344179, label = "Maelstrom Weapon", maxStackTime = 20 },
            },
            priorityNotes = {
                "Maintain Flame Shock on targets for Hot Hand procs and Lava Lash damage (not directly tracked)",
                "Spend Maelstrom Weapon at 5+ stacks — spend at 10 before any cap",
                "Stormstrike on cooldown — primary builder and damage source",
                "Lava Lash to spread Flame Shock in multi-target and spend Maelstrom stacks",
                "Crash Lightning before AoE pulls to apply the ground effect",
                "Use Primordial Wave before Lightning Bolt for overloaded hits if talented",
                "Doom Winds: use at peak Maelstrom / Feral Spirit window for burst if talented",
                "Avoid Maelstrom Weapon overcap — spend with Lightning Bolt or Elemental Blast",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Enhancement Shaman guide",
        },

        -- Restoration
        -- Added:    Cloudburst Totem (157153) to majorCooldowns (significant throughput CD)
        --           Ancestral Guidance (108281) to majorCooldowns (common healing CD)
        -- Kept:     Spirit Link Totem, Healing Tide Totem, Healing Rain, Ascendance unchanged
        -- Removed:  Nothing removed
        -- Expanded: priorityNotes with Riptide rolling, Cloudburst timing, Healing Rain usage,
        --           cooldown alignment with damage windows, overheal awareness
        -- Not added: Tidal Waves — player aura but needs in-game C_UnitAuras verification.
        --            Reason: healer proc tracking adds little grading value vs. complexity risk.
        [3] = {
            name = "Restoration", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 98008,  label = "Spirit Link Totem",   expectedUses = "dangerous stacks"    },
                { id = 108280, label = "Healing Tide Totem",  expectedUses = "raid damage"         },
                { id = 157153, label = "Cloudburst Totem",    expectedUses = "before damage"       },
                { id = 73920,  label = "Healing Rain",        expectedUses = "on CD when stacked"  },
                { id = 108281, label = "Ancestral Guidance",  expectedUses = "heavy damage phases" },
                { id = 114052, label = "Ascendance",          expectedUses = "emergency healing"   },
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Riptide rolling on 2-3 injured targets at all times",
                "Place Cloudburst Totem before predictable damage, then recall it for burst healing",
                "Healing Rain on stacked groups — high mana efficiency, keep it active",
                "Chain Heal for group damage when multiple targets are injured",
                "Spirit Link Totem to equalize dangerous health imbalances in the raid",
                "Healing Tide Totem for sustained raid damage — do not hold it too long",
                "Ascendance for emergency throughput — not a maintenance cooldown",
                "Avoid excessive overheal — cast slightly later on targets above 70% health",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Restoration Shaman guide",
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
                { id = 133,    label = "Fireball",   minFightSeconds = 20 },
                { id = 108853, label = "Fire Blast", minFightSeconds = 20 },
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
                { id = 30455,  label = "Ice Lance", minFightSeconds = 20 },
                { id = 44614,  label = "Flurry",    minFightSeconds = 20 },
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

        -- Affliction
        -- Added:    Malevolence (458355), Dark Harvest (387166) to majorCooldowns
        --           rotationalSpells: Haunt (48181) — short-CD rotation-priority spell,
        --           tracked for presence via rotationalSpells bucket.
        -- Removed:  Agony, Corruption, Unstable Affliction from uptimeBuffs (enemy debuffs,
        --           not detectable via C_UnitAuras.GetPlayerAuraBySpellID)
        -- Removed:  debuffUptime from scoreWeights (no trackable uptimeBuffs remain)
        -- Moved to priorityNotes: DoT maintenance, shard pooling, burst alignment
        -- Note:     Nightfall (264571) is a real player aura but needs in-game verification
        --           via C_UnitAuras before adding to procBuffs — omitted until confirmed.
        -- Reason:   Aligns spec with addon's player-aura-only tracking model.
        [1] = {
            name = "Affliction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 205180, label = "Summon Darkglare",     expectedUses = "on CD"          },
                { id = 458355, label = "Malevolence",          expectedUses = "on CD"          },
                { id = 387166, label = "Dark Harvest",         expectedUses = "on CD (talent)" },
                { id = 205179, label = "Phantom Singularity",  expectedUses = "on CD (talent)" },
                { id = 278350, label = "Vile Taint",           expectedUses = "on CD (talent)" },
            },
            rotationalSpells = {
                -- Haunt has a ~15s CD making it rotation-priority rather than burst-window.
                -- Tracked via ABILITY_USED; flagged only if never used in fights >= 45s.
                { id = 48181, label = "Haunt", minFightSeconds = 45 },
            },
            -- uptimeBuffs intentionally empty: Agony, Corruption, UA are enemy debuffs
            -- and cannot be tracked via C_UnitAuras.GetPlayerAuraBySpellID.
            uptimeBuffs = {},
            priorityNotes = {
                "Maintain Agony, Corruption, and Unstable Affliction on all targets (not directly tracked)",
                "Haunt on cooldown for the damage amp window",
                "Pool Soul Shards before burst windows — avoid overcapping",
                "Align Malevolence and Dark Harvest with Darkglare for stacked burst",
                "Malefic Rapture to spend Soul Shards during Darkglare windows",
                "Phantom Singularity and Vile Taint on cooldown if talented",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Affliction Warlock guide",
        },

        -- Demonology
        -- Added:    Malevolence (458355) to majorCooldowns
        --           rotationalSpells: Implosion (196277), Power Siphon (264170)
        -- Removed:  Implosion from majorCooldowns — it has no cooldown and does not belong
        --           in the cooldown scoring bucket. Moved to rotationalSpells for presence tracking.
        -- Kept:     Demonic Core in procBuffs (real player self-buff, ID 267102)
        -- Reason:   rotationalSpells tracks usage via ABILITY_USED without frequency-penalising
        --           spells that have no static CD. Feedback fires only if never used in 60s+ fights.
        [2] = {
            name = "Demonology", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 265187, label = "Summon Demonic Tyrant", expectedUses = "on CD"          },
                { id = 458355, label = "Malevolence",           expectedUses = "on CD"          },
                { id = 104316, label = "Call Dreadstalkers",    expectedUses = "on CD"          },
                { id = 264119, label = "Summon Vilefiend",      expectedUses = "on CD (talent)" },
            },
            rotationalSpells = {
                -- Tracked via ABILITY_USED; only flagged unused in fights >= minFightSeconds.
                -- IsPlayerSpell gates talent-dependent entries at fight start.
                { id = 196277, label = "Implosion",     minFightSeconds = 45 },
                { id = 264170, label = "Power Siphon",  minFightSeconds = 60 },
            },
            procBuffs = {
                { id = 267102, label = "Demonic Core", maxStackTime = 20 },
            },
            priorityNotes = {
                "Stack demons before Demonic Tyrant — Tyrant extends all active pet durations",
                "Use Implosion at 6+ Wild Imps for maximum damage",
                "Use Power Siphon when Demonic Core stacks are low and imps are active",
                "Call Dreadstalkers on cooldown — core damage and imp generation",
                "Spend Demonic Core procs on Demonbolt — don't sit on stacks",
                "Hand of Gul'dan to summon imps and enable Implosion windows",
                "Avoid Soul Shard overcap — spend with Hand of Gul'dan",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 25, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Demonology Warlock guide",
        },

        -- Destruction
        -- Added:    Malevolence (458355), Cataclysm (152108) to majorCooldowns
        -- Removed:  Immolate from uptimeBuffs (enemy debuff, not detectable via C_UnitAuras)
        -- Removed:  debuffUptime from scoreWeights (no trackable uptimeBuffs remain)
        -- Moved to priorityNotes: Immolate maintenance, Backdraft usage, Havoc cleave
        -- Not added: Backdraft (117828) to procBuffs/uptimeBuffs — player self-buff but needs
        --            in-game verification via C_UnitAuras before adding. Omitted until confirmed.
        -- Reason:   Aligns spec with addon's player-aura-only tracking model.
        [3] = {
            name = "Destruction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 1122,   label = "Summon Infernal",  expectedUses = "on CD"          },
                { id = 458355, label = "Malevolence",      expectedUses = "on CD"          },
                { id = 152108, label = "Cataclysm",        expectedUses = "on CD (talent)" },
                { id = 80240,  label = "Havoc",            expectedUses = "cleave windows" },
            },
            -- uptimeBuffs intentionally empty: Immolate is an enemy debuff and
            -- cannot be tracked via C_UnitAuras.GetPlayerAuraBySpellID.
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 29722,  label = "Incinerate",   minFightSeconds = 20 },
                { id = 116858, label = "Chaos Bolt",   minFightSeconds = 30 },
                { id = 348,    label = "Immolate",     minFightSeconds = 20 },
            },
            priorityNotes = {
                "Maintain Immolate on all targets for shard generation (not directly tracked)",
                "Use Conflagrate to generate Backdraft charges for cheaper Incinerate casts",
                "Do not waste Backdraft — cast Incinerate or Chaos Bolt while it is active",
                "Chaos Bolt is the primary shard spender — align with Summon Infernal and Malevolence",
                "Use Havoc for Chaos Bolt cleave on two targets",
                "Cataclysm on cooldown for AoE shard generation and Immolate spread",
                "Avoid Soul Shard overcap — spend with Chaos Bolt or Shadowburn on low health targets",
            },
            scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
            sourceNote = "Adapted from Icy Veins Destruction Warlock guide",
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
                { id = 113656, label = "Fists of Fury",   minFightSeconds = 20 },
                { id = 107428, label = "Rising Sun Kick",  minFightSeconds = 20 },
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

        -- Balance
        -- Removed:  Moonfire (164812), Sunfire (93402) from uptimeBuffs — enemy debuffs
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Moonfire (8921), Sunfire (93402), Starsurge (78674)
        [1] = {
            name = "Balance", role = "DPS",
            resourceType = 8, resourceLabel = "ASTRAL POWER", overcapAt = 90,
            majorCooldowns = {
                { id = 194223, label = "Celestial Alignment", expectedUses = "on CD"          },
                { id = 102560, label = "Incarnation: Elune",  expectedUses = "on CD (talent)" },
                { id = 191034, label = "Starfall",            expectedUses = "AoE on CD"      },
            },
            -- uptimeBuffs empty: Moonfire and Sunfire are enemy debuffs, not player self-auras
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 8921,  label = "Moonfire",   minFightSeconds = 20 },
                { id = 93402, label = "Sunfire",    minFightSeconds = 20 },
                { id = 78674, label = "Starsurge",  minFightSeconds = 30 },
            },
            priorityNotes = {
                "Maintain Moonfire and Sunfire on all targets — do not let them fall off (not directly tracked)",
                "Celestial Alignment / Incarnation on cooldown — enter Eclipse burst window",
                "Starsurge during Solar/Lunar Eclipse to spend Astral Power",
                "Starfall during AoE phases — more efficient than Starsurge at 3+ targets",
                "Never overcap Astral Power at 90 — spend with Starsurge or Starfall",
            },
            scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Adapted from Icy Veins Balance Druid guide",
        },

        -- Feral
        -- Removed:  Rip (1079), Rake (1822) from uptimeBuffs — enemy debuffs, not player self-auras
        -- Removed:  debuffUptime from scoreWeights
        -- Added:    rotationalSpells: Rip (1079), Rake (1822), Ferocious Bite (22568)
        -- Kept:     Predatory Swiftness in procBuffs — real player self-buff (VERIFY C_UnitAuras)
        [2] = {
            name = "Feral", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 5217,   label = "Tiger's Fury",      expectedUses = "on CD"          },
                { id = 106951, label = "Berserk",           expectedUses = "burst windows"  },
                { id = 102543, label = "Incarnation: King", expectedUses = "on CD (talent)" },
            },
            -- uptimeBuffs empty: Rip and Rake are enemy debuffs, not player self-auras
            uptimeBuffs = {},
            rotationalSpells = {
                { id = 1079,  label = "Rip",            minFightSeconds = 20 },
                { id = 1822,  label = "Rake",           minFightSeconds = 20 },
                { id = 22568, label = "Ferocious Bite", minFightSeconds = 30 },
            },
            procBuffs = {
                { id = 69369, label = "Predatory Swiftness", maxStackTime = 12 },  -- VERIFY C_UnitAuras
            },
            priorityNotes = {
                "Maintain Rip and Rake on all targets — core bleed damage (not directly tracked)",
                "Tiger's Fury on cooldown — Energy refill and 15% damage buff",
                "Berserk / Incarnation for burst — massive CP generation rate",
                "Shred to build combo points, Ferocious Bite to spend at 5 CP",
                "Spend Predatory Swiftness procs immediately — free instant Regrowth",
            },
            scoreWeights = { cooldownUsage = 25, procUsage = 25, activity = 30, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Feral Druid guide",
        },

        -- Guardian
        [3] = {
            name = "Guardian", role = "TANK",
            resourceType = 8, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 102558, label = "Incarn: Guardian",      expectedUses = "on CD"         },
                { id = 22812,  label = "Barkskin",              expectedUses = "magic damage"  },
                { id = 61336,  label = "Survival Instincts",    expectedUses = "emergency"     },
                { id = 22842,  label = "Frenzied Regeneration", expectedUses = "sustained dmg" },
            },
            uptimeBuffs = {
                { id = 192081, label = "Ironfur", targetUptime = 70 },
            },
            rotationalSpells = {
                { id = 33917,  label = "Mangle",  minFightSeconds = 20 },
                { id = 77758,  label = "Thrash",  minFightSeconds = 20 },
            },
            tankMetrics = { targetMitigationUptime = 70 },
            priorityNotes = {
                "Keep Ironfur up constantly — spend Rage for 70%+ uptime (tracked via uptimeBuffs)",
                "Mangle on cooldown — primary Rage generator",
                "Thrash on cooldown — DoT damage and AoE threat",
                "Frenzied Regeneration for healing in sustained high damage windows",
                "Barkskin for magic damage, Survival Instincts for emergencies",
            },
            scoreWeights = { cooldownUsage = 25, mitigationUptime = 40, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Guardian Druid guide",
        },

        -- Restoration
        [4] = {
            name = "Restoration", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 740,    label = "Tranquility",       expectedUses = "1-2 per fight"   },
                { id = 33891,  label = "Incarnation: Tree", expectedUses = "sustained burst" },
                { id = 197721, label = "Flourish",          expectedUses = "extend HoTs"     },
                { id = 48438,  label = "Wild Growth",       expectedUses = "on CD AoE"       },
            },
            rotationalSpells = {
                { id = 774,   label = "Rejuvenation", minFightSeconds = 20 },
                { id = 18562, label = "Swiftmend",    minFightSeconds = 20 },
            },
            healerMetrics = { targetOverheal = 35, targetActivity = 75, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Rejuvenation rolling on injured targets — HoT foundation",
                "Wild Growth on cooldown for efficient AoE healing",
                "Flourish to extend all active HoTs during damage windows",
                "Swiftmend for emergency instant healing — generates Soul of the Forest",
                "Tranquility for heavy sustained raid damage — 1-2 uses per fight",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Restoration Druid guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 12 · DEMON HUNTER
    ----------------------------------------------------------------------------
    [12] = {
        className = "Demon Hunter",

        -- Havoc
        [1] = {
            name = "Havoc", role = "DPS",
            resourceType = 17, resourceLabel = "FURY", overcapAt = 100,
            majorCooldowns = {
                { id = 191427, label = "Metamorphosis",  expectedUses = "burst windows"  },
                { id = 198013, label = "Eye Beam",       expectedUses = "on CD"          },
                { id = 258925, label = "Fel Barrage",    expectedUses = "on CD (talent)" },
                { id = 370965, label = "The Hunt",       expectedUses = "on CD (talent)" },
            },
            rotationalSpells = {
                { id = 188499, label = "Blade Dance",      minFightSeconds = 20 },
                { id = 162794, label = "Chaos Strike",     minFightSeconds = 20 },
                { id = 258920, label = "Immolation Aura",  minFightSeconds = 20 },
            },
            procBuffs = {
                { id = 337567, label = "Furious Gaze",  maxStackTime = 8  },
                { id = 389860, label = "Unbound Chaos", maxStackTime = 12 },
            },
            priorityNotes = {
                "Immolation Aura on cooldown — primary Fury generator",
                "Eye Beam on cooldown — core damage and Fury dump",
                "Blade Dance / Death Sweep on cooldown — highest priority spender",
                "Chaos Strike to spend Fury — never overcap at 100",
                "Metamorphosis for burst — align with trinkets and lust",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 20, activity = 30, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Havoc Demon Hunter guide",
        },

        -- Vengeance
        [2] = {
            name = "Vengeance", role = "TANK",
            resourceType = 17, resourceLabel = "FURY", overcapAt = 100,
            majorCooldowns = {
                { id = 187827, label = "Metamorphosis",  expectedUses = "emergency mitigation" },
                { id = 204021, label = "Fiery Brand",    expectedUses = "tank busters"         },
                { id = 212084, label = "Fel Devastation",expectedUses = "on CD"                },
                { id = 263648, label = "Soul Barrier",   expectedUses = "big hits (talent)"    },
            },
            uptimeBuffs = {
                { id = 203819, label = "Demon Spikes", targetUptime = 50 },
            },
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Maintain Demon Spikes for physical mitigation",
                "Immolation Aura on cooldown for Fury and damage",
                "Fracture / Shear to generate Soul Fragments",
                "Spirit Bomb with 4-5 Soul Fragments",
                "Fiery Brand for magic damage or tank busters",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Vengeance Demon Hunter guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 13 · EVOKER
    ----------------------------------------------------------------------------
    [13] = {
        className = "Evoker",

        -- Devastation
        [1] = {
            name = "Devastation", role = "DPS",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,  -- VERIFY resource enum
            majorCooldowns = {
                { id = 375087, label = "Dragonrage",     expectedUses = "on CD"         },
                { id = 357208, label = "Fire Breath",    expectedUses = "on CD"         },
                { id = 359073, label = "Eternity Surge", expectedUses = "on CD"         },
                { id = 357210, label = "Deep Breath",    expectedUses = "burst windows" },
            },
            rotationalSpells = {
                { id = 361469, label = "Living Flame",  minFightSeconds = 20 },
                { id = 356995, label = "Disintegrate",  minFightSeconds = 20 },
            },
            priorityNotes = {
                "Fire Breath and Eternity Surge on cooldown — highest priority empowered spells",
                "Dragonrage for burst — maximize empowered cast rate inside window",
                "Disintegrate as primary filler — strong sustained channel",
                "Living Flame as filler when moving — do not cap Essence",
                "Deep Breath for AoE on stacked targets",
            },
            scoreWeights = { cooldownUsage = 35, activity = 30, resourceMgmt = 25, procUsage = 10 },
            sourceNote = "Adapted from Icy Veins Devastation Evoker guide",
        },

        -- Preservation
        [2] = {
            name = "Preservation", role = "HEALER",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,
            majorCooldowns = {
                { id = 363534, label = "Rewind",            expectedUses = "emergency"     },
                { id = 355936, label = "Dream Breath",      expectedUses = "on CD AoE"     },
                { id = 370960, label = "Emerald Communion", expectedUses = "sustained AoE" },
                { id = 374348, label = "Tip the Scales",    expectedUses = "burst ramp"    },
            },
            rotationalSpells = {
                { id = 366155, label = "Reversion",        minFightSeconds = 20 },
                { id = 355913, label = "Emerald Blossom",  minFightSeconds = 30 },
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 10 },
            priorityNotes = {
                "Reversion on cooldown — primary single-target HoT filler",
                "Emerald Blossom for group healing efficiency",
                "Dream Breath on cooldown — primary AoE healing",
                "Echo to amplify upcoming high-throughput spells",
                "Rewind is a true emergency — save for near-wipes only",
            },
            scoreWeights = { cooldownUsage = 30, efficiency = 30, activity = 25, responsiveness = 15 },
            sourceNote = "Adapted from Icy Veins Preservation Evoker guide",
        },

        -- Augmentation
        [3] = {
            name = "Augmentation", role = "DPS",
            resourceType = 17, resourceLabel = "ESSENCE", overcapAt = 6,
            majorCooldowns = {
                { id = 403631, label = "Breath of Eons", expectedUses = "burst windows" },
                { id = 395152, label = "Ebon Might",     expectedUses = "on CD"         },
                { id = 409311, label = "Prescience",     expectedUses = "pre-burst"     },
            },
            -- Ebon Might IS a player self-buff — kept in uptimeBuffs
            uptimeBuffs = {
                { id = 395152, label = "Ebon Might", targetUptime = 70 },
            },
            rotationalSpells = {
                { id = 396286, label = "Upheaval",  minFightSeconds = 20 },
                { id = 359618, label = "Eruption",  minFightSeconds = 20 },
            },
            priorityNotes = {
                "Ebon Might on cooldown — core party amplification buff (tracked via uptimeBuffs)",
                "Prescience before burst cooldowns to amplify allies",
                "Upheaval and Eruption for personal damage contribution",
                "Breath of Eons for peak burst — aligns with lust",
                "Maintain Ebon Might uptime at 70%+ for maximum support value",
            },
            scoreWeights = { cooldownUsage = 35, mitigationUptime = 30, activity = 25, resourceMgmt = 10 },
            sourceNote = "Adapted from Icy Veins Augmentation Evoker guide",
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
        Core.Emit(Core.EVENTS.SESSION_READY)
        print("|cff00D1FFMidnight Sensei|r v" .. Core.VERSION ..
              " loaded.  Type |cffFFD700/ms|r for commands.")

    elseif event == "PLAYER_ENTERING_WORLD" then
        DetectSpec()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        DetectSpec()

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

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID then
            Core.Emit(Core.EVENTS.ABILITY_USED, spellID, GetTime())
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        BroadcastVersion()

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, payload, _, sender = ...
        if prefix ~= VER_PREFIX then return end
        local theirVer = payload:match("^VERSION|(.+)$")
        if not theirVer or notifiedThisSession then return end
        local sname = (sender:match("^([^%-]+)") or sender)
        if sname == UnitName("player") then return end
        if IsNewer(theirVer, Core.VERSION) then
            notifiedThisSession = true
            print("|cff00D1FFMidnight Sensei:|r A new version is available. Check Github for latest update.")
            Call(MS.UI, "ShowUpdateToast", sname, theirVer)
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
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

-- UNIT_AURA is dispatched to CombatLog for buff/debuff uptime tracking

C_ChatInfo.RegisterAddonMessagePrefix(VER_PREFIX)

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------
SLASH_MIDNIGHTSENSEI1 = "/ms"
SLASH_MIDNIGHTSENSEI2 = "/midnightsensei"

SlashCmdList["MIDNIGHTSENSEI"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "" or msg == "show" then
        Call(MS.UI, "ToggleMainFrame")
        -- Print a quick tip so players know other commands exist
        print("|cff00D1FFMidnight Sensei:|r Type |cffFFFFFF/ms help|r for all commands.")
    elseif msg == "options" or msg == "config" then Call(MS.UI, "OpenOptions")
    elseif msg == "help"    or msg == "?"      then Call(MS.UI, "ShowFAQ")
    elseif msg == "credits"                    then Call(MS.UI, "ShowCredits")
    elseif msg == "report"                     then Call(MS.UI, "ShowReportPopup")
    elseif msg == "history"                    then Call(MS.UI, "ShowHistory")
    elseif msg == "leaderboard" or msg == "lb" then Call(MS.Leaderboard, "Toggle")
    elseif msg == "lb fix" then
        -- ── Beta maintenance: scan and repair leaderboard data issues ─────────
        -- Removes entries with no meaningful score data, deduplicates guild
        -- entries with score=0 and no allTimeBest, and prints a summary.
        -- Remove this command before shipping out of beta.
        local db = MidnightSenseiDB
        if not db then
            print("|cff00D1FFMidnight Sensei:|r No saved data found.")
        else
            local fixed = 0

            -- 1. Purge guild entries with zero allTimeBest and zero score
            --    (ghost entries from HELLO before any fight was completed)
            if db.guild then
                local toRemove = {}
                for name, entry in pairs(db.guild) do
                    local hasMeaningfulData = (entry.allTimeBest or 0) > 0
                        or (entry.score or 0) > 0
                        or (entry.weeklyAvg or 0) > 0
                    if not hasMeaningfulData then
                        table.insert(toRemove, name)
                    end
                end
                for _, name in ipairs(toRemove) do
                    db.guild[name] = nil
                    fixed = fixed + 1
                    print("|cff888888  Removed ghost guild entry:|r " .. name)
                end
            end

            -- 2. Scan encounter history for entries missing class/spec fields
            --    and back-fill from charName if possible (best-effort).
            if db.encounters then
                local patched = 0
                for i, enc in ipairs(db.encounters) do
                    if not enc.className or enc.className == "?" then
                        -- Can't recover class from here; just flag it
                        patched = patched + 1
                    end
                    -- Ensure encType is never nil (older saves may lack it)
                    if not enc.encType then
                        enc.encType = "normal"
                        patched = patched + 1
                    end
                end
                if patched > 0 then
                    print("|cff888888  Patched " .. patched .. " encounter record(s) with missing fields.|r")
                    fixed = fixed + patched
                end
            end

            -- 3. Report duplicates in encounter history (same timestamp within 1s)
            if db.encounters then
                local seen = {}
                local dupes = 0
                for i = #db.encounters, 1, -1 do
                    local enc = db.encounters[i]
                    local key = (enc.timestamp or 0) .. "_" .. (enc.finalScore or 0)
                    if seen[key] then
                        table.remove(db.encounters, i)
                        dupes = dupes + 1
                    else
                        seen[key] = true
                    end
                end
                if dupes > 0 then
                    print("|cff888888  Removed " .. dupes .. " duplicate encounter(s).|r")
                    fixed = fixed + dupes
                end
            end

            if fixed == 0 then
                print("|cff00D1FFMidnight Sensei:|r Leaderboard data looks clean — nothing to fix.")
            else
                print("|cff00D1FFMidnight Sensei:|r Fixed " .. fixed .. " issue(s). Reopen the leaderboard to see changes.")
                if MS.Leaderboard and MS.Leaderboard.RefreshUI then
                    MS.Leaderboard.RefreshUI()
                end
            end
        end
        if MidnightSenseiDB then
            MidnightSenseiDB.encounters = {}
            MidnightSenseiDB.stats = {}
            print("|cff00D1FFMidnight Sensei:|r Encounter history cleared.")
        end
    elseif msg == "update" then
        local v = Core.VERSION
        print("|cff00D1FFMidnight Sensei v" .. v .. "|r   -  " .. Core.TAGLINE)
        print(" ")
        print("|cffFFD700v1.2.0|r  |cff888888 -  Leaderboard Overhaul & Delve Support|r")
        print("  + Leaderboard redesigned: Social row (Party/Guild/Friends),")
        print("    Content row (Delves/Dungeons/Raids), Sort row (Week Avg/All-Time)")
        print("  + Delve tab shows personal delve run history with tier labels")
        print("  + Weekly average is now boss-encounters-only (hardcoded, not optional)")
        print("  + Weekly average fixed  -  was not persisting across reloads")
        print("  + Weekly reset now aligned to Tuesday 7am PDT (Blizzard reset)")
        print("  + BNet friends now receive scores via whisper, not just guild channel")
        print("  + Party channel spam fix for LFD/instance groups")
        print("  + Grading is now fully behavior-driven — Play Style setting removed")
        print("  + Registered in WoW Options -> AddOns panel")
        print("  + Credits panel now has About and Sources tabs")
        print("  + os.time() crash fixed (not available in WoW Lua environment)")
        print(" ")
        print("|cffFFD700v1.1.0|r  |cff888888 -  Leaderboard & Boss Tracking|r")
        print("  + Social leaderboard: Party, Guild, Friends tabs")
        print("  + Boss fight detection via ENCOUNTER_START/END events")
        print("  + Difficulty labels: LFR/Normal/Heroic/Mythic for raids,")
        print("    Normal/Heroic/Mythic/M+N for dungeons, Tier N for delves")
        print("  + Integrity checksums on leaderboard score broadcasts")
        print("  + GRM-style peer sync for score recovery after reinstall")
        print("  + Leaderboard weekly avg aligned to WoW weekly reset")
        print(" ")
        print("|cffFFD700v1.0.0|r  |cff888888 -  Initial Release|r")
        print("  + Fight grading A+ through F for all 13 classes / 39 specs")
        print("  + Talent-aware cooldown scoring (IsPlayerSpell check at fight start)")
        print("  + Per-role scoring: DPS activity, healer efficiency, tank mitigation")
        print("  + Grade history panel with trend sparkline and encounter detail")
        print("  + HUD with post-fight review button and right-click context menu")
        print("  + Midnight 12.0 compatible: UNIT_AURA replaces blocked CLEU")
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
                      " minFight=" .. (rs.minFightSeconds or 60) .. "s")
            end
        else
            print("  No rotationalSpells defined for current spec.")
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
    elseif msg == "debug delve" then
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
    else
        print("|cff00D1FFMidnight Sensei Commands:|r")
        print("  /ms               Toggle main HUD")
        print("  /ms history       Grade history & trends")
        print("  /ms lb            Social leaderboard")
        print("  /ms options       Settings panel")
        print("  /ms help          Help & FAQ")
        print("  /ms credits       Credits & about")
        print("  /ms about         Same as /ms credits")
        print("  /ms report        Report a bug on GitHub")
        print("  /ms reset         Clear fight history")
        print("  /ms update        Show changelog")
        print("  /ms debug         Current spec / class IDs")
        print("  /ms debug friends  BNet friend detection diagnostic")
        print("  /ms lb fix        [BETA] Scan and repair leaderboard data issues")
        print("  /ms debuglog clear  Clear the debug log")
    end
end

function Core.GetSpecInfoString()
    if not Core.ActiveSpec then return "No spec loaded" end
    return Core.ActiveSpec.className .. "  -  " .. Core.ActiveSpec.name
end
