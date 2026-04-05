[![Download Latest](https://img.shields.io/github/v/release/midnightstockton/MidnightSensei?include_prereleases&cacheSeconds=300)](https://github.com/midnightstockton/MidnightSensei/releases)
[![Download ZIP](https://img.shields.io/badge/Download-Addon%20ZIP-brightgreen)](https://github.com/midnightstockton/MidnightSensei/releases/latest)
![Downloads](https://img.shields.io/github/downloads/midnightstockton/MidnightSensei/total)
![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue)
![Interface](https://img.shields.io/badge/Interface-120001-blue)
![Status](https://img.shields.io/badge/Status-Beta-orange)
![Stars](https://img.shields.io/github/stars/midnightstockton/MidnightSensei?style=social)
[![Report Issue](https://img.shields.io/badge/Report-Issue-red)](https://github.com/midnightstockton/MidnightSensei/issues/new/choose)

# 🧠 Midnight Sensei  
### Real-Time Performance Coaching for World of Warcraft

Midnight Sensei is a real-time performance coaching addon designed to help you understand **how you play**, not just how much damage or healing you do.

It evaluates your gameplay during combat and translates it into **clear, actionable feedback** you can use immediately.

<img width="1999" height="636" alt="image" src="https://github.com/user-attachments/assets/16c2c42b-5950-419a-be9b-d4f2cea38bf9" />

---

## ⚠️ What This Addon Is (And Isn’t)

Midnight Sensei is **not** designed to turn you into a top-tier parser overnight.

Instead, it is meant to:

- Help **close gameplay gaps**
- Act as a **real-time reference while playing**
- Provide **immediate, actionable feedback**
- Serve as a **bridge between gameplay and deeper analysis tools**

Think of it as:

> A buffer between playing the game and diving into tools like Warcraft Logs.

More advanced tools like Warcraft Logs will always be:
- More precise  
- More granular  
- More data-rich  

Midnight Sensei focuses on:
- Speed
- clarity
- usability **in the moment**

This addon will continue to improve over time as detection and feedback systems evolve.

---

## 🎯 What This Addon Is Built For

Midnight Sensei is aimed at players who:

- Want to improve rotation and decision-making  
- Feel stuck in mid-performance ranges  
- Don’t want to dig through logs to figure out what went wrong  
- Prefer feedback that teaches instead of overwhelms  

---

## ⚙️ Core Systems Overview

### 📊 Performance Scoring Engine

| Category | What It Measures |
|----------|----------------|
| Cooldown Usage | Efficient and timely use of major abilities |
| Activity | Time spent actively casting vs idle |
| Resource Management | Overcapping and wasted resources |
| Buff / Proc Usage | Proc consumption and uptime |
| Rotational Usage | Missing key abilities entirely |
| Role Efficiency | Healing efficiency or mitigation |

Each encounter is scored and converted into a simple grade.

---

### 🏆 Grading System

| Grade | Meaning |
|------|--------|
| A+ | Exceptional |
| A  | Excellent |
| B  | Strong / On Track |
| C  | Room to Improve |
| D  | Learning Phase |
| F  | Needs Work |

Grades are designed to be **encouraging and directional**, not punishing.

---

## 🧩 Feature Breakdown

### ⚔️ Combat Analysis

- Tracks ability usage and GCD activity in real time  
- Monitors cooldown usage and expected timings  
- Detects resource overcapping (edge-triggered)  
- Evaluates proc usage and buff uptime  
- Tracks rotational abilities (even those without cooldowns)  
- Uses **player-only aura tracking (Midnight 12.0 compliant)**  

---

### 🧠 Smart Feedback System

Provides actionable insight into:

- Missed cooldowns  
- Unused rotational abilities  
- Poor uptime or proc usage  
- Resource overcapping  
- Idle time / low activity  
- Role inefficiencies  

---

### 📈 Post-Fight Review

- No intrusive popups  
- “Review Fight” button appears after combat  
- Displays:
  - Final score  
  - Grade  
  - Category breakdown  
  - Top feedback items  
  - Biggest improvement opportunity  

---

### 📜 Encounter History

- Stores last **100 encounters**
- Tracks:
  - Scores
  - Grades
  - Duration
  - Encounter type
- Includes full detail drill-down

---

## 👥 Social Leaderboard System

### 🧭 Leaderboard Tabs

| Tab | Description |
|-----|------------|
| Party | Live comparison with group |
| Guild | Tracks guild performance over time |

---

### 🧠 Data Tracked

| Field | Description |
|------|------------|
| Player Name | Character name |
| Class / Spec | Active specialization |
| Role | DPS / Healer / Tank |
| Grade | A–F rating |
| Score | 0–100 |
| Duration | Fight length |
| Encounter Type | Dungeon / Raid / Delve / World |
| Last Updated | Timestamp |

---

### 🏆 Weekly System

- Tracks rolling weekly averages  
- Resets on WoW weekly reset  
- Boss encounters prioritized  
- Rewards consistency over single performances  

---

### ⚔️ Encounter Types

| Type | Description |
|------|------------|
| Dungeon | Includes Mythic+ |
| Raid | LFR, Normal, Heroic, Mythic |
| Delve | Scenario-based content |
| World | Open-world combat |

---

### 🔐 Integrity System

- Checksum validation  
- Plausibility checks  
- Rate limiting  

---

## 🧬 Spec-Aware Coaching

- Supports all **13 classes / 39 specs**
- Includes:
  - Cooldowns
  - Rotational abilities
  - Proc tracking
  - Talent-aware logic

---

## 🧪 Commands

| Command | Description |
|--------|------------|
| `/ms show` | Show UI |
| `/ms hide` | Hide UI |
| `/ms help` | Show commands |
| `/ms faq` | Open FAQ |
| `/ms update` | Open changelog |
| `/ms verify` | Spell verification |
| `/ms verify report` | Export report |
| `/ms lb debug` | Debug leaderboard |

---

## ⚠️ Limitations (By Design)

Due to Midnight 12.0 API restrictions:

- No enemy debuff tracking  
- No full combat log parsing  
- Limited party sync in instance groups  

These are **intentional constraints**, not bugs.

---

## 🐛 How to Report Bugs

If something isn’t working correctly, reporting it properly helps fix it quickly.

### Step 1 — Use the Issue Template
Go here:  
👉 https://github.com/midnighttim/MidnightSensei/issues/new/choose

---

### Step 2 — Include the Following

Please include as much of this as possible:

**Basic Info**
- Class + Spec  
- What you were doing (raid, dungeon, target dummy, etc.)  
- Fight duration (approximate is fine)  

**What Happened**
- What did the addon say or do?  
- What did you expect instead?  

**Optional (Highly Helpful)**
- `/ms verify report` output  
- Screenshot of results screen  
- Steps to reproduce  

---

---

## 💡 Final Note

Midnight Sensei isn’t here to replace advanced tools.

It’s here to give you **fast, usable feedback while you play** so you can improve without stopping to analyze logs.

---

## ❤️ Credits

- Wowhead  
- SimulationCraft  
- Warcraft Logs  
- WoWAnalyzer  
