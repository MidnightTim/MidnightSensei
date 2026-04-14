# Commit — Midnight Sensei v1.4.2

**Date:** April 2026
**Author:** Midnight - Thrall (US)
**Branch:** main
**Tag:** v1.4.2

---

## Summary

Spec database audit for Paladin (3 specs), Death Knight (3 specs), Mage (3 specs), Rogue (3 specs), and Monk (3 specs). All 39 specs now audited against live Midnight 12.0 snapshots. UX polish: login message, bare /ms command, public help output, debug guild inject removal.

---

## Changed Files

- `Core.lua` — version 1.4.2, changelog expanded, all spec DB changes
- `UI.lua` — FAQ panel command list cleaned

---

## Commits

### chore: bump version to 1.4.2, expand changelog

### fix(ux): login message, bare /ms, help output, debug inject removal
- Login: direct show/help hint instead of two-step redirect
- `/ms` bare: compact command strip
- `/ms help` and FAQ: removed reset/debug/verify; added versions/friend
- `debug guild inject` elseif handler deleted entirely

### fix(spec-db/paladin/holy): resourceType corrected, Beacon removed from uptimeBuffs, CDs and rotational added
- `resourceType` 0 → 9 (Holy Power)
- Beacon of Light `53563` removed from uptimeBuffs
- Blessing of Sacrifice marked talentGated; Aura Mastery `31821`, Lay on Hands `633`, Holy Bulwark `432459` added
- Light of Dawn `85222` added rotational

### fix(spec-db/paladin/protection): missing CDs added, spec-variant label corrected, rotational expanded
- Avenging Wrath `31884` and Divine Toll `375576` added — both missing
- Rebuke `96231` isInterrupt; `35395` label → "Blessed Hammer"
- Consecration `26573` and Holy Shock `20473` added rotational
- Shield of the Righteous aura `132403` flagged VERIFY

### fix(spec-db/paladin/retribution): Crusade removed, Final Verdict corrected, CDs and rotational added
- Crusade `231895` removed — PASSIVE modifier
- Templar's Verdict `85256` → Final Verdict `383328` (Midnight 12.0 rename)
- Divine Toll `375576` added; Rebuke `96231` isInterrupt
- Execution Sentence `343527` talentGated; Blade of Justice `184575`, Divine Storm `53385` added rotational
- Art of War `406064` procBuff VERIFY

### fix(spec-db/dk/blood): Abomination Limb/Bonestorm removed, Blood Shield removed, rotational block added
- Abomination Limb `383269`, Bonestorm `194844` removed
- Blood Shield `77535` removed from uptimeBuffs (proc absorb)
- Reaper's Mark `439843` CD; Mind Freeze `47528` isInterrupt
- Marrowrend `195182`, Heart Strike `206930`, Blood Boil `50842`, Death Strike `49998` added rotational

### fix(spec-db/dk/frost): Breath added, Howling Blast added, proc IDs flagged VERIFY
- Breath of Sindragosa `1249658` talentGated CD; Reaper's Mark `439843` CD; Mind Freeze `47528` isInterrupt
- Howling Blast `49184` rotational; Frostscythe `207230` talentGated rotational
- Killing Machine `59052`, Rime `51124` VERIFY flags added

### fix(spec-db/dk/unholy): Apocalypse/Unholy Assault removed, Dark Transformation corrected, spec-variant fixed
- Apocalypse `275699`, Unholy Assault `207289` removed
- Dark Transformation `63560` → `1233448` (spec-variant); Outbreak `77575`, Soul Reaper `343294` CDs
- Mind Freeze `47528` isInterrupt; Festering Strike `85092` → `316239` (spec-variant); Putrefy `1247378` rotational

### fix(spec-db/mage/arcane): Touch of the Magi/Evocation removed, spec-variant IDs corrected, rotational added
- Touch of the Magi `210824`, Evocation `12051` removed
- Arcane Blast `30451` → `116`; Arcane Barrage `44425` → `319836`; Clearcasting `276743` → `79684`
- Alter Time `342245` CD; Arcane Missiles `5143`, Arcane Explosion `1449` rotational

### fix(spec-db/mage/fire): Phoenix Flames removed, Fireball corrected, Pyroblast/Scorch added
- Phoenix Flames `257541` removed
- Fireball `133` → `116` (spec-variant); Supernova `157980`, Frostfire Bolt `431044` talentGated CDs
- Pyroblast `11366`, Scorch `2948` rotational; Hot Streak `48108` VERIFY

### fix(spec-db/mage/frost): Icy Veins removed, Frostbolt added, proc IDs flagged VERIFY
- Icy Veins `12472` removed; Flurry `44614`, Frostfire Bolt `431044`, Ray of Frost `205021`, Dragon's Breath `31661` added as CDs
- Frostbolt `116` rotational — primary filler missing entirely
- Brain Freeze `190446`, Fingers of Frost `44544` VERIFY flags added

### fix(spec-db/rogue/assassination): Vendetta removed, Kick isInterrupt, Envenom/Mutilate corrected
- Vendetta `79140` removed; Kick `1766` isInterrupt
- Envenom `32645` → `196819` (spec-variant); Mutilate `1752`, Crimson Tempest `1247227` rotational

### fix(spec-db/rogue/outlaw): Roll the Bones/BtE/Dispatch corrected, builders added
- Roll the Bones `315508` → `1214909`; Between the Eyes `199804` → `315341`; Dispatch `2098` → `196819`
- Blade Rush `271877`, Keep It Rolling `381989` talentGated CDs; Kick `1766` isInterrupt
- Sinister Strike `1752`, Pistol Shot `185763` rotational — both missing entirely

### fix(spec-db/rogue/subtlety): Symbols of Death/Nightblade removed, Kick isInterrupt, Backstab/Shuriken added
- Symbols of Death `212283` removed; Kick `1766` isInterrupt; Nightblade `195452` removed
- Backstab `1752`, Shuriken Storm `197835` rotational

### fix(spec-db/monk/brewmaster): Celestial Brew/Ironskin removed, rotational block built out
- Celestial Brew `322507` removed; Ironskin Brew `215479` removed from uptimeBuffs
- Exploding Keg `325153`, Celestial Infusion `1241059` CDs; Spear Hand Strike `116705` isInterrupt
- Breath of Fire `115181`, Tiger Palm `100780`, Blackout Kick `100784` rotational — all missing

### fix(spec-db/monk/mistweaver): Yu'lon removed, Chi-Ji added, Renewing Mist ID corrected
- Invoke Yu'lon `322118` removed; Invoke Chi-Ji `325197` added
- Renewing Mist `119611` → `115151` (wrong ID); Life Cocoon `116849`, Celestial Conduit `443028` CDs
- Spear Hand Strike `116705` isInterrupt; Enveloping Mist `124682` rotational

### fix(spec-db/monk/windwalker): SEF/Serenity removed, Zenith added, Tiger Palm/Blackout Kick added
- Storm, Earth and Fire `137639`, Serenity `152173` removed
- Zenith `1249625` CD; Spear Hand Strike `116705` isInterrupt; Combo Breaker:BoK `116768` removed from procBuffs
- Tiger Palm `100780`, Blackout Kick `100784`, Whirling Dragon Punch `152175` rotational
