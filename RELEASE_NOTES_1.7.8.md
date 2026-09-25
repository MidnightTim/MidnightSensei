# MidnightSensei 1.7.8 Release Notes

This release fixes a scoring bug that turned out to be bigger than it first looked, plus a UI annoyance several users reported.

## Cooldown and rotation tracking

Fixed a bug where spells correctly marked as optional/situational could still be flagged as "never used" in your Fight Complete feedback, counting against your score as if they were expected rotation. This started as a report about Unholy Death Knight's Death Strike, but tracing it down turned up the same problem across several other classes:

- **Death Knight (Unholy)** — Death Strike
- **Druid (Feral)** — Chomp
- **Monk (Windwalker)** — Strike of the Windlord
- **Paladin (Protection)** — Hammer of the Righteous
- **Priest (Holy)** — Holy Word: Chastise
- **Shaman (Elemental)** — Earth Shock
- **Shaman (Restoration)** — Lava Burst
- **Warlock (Affliction)** — Agony

None of these will be counted against you anymore if you skip them.

## UI

The Fight Complete window now updates automatically if you leave it open while another fight finishes, instead of getting stuck showing the previous fight's results.
