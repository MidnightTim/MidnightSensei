local Core = MidnightSensei.Core

Core.RegisterSpec(2, {
    className = "Paladin",

    -- Holy (Midnight 12.0 PASSIVE audit — April 2026)
    -- Beacon of Light (53563) removed from uptimeBuffs — applied to target, not a self-aura
    -- Blessing of Sacrifice (6940) nodeID 81614 INACTIVE in this build — talentGated
    -- Aura Mastery (31821) added to majorCooldowns — nodeID 81567 non-PASSIVE ACTIVE
    -- Lay on Hands (633) added to majorCooldowns — nodeID 81597 non-PASSIVE ACTIVE
    -- Holy Bulwark (432459) added to majorCooldowns — nodeID 110257 non-PASSIVE ACTIVE
    -- Light of Dawn (85222) added to rotational — nodeID 81565 non-PASSIVE ACTIVE; AoE HP spender
    [1] = {
        name = "Holy", role = "HEALER",
        resourceType = 9, resourceLabel = "HOLY POWER", overcapAt = 5,
        majorCooldowns = {
            { id = 31884,  label = "Avenging Wrath",        expectedUses = "burst phases",        talentGated = true                            },  -- confirmed spell list; class talent
            { id = 375576, label = "Divine Toll",           expectedUses = "on CD",               talentGated = true                            },  -- confirmed spell list; class talent
            { id = 31821,  label = "Aura Mastery",          expectedUses = "heavy magic damage",  healerConditional = true                      },  -- nodeID 81567 non-PASSIVE ACTIVE
            { id = 86659,  label = "Guardian of Anc. Kings",expectedUses = "emergency throughput",healerConditional = true                      },  -- confirmed spell list
            { id = 633,    label = "Lay on Hands",          expectedUses = "emergencies",         healerConditional = true                      },  -- nodeID 81597 non-PASSIVE ACTIVE
            { id = 432459, label = "Holy Bulwark",          expectedUses = "on CD"                                                              },  -- nodeID 110257 non-PASSIVE ACTIVE
            { id = 6940,   label = "Blessing of Sacrifice", expectedUses = "tank busters",        healerConditional = true, talentGated = true   },  -- nodeID 81614 INACTIVE this build
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 20473, label = "Holy Shock",    minFightSeconds = 15 },  -- nodeID 81555 non-PASSIVE ACTIVE; primary HP generator
            { id = 85673, label = "Word of Glory", minFightSeconds = 20 },  -- confirmed spell list; ST HP spender
            { id = 85222, label = "Light of Dawn", minFightSeconds = 20 },  -- nodeID 81565 non-PASSIVE ACTIVE; AoE HP spender
        },
        healerMetrics = { targetOverheal = 25, targetActivity = 85, targetManaEnd = 10 },
        priorityNotes = {
            "Holy Shock on cooldown — primary Holy Power generator and heal",
            "Word of Glory and Light of Dawn to spend Holy Power — never overcap at 5",
            "Divine Toll on cooldown — generates 5 Holy Power and AoE heals",
            "Avenging Wrath during burst damage phases",
            "Aura Mastery for heavy magic damage — covers raid with Devotion Aura",
            "Lay on Hands as an emergency — do not hold it when someone will die",
        },
        scoreWeights = { cooldownUsage = 25, efficiency = 30, activity = 25, responsiveness = 20 },
        sourceNote = "Midnight 12.0 verified against full Holy talent tree 103 nodes (April 2026)",
    },

    -- Protection (Midnight 12.0 PASSIVE audit — April 2026)
    -- Avenging Wrath (31884) added to majorCooldowns — nodeID 81483 non-PASSIVE ACTIVE
    -- Divine Toll (375576) added to majorCooldowns — nodeID 110006 non-PASSIVE ACTIVE
    -- Rebuke (96231) added as isInterrupt — nodeID 81604 non-PASSIVE ACTIVE
    -- Shield of the Righteous uptimeBuff: 132403 (old aura ID) → VERIFY; spell list shows 53600/415091
    -- Crusader Strike label corrected: 35395 shows as "Blessed Hammer" in Prot spell list (spec-variant)
    -- Consecration (26573) added to rotational — confirmed spell list baseline
    -- Holy Shock (20473) added to rotational — confirmed Prot spell list baseline
    [2] = {
        name = "Protection", role = "TANK",
        resourceType = 9, resourceLabel = "HOLY POWER", overcapAt = 5,
        majorCooldowns = {
            { id = 31850,  label = "Ardent Defender",        expectedUses = "dangerous windows"   },  -- nodeID 81481 non-PASSIVE ACTIVE
            { id = 86659,  label = "Guardian of Anc. Kings", expectedUses = "emergency"           },  -- nodeID 81490 non-PASSIVE ACTIVE
            { id = 31935,  label = "Avenger's Shield",       expectedUses = "on CD"               },  -- nodeID 81502 non-PASSIVE ACTIVE
            { id = 31884,  label = "Avenging Wrath",         expectedUses = "on CD",              talentGated = true },  -- nodeID 81483; class talent
            { id = 375576, label = "Divine Toll",            expectedUses = "on CD",              talentGated = true },  -- nodeID 110006; class talent
            { id = 96231,  label = "Rebuke",                 expectedUses = "situational",  isInterrupt = true },  -- nodeID 81604 non-PASSIVE ACTIVE
        },
        uptimeBuffs = {
            { id = 132403, label = "Shield of the Righteous", targetUptime = 50 },  -- VERIFY aura ID — spell list shows 53600/415091 as cast IDs
        },
        rotationalSpells = {
            { id = 53600, label = "Shield of the Righteous", minFightSeconds = 15 },  -- confirmed spell list; HP spender + mitigation
            { id = 35395, label = "Blessed Hammer",          minFightSeconds = 15 },  -- nodeID 81469 non-PASSIVE ACTIVE; shows as "Blessed Hammer" in Prot (spec-variant of Crusader Strike)
            { id = 26573, label = "Consecration",            minFightSeconds = 15 },  -- confirmed spell list baseline; AoE damage and ground effect
            { id = 20473, label = "Holy Shock",              minFightSeconds = 20 },  -- confirmed Prot spell list baseline
        },
        tankMetrics = { targetMitigationUptime = 50 },
        priorityNotes = {
            "Shield of the Righteous to spend Holy Power — core mitigation (tracked via uptimeBuffs)",
            "Avenger's Shield on cooldown — primary damage and threat",
            "Blessed Hammer on cooldown — Holy Power generator",
            "Consecration on cooldown — AoE threat and damage",
            "Avenging Wrath and Divine Toll on cooldown for burst",
            "Ardent Defender and Guardian of Ancient Kings for heavy damage windows",
        },
        scoreWeights = { cooldownUsage = 30, mitigationUptime = 35, activity = 20, resourceMgmt = 15 },
        sourceNote = "Midnight 12.0 verified against full Protection Paladin talent tree snapshot v1.4.3 114 nodes (April 2026)",
    },

    -- Retribution (Midnight 12.0 PASSIVE audit + rotation guide — April 2026)
    -- Crusade (231895) removed — not in Ret talent tree or spell list;
    --   1253598 Crusade is PASSIVE nodeID 109369 (modifies Avenging Wrath, not castable separately)
    -- Avenging Wrath (31884) confirmed nodeID 81544 non-PASSIVE ACTIVE
    -- Wake of Ashes (255937) confirmed nodeID 81525 non-PASSIVE ACTIVE
    -- Execution Sentence (343527) confirmed nodeID 109373 non-PASSIVE INACTIVE — talentGated
    -- Divine Toll (375576) added to majorCooldowns — nodeID 109368 non-PASSIVE ACTIVE
    -- Rebuke (96231) added as isInterrupt — nodeID 110093 non-PASSIVE ACTIVE
    -- Templar's Verdict (85256) corrected → Final Verdict (383328) — 85256 shows as "Final Verdict"
    --   in Ret spell list (spec-variant rename in Midnight 12.0); nodeID 81532 non-PASSIVE ACTIVE
    -- Blade of Justice (184575) added to rotational — nodeID 81526 non-PASSIVE ACTIVE; rotation priority #8/10
    -- Divine Storm (53385) added to rotational — nodeID 81527 non-PASSIVE ACTIVE; AoE HP spender
    -- Judgment (20271) confirmed spell list ✅
    -- Art of War (406064) PASSIVE nodeID 81523 — procs reset Blade of Justice; tracked as procBuff (VERIFY)
    -- Hammer of Light — not in talent tree or spell list; not tracked until confirmed
    [3] = {
        name = "Retribution", role = "DPS",
        resourceType = 9, resourceLabel = "HOLY POWER", overcapAt = 5,
        majorCooldowns = {
            { id = 31884,  label = "Avenging Wrath",     expectedUses = "on CD",              talentGated = true },  -- nodeID 81544; class talent; rotation priority #1
            { id = 255937, label = "Wake of Ashes",      expectedUses = "at 0 HP / burst windows"  },  -- nodeID 81525 non-PASSIVE ACTIVE; rotation priority #6; generates 3 HP
            { id = 375576, label = "Divine Toll",         expectedUses = "on CD",              talentGated = true },  -- nodeID 109368; class talent; rotation priority #7
            { id = 343527, label = "Execution Sentence", expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 109373 non-PASSIVE INACTIVE
            { id = 96231,  label = "Rebuke",             expectedUses = "situational",     isInterrupt = true },  -- nodeID 110093 non-PASSIVE ACTIVE
            -- Crusade (231895) removed — not in talent tree; 1253598 is a PASSIVE modifier
        },
        rotationalSpells = {
            { id = 383328, label = "Final Verdict",  minFightSeconds = 15 },  -- nodeID 81532 non-PASSIVE ACTIVE; primary 5 HP spender (was 85256 Templar's Verdict — Midnight 12.0 rename)
            { id = 20271,  label = "Judgment",       minFightSeconds = 15 },  -- confirmed spell list; rotation priority #12
            { id = 184575, label = "Blade of Justice",minFightSeconds = 15 },  -- nodeID 81526 non-PASSIVE ACTIVE; rotation priority #8/10
            { id = 53385,  label = "Divine Storm",   minFightSeconds = 20 },  -- nodeID 81527 non-PASSIVE ACTIVE; AoE HP spender
        },
        procBuffs = {
            { id = 406064, label = "Art of War", maxStackTime = 10 },  -- PASSIVE nodeID 81523; procs reset Blade of Justice — VERIFY C_UnitAuras
        },
        priorityNotes = {
            "Avenging Wrath on cooldown — primary burst window, priority #1",
            "Execution Sentence on cooldown when talented — high priority during Avenging Wrath",
            "Build to 5 Holy Power before spending with Final Verdict — never overcap",
            "Wake of Ashes at 0 Holy Power or during burst — generates 3 Holy Power",
            "Divine Toll on cooldown — Holy Power and damage",
            "Blade of Justice on cooldown — spend Art of War procs immediately",
            "Judgment on cooldown — Holy Power generator",
            "Divine Storm as AoE finisher at 5 Holy Power",
        },
        scoreWeights = { cooldownUsage = 35, activity = 30, resourceMgmt = 25, procUsage = 10 },
        sourceNote = "Midnight 12.0 verified against full Retribution talent tree snapshot v1.4.3 107 nodes (April 2026)",
    },
})
