## [Enhancement] Rogue Outlaw/Subtlety: Thistle Tea cooldown tracking

**Description:** Thistle Tea was not tracked as a cooldown for Outlaw or Subtlety Rogue — this was a plain gap, not a prior incorrect finding. Assassination's Thistle Tea was already tracked, but it turns out Outlaw and Subtlety use a different spell ID for the same-named talent.

**Context:** Assassination's Thistle Tea auto-triggers when Energy drops below 30. The Outlaw/Subtlety version is a separate spell ID that has to be cast manually — no auto-trigger clause — so it was never going to be caught by matching Assassination's ID.

**Fix:** Thistle Tea added to both Outlaw and Subtlety as a tracked cooldown (the manually-cast spell ID, distinct from Assassination's), expected to be used regularly rather than held.

**Steps to reproduce (before fix):** Talent into Thistle Tea on Outlaw or Subtlety and cast it during a fight — the addon would never register the cast.
