# Midnight Sensei v1.7.3 - Release Notes
**Date:** July 7, 2026

## Overview

Version 1.7.3 fixes an Enhancement Shaman tracking issue affecting players who use Ascendance instead of Doom Winds.

---

## Enhancement Shaman: Doom Winds No Longer Flagged When Ascendance is Talented

Doom Winds and Ascendance are a choice node in the Enhancement talent tree. When Ascendance is talented, it fully replaces Doom Winds on the action bar - Ascendance is a 3-minute transformation CD that triggers Doom Winds automatically as part of its effect. Players on the Ascendance side of the choice node cannot and should not cast Doom Winds separately.

Players with Ascendance talented were receiving Doom Winds feedback (never pressed, underused) despite having no ability to cast it.

**Fix:** Doom Winds is now suppressed from tracking when Ascendance is talented. Ascendance players will no longer see any Doom Winds feedback.
