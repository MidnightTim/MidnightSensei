[![Download Latest](https://img.shields.io/github/v/release/midnightstockton/MidnightSensei?label=Download)](https://github.com/midnightstockton/MidnightSensei/releases)
[![Download ZIP](https://img.shields.io/badge/Download-Addon%20ZIP-brightgreen)](https://github.com/midnightstockton/MidnightSensei/releases/latest)
![Downloads](https://img.shields.io/github/downloads/midnightstockton/MidnightSensei/total)
![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue)
![Interface](https://img.shields.io/badge/Interface-120001-blue)
![Status](https://img.shields.io/badge/Status-Beta-orange)
![Stars](https://img.shields.io/github/stars/midnightstockton/MidnightSensei?style=social)
[![Report Issue](https://img.shields.io/badge/Report-Issue-red)](https://github.com/midnightstockton/MidnightSensei/issues/new/choose)

# 🧠 Midnight Sensei  
### Real-time Performance Coaching for World of Warcraft

Midnight Sensei is a real-time performance coaching addon for World of Warcraft designed to help you understand how you play, not just how much you do.

Instead of throwing raw logs or overwhelming data at you, it evaluates your gameplay during combat and translates it into clear, actionable feedback you can actually use to improve.
<img width="1973" height="704" alt="image" src="https://github.com/user-attachments/assets/bde8245b-3df9-4ecd-b248-4a9f5fcee408" />

---

## 🎯 What This Addon Is Built For

Midnight Sensei is aimed at players who:

- Want to improve their rotation and decision-making  
- Feel stuck in the mid-performance range (roughly 60–80 parses)  
- Don’t want to dig through logs to figure out what went wrong  
- Prefer feedback that teaches, not punishes  

---

## ⚙️ Core Systems Overview

### 📊 Performance Scoring Engine

| Category | What It Measures |
|----------|----------------|
| Cooldown Usage | Efficient and timely use of major abilities |
| Activity | Time spent actively casting vs idle |
| Resource Management | Overcapping or wasted resources |
| Buff / Proc Usage | Proper proc usage and uptime |
| Role Efficiency | Healing efficiency or tank mitigation |

Each encounter is scored and converted into an easy-to-understand grade.

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

Grades are designed to be encouraging, not punishing.

---

## 🧩 Feature Breakdown

### ⚔️ Combat Analysis

- Tracks ability usage and GCD activity in real time  
- Monitors cooldown usage and expected timings  
- Detects resource overcapping using an edge-triggered system  
- Evaluates buff uptime and proc consumption  
- Captures fight duration and performance context  

---

### 📈 Post-Fight Review

- No intrusive popups  
- "Review Fight" button appears after combat  
- Includes:
  - Category scores  
  - Final grade  
  - Personalized feedback  

---

### 📜 Encounter History & Trends

- Stores last 100 encounters  
- Tracks:
  - Average score  
  - Best / worst performance  
  - Trends over time  
- Full drill-down per fight  

---

### 🧠 Smart Feedback System

Provides insight into:

- Missed cooldown usage  
- Poor buff uptime  
- Resource overcapping  
- Low activity or idle time  
- Inefficient healing or mitigation  

---

## 👥 Social Leaderboard System

### 🧭 Leaderboard Tabs

| Tab | Description |
|-----|------------|
| Party | Live comparison with current group |
| Guild | Tracks guild members as they log in |

---

### 🧠 Data Tracked

| Field | Description |
|------|------------|
| Player Name | Character name |
| Class / Spec | Current specialization |
| Role | DPS, Healer, Tank |
| Grade | A–F rating |
| Score | 0–100 score |
| Duration | Fight length |
| Encounter Type | Dungeon, Raid, Delve, World |
| Last Updated | Time since last fight |

---

### 🏆 Weekly System

- Tracks rolling weekly averages  
- Resets on WoW weekly reset  
- Rewards consistency over one-time performance  

---

### ⚔️ Encounter Types

| Type | Description |
|------|------------|
| Dungeon | Includes Mythic+ |
| Raid | LFR, Normal, Heroic, Mythic |
| Delve | Scenario-based content |
| World | Open-world combat |

---

### 🗝 Mythic+ Support

- Detects keystone level  
- Displays as: M+2, M+10, M+20  
- Stores level with encounter data  

---

### 🏰 Raid Difficulty Tracking

| Difficulty | Label |
|------------|------|
| LFR | LFR |
| Normal | Normal |
| Heroic | Heroic |
| Mythic | Mythic |

---

### 🔐 Integrity System

- Checksum validation  
- Plausibility checks  
- Rate limiting  

---

## 🧬 Spec-Aware Coaching

Each spec includes:

- Priority-based evaluation  
- Cooldown expectations  
- Resource thresholds  
- Buff uptime targets  

---

## 🚧 Current Status

This is a beta release.

### Known Limitations

- Enemy debuff tracking limited by WoW API  
- Some specs still being expanded  
- Scoring continues to evolve  

---

## 📦 Installation

1. Download from Releases  
2. Extract to:
AddOns/
└── MidnightSensei/


---

## 🙌 Credits

- Icy Veins  
- Wowhead  
- SimulationCraft  
- Warcraft Logs  
- WoWAnalyzer

- ## 🐞 Reporting Issues

If something feels off, you can report it here:

👉 https://github.com/midnightstockton/MidnightSensei/issues

Click **"New Issue"** and choose one of the options:

- 🐞 Bug Report – for things not working correctly  
- 💡 Enhancement Request – for ideas or improvements  
- ⚡ Quick Report – for anything that just feels off  

The form is quick, just check a few boxes and add a short description.

Even minimal details are helpful.
