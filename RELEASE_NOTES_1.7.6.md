# MidnightSensei 1.7.6 Release Notes

This release closes out a batch of cooldown-tracking gaps found across six classes — mostly talents that were never being detected at all, so using them correctly still produced "never used" feedback. If any of these applied to your class, your cooldown usage score should now reflect reality.

## Warrior

**Arms — Bladestorm.** Now tracked as a cooldown. Bladestorm is a choice talent alongside Ravager (already tracked) — only whichever one you've actually chosen affects your score.

**Fury — Ravager and Bladestorm.** Both now tracked as cooldowns. Neither was being detected on this spec before, regardless of which one was talented.

## Priest

**Discipline — Power Word: Barrier.** Now tracked as a situational cooldown.

## Monk

**Brewmaster — Celestial Brew.** Now tracked as a cooldown, expected to be used regularly rather than held.

**Mistweaver — Invoke Yu'lon, the Jade Serpent.** Now tracked as a cooldown. This is a choice talent alongside Invoke Chi-Ji (already tracked) — only whichever one you've actually chosen affects your score. Previously, choosing Yu'lon over Chi-Ji meant your major healing cooldown was invisible to the addon entirely.

## Evoker

**Augmentation — Timelessness.** Now tracked as a situational cooldown.

## Druid

**Feral — Incarnation: Avatar of Ashamane.** Now tracked as a cooldown. This talent replaces Berserk on your action bar, so Berserk will no longer be flagged as unused if you've talented into Ashamane instead. Ashamane is also a choice talent alongside Convoke the Spirits (already tracked) — only whichever one you've chosen affects your score.

**Restoration — Incarnation: Tree of Life.** Now tracked as a situational cooldown. This is a choice talent alongside Convoke the Spirits (already tracked) — only whichever one you've chosen affects your score.

## Rogue

**Outlaw and Subtlety — Thistle Tea.** Now tracked as a cooldown on both specs, expected to be used regularly rather than held.
