local Core = MidnightSensei.Core

Core.RegisterSpec(8, {
    className = "Mage",

    -- Arcane (Midnight 12.0 PASSIVE audit — April 2026)
    -- Verified against v1.4.3 talent snapshot (90 nodes, descriptions) — FLAGGED: 2
    -- Flags: Ice Block [Causes] = self-CC effect; Arcane Orb [Grants] = Arcane Power charge.
    --   Neither is a spell-replacement pattern. No suppressIfTalent needed.
    -- Touch of the Magi 210824 was wrong ID. 321507 confirmed nodeID 102468 INACTIVE — restored
    -- Arcane Orb (153626) added as talentGated CD — nodeID 104113 INACTIVE this build
    -- Arcane Pulse (1241462) added as talentGated CD — nodeID 102439 INACTIVE this build
    -- Evocation (12051) removed — not in Arcane talent tree or spell list
    -- Arcane Surge (365350) nodeID 102449 INACTIVE in this build — talentGated
    -- Alter Time (342245) added to majorCooldowns — nodeID 62115 non-PASSIVE ACTIVE
    -- Arcane Barrage corrected 44425 → 319836 — Fire/Frost variant; 319836 confirmed Arcane spell list
    -- Arcane Missiles (5143) added to rotational — nodeID 102467 non-PASSIVE ACTIVE; Clearcasting consumer
    -- Arcane Explosion (1449) added to rotational — baseline confirmed Arcane spell list; AoE filler
    -- Clearcasting procBuff corrected 276743 → 79684 — confirmed Arcane spell list
    [1] = {
        name = "Arcane", role = "DPS",
        resourceType = 0,
        majorCooldowns = {
            { id = 365350, label = "Arcane Surge",     expectedUses = "on CD",    talentGated = true },  -- nodeID 102449 INACTIVE this build
            { id = 342245, label = "Alter Time",       expectedUses = "on CD"                       },  -- nodeID 62115 non-PASSIVE ACTIVE
            { id = 321507, label = "Touch of the Magi",expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 102468 INACTIVE (was 210824 — wrong ID)
            { id = 153626, label = "Arcane Orb",       expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 104113 INACTIVE this build
            { id = 1241462,label = "Arcane Pulse",     expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 102439 INACTIVE this build
        },
        rotationalSpells = {
            { id = 116,    label = "Arcane Blast",     minFightSeconds = 15 },  -- baseline confirmed spell list; primary charge builder
            { id = 319836, label = "Arcane Barrage",   minFightSeconds = 20 },  -- confirmed Arcane spell list (was 44425 — Fire/Frost variant)
            { id = 5143,   label = "Arcane Missiles",  minFightSeconds = 15, talentGated = true },  -- nodeID 102467 non-PASSIVE ACTIVE; Clearcasting consumer
            { id = 1449,   label = "Arcane Explosion", minFightSeconds = 20 },  -- baseline confirmed Arcane spell list; AoE filler
        },
        procBuffs = {
            { id = 79684, label = "Clearcasting", maxStackTime = 15 },  -- confirmed Arcane spell list (was 276743 — old aura ID)
        },
        priorityNotes = {
            "Build to 4 Arcane Charges with Arcane Blast before spending",
            "Arcane Barrage to dump charges and reset for mana conservation",
            "Arcane Surge at 4 charges when talented — primary burst window",
            "Touch of the Magi on cooldown when talented — detonates accumulated damage",
            "Spend Clearcasting procs on Arcane Missiles immediately",
            "Arcane Orb and Arcane Pulse on cooldown when talented",
            "Alter Time on cooldown — rewind to a better mana/charges state",
        },
        scoreWeights = { cooldownUsage = 30, procUsage = 25, activity = 25, resourceMgmt = 20 },
        sourceNote = "Midnight 12.0 verified against full Arcane talent tree snapshot v1.4.3 90 nodes (April 2026)",
    },

    -- Fire (Midnight 12.0 PASSIVE audit — April 2026)
    -- Phoenix Flames (257541) removed — not in Fire talent tree or spell list
    -- Supernova (157980) added to majorCooldowns — nodeID 101883 non-PASSIVE ACTIVE
    -- Frostfire Bolt (431044) added to majorCooldowns — nodeID 109956 non-PASSIVE ACTIVE
    -- Fireball corrected 133 → 116 — Fire spec-variant; 116 shows as "Fireball" in Fire spell list
    -- Pyroblast (11366) added to rotational — nodeID 100998 non-PASSIVE ACTIVE; Hot Streak proc consumer
    -- Scorch (2948) added to rotational — nodeID 110322 non-PASSIVE ACTIVE; filler/execute
    -- Hot Streak procBuff: 48108 (old aura ID) — VERIFY; spell list shows 195283 Hot Streak
    [2] = {
        name = "Fire", role = "DPS",
        resourceType = 0,
        majorCooldowns = {
            { id = 190319, label = "Combustion",     expectedUses = "burst windows"           },  -- nodeID 100995 non-PASSIVE ACTIVE
            { id = 153561, label = "Meteor",         expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 101021 non-PASSIVE ACTIVE
            { id = 157980, label = "Supernova",      expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 101883 non-PASSIVE ACTIVE
            { id = 431044, label = "Frostfire Bolt", expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 109956 non-PASSIVE ACTIVE
            -- Phoenix Flames (257541) removed — not in Fire talent tree or spell list
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 116,     label = "Fireball",    minFightSeconds = 15 },  -- Fire spec-variant confirmed spell list (was 133 — Arcane/Frost variant)
            { id = 108853,  label = "Fire Blast",  minFightSeconds = 15 },  -- nodeID 100989 non-PASSIVE ACTIVE; instant Hot Streak proc
            { id = 11366,   label = "Pyroblast",   minFightSeconds = 15 },  -- nodeID 100998 non-PASSIVE ACTIVE; Hot Streak proc consumer
            { id = 2948,    label = "Scorch",      minFightSeconds = 20, talentGated = true },  -- nodeID 110322 non-PASSIVE ACTIVE; filler/execute
            { id = 1254851, label = "Flamestrike", minFightSeconds = 20, talentGated = true },  -- nodeID 109409 non-PASSIVE ACTIVE; Fire spec-variant AoE
        },
        procBuffs = {
            { id = 48108, label = "Hot Streak", maxStackTime = 10 },  -- VERIFY aura ID — spell list shows 195283 Hot Streak
        },
        priorityNotes = {
            "Build Hot Streak with Fireball + Fire Blast crits",
            "Spend Hot Streak procs on Pyroblast immediately — do not sit on them",
            "Combustion for burst — align with trinkets and lust",
            "Fire Blast on cooldown to proc or extend Hot Streak",
            "Scorch as filler during execute phase and while moving when talented",
            "Flamestrike for AoE when talented",
            "Meteor and Supernova on cooldown when talented",
        },
        scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
        sourceNote = "Midnight 12.0 verified against full Fire talent tree snapshot v1.4.3 101 nodes (April 2026)",
    },

    -- Frost (Midnight 12.0 PASSIVE audit — April 2026)
    -- Icy Veins (12472) removed — not in Frost talent tree or spell list
    -- Flurry (44614) added to majorCooldowns — nodeID 62178 non-PASSIVE ACTIVE; key burst/proc cast
    -- Frostfire Bolt (431044) added to majorCooldowns — nodeID 94636 non-PASSIVE ACTIVE
    -- Ray of Frost (205021) added to majorCooldowns — nodeID 62153 non-PASSIVE ACTIVE; talentGated
    -- Dragon's Breath (31661) added to majorCooldowns — nodeID 101883 non-PASSIVE ACTIVE; talentGated
    -- Frostbolt (116) added to rotational — baseline confirmed Frost spell list; primary filler missing entirely
    -- Brain Freeze procBuff: 190446 (old aura ID) — VERIFY; talent tree shows 190447 at nodeID 62179
    -- Fingers of Frost procBuff: 44544 (old aura ID) — VERIFY; talent tree shows 112965 at nodeID 62164
    [3] = {
        name = "Frost", role = "DPS",
        resourceType = 0,
        majorCooldowns = {
            { id = 84714,  label = "Frozen Orb",    expectedUses = "on CD"           },  -- nodeID 62177 non-PASSIVE ACTIVE
            { id = 44614,  label = "Flurry",        expectedUses = "Brain Freeze procs" },  -- nodeID 62178 non-PASSIVE ACTIVE
            { id = 431044, label = "Frostfire Bolt",expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 94636 non-PASSIVE ACTIVE
            { id = 205021, label = "Ray of Frost",  expectedUses = "on CD (talent)",  talentGated = true },  -- nodeID 62153 non-PASSIVE ACTIVE
            { id = 31661,  label = "Dragon's Breath",expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 101883 non-PASSIVE ACTIVE
            -- Icy Veins (12472) removed — not in Frost talent tree or spell list
        },
        rotationalSpells = {
            { id = 116,   label = "Frostbolt", minFightSeconds = 15 },  -- baseline confirmed Frost spell list; primary filler was missing entirely
            { id = 30455, label = "Ice Lance",  minFightSeconds = 15 },  -- nodeID 62176 non-PASSIVE ACTIVE; Fingers of Frost consumer
            { id = 44614, label = "Flurry",     minFightSeconds = 15 },  -- nodeID 62178; also tracked in CDs above
        },
        procBuffs = {
            { id = 190446, label = "Brain Freeze",     maxStackTime = 15 },  -- VERIFY aura ID — talent shows 190447 nodeID 62179
            { id = 44544,  label = "Fingers of Frost", maxStackTime = 15 },  -- VERIFY aura ID — talent shows 112965 nodeID 62164
        },
        priorityNotes = {
            "Spend Brain Freeze procs with Flurry immediately — before Ice Lance for shatter",
            "Spend Fingers of Frost with Ice Lance — do not let them expire",
            "Frostbolt as primary filler — generates Brain Freeze and Fingers of Frost",
            "Frozen Orb on cooldown for burst proc generation",
            "Ray of Frost on cooldown when talented — channel for massive damage",
            "Frostfire Bolt on cooldown when talented",
        },
        scoreWeights = { cooldownUsage = 30, procUsage = 30, activity = 25, resourceMgmt = 15 },
        sourceNote = "Midnight 12.0 verified against full Frost Mage talent tree snapshot v1.4.3 100 nodes (April 2026)",
    },
})
