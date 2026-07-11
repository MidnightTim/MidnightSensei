# Enhancement Shaman: Ascendance not tracked as a major cooldown

**Type:** Enhancement
**Version:** 1.7.4
**Date:** 07/11/2026

## Summary

Ascendance (id 114051) is a 2-minute major cooldown in the Enhancement Shaman talent tree that was not being tracked by the addon. Players using Ascendance received no cooldown usage feedback for it.

## Context

Ascendance and Doom Winds are a choice node in the Enhancement talent tree (nodeID 92219 for Ascendance). When Ascendance is talented, it replaces Doom Winds on the action bar. Ascendance transforms the player into an Air Ascendant for 15 seconds, unleashes Doom Winds automatically, reduces Stormstrike cooldown and cost by 60%, and converts auto attacks and Stormstrike into Wind attacks that bypass armor and have 30 yd range.

As of v1.7.3, Doom Winds was correctly suppressed when Ascendance is talented. However, Ascendance itself was not added to tracking at that time — it was pending in-game verification that the spell fires UNIT_SPELLCAST_SUCCEEDED (not UPDATE_SHAPESHIFT_FORM like Resto Ascendance 114052).

## Verification

Spell ID 114051 confirmed via in-game tooltip debug overlay (07/11/2026). Player confirmed Ascendance fires correctly as a tracked cast event. Spell IDs confirmed:
- Ascendance: 114051 (nodeID 92219, Entry ID 114291, 2 min cooldown)
- Doom Winds: 384352 (nodeID 80959, Entry ID 101824, 1 min cooldown - already tracked)

Note: previous session notes incorrectly listed Ascendance as a 3 min CD; confirmed 2 min via in-game tooltip.

## Fix

Added Ascendance (114051) to Enhancement majorCooldowns as talentGated. Players who have Ascendance talented will now receive cooldown usage feedback for it. Players who have Doom Winds talented will not see Ascendance in tracking.
