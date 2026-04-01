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

Core.VERSION      = "1.1.0"
Core.DISPLAY_NAME = "Midnight Sensei"   -- always use this in UI strings

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
    def("lbBossOnly",       true)    -- leaderboard weekly avg: boss encounters only (issue #6)
    def("playStyle",        "manual") -- "manual" | "assisted" — grade ceiling (issue #5)
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
Core.CREDITS = {
    { source = "Icy Veins",       url = "https://www.icy-veins.com",       desc = "Class guides and rotational priorities"    },
    { source = "Wowhead",         url = "https://www.wowhead.com",         desc = "Spell data and talent information"         },
    { source = "SimulationCraft", url = "https://www.simulationcraft.org", desc = "DPS baseline methodology and APL concepts" },
    { source = "WoWAnalyzer",     url = "https://wowanalyzer.com",         desc = "Performance analysis patterns and metrics" },
    { source = "Warcraft Logs",   url = "https://www.warcraftlogs.com",    desc = "Community performance benchmarks"          },
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
        [1] = {
            name = "Arms", role = "DPS",
            resourceType = 1, resourceLabel = "RAGE", overcapAt = 100,
            majorCooldowns = {
                { id = 227847, label = "Bladestorm",   expectedUses = "on CD"    },
                { id = 107574, label = "Avatar",       expectedUses = "on CD"    },
                { id = 262161, label = "Warbreaker",   expectedUses = "on CD"    },
            },
            uptimeBuffs = {
                { id = 208086, label = "Colossus Smash", targetUptime = 30 },
            },
            priorityNotes = {
                "Keep Colossus Smash / Warbreaker debuff active",
                "Mortal Strike on cooldown",
                "Execute during execute phase (< 20% health)",
                "Pool rage for Colossus Smash windows",
                "Bladestorm during Avatar for maximum burst",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
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
            uptimeBuffs = {
                { id = 184362, label = "Enrage", targetUptime = 60 },
            },
            priorityNotes = {
                "Keep Enrage active — Bloodthirst procs it on CD",
                "Rampage to refresh Enrage and spend rage",
                "Onslaught during Enrage for maximum damage",
                "Recklessness to align with Enrage and trinkets",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
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
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Maintain Shield Block for physical mitigation",
                "Ignore Pain to absorb incoming hits",
                "Thunder Clap on cooldown for damage reduction",
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
            healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
            priorityNotes = {
                "Beacon of Light on the tank — never let it drop",
                "Holy Shock on cooldown — reduces Holy Word CDs",
                "Use Holy Words as they come off cooldown",
                "Divine Toll for burst AoE on cooldown",
                "Infusion of Light procs: free Flash of Light — use immediately",
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
            tankMetrics = { targetMitigationUptime = 50 },
            priorityNotes = {
                "Spend Holy Power on Shield of the Righteous for mitigation",
                "Avenger's Shield on cooldown — primary threat tool",
                "Hammer of the Righteous for Holy Power generation",
                "Ardent Defender for sustained dangerous phases",
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
                { id = 255937, label = "Wake of Ashes",      expectedUses = "on CD / 0 HP"   },
                { id = 343527, label = "Execution Sentence", expectedUses = "on CD (talent)" },
            },
            priorityNotes = {
                "Build to 5 Holy Power before spending",
                "Templar's Verdict (single) / Divine Storm (AoE) as spenders",
                "Wake of Ashes: 3 Holy Power on CD",
                "Judgment debuff amplifies damage — reapply on CD",
                "Align Crusade / Avenging Wrath with trinkets",
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
        [1] = {
            name = "Beast Mastery", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 19574,  label = "Bestial Wrath",    expectedUses = "on CD"   },
                { id = 359844, label = "Call of the Wild", expectedUses = "on CD"   },
            },
            uptimeBuffs = {
                { id = 259277, label = "Barbed Shot DoT", targetUptime = 90 },
            },
            procBuffs = {
                { id = 246152, label = "Thrill of the Hunt", maxStackTime = 12 },  -- VERIFY
            },
            priorityNotes = {
                "Keep Barbed Shot rolling — maintains Frenzy on your pet",
                "Bestial Wrath on cooldown",
                "Call of the Wild for coordinated burst",
                "Kill Command on cooldown for Focus generation",
                "Never overcap Focus — spender always ready",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Beast Mastery Hunter guide",
        },

        -- Marksmanship
        [2] = {
            name = "Marksmanship", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 288613, label = "Trueshot",   expectedUses = "on CD"          },
                { id = 257044, label = "Rapid Fire", expectedUses = "on CD"          },
                { id = 260243, label = "Volley",     expectedUses = "AoE on CD"      },
            },
            procBuffs = {
                { id = 342776, label = "Precise Shots", maxStackTime = 15 },  -- VERIFY
            },
            priorityNotes = {
                "Aimed Shot on cooldown — primary spender",
                "Rapid Fire on cooldown — free cast",
                "Precise Shots procs: free Arcane/Multi-Shot immediately",
                "Trueshot for burst — align with trinkets and lust",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Marksmanship Hunter guide",
        },

        -- Survival
        [3] = {
            name = "Survival", role = "DPS",
            resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
            majorCooldowns = {
                { id = 360952, label = "Coordinated Assault", expectedUses = "burst windows" },
                { id = 259495, label = "Wildfire Bomb",       expectedUses = "on CD"         },
            },
            uptimeBuffs = {
                { id = 118253, label = "Serpent Sting", targetUptime = 90 },
            },
            priorityNotes = {
                "Maintain Serpent Sting on targets",
                "Kill Command on cooldown",
                "Wildfire Bomb on cooldown for burst",
                "Mongoose Bite during Aspect of the Eagle for stacks",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Survival Hunter guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 4 · ROGUE
    ----------------------------------------------------------------------------
    [4] = {
        className = "Rogue",

        -- Assassination
        [1] = {
            name = "Assassination", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 360194, label = "Deathmark", expectedUses = "on CD"              },
                { id = 385627, label = "Kingsbane", expectedUses = "on CD (if talented)"},
                { id = 79140,  label = "Vendetta",  expectedUses = "on CD"              },
            },
            uptimeBuffs = {
                { id = 1943,  label = "Rupture", targetUptime = 90 },
                { id = 703,   label = "Garrote", targetUptime = 90 },
            },
            priorityNotes = {
                "Maintain Rupture and Garrote on all targets",
                "Keep Envenom up for the amplify buff",
                "Spend at 4-5 combo points",
                "Deathmark doubles bleeds — use with other CDs",
            },
            scoreWeights = { cooldownUsage = 25, debuffUptime = 35, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Assassination Rogue guide",
        },

        -- Outlaw
        [2] = {
            name = "Outlaw", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 13750,  label = "Adrenaline Rush", expectedUses = "on CD"          },
                { id = 315508, label = "Roll the Bones",  expectedUses = "keep refreshed" },
                { id = 13877,  label = "Blade Flurry",    expectedUses = "AoE"            },
            },
            procBuffs = {
                { id = 315508, label = "Roll the Bones Buff", maxStackTime = 30 },
            },
            priorityNotes = {
                "Keep Roll the Bones active — reroll bad buffs",
                "Between the Eyes on cooldown during Adrenaline Rush",
                "Sinister Strike to build combo points",
                "Eviscerate at 5+ combo points",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 25, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Outlaw Rogue guide",
        },

        -- Subtlety
        [3] = {
            name = "Subtlety", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 185313, label = "Shadow Dance",     expectedUses = "burst windows" },
                { id = 212283, label = "Symbols of Death", expectedUses = "on CD"         },
                { id = 121471, label = "Shadow Blades",    expectedUses = "on CD"         },
            },
            uptimeBuffs = {
                { id = 121733, label = "Find Weakness", targetUptime = 40 },
            },
            priorityNotes = {
                "Shadow Dance for burst with Shadowstrike",
                "Symbols of Death on cooldown",
                "Maintain Nightblade for damage amp",
                "Shadow Blades for sustained burst",
            },
            scoreWeights = { cooldownUsage = 35, debuffUptime = 25, activity = 25, resourceMgmt = 15 },
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
                "Holy Words on cooldown — they reduce each other's CD",
                "Divine Hymn for raid-wide burst damage",
                "Circle of Healing on cooldown for efficiency",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Holy Priest guide",
        },

        -- Shadow
        [3] = {
            name = "Shadow", role = "DPS",
            resourceType = 13, resourceLabel = "INSANITY", overcapAt = 90,
            majorCooldowns = {
                { id = 228260, label = "Void Eruption",   expectedUses = "on CD"          },
                { id = 391109, label = "Dark Ascension",  expectedUses = "on CD (talent)" },
                { id = 263165, label = "Void Torrent",    expectedUses = "on CD"          },
                { id = 205385, label = "Shadow Crash",    expectedUses = "on CD"          },
            },
            uptimeBuffs = {
                { id = 589,   label = "Shadow Word: Pain", targetUptime = 95 },
                { id = 34914, label = "Vampiric Touch",    targetUptime = 95 },
            },
            priorityNotes = {
                "Maintain SW:Pain and Vampiric Touch on all targets",
                "Enter Voidform / Dark Ascension on cooldown",
                "Devouring Plague to spend Insanity — never overcap",
                "Mind Blast on cooldown for Insanity gen",
                "Void Torrent on CD — strong channel",
            },
            scoreWeights = { cooldownUsage = 25, debuffUptime = 30, activity = 25, resourceMgmt = 20 },
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
                "Death Strike is your healing — use on incoming damage",
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
            procBuffs = {
                { id = 59052,  label = "Killing Machine",      maxStackTime = 10 },
                { id = 51124,  label = "Rime (Howling Blast)", maxStackTime = 15 },
            },
            priorityNotes = {
                "Spend Killing Machine procs with Obliterate immediately",
                "Spend Rime procs with Howling Blast",
                "Pillar of Frost for burst — align with trinkets",
                "Obliterate on cooldown, Frost Strike to dump Runic Power",
                "Empower Rune Weapon to reset runes mid-Pillar",
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
            uptimeBuffs = {
                { id = 55078, label = "Blood Plague", targetUptime = 90 },
            },
            priorityNotes = {
                "Apply Festering Wounds with Festering Strike",
                "Pop wounds with Scourge Strike in batches",
                "Apocalypse requires 8 wounds — build before using",
                "Dark Transformation on cooldown — empowers ghoul",
                "Death Coil to dump Runic Power",
            },
            scoreWeights = { cooldownUsage = 25, debuffUptime = 30, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Unholy Death Knight guide",
        },
    },

    ----------------------------------------------------------------------------
    -- 7 · SHAMAN
    ----------------------------------------------------------------------------
    [7] = {
        className = "Shaman",

        -- Elemental
        [1] = {
            name = "Elemental", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 90,
            majorCooldowns = {
                { id = 191634, label = "Stormkeeper",    expectedUses = "on CD"           },
                { id = 198067, label = "Fire Elemental", expectedUses = "on CD (2.5 min)" },
                { id = 114050, label = "Ascendance",     expectedUses = "burst windows"   },
            },
            uptimeBuffs = {
                { id = 188389, label = "Flame Shock", targetUptime = 95 },
            },
            priorityNotes = {
                "Maintain Flame Shock for Lava Surge procs",
                "Lava Burst on cooldown — always instant with Lava Surge",
                "Stormkeeper before Lightning Bolt for empowered hits",
                "Earth Shock / Earthquake to spend Maelstrom",
                "Fire Elemental is your major CD — align with lust",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Elemental Shaman guide",
        },

        -- Enhancement
        [2] = {
            name = "Enhancement", role = "DPS",
            resourceType = 11, resourceLabel = "MAELSTROM", overcapAt = 140,
            majorCooldowns = {
                { id = 51533,  label = "Feral Spirit",  expectedUses = "on CD"          },
                { id = 114051, label = "Ascendance",    expectedUses = "burst windows"  },
                { id = 384352, label = "Doom Winds",    expectedUses = "on CD (talent)" },
            },
            uptimeBuffs = {
                { id = 188389, label = "Flame Shock", targetUptime = 90 },
            },
            procBuffs = {
                { id = 344179, label = "Maelstrom Weapon", maxStackTime = 20 },
            },
            priorityNotes = {
                "Spend Maelstrom Weapon at 5+ stacks on Lightning Bolt",
                "Stormstrike on every cooldown",
                "Flame Shock active for Hot Hand procs",
                "Feral Spirit on cooldown",
                "Doom Winds for massive burst if talented",
            },
            scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Enhancement Shaman guide",
        },

        -- Restoration
        [3] = {
            name = "Restoration", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 98008,  label = "Spirit Link Totem",    expectedUses = "dangerous stacks"   },
                { id = 108280, label = "Healing Tide Totem",   expectedUses = "raid damage"        },
                { id = 73920,  label = "Healing Rain",         expectedUses = "on CD when stacked" },
                { id = 114052, label = "Ascendance",           expectedUses = "emergency healing"  },
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Riptide rolling on injured targets (2-3 active)",
                "Healing Rain on stacked groups — high efficiency",
                "Chain Heal for group damage",
                "Spirit Link to equalize dangerous health imbalances",
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
                { id = 365350, label = "Arcane Surge",       expectedUses = "on CD"    },
                { id = 210824, label = "Touch of the Magi",  expectedUses = "on CD"    },
                { id = 12051,  label = "Evocation",          expectedUses = "low mana" },
            },
            procBuffs = {
                { id = 276743, label = "Clearcasting", maxStackTime = 15 },
            },
            priorityNotes = {
                "Build to 4 Arcane Charges before spending",
                "Arcane Surge at 4 charges for maximum damage",
                "Touch of the Magi to detonate damage window",
                "Spend Clearcasting procs on Arcane Missiles",
                "Evocation when low on mana — don't hold it",
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
            uptimeBuffs = {
                { id = 11366, label = "Ignite", targetUptime = 90 },
            },
            procBuffs = {
                { id = 48108, label = "Hot Streak", maxStackTime = 10 },
            },
            priorityNotes = {
                "Build Hot Streak with Fireball + Fire Blast crits",
                "Spend Hot Streak procs on Pyroblast immediately",
                "Combustion for burst — align with trinkets and lust",
                "Phoenix Flames to ensure crits during Combustion",
                "Keep Ignite rolling for passive damage",
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
            procBuffs = {
                { id = 190446, label = "Brain Freeze",       maxStackTime = 15 },
                { id = 44544,  label = "Fingers of Frost",   maxStackTime = 15 },
            },
            priorityNotes = {
                "Spend Brain Freeze procs with Flurry immediately",
                "Spend Fingers of Frost with Ice Lance",
                "Frozen Orb on cooldown for proc generation",
                "Icy Veins during burst windows",
                "Avoid munching procs",
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
        [1] = {
            name = "Affliction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 205180, label = "Summon Darkglare",     expectedUses = "on CD"          },
                { id = 205179, label = "Phantom Singularity",  expectedUses = "on CD (talent)" },
                { id = 278350, label = "Vile Taint",           expectedUses = "on CD (talent)" },
            },
            uptimeBuffs = {
                { id = 980,   label = "Agony",               targetUptime = 95 },
                { id = 172,   label = "Corruption",          targetUptime = 95 },
                { id = 30108, label = "Unstable Affliction",  targetUptime = 90 },
            },
            priorityNotes = {
                "Maintain Agony, Corruption, UA on all targets",
                "Malefic Rapture to spend Soul Shards — don't overcap",
                "Summon Darkglare when DoTs are fully applied",
                "Phantom Singularity + Vile Taint on cooldown",
            },
            scoreWeights = { cooldownUsage = 20, debuffUptime = 40, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Affliction Warlock guide",
        },

        -- Demonology
        [2] = {
            name = "Demonology", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 265187, label = "Summon Demonic Tyrant", expectedUses = "on CD"          },
                { id = 104316, label = "Call Dreadstalkers",    expectedUses = "on CD"          },
                { id = 264119, label = "Summon Vilefiend",      expectedUses = "on CD (talent)" },
            },
            procBuffs = {
                { id = 267102, label = "Demonic Core", maxStackTime = 20 },
            },
            priorityNotes = {
                "Build and bank imps before Demonic Tyrant",
                "Call Dreadstalkers on cooldown — core damage",
                "Spend Demonic Core procs on Demonbolt",
                "Hand of Gul'dan to summon imps",
                "Tyrant extends all pet duration — build a full army first",
            },
            scoreWeights = { cooldownUsage = 35, procUsage = 25, activity = 25, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Demonology Warlock guide",
        },

        -- Destruction
        [3] = {
            name = "Destruction", role = "DPS",
            resourceType = 7, resourceLabel = "SOUL SHARDS", overcapAt = 5,
            majorCooldowns = {
                { id = 1122,  label = "Summon Infernal",    expectedUses = "on CD"         },
                { id = 80240, label = "Havoc",              expectedUses = "cleave targets" },
            },
            uptimeBuffs = {
                { id = 348, label = "Immolate", targetUptime = 95 },
            },
            priorityNotes = {
                "Maintain Immolate on target for shard generation",
                "Chaos Bolt as shard spender — line up with cooldowns",
                "Havoc for Chaos Bolt cleave on two targets",
                "Rain of Fire for AoE — efficient at 3+ targets",
                "Summon Infernal on cooldown",
            },
            scoreWeights = { cooldownUsage = 30, debuffUptime = 25, activity = 25, resourceMgmt = 20 },
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
            tankMetrics = { targetMitigationUptime = 60 },
            priorityNotes = {
                "Maintain Ironskin Brew for stagger reduction (60%+)",
                "Purifying Brew to clear Heavy/Severe Stagger",
                "Keg Smash on cooldown — generates Brews",
                "Celestial Brew for absorb shield before big hits",
            },
            scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
            sourceNote = "Adapted from Icy Veins Brewmaster Monk guide",
        },

        -- Mistweaver
        [2] = {
            name = "Mistweaver", role = "HEALER",
            resourceType = 0,
            majorCooldowns = {
                { id = 115310, label = "Revival",             expectedUses = "raid emergency" },
                { id = 322118, label = "Invoke Yu'lon",       expectedUses = "sustained AoE" },
                { id = 116680, label = "Thunder Focus Tea",   expectedUses = "on CD"         },
            },
            healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
            priorityNotes = {
                "Keep Renewing Mist rolling on as many targets as possible",
                "Rising Sun Kick on cooldown for damage amp",
                "Vivify to proc Renewing Mist bouncing",
                "Thunder Focus Tea on CD — empowered heals",
                "Revival for emergency full-group healing",
            },
            scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
            sourceNote = "Adapted from Icy Veins Mistweaver Monk guide",
        },

        -- Windwalker
        [3] = {
            name = "Windwalker", role = "DPS",
            resourceType = 12, resourceLabel = "CHI", overcapAt = 6,
            majorCooldowns = {
                { id = 137639, label = "Storm, Earth and Fire", expectedUses = "on CD"          },
                { id = 123904, label = "Invoke Xuen",           expectedUses = "burst windows"  },
                { id = 152173, label = "Serenity",              expectedUses = "burst (talent)" },
            },
            procBuffs = {
                { id = 116768, label = "Combo Breaker: BoK", maxStackTime = 15 },
            },
            priorityNotes = {
                "Fists of Fury on cooldown — highest damage ability",
                "Rising Sun Kick on cooldown",
                "SEF charges on cooldown for sustained uptime",
                "Blackout Kick to generate Chi and deal damage",
                "Serenity / Xuen for burst — align with trinkets",
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
        [1] = {
            name = "Balance", role = "DPS",
            resourceType = 8, resourceLabel = "ASTRAL POWER", overcapAt = 90,
            majorCooldowns = {
                { id = 194223, label = "Celestial Alignment", expectedUses = "on CD"          },
                { id = 102560, label = "Incarnation: Elune",  expectedUses = "on CD (talent)" },
                { id = 191034, label = "Starfall",            expectedUses = "AoE on CD"      },
            },
            uptimeBuffs = {
                { id = 164812, label = "Moonfire", targetUptime = 90 },
                { id = 93402,  label = "Sunfire",  targetUptime = 90 },
            },
            priorityNotes = {
                "Maintain Moonfire and Sunfire on all targets",
                "Celestial Alignment / Incarnation on cooldown",
                "Starsurge to spend Astral Power during Eclipse",
                "Starfall during AoE phases",
                "Don't overcap Astral Power",
            },
            scoreWeights = { cooldownUsage = 25, debuffUptime = 30, activity = 25, resourceMgmt = 20 },
            sourceNote = "Adapted from Icy Veins Balance Druid guide",
        },

        -- Feral
        [2] = {
            name = "Feral", role = "DPS",
            resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
            majorCooldowns = {
                { id = 5217,   label = "Tiger's Fury",      expectedUses = "on CD"          },
                { id = 106951, label = "Berserk",           expectedUses = "burst windows"  },
                { id = 102543, label = "Incarnation: King", expectedUses = "on CD (talent)" },
            },
            uptimeBuffs = {
                { id = 1079, label = "Rip",  targetUptime = 90 },
                { id = 1822, label = "Rake", targetUptime = 95 },
            },
            procBuffs = {
                { id = 69369, label = "Predatory Swiftness", maxStackTime = 12 },
            },
            priorityNotes = {
                "Maintain Rip and Rake on all targets",
                "Tiger's Fury on cooldown — energy + damage buff",
                "Berserk for burst — combo point gen spikes",
                "Shred to build combo points, Ferocious Bite to spend",
            },
            scoreWeights = { cooldownUsage = 25, debuffUptime = 35, activity = 25, resourceMgmt = 15 },
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
            tankMetrics = { targetMitigationUptime = 70 },
            priorityNotes = {
                "Keep Ironfur up constantly with Rage (70%+ target)",
                "Mangle on cooldown for Rage generation",
                "Frenzied Regeneration for healing in high damage windows",
                "Barkskin for magic damage, Survival Instincts emergencies",
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
            healerMetrics = { targetOverheal = 35, targetActivity = 75, targetManaEnd = 15 },
            priorityNotes = {
                "Keep Rejuvenation on injured targets — HoT foundation",
                "Wild Growth on cooldown for group AoE healing",
                "Flourish to extend all active HoTs mid-damage",
                "Swiftmend for emergency instant heal",
                "Tranquility for heavy sustained raid damage",
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
            procBuffs = {
                { id = 337567, label = "Furious Gaze",   maxStackTime = 8  },
                { id = 389860, label = "Unbound Chaos",  maxStackTime = 12 },
            },
            priorityNotes = {
                "Immolation Aura on cooldown for Fury generation",
                "Eye Beam on cooldown — core damage and Fury",
                "Blade Dance / Death Sweep on cooldown",
                "Chaos Strike to spend Fury — don't overcap",
                "Metamorphosis for burst — align with trinkets",
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
            priorityNotes = {
                "Fire Breath and Eternity Surge on cooldown",
                "Dragonrage for burst — maximize empowered cast rate",
                "Living Flame as filler — don't cap Essence",
                "Disintegrate as strong filler channel",
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
                { id = 363534, label = "Rewind",             expectedUses = "emergency"     },
                { id = 355936, label = "Dream Breath",       expectedUses = "on CD AoE"     },
                { id = 370960, label = "Emerald Communion",  expectedUses = "sustained AoE" },
                { id = 374348, label = "Tip the Scales",     expectedUses = "burst ramp"    },
            },
            healerMetrics = { targetOverheal = 30, targetActivity = 80, targetManaEnd = 10 },
            priorityNotes = {
                "Reversion and Living Flame as core filler heals",
                "Dream Breath on cooldown for AoE healing",
                "Emerald Blossom for group-wide healing efficiency",
                "Echo to amplify upcoming high-throughput spells",
                "Rewind is a true emergency — save for near-wipes",
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
            uptimeBuffs = {
                { id = 395152, label = "Ebon Might", targetUptime = 70 },
            },
            priorityNotes = {
                "Ebon Might on cooldown — core party buff",
                "Prescience before burst cooldowns to amplify allies",
                "Upheaval and Eruption for personal damage",
                "Breath of Eons for peak burst — aligns with lust",
                "Maintain Ebon Might uptime at 70%+ for max support",
            },
            scoreWeights = { cooldownUsage = 35, debuffUptime = 30, activity = 25, resourceMgmt = 10 },
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
            print("|cff00D1FFMidnight Sensei:|r " .. sname ..
                  " has v" .. theirVer .. " (you have " .. Core.VERSION ..
                  "). Type /ms update.")
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
    if     msg == "" or msg == "show" then Call(MS.UI, "ToggleMainFrame")
    elseif msg == "options" or msg == "config" then Call(MS.UI, "OpenOptions")
    elseif msg == "help"    or msg == "?"      then Call(MS.UI, "ShowFAQ")
    elseif msg == "credits"                    then Call(MS.UI, "ShowCredits")
    elseif msg == "history"                    then Call(MS.UI, "ShowHistory")
    elseif msg == "leaderboard" or msg == "lb" then Call(MS.Leaderboard, "Toggle")
    elseif msg == "reset" then
        if MidnightSenseiDB then
            MidnightSenseiDB.encounters = {}
            MidnightSenseiDB.stats = {}
            print("|cff00D1FFMidnight Sensei:|r Encounter history cleared.")
        end
    elseif msg == "update" then
        print("|cff00D1FFMidnight Sensei v" .. Core.VERSION .. " — What's new:|r")
        print("  · Full CLEU tracking: debuff uptime, proc usage, healer overhealing")
        print("  · All 13 classes / 39 specs in spec database")
        print("  · Grade history & trending panel (/ms history)")
        print("  · Social leaderboard: Party / Guild / Friends (/ms lb)")
        print("  · Right-click context menus on history entries")
        print("  · Display name fixed: Midnight Sensei (with space)")
    elseif msg == "debug" then
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
    else
        print("|cff00D1FFMidnight Sensei Commands:|r")
        print("  /ms               Toggle main window")
        print("  /ms history       Grade history & trending")
        print("  /ms leaderboard   Social leaderboard (lb also works)")
        print("  /ms options       Settings")
        print("  /ms credits       Attribution")
        print("  /ms reset         Clear encounter history")
        print("  /ms update        Show changelog")
        print("  /ms debug         Current spec info")
    end
end

function Core.GetSpecInfoString()
    if not Core.ActiveSpec then return "No spec loaded" end
    return Core.ActiveSpec.className .. " — " .. Core.ActiveSpec.name
end
