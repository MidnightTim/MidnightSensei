## Midnight Sensei
[![Version](https://img.shields.io/github/v/release/MidnightTim/MidnightSensei?include_prereleases&label=version&logo=github&sort=semver&cacheSeconds=300)](https://github.com/MidnightTim/MidnightSensei/releases/latest)
[![WoW Version](https://img.shields.io/badge/WoW-Midnight%2012.0.5-purple)](https://github.com/MidnightTim/MidnightSensei)
[![Classes](https://img.shields.io/badge/classes-13-success)](https://github.com/MidnightTim/MidnightSensei)
[![Specs](https://img.shields.io/badge/specs-39-success)](https://github.com/MidnightTim/MidnightSensei)
[![Type](https://img.shields.io/badge/type-Combat%20Performance%20Coaching-orange)](https://github.com/MidnightTim/MidnightSensei)
[![Status](https://img.shields.io/badge/status-Active%20Development-brightgreen)](https://github.com/MidnightTim/MidnightSensei)
[![Issues](https://img.shields.io/github/issues/MidnightTim/MidnightSensei?label=issues&logo=github)](https://github.com/MidnightTim/MidnightSensei/issues)
[![Last Commit](https://img.shields.io/github/last-commit/MidnightTim/MidnightSensei?label=last%20commit&logo=github)](https://github.com/MidnightTim/MidnightSensei/commits/main)
[![CurseForge](https://img.shields.io/curseforge/dt/1508666?label=curseforge)](https://www.curseforge.com/wow/addons/midnight-sensei)
[![Wago](https://img.shields.io/badge/wago-available-blue)](https://addons.wago.io/addons/midnightsensei)
[![Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?logo=discord&logoColor=white)](https://discord.gg/QqV3umH8pN)

Combat performance coaching for all 13 classes, grade your fights A+ to F.

## What is Midnight Sensei?

Midnight Sensei is a World of Warcraft addon built to help you review how you actually played in combat, not just whether the pull ended in a kill. It grades your fights, tracks major cooldown usage, checks rotational habits, watches for wasted resources, and gives you readable post-fight feedback so you can improve without constantly needing to leave the game and dig through logs.

This addon is built around practical coaching. The goal is not to bury you in noise, it is to show you where your habits are strong, where they are slipping, and what you should tighten up next.

**Author:** Midnight - Thrall (US)

## Current support

Midnight Sensei currently supports:

- All **13 classes**
- All **40 specs**
- DPS, healer, and tank role-aware scoring
- Boss encounter tracking for **Delves**, **Dungeons**, and **Raids**
- Social score sharing through **Party**, **Guild**, and **Friends**
- Personal all-time boss best tracking through the **Boss Board**
- Debug and export tooling for spec verification and issue reporting

## Core features

### Fight grading

Every qualifying combat encounter is scored and graded from **A+ to F**.

Depending on your spec and role, Midnight Sensei can evaluate things like:

- Major cooldown usage
- Rotational spell usage
- Activity and cast consistency
- Resource management and overcapping
- Self-buff uptime
- Proc usage speed
- Healer efficiency and overheal handling

A fight shorter than **15 seconds** is not recorded.

### Post-fight feedback

After combat, Midnight Sensei gives you readable feedback that points to the biggest areas to improve. Instead of drowning you in raw numbers, it highlights practical issues like missed cooldowns, low activity, poor proc handling, weak rotational coverage, or overcapping.

### HUD and review flow

The addon includes a HUD that shows your last result, your score, and your current spec. After a fight, you will get a **Review Fight** option so you can inspect what happened right in game.

The HUD can be set to:

- Always visible
- In combat only
- Hidden until manually shown

You can also right-click the HUD for quick access to major features.

## Boss tracking and content awareness

Midnight Sensei detects boss encounters through the encounter system and separates boss content from normal combat. This keeps real boss pulls from getting mixed in with trash, dummy testing, or random world combat.

The addon is content-aware and tracks context for:

- **Delves**
- **Dungeons**
- **Raids**
- Mythic+ key level, where available
- Difficulty labels such as LFR, Normal, Heroic, Mythic, and M+ levels

Boss fights are tagged and can be filtered in history so you can focus on actual encounter performance.

Fight history distinguishes **boss kills** from **wipes** with [K] and [W] tags. Stats such as averages and personal bests are calculated from kills only, so wipe data does not skew your numbers.

## Leaderboard

Midnight Sensei includes a social leaderboard with views for:

- **Party**
- **Guild**
- **Friends**

Highlights include:

- Weekly average tracking
- All-time best tracking
- Boss-only weekly average logic
- Guild persistence across sessions
- Local self-entry refresh from your own history
- Content-specific tabs so raid and dungeon runs do not bleed into each other
- Mythic+ key level display where available
- Direct player query support with `/ms friend Name` or `/ms friend Name-Realm`

The leaderboard is designed for lightweight social comparison and progress tracking, not as a replacement for full combat logging platforms.

## Boss Board

The **Boss Board** is a personal all-time boss best tracker.

Boss Board features include:

- Separate tabs for **Delves**, **Dungeons**, and **Raids**
- Tracks your **highest score per boss encounter**
- Sortable columns for **Date**, **Character**, **Spec**, **Diff/Boss**, and **Score**
- Shared snapshot recovery support in the account-wide database
- Live refresh when new boss results are recorded
- Quick access from slash commands, the HUD menu, and minimap controls

If you want a clean view of your best boss pulls instead of just a rolling encounter history, Boss Board is now one of the main addon features.

## Debug and verification tools

Midnight Sensei includes built-in debugging tools to make spec validation and issue reporting easier.

Current tools include:

- **Verify Mode**
- **Verify Report** export
- **Talent Snapshot** export
- **Spell Snapshot** export
- Boss Board ingest and recovery tools
- Version and zone debugging
- Rotational spell validation support
- **Verify History + Compare window** — fight snapshots saved automatically on combat end; side-by-side panel to compare any two pulls

These tools are especially useful when validating a new spec pass, checking talent-gated abilities, or troubleshooting a grading issue after a patch.

## Rotation data source

Spec rotation priorities and spell tracking are validated against **[Archon.gg](https://www.archon.gg)** top parse data for Midnight 12.0 Mythic+. Archon data reflects how top-ranked players actually play each spec in live content, including the exact spell IDs that fire in combat — which frequently differ from spellbook IDs in Midnight 12.0.

Secondary sources including Wowhead, Warcraft Logs, and SimulationCraft are used for spell node IDs, talent tree structure, and methodology reference.

All tracked spell IDs are confirmed through session log verification before changes are applied. When a combat ID diverges from the spellbook ID, the correct ID is captured through live `UNIT_SPELLCAST_SUCCEEDED` output rather than assumed from tooltips.

## Midnight 12.0 restrictions

Blizzard restricted enemy unit aura reads in Midnight 12.0.

That means Midnight Sensei cannot reliably score enemy target debuffs the same way older versions of the game allowed. Effects such as target-side debuffs may still appear as guidance in notes or priority feedback, but they are **not scored directly** unless the game provides a safe way to track them.

A separate restriction also affects player self-buff aura scanning. Midnight 12.0 blocks spell ID comparisons on aura table data when addon code is active, which caused error spam and made aura-based uptime tracking silently non-functional. As of v1.5.5, self-buff uptime tracking no longer uses aura scanning — it uses cast events instead, which are not affected by this restriction. Player self-buff uptime continues to be scored normally.

What still works normally:

- Player self-buffs
- Cooldown usage
- Rotational spell tracking
- Resource tracking
- Proc handling
- Boss encounter detection

Because of these restrictions, some specs receive neutral handling in places where aura-based tracking would otherwise be required.

## How grading works

Midnight Sensei does not use one universal score formula for every spec. It uses role-aware and spec-aware logic.

In general:

- DPS specs are scored around activity, cooldown usage, rotation, buffs, procs, and resource efficiency
- Healers include healing efficiency and overheal-sensitive logic
- Tanks use role-appropriate handling instead of pure DPS logic
- Talent-aware scoring means spells are only evaluated when you actually have them learned

If you do not have a talent selected, Midnight Sensei does not score that spell against you.

## Installation

1. Download the latest release.
2. Extract the addon folder into your World of Warcraft AddOns directory.
3. Confirm the folder is named `MidnightSensei`.
4. Launch or reload the game.
5. Use `/ms show` to open the HUD.

Typical path:

`World of Warcraft\_retail_\Interface\AddOns\MidnightSensei`

## Slash commands

### Main commands

- `/ms show` - Show the HUD
- `/ms hide` - Hide the HUD
- `/ms history` - Open grade history and trending
- `/ms lb` - Open the social leaderboard
- `/ms lb remove` - Remove a player from the guild leaderboard
- `/ms options` - Open settings
- `/ms faq` - Open the help panel
- `/ms update` - View changelog
- `/ms credits` - Credits and about
- `/ms report` - Bug report guidance
- `/ms reset` - Clear fight history
- `/ms verify` - Toggle spell ID verification mode
- `/ms debug` - Show current spec and class debug info

### Common debug helpers

- `/ms verify report` - Export a verification report
- `/ms debug talents` - Export the active talent snapshot
- `/ms debug spells` - Export the known spell snapshot
- `/ms debug auras` - Dump all active player buff IDs for aura identification
- `/ms debug bossboard ingest` - Seed Boss Board from existing encounter history
- `/ms debug fixname` - Fix all stored character names after a rename (grade history, review fights, Boss Board)
- `/ms friend Name` - Query a player directly
- `/ms friend Name-Realm` - Query a cross-realm player directly
- `/ms bossboard` - Open Boss Board
- `/ms bb` - Open Boss Board

## Minimap controls

- **Left-click** - Toggle HUD
- **Right-click** - Open Leaderboard
- **Ctrl + Right-click** - Open Boss Board
- **Shift + Right-click** - Open Options

## In-game panels

Midnight Sensei includes multiple in-game panels so you can use it without extra setup:

- HUD
- Encounter detail review
- Grade history and trends
- Social leaderboard
- Boss Board
- Options panel
- Help and FAQ panel
- Credits and changelog panel
- Debug tools window

The addon also registers in the game's AddOns settings panel.

## Who this addon is for

Midnight Sensei is meant for players who want useful feedback in the moment.

That includes:

- Players learning a new spec
- Returning players rebuilding habits
- People who want better cooldown discipline
- Players who want immediate post-fight feedback without leaving the game
- Guilds and friend groups who want lightweight comparison and progress tracking

It is not trying to replace Warcraft Logs or other deep analysis tools. It is trying to make improvement visible and actionable **inside the game**.

## Recent highlights

- **Archon.gg adopted as primary rotation source** — spec ability tracking and spell IDs validated against top-ranked Mythic+ parse data for Midnight 12.0; confirmed through live session logs (v1.5.9)
- **Rogue full spec audit** — all three primary builder IDs (Backstab, Mutilate, Sinister Strike) were wrong in Midnight 12.0 and have been corrected; Envenom, Rupture, and Dispatch also fixed; missing abilities added across all three specs (v1.5.9)
- **Death Knight full spec audit** — rotation gaps filled across all three specs via Archon.gg: Unholy, Frost, and Blood all received corrections and new ability tracking (v1.5.9)
- **Verify history and compare window** — per-fight verify snapshots saved automatically on combat end; side-by-side compare panel for reviewing any two pulls at once (v1.5.7)
- **Self-buff uptime tracking rewritten** — aura scanning for player buffs was blocked by Midnight 12.0 taint restrictions and has been fully replaced with cast-event-based tracking (v1.5.5)
- **Kill and wipe distinction** — fight history tags boss kills [K] and wipes [W]; averages, bests, and leaderboards use kills only (v1.4.11)
- **Alt spell ID support** — abilities that fire different combat IDs under hero talent paths are routed to the correct tracking entry via the `altIds` system (v1.4.13+)
- **Talent-gated spell suppression** — replacement talents automatically suppress the ability they replace so unused CDs are never penalised incorrectly (v1.4.4+)

## Reporting issues

If something looks off, especially after a class update or patch, use the built-in debug and export tools first. Verify reports, spell exports, and talent exports make it much easier to identify whether the issue is missing spec data, a missing spell ID, a talent gate problem, or a game API limitation.

- GitHub Issues: https://github.com/MidnightTim/MidnightSensei/issues
- Discord: https://discord.gg/QqV3umH8pN

## Final note

Midnight Sensei is built around practical feedback and steady improvement. As the game changes, the addon continues to evolve with spec updates, scoring improvements, UI additions, and better recovery and debugging tools.

If you want an in-game coach that helps you understand your habits pull by pull, that is exactly what Midnight Sensei is built to do.

