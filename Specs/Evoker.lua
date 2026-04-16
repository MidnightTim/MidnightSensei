local Core = MidnightSensei.Core

Core.RegisterSpec(13, {
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
        sourceNote = "Midnight 12.0 verified against full Devastation talent tree snapshot v1.4.3 122 nodes (April 2026)",
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
        sourceNote = "Midnight 12.0 verified against full Preservation talent tree snapshot v1.4.3 123 nodes (April 2026)",
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
        sourceNote = "Midnight 12.0 verified against full Augmentation talent tree snapshot v1.4.3 114 nodes (April 2026)",
    },
})
