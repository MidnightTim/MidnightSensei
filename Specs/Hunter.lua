local Core = MidnightSensei.Core

Core.RegisterSpec(3, {
    className = "Hunter",

    -- Beast Mastery (Midnight 12.0 PASSIVE audit — April 2026)
    -- Call of the Wild (359844) removed — not in BM talent tree or spell list
    -- Thrill of the Hunt (246152) removed from procBuffs — not in talent tree or spell list
    -- Counter Shot (147362) added as isInterrupt — nodeID 102292 non-PASSIVE ACTIVE
    -- Cobra Shot (193455) added to rotational — nodeID 102354 non-PASSIVE ACTIVE; primary filler/Focus dump
    -- Black Arrow (466930) added to rotational — nodeID 109961 non-PASSIVE ACTIVE; new Midnight ability
    -- Wild Thrash (1264359) added to rotational — nodeID 102363 non-PASSIVE ACTIVE
    [1] = {
        name = "Beast Mastery", role = "DPS",
        resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
        majorCooldowns = {
            { id = 19574,  label = "Bestial Wrath",  expectedUses = "on CD"   },  -- nodeID 102340 non-PASSIVE ACTIVE
            { id = 147362, label = "Counter Shot",   expectedUses = "situational", isInterrupt = true },  -- nodeID 102292 non-PASSIVE ACTIVE
            -- Call of the Wild (359844) removed — not in BM talent tree or spell list
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 34026,   label = "Kill Command",  minFightSeconds = 15 },  -- nodeID 102346 non-PASSIVE ACTIVE
            { id = 217200,  label = "Barbed Shot",   minFightSeconds = 15 },  -- nodeID 102377 non-PASSIVE ACTIVE
            { id = 193455,  label = "Cobra Shot",    minFightSeconds = 15 },  -- nodeID 102354 non-PASSIVE ACTIVE; Focus dump/filler
            { id = 466930,  label = "Black Arrow",   minFightSeconds = 20, talentGated = true },  -- nodeID 109961 non-PASSIVE ACTIVE
            { id = 1264359, label = "Wild Thrash",   minFightSeconds = 20, talentGated = true },  -- nodeID 102363 non-PASSIVE ACTIVE
        },
        priorityNotes = {
            "Keep Barbed Shot rolling to maintain Frenzy stacks on your pet",
            "Kill Command on cooldown — primary Focus spender and damage",
            "Bestial Wrath on cooldown — aligns with pet Frenzy stacks",
            "Cobra Shot to dump Focus — never overcap at 100",
            "Black Arrow and Wild Thrash on cooldown when talented",
        },
        scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
        sourceNote = "Midnight 12.0 verified against full BM Hunter talent tree snapshot v1.4.3 104 nodes (April 2026)",
    },

    -- Marksmanship (Midnight 12.0 PASSIVE audit — April 2026)
    -- Precise Shots (342776) removed from procBuffs — not in MM talent tree or spell list
    -- Counter Shot (147362) added as isInterrupt — nodeID 102402 non-PASSIVE ACTIVE
    -- Arcane Shot (185358) added to rotational — baseline confirmed spell list; primary Focus spender
    [2] = {
        name = "Marksmanship", role = "DPS",
        resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
        majorCooldowns = {
            { id = 288613, label = "Trueshot",   expectedUses = "on CD"     },  -- nodeID 103947 non-PASSIVE ACTIVE
            { id = 257044, label = "Rapid Fire", expectedUses = "on CD"     },  -- nodeID 103961 non-PASSIVE ACTIVE
            { id = 260243, label = "Volley",     expectedUses = "AoE on CD" },  -- nodeID 103956 non-PASSIVE ACTIVE
            { id = 147362, label = "Counter Shot", expectedUses = "situational", isInterrupt = true },  -- nodeID 102402 non-PASSIVE ACTIVE
            -- Precise Shots (342776) removed — not in talent tree or spell list
        },
        rotationalSpells = {
            { id = 19434,  label = "Aimed Shot",  minFightSeconds = 20 },  -- nodeID 103982 non-PASSIVE ACTIVE
            { id = 185358, label = "Arcane Shot", minFightSeconds = 15 },  -- baseline confirmed spell list; Focus spender
        },
        priorityNotes = {
            "Aimed Shot on cooldown — primary Focus spender and damage",
            "Rapid Fire on cooldown — empowered burst cast",
            "Arcane Shot to dump Focus — never overcap at 100",
            "Volley for AoE on cooldown at 3+ targets",
            "Trueshot for burst — align with trinkets and lust",
        },
        scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
        sourceNote = "Midnight 12.0 verified against full MM Hunter talent tree snapshot v1.4.3 103 nodes (April 2026)",
    },

    -- Survival (Midnight 12.0 PASSIVE audit — April 2026)
    -- Coordinated Assault (360952) removed — not in Survival talent tree or spell list
    -- Kill Command corrected 34026 (BM ID) → 259489 — nodeID 102255 non-PASSIVE ACTIVE; Survival spec-variant
    -- Mongoose Bite (259387) removed — not in Survival talent tree or spell list
    -- Muzzle (187707) added as isInterrupt — nodeID 79837 non-PASSIVE ACTIVE; confirmed spell list
    -- Raptor Strike (186270) added to rotational — nodeID 102262 non-PASSIVE ACTIVE; confirmed spell list
    -- Takedown (1250646) added to rotational — nodeID 109323 non-PASSIVE ACTIVE; confirmed spell list
    -- Boomstick (1261193) added to rotational — nodeID 109324 non-PASSIVE ACTIVE; confirmed spell list
    -- Flamefang Pitch (1251592) kept out — nodeID 102252 non-PASSIVE INACTIVE in this build
    [3] = {
        name = "Survival", role = "DPS",
        resourceType = 3, resourceLabel = "FOCUS", overcapAt = 100,
        majorCooldowns = {
            { id = 259495, label = "Wildfire Bomb", expectedUses = "on CD"        },  -- nodeID 102264 non-PASSIVE ACTIVE
            { id = 187707, label = "Muzzle",        expectedUses = "situational", isInterrupt = true },  -- nodeID 79837 non-PASSIVE ACTIVE
            -- Coordinated Assault (360952) removed — not in Survival talent tree or spell list
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 259489,  label = "Kill Command",  minFightSeconds = 15 },  -- nodeID 102255 non-PASSIVE ACTIVE (Survival spec-variant; was 34026 BM ID)
            { id = 186270,  label = "Raptor Strike", minFightSeconds = 15 },  -- nodeID 102262 non-PASSIVE ACTIVE
            { id = 259495,  label = "Wildfire Bomb", minFightSeconds = 20 },  -- also rotational between CD windows
            { id = 1250646, label = "Takedown",      minFightSeconds = 20, talentGated = true },  -- nodeID 109323 non-PASSIVE ACTIVE
            { id = 1261193, label = "Boomstick",     minFightSeconds = 20, talentGated = true },  -- nodeID 109324 non-PASSIVE ACTIVE
        },
        priorityNotes = {
            "Wildfire Bomb on cooldown — highest priority damage ability",
            "Kill Command on cooldown — primary builder",
            "Raptor Strike to spend Focus — never overcap at 100",
            "Takedown and Boomstick on cooldown when talented",
        },
        scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
        sourceNote = "Midnight 12.0 verified against full Survival Hunter talent tree snapshot v1.4.3 99 nodes (April 2026)",
    },
})
