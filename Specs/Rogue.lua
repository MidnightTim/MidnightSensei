local Core = MidnightSensei.Core

Core.RegisterSpec(4, {
    className = "Rogue",

    -- Assassination (Midnight 12.0 PASSIVE audit — April 2026)
    -- Vendetta (79140) removed — not in Assassination talent tree or spell list
    -- Kick (1766) added as isInterrupt — confirmed Assassination spell list
    -- Envenom corrected 32645 → 196819 — Assassination spec-variant confirmed spell list
    -- Mutilate (1752) added to rotational — confirmed Assassination spell list; primary CP builder
    -- Crimson Tempest (1247227) added to rotational — nodeID 94557 non-PASSIVE ACTIVE; AoE finisher
    [1] = {
        name = "Assassination", role = "DPS",
        resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
        majorCooldowns = {
            { id = 360194, label = "Deathmark",        expectedUses = "on CD"           },  -- nodeID 90769 non-PASSIVE ACTIVE
            { id = 385627, label = "Kingsbane",        expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 90770 non-PASSIVE ACTIVE
            { id = 1766,   label = "Kick",             expectedUses = "situational",    isInterrupt = true },  -- confirmed Assassination spell list
            -- Vendetta (79140) removed — not in Assassination talent tree or spell list
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 703,    label = "Garrote",          minFightSeconds = 15 },  -- confirmed spell list; opener bleed
            { id = 1943,   label = "Rupture",          minFightSeconds = 15 },  -- confirmed spell list; core bleed
            { id = 1752,   label = "Mutilate",         minFightSeconds = 15 },  -- confirmed spell list; primary CP builder
            { id = 196819, label = "Envenom",          minFightSeconds = 20 },  -- Assassination spec-variant (was 32645 — Outlaw ID)
            { id = 1247227,label = "Crimson Tempest",  minFightSeconds = 20, talentGated = true },  -- nodeID 94557 non-PASSIVE ACTIVE; AoE finisher
        },
        priorityNotes = {
            "Maintain Garrote and Rupture on all targets — core bleed damage",
            "Mutilate to build combo points — primary builder",
            "Envenom at 4-5 combo points — primary finisher and damage amp",
            "Deathmark doubles all bleeds — use with Kingsbane for burst",
            "Crimson Tempest for AoE — keeps bleeds rolling on multiple targets",
        },
        scoreWeights = { cooldownUsage = 30, activity = 35, resourceMgmt = 25, procUsage = 10 },
        sourceNote = "Midnight 12.0 verified against full Assassination talent tree snapshot v1.4.3 103 nodes (April 2026)",
    },

    -- Outlaw (Midnight 12.0 PASSIVE audit — April 2026)
    -- Verified against v1.4.3 talent snapshot (102 nodes, descriptions) — FLAGGED: 0
    -- Roll the Bones corrected 315508 → 1214909 — confirmed Outlaw spell list
    -- Blade Rush (271877) added to majorCooldowns — nodeID 90649 non-PASSIVE ACTIVE
    -- Keep It Rolling (381989) added to majorCooldowns — nodeID 90652 non-PASSIVE ACTIVE
    -- Kick (1766) added as isInterrupt — confirmed Outlaw spell list
    -- Killing Spree (51690) added as talentGated CD — nodeID 94565 INACTIVE this build
    -- Between the Eyes corrected 199804 → 315341 — Outlaw spec-variant confirmed spell list
    -- Dispatch corrected 2098 → 196819 — Outlaw spec-variant confirmed spell list
    -- Sinister Strike (1752) added to rotational — Outlaw spec-variant; primary builder
    -- Pistol Shot (185763) added to rotational — confirmed Outlaw spell list; builder/proc spender
    [2] = {
        name = "Outlaw", role = "DPS",
        resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
        majorCooldowns = {
            { id = 13750,   label = "Adrenaline Rush",  expectedUses = "on CD"          },  -- nodeID 90659 non-PASSIVE ACTIVE
            { id = 1214909, label = "Roll the Bones",   expectedUses = "keep refreshed" },  -- confirmed Outlaw spell list (was 315508)
            { id = 13877,   label = "Blade Flurry",     expectedUses = "AoE on CD"      },  -- baseline confirmed Outlaw spell list
            { id = 271877,  label = "Blade Rush",       expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 90649 non-PASSIVE ACTIVE
            { id = 381989,  label = "Keep It Rolling",  expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 90652 non-PASSIVE ACTIVE
            { id = 51690,   label = "Killing Spree",    expectedUses = "burst windows (talent)", talentGated = true },  -- nodeID 94565 INACTIVE this build
            { id = 1766,    label = "Kick",             expectedUses = "situational",    isInterrupt = true },
        },
        rotationalSpells = {
            { id = 1752,   label = "Sinister Strike",  minFightSeconds = 15 },
            { id = 185763, label = "Pistol Shot",      minFightSeconds = 15 },
            { id = 315341, label = "Between the Eyes", minFightSeconds = 20 },
            { id = 196819, label = "Dispatch",         minFightSeconds = 20 },
        },
        priorityNotes = {
            "Keep Roll the Bones active — reroll for better buffs with Keep It Rolling",
            "Adrenaline Rush on cooldown — massive Energy regeneration burst",
            "Between the Eyes on cooldown during Adrenaline Rush for burst",
            "Sinister Strike / Pistol Shot to build combo points",
            "Dispatch at 5+ combo points — primary finisher",
            "Killing Spree for burst when talented",
            "Blade Flurry for any 2+ target situation",
        },
        scoreWeights = { cooldownUsage = 35, activity = 35, resourceMgmt = 20, procUsage = 10 },
        sourceNote = "Midnight 12.0 verified against full Outlaw talent tree snapshot v1.4.3 102 nodes (April 2026)",
    },

    -- Subtlety (Midnight 12.0 PASSIVE audit — April 2026)
    -- Verified against v1.4.3 talent snapshot (105 nodes, descriptions) — FLAGGED: 0
    -- Symbols of Death (212283) removed — not in Subtlety talent tree or spell list
    -- Kick (1766) added as isInterrupt — confirmed Subtlety spell list
    -- Nightblade (195452) removed from rotational — not in Subtlety talent tree or spell list
    -- Backstab (1752): suppressIfTalent = 200758 (Gloomblade) — Gloomblade is a choice node
    --   that replaces Backstab as the primary builder. Both are in the tree as INACTIVE in
    --   this build; only one should be tracked depending on which is talented.
    -- Goremaw's Bite (426591) added as talentGated CD — nodeID 94581 INACTIVE this build
    -- Shuriken Storm (197835) added to rotational — confirmed Sub spell list; AoE builder
    [3] = {
        name = "Subtlety", role = "DPS",
        resourceType = 4, resourceLabel = "ENERGY", overcapAt = 100,
        majorCooldowns = {
            { id = 185313, label = "Shadow Dance",   expectedUses = "burst windows"           },  -- baseline confirmed Sub spell list
            { id = 121471, label = "Shadow Blades",  expectedUses = "on CD"                   },  -- nodeID 90726 non-PASSIVE ACTIVE
            { id = 426591, label = "Goremaw's Bite", expectedUses = "on CD (talent)", talentGated = true },  -- nodeID 94581 INACTIVE this build
            { id = 1766,   label = "Kick",           expectedUses = "situational",    isInterrupt = true },
        },
        uptimeBuffs = {},
        rotationalSpells = {
            { id = 185438, label = "Shadowstrike",   minFightSeconds = 20 },  -- confirmed Sub spell list; Stealth builder
            { id = 1752,   label = "Backstab",       minFightSeconds = 15,
              suppressIfTalent = 200758 },   -- Gloomblade (200758) replaces Backstab as primary builder
            { id = 200758, label = "Gloomblade",     minFightSeconds = 15, talentGated = true },  -- choice node replacing Backstab
            { id = 196819, label = "Eviscerate",     minFightSeconds = 20 },  -- confirmed Sub spell list; primary finisher
            { id = 197835, label = "Shuriken Storm", minFightSeconds = 20 },  -- confirmed Sub spell list; AoE builder
        },
        priorityNotes = {
            "Shadow Dance for burst — spend with Shadowstrike inside every window",
            "Shadow Blades on cooldown — sustained burst and CP generation",
            "Shadowstrike inside Shadow Dance, Backstab (or Gloomblade) outside",
            "Eviscerate at 5+ combo points — primary finisher",
            "Goremaw's Bite on cooldown when talented",
            "Shuriken Storm as AoE builder at 3+ targets",
        },
        scoreWeights = { cooldownUsage = 35, activity = 40, resourceMgmt = 25 },
        sourceNote = "Midnight 12.0 verified against full Subtlety talent tree snapshot v1.4.3 105 nodes (April 2026)",
    },
})
