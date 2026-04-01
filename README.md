[![Download Latest](https://img.shields.io/github/v/release/midnightstockton/MidnightSensei?label=Download)](https://github.com/midnightstockton/MidnightSensei/releases)
[![Download ZIP](https://img.shields.io/badge/Download-Addon%20ZIP-brightgreen)](https://github.com/midnightstockton/MidnightSensei/releases/latest)
![Downloads](https://img.shields.io/github/downloads/midnightstockton/MidnightSensei/total)
![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue)
![Interface](https://img.shields.io/badge/Interface-120001-blue)
![Status](https://img.shields.io/badge/Status-Beta-orange)
![Stars](https://img.shields.io/github/stars/midnightstockton/MidnightSensei?style=social)
# 🧠 Midnight Sensei
Midnight Sensei is a real-time performance coaching addon for World of Warcraft designed to help you understand how you play, not just how much you do.

Instead of throwing raw logs or overwhelming data at you, it evaluates your gameplay during combat and translates it into clear, actionable feedback you can actually use to improve.

🎯 What This Addon Is Built For

Midnight Sensei is aimed at players who:

Want to improve their rotation and decision-making
Feel stuck in the mid-performance range (roughly 60–80 parses)
Don’t want to dig through logs to figure out what went wrong
Prefer feedback that teaches, not punishes
⚙️ Core Systems Overview
📊 Performance Scoring Engine

Your gameplay is evaluated across multiple weighted categories:

Category	What It Measures
Cooldown Usage	Are you using major abilities efficiently and on time
Activity	Are you actively casting or wasting time
Resource Management	Are you overcapping or mismanaging resources
Buff / Proc Usage	Are you properly consuming procs and maintaining buffs
Role Efficiency	Healer efficiency (overhealing), Tank mitigation uptime

Each encounter is scored and converted into an easy-to-understand grade.

🏆 Grading System
Grade	Meaning
A+	Exceptional
A	Excellent
B	Strong / On Track
C	Room to Improve
D	Learning Phase
F	Needs Work

Grades are designed to be encouraging, not punishing.

🧩 Feature Breakdown
⚔️ Combat Analysis
Tracks ability usage and GCD activity in real time
Monitors cooldown usage and expected timings
Detects resource overcapping using an edge-triggered system
Evaluates buff uptime and proc consumption
Captures fight duration, encounter context, and performance snapshot
📈 Post-Fight Review System
No intrusive popups
Review button appears after combat ends
Full breakdown of:
Score per category
Final grade
Personalized feedback
📜 Encounter History & Trends
Stores last 100 encounters
Displays:
Average score
Best / worst performance
Trend over time
Includes detailed drill-down per fight
🧠 Smart Feedback System

Feedback is dynamically generated based on performance:

Missed cooldown usage
Poor uptime on key buffs
Resource overcapping
Low activity or idle time
Inefficient healing or mitigation

The goal is to tell you what to fix and why, not just that something was wrong.

👥 Social Leaderboard System

Compare performance across:

Tab	Description
Party	Real-time comparison with current group
Guild	Tracks guild members as they log in
Friends	Tracks Battle.net friends using the addon

Features:

Weekly performance tracking
All-time best scores
Class/spec display
Online/offline tracking
Anti-tamper validation system
🔐 Integrity & Validation System

Leaderboard data includes:

Checksum validation to prevent score tampering
Rate limiting per sender
Plausibility checks (score vs fight duration)
🎮 UI & Interaction
Clean, modern HUD
Right-click context menu:
Lock / Unlock UI
Open History
Open Leaderboard
Options
Credits / FAQ
Draggable and customizable positioning
Scrollable panels with proper layout handling
🧬 Spec-Aware Coaching

Each spec includes:

Priority-based evaluation logic
Cooldown expectations
Resource thresholds
Buff / uptime targets

Data is informed by:

Icy Veins
Wowhead
SimulationCraft
Warcraft Logs patterns
🔧 Technical Highlights
System	Description
Event Bus	Internal event-driven architecture
Tick System	Lightweight periodic evaluation engine
Combat Tracking	Uses UNIT_AURA + API-safe methods
Saved Data	Stores encounters and leaderboard history
Modular Design	Separate Core, UI, Analytics, CombatLog, Leaderboard modules
🚧 Current Status (Beta)

This is an active beta release.

Known Limitations
Enemy debuff tracking is limited due to WoW API restrictions
Some specs still being expanded/refined
Proc/debuff scoring continues to evolve
🚀 Roadmap
Expanded spec coverage across all classes
Improved proc/debuff tracking logic
Advanced trend analytics
UI polish and customization options
Additional leaderboard metrics
💡 Philosophy

Midnight Sensei is not trying to replace logs.

It’s built to bridge the gap between:

“I think I’m doing okay”
and
“I understand exactly what I need to fix.”

📦 Installation
Download the release ZIP from the Releases section
Extract into:
World of Warcraft/_retail_/Interface/AddOns/
Ensure folder structure:
AddOns/
 └── MidnightSensei/
     ├── MidnightSensei.toc
     ├── Core.lua
     ├── UI.lua
Launch the game and enable the addon
🗨️ Feedback

This addon is actively evolving. Feedback, ideas, and testing are extremely valuable during this phase.

🙌 Credits

Inspired by and built using concepts from:

Icy Veins
Wowhead
SimulationCraft
Warcraft Logs
WoWAnalyzer

If you want, I can next:

add badges (downloads, version, WoW patch)
make a CurseForge version of this
or shorten this into a clean “TL;DR” header version for visibility

But this right here is a top-tier first GitHub release page.

can we also include all the leaderboard details, weekly reset dungeons, mythics, raids, delves, etc.

Absolutely, and this is a great call because your leaderboard system is honestly one of the strongest parts of what you built. I expanded your section and made it clean, detailed, and GitHub-ready so it actually shows off the depth.

You can drop this right into your README under the leaderboard section or replace it entirely.

👥 Social Leaderboard System

Midnight Sensei includes a fully integrated, real-time leaderboard system designed to motivate improvement through friendly comparison and consistent performance tracking.

🧭 Leaderboard Tabs
Tab	Description
Party	Live performance data from your current group
Guild	Persistent tracking of guild members as they log in and play
Friends	Tracks Battle.net friends using the addon during the session

Each tab updates dynamically and reflects the most recent performance data broadcast by players using the addon.

🧠 What Gets Tracked

Each leaderboard entry includes:

Field	Description
Player Name	Character name (realm-aware)
Class / Spec	Current specialization
Role	DPS, Healer, or Tank
Grade	A–F performance rating
Score	Numeric score (0–100)
Fight Duration	Length of the encounter
Encounter Type	Dungeon, Raid, Delve, or World
Last Updated	Timestamp of last performance
🏆 Weekly Performance System

The leaderboard emphasizes consistent performance, not just one good run.

Tracks a rolling weekly average per player
Automatically resets based on WoW weekly reset timing
Prioritizes sustained performance over one-time high scores
🗓 Weekly Reset Logic
Reset occurs based on WoW’s weekly cycle
Anchored to:
Tuesday 7:00 AM PDT (14:00 UTC)
Each week is assigned a unique key (YYYYMMDD) tied to reset day

This ensures:

Fair comparisons within the same weekly window
Clean separation of performance across resets
⚔️ Encounter Type Classification

Each fight is categorized automatically based on instance context:

Type	Description
Dungeon	5-player content, including Mythic+
Raid	Any raid difficulty (LFR, Normal, Heroic, Mythic)
Delve	Scenario-based delve content with tier scaling
World	Open-world combat
🗝 Mythic+ Support
Detects active keystone level
Displays as:
M+2, M+10, M+20, etc.
Stores keystone level as part of encounter context

This allows:

More accurate comparisons between runs
Context-aware performance tracking
🏰 Raid Difficulty Tracking

Raid encounters are labeled automatically:

Difficulty	Label
LFR	LFR
Normal	Normal
Heroic	Heroic
Mythic	Mythic
🕳 Delve Support
Detects delve-based content via scenario system
Extracts tier information when available

Example:

Tier 8 Delve
📊 Ranking Logic

Leaderboard sorting prioritizes:

Weekly Average Score (Primary)
All-Time Best Score (Secondary)

This ensures:

Players who perform consistently rank higher
One-off high scores don’t dominate rankings
🔐 Integrity & Anti-Tamper System

To maintain fairness, all leaderboard data is validated:

✔ Checksum Validation

Each score includes a checksum derived from:

Score
Duration
Encounter type
Character identity

Invalid or manipulated values are rejected automatically.

✔ Plausibility Checks

Scores are validated against fight duration:

Rule
High scores require minimum fight length
Extremely high scores in short fights are rejected
✔ Rate Limiting
Limits score broadcasts per player per session
Prevents spam or abuse
🔄 Real-Time Updates
Party data updates instantly during group play
Guild roster updates as members log in/out
Friends list integrates Battle.net presence
🎯 Why It Matters

The leaderboard isn’t about competing for perfection.

It’s designed to:

Encourage steady improvement
Provide context for your performance
Make progression visible and motivating
💡 Example Entry
Tim - Fury Warrior
Grade: A-
Score: 87
Dungeon: M+12
Duration: 4:32
Updated: 2m ago

If you want, next step I can:

add badges (WoW version, release version, etc.)
generate screenshots/mock UI for the README
or create a CurseForge version of this that’s a bit shorter and more “storefront” style

But this right here? This makes your addon look serious.

revise the whole description with that

Perfect, I pulled everything together into one clean, polished, GitHub-ready full description that includes your leaderboard system, all the technical depth, and still reads like it came from you.

You can paste this directly into your README or release page.

🧠 Midnight Sensei

Midnight Sensei is a real-time performance coaching addon for World of Warcraft designed to help you actually understand your gameplay and improve with purpose.

Instead of overwhelming you with logs or raw data, it evaluates your performance during combat and turns it into clear, actionable feedback you can use immediately.

This isn’t about chasing perfect parses. It’s about helping you move from “I think I’m doing okay” to “I know exactly what I need to fix.”

🎯 What This Addon Is Built For

Midnight Sensei is built for players who:

Want to improve their rotation and decision-making
Feel stuck in that mid-performance range and aren’t sure why
Don’t want to dig through logs to find answers
Prefer feedback that teaches instead of punishes
⚙️ Core Systems Overview
📊 Performance Scoring Engine

Each fight is evaluated across multiple weighted categories:

Category	What It Measures
Cooldown Usage	Are major abilities used efficiently and on time
Activity	Are you actively casting or leaving gaps
Resource Management	Are you overcapping or wasting resources
Buff / Proc Usage	Are procs consumed properly and buffs maintained
Role Efficiency	Healer overhealing, tank mitigation uptime

All of this is combined into a single score and grade.

🏆 Grading System
Grade	Meaning
A+	Exceptional
A	Excellent
B	Strong / On Track
C	Room to Improve
D	Learning Phase
F	Needs Work

Grades are intentionally encouraging and constructive, not punishing.

🧩 Feature Breakdown
⚔️ Real-Time Combat Analysis
Tracks ability usage and GCD activity
Monitors cooldown timing and expected usage
Detects resource overcapping using an edge-triggered system
Evaluates buff uptime and proc usage
Captures encounter duration and performance context
📈 Post-Fight Review System
No intrusive popups
A Review Fight button appears after combat
Full breakdown includes:
Category scores
Final grade
Smart feedback
📜 Encounter History & Trends
Stores last 100 encounters
Tracks:
Average performance
Best and worst fights
Performance trends over time
Click any fight for a full detailed breakdown
🧠 Smart Feedback System

Feedback is generated dynamically based on your gameplay:

Missed cooldown opportunities
Poor uptime on key buffs
Resource overcapping
Idle time / low activity
Inefficient healing or mitigation

It focuses on what to fix and why, not just what went wrong.

👥 Social Leaderboard System

Midnight Sensei includes a fully integrated leaderboard system designed to motivate improvement through real gameplay comparison.

🧭 Leaderboard Tabs
Tab	Description
Party	Live comparison with your current group
Guild	Tracks guild members as they log in and play
Friends	Tracks Battle.net friends using the addon
🧠 What Gets Tracked

Each player entry includes:

Field	Description
Player Name	Character name (realm-aware)
Class / Spec	Current specialization
Role	DPS, Healer, Tank
Grade	A–F rating
Score	0–100 performance score
Duration	Length of encounter
Encounter Type	Dungeon, Raid, Delve, or World
Last Updated	Time since last recorded fight
🏆 Weekly Performance System

The leaderboard emphasizes consistency over one-off performance:

Tracks a rolling weekly average
Resets automatically with WoW’s weekly reset
Prioritizes sustained performance over single high scores
🗓 Weekly Reset Timing
Based on WoW reset schedule
Tuesday 7:00 AM PDT (14:00 UTC)
Each week is tracked independently
⚔️ Encounter Classification

All encounters are automatically categorized:

Type	Description
Dungeon	5-player content, including Mythic+
Raid	LFR, Normal, Heroic, Mythic
Delve	Scenario-based delve content
World	Open-world combat
🗝 Mythic+ Support
Detects active keystone level
Displays as:
M+2, M+10, M+20, etc.
Stores keystone level as part of encounter data
🏰 Raid Difficulty Tracking
Difficulty	Label
LFR	LFR
Normal	Normal
Heroic	Heroic
Mythic	Mythic
🕳 Delve Support
Detects delve encounters via scenario system
Extracts tier level when available

Example:

Tier 8 Delve
📊 Ranking Logic

Leaderboard sorting prioritizes:

Weekly Average Score
All-Time Best Score

This rewards consistency over lucky runs.

🔐 Integrity & Anti-Tamper System

To keep the leaderboard fair:

✔ Checksum validation on all scores
✔ Plausibility checks (score vs duration)
✔ Rate limiting per player

Invalid or manipulated data is rejected automatically.

🔄 Real-Time Updates
Party updates live during gameplay
Guild updates on login/logout
Friends integrate via Battle.net presence
🧬 Spec-Aware Coaching

Each specialization includes:

Priority-based evaluation logic
Cooldown expectations
Resource thresholds
Buff and uptime targets

Data is informed by:

Icy Veins
Wowhead
SimulationCraft
Warcraft Logs patterns
🔧 Technical Highlights
System	Description
Event Bus	Internal event-driven architecture
Tick System	Lightweight periodic evaluation
Combat Tracking	API-safe aura and combat analysis
Saved Data	Stores encounter history and leaderboard data
Modular Design	Core, UI, Analytics, CombatLog, Leaderboard modules
🚧 Current Status (Beta)

This is an active beta release.

Known Limitations
Enemy debuff tracking is limited by WoW API restrictions
Some specs are still being expanded
Proc and uptime scoring continues to evolve
🚀 Roadmap
Full spec coverage across all classes
Expanded analytics and scoring accuracy
Enhanced trend analysis
UI customization improvements
Additional leaderboard metrics
💡 Philosophy

Midnight Sensei is not trying to replace logs.

It’s built to bridge the gap between:

“I think I’m doing fine”
and
“I know exactly what I need to improve.”

📦 Installation
Download MidnightSensei.zip from Releases
Extract to:
World of Warcraft/_retail_/Interface/AddOns/
Verify structure:
AddOns/
 └── MidnightSensei/
     ├── MidnightSensei.toc
     ├── Core.lua
     ├── UI.lua
Launch the game and enable the addon
🙌 Credits

Inspired by and built using concepts from:

Icy Veins
Wowhead
SimulationCraft
Warcraft Logs
WoWAnalyzer
🗨️ Feedback

This addon is actively evolving and feedback is incredibly valuable.
