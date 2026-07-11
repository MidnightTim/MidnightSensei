# Enhancement Shaman: Doom Winds tracked when Ascendance is talented

**Type:** Bug
**Version:** 1.7.3
**Date:** 07/07/2026

## Summary

Doom Winds (id 384352) was being tracked and generating feedback for Enhancement Shaman players who had Ascendance talented, even though Ascendance fully replaces Doom Winds on the action bar.

## Root Cause

Doom Winds and Ascendance (id 114051) are a choice node in the Enhancement talent tree. When Ascendance is talented, the player loses access to Doom Winds as a castable ability - Ascendance triggers Doom Winds automatically as part of its transformation. The spec DB had no suppressIfTalent on Doom Winds, so the addon tracked it as a missing CD for players on the Ascendance side of the choice node.

The spec file also had an incorrect comment stating Ascendance (114051) was "not in Enhancement talent tree" - this was stale data from a prior audit. Ascendance is confirmed in the tree as of 12.0.7 as a 3-minute CD transformation ability.

## Fix

Added suppressIfTalent=114051 (Ascendance) to Doom Winds. When Ascendance is talented, Doom Winds is excluded from tracking entirely.

## Follow-up: Ascendance Tracking (VERIFY pending)

Ascendance (114051) is a significant 3-minute CD that may warrant tracking on its own. However, it is a transformation ability and may fire UPDATE_SHAPESHIFT_FORM rather than UNIT_SPELLCAST_SUCCEEDED (same concern as Resto Ascendance 114052). Needs an in-game /ms verify session before adding to majorCooldowns.
