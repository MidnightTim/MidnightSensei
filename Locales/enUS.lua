-- MidnightSensei — Locale: enUS (English)
-- Always loaded first. Provides all default strings.
-- Other locale files override only the keys they supply;
-- any missing key falls back to these English values.

MidnightSensei = MidnightSensei or {}
MidnightSensei.L = {}
local L = MidnightSensei.L

---------------------------------------------------------------------------
-- Grade labels (Core.GRADES)
---------------------------------------------------------------------------
L["GRADE_EXCEPTIONAL"]       = "Exceptional"
L["GRADE_EXCELLENT"]         = "Excellent"
L["GRADE_GREAT_WORK"]        = "Great work"
L["GRADE_STRONG"]            = "Strong"
L["GRADE_ON_TRACK"]          = "On track"
L["GRADE_SOLID"]             = "Solid"
L["GRADE_GOOD_FOUNDATION"]   = "Good foundation"
L["GRADE_ROOM_TO_GROW"]      = "Room to grow"
L["GRADE_KEEP_PRACTICING"]   = "Keep practicing"
L["GRADE_BUILDING_HABITS"]   = "Building habits"
L["GRADE_LEARNING_CURVE"]    = "Learning curve"
L["GRADE_EARLY_DAYS"]        = "Early days"
L["GRADE_FRESH_START"]       = "Fresh start"

---------------------------------------------------------------------------
-- Addon load / level gate (Core.lua)
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "loaded.  /ms show to open the HUD  ·  /ms help for commands."
L["LEVEL_GATE_WARNING"]      = "This addon is designed for level 80+ content. Fight tracking and grading are disabled until you reach level 80."
L["WEEKLY_RESET_DETECTED"]   = "Weekly Reset Detected."

---------------------------------------------------------------------------
-- Slash commands (Core.lua)
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Midnight Sensei Commands:"
L["SLASH_HELP_SHOW"]         = "  /ms show          Show the HUD"
L["SLASH_HELP_HIDE"]         = "  /ms hide          Hide the HUD"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Grade history & trends"
L["SLASH_HELP_LB"]           = "  /ms lb            Social leaderboard"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Personal boss best leaderboard  (alias: /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Settings panel"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Help & FAQ panel"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Credits & about"
L["SLASH_HELP_REPORT"]       = "  /ms report        Report a bug on GitHub"
L["SLASH_HELP_UPDATE"]       = "  /ms update        Show changelog"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Show addon versions seen this session"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Query a player's last score directly"

---------------------------------------------------------------------------
-- Chat status messages (Core.lua)
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "Guild DB is empty."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei — Guild DB keys:"
L["FRIEND_USAGE"]            = "Usage: /ms friend Name  or  /ms friend add Name  or  /ms friend remove Name"
L["LB_REMOVE_USAGE"]         = "Usage: /ms lb remove <PlayerName>"
L["VERSIONS_HEADER"]         = "Midnight Sensei — Versions seen this session:"
L["VERSIONS_NO_DATA"]        = "No version data yet — versions are collected automatically when players log in or join your group."
L["VERSIONS_YOU"]            = "(you)"
L["VERSIONS_OUTDATED"]       = "(outdated)"
L["SILENT_MODE_ON"]          = "Midnight Sensei: Silent mode ON — all outbound addon messages suppressed."
L["SILENT_MODE_OFF"]         = "Midnight Sensei: Silent mode OFF — normal operation resumed."

---------------------------------------------------------------------------
-- Verify mode (Core.lua)
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei Verify Mode: ON"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei Verify Mode: OFF"
L["VERIFY_CAST_HINT"]        = "Cast your spells normally. After combat type /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei: No spec loaded."

---------------------------------------------------------------------------
-- Snapshots (Core.lua)
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei: No talent snapshot yet — one is built automatically on login and spec change. If this is your first session, type /reload and try again."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei: No spell snapshot yet — one is built automatically on login. If this is your first session, type /reload and try again."

---------------------------------------------------------------------------
-- BossBoard.lua — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Boss Board"
L["BB_DESCRIPTION"]          = "Your all-time highest score per boss in Midnight — click any row to review your best performance feedback"
L["BB_TAB_DUNGEONS"]         = "Dungeons"
L["BB_TAB_RAIDS"]            = "Raids"
L["BB_TAB_DELVES"]           = "Delves"
L["BB_COL_DATE"]             = "DATE"
L["BB_COL_CHARACTER"]        = "CHARACTER"
L["BB_COL_SPEC"]             = "SPEC"
L["BB_COL_DIFF_BOSS"]        = "DIFF / BOSS"
L["BB_COL_SCORE"]            = "SCORE"
L["BB_NO_ENCOUNTERS"]        = "No boss encounters recorded for this content type yet."
L["BB_FOOTER_INFO"]          = "Boss kills only  -  level 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d boss%s recorded"
L["BB_TT_BEST"]              = "Best: %s  %d"
L["BB_TT_DATE"]              = "Date: %s"
L["BB_TT_KILLS"]             = "Kills tracked: %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Click to view feedback"

---------------------------------------------------------------------------
-- BossBoard.lua — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Boss Board: Ingest complete — added: %d  updated: %d  skipped: %d"
L["BB_SPEC_NOT_DETECTED"]    = "Boss Board: Could not detect active spec — character/spec fields may be incomplete. Try again after fully loading in."
L["BB_REPAIR_COMPLETE"]      = "Boss Board: Identity repair complete — patched: %d entr%s"
L["BB_NO_BOSSDATA"]          = "No bossBests data found."
L["BB_SPEC_UNRESOLVED"]      = "Boss Board: Spec not detected yet — try again after fully loading in."
L["BB_RENAME_COMPLETE"]      = "Character rename fix complete (%s → %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Grade history / review fights: %d encounter%s updated"
L["BB_RENAME_BB_UPDATED"]    = "  Boss Board: %d entr%s updated; shared snapshot re-keyed"
L["BB_CANNOT_READ_NAME"]     = "Could not read player name — try again after fully loading in."
L["BB_NO_CHARDB"]            = "No CharDB found."
L["BB_NO_SNAPDATA"]          = "No shared snapshot found."
L["BB_CLEANUP_DRY_HDR"]      = "Cleanup: %d encounter(s) would be marked as wipes. Run /ms debug cleanup history confirm to apply."
L["BB_CLEANUP_APPLIED"]      = "History cleanup — %d legacy wipe(s) corrected; Boss Board updated where history data was available."
L["BB_RESTORE_COMPLETE"]     = "Snapshot restore complete — recovered: %d  already current: %d"
L["BB_RESTORE_NOTE"]         = "Restored entries have score/grade/date but no fight feedback or component scores."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei: Boss Board cleared."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei: Fight history cleared."

---------------------------------------------------------------------------
-- BossBoard.lua — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Fix Character Name"
L["FIX_NAME_OLD_LABEL"]      = "Old character name (found in your history):"
L["FIX_NAME_NEW_LABEL"]      = "Will be replaced with (your current character name):"
L["FIX_NAME_ERR_EMPTY"]      = "Please enter the old character name."
L["FIX_NAME_ERR_SAME"]       = "That name matches your current character — nothing to fix."
L["FIX_NAME_ERR_NOT_FOUND"]  = "No history found under \"%s\". Check spelling, capitalization, and any special characters."
L["FIX_NAME_BTN_CONFIRM"]    = "Confirm Fix"

---------------------------------------------------------------------------
-- Leaderboard.lua — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Usage: /ms friend Name  or  /ms friend Name-Realm"
L["FRIEND_CHECKING"]         = "Checking %s..."
L["FRIEND_OFFLINE"]          = "%s (Offline) — Not updated or addon not installed"
L["FRIEND_CANNOT_REACH"]     = "Could not reach %s — check the name/realm spelling. Error: %s"
L["FRIEND_LIST_FULL"]        = "Friend list is full (%d max). Remove someone first with right-click or /ms friend remove Name."
L["FRIEND_ALREADY_IN"]       = "%s is already in your friend list."
L["FRIEND_ADDED"]            = "Added %s to your friend list (%d/%d)."
L["FRIEND_REMOVED"]          = "Removed %s from your friend list (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s not found in friend list."
L["FRIEND_ONLINE_UPDATED"]   = "%s (Online) — Updated"

---------------------------------------------------------------------------
-- UI.lua — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - Encounter Detail"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Grade History"
L["TITLE_HUD"]               = "Midnight Sensei"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Fight Complete"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Options"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei — Verify Report"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei — Verify Compare"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - My Spell List"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Debug Tools"
L["TITLE_CREDITS"]           = "Midnight Sensei - Credits & About"
L["TITLE_FAQ"]               = "Midnight Sensei - Help & FAQ"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Rotation Tracker"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei — Update Available"

---------------------------------------------------------------------------
-- UI.lua — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Inspect Details"
L["CTX_DELETE_ENTRY"]        = "Delete Entry"
L["CTX_CANCEL"]              = "Cancel"
L["CTX_LOCK_POSITION"]       = "Lock Position"
L["CTX_UNLOCK_POSITION"]     = "Unlock Position"
L["CTX_GRADE_HISTORY"]       = "Grade History"
L["CTX_LEADERBOARD"]         = "Leaderboard"
L["CTX_BOSS_BOARD"]          = "Boss Board"
L["CTX_OPTIONS"]             = "Options"
L["CTX_MY_SPELL_LIST"]       = "My Spell List"
L["CTX_HELP_FAQ"]            = "Help / FAQ"
L["CTX_CREDITS"]             = "Credits"
L["CTX_DEBUG_TOOLS"]         = "Debug Tools"
L["CTX_CLOSE_HUD"]           = "Close HUD"

---------------------------------------------------------------------------
-- UI.lua — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Duration: %s    Grade: %s  (%s)"
L["DETAIL_SCORE"]            = "Score: %d"
L["DETAIL_COMPONENT_SCORES"] = "Component Scores:"
L["DETAIL_FEEDBACK"]         = "Feedback:"
L["DETAIL_ENC_DUNGEON"]      = "Dungeon"
L["DETAIL_ENC_RAID"]         = "Raid"
L["DETAIL_ENC_DELVE"]        = "Delve"
L["DETAIL_ENC_WORLD"]        = "World"
L["DETAIL_ENC_COMBAT"]       = "Combat"
L["BTN_CLOSE"]               = "Close"

---------------------------------------------------------------------------
-- UI.lua — grade history panel
---------------------------------------------------------------------------
L["HISTORY_TREND_LABEL"]     = "Trend (last 20):"
L["HISTORY_FILTER_LABEL"]    = "Filter:"
L["FILTER_THIS_CHARACTER"]   = "This Character"
L["FILTER_BOSS_ONLY"]        = "[Boss] Only"
L["HISTORY_COL_GR"]          = "GR"
L["HISTORY_COL_CHARACTER"]   = "CHARACTER"
L["HISTORY_COL_SPEC_DIFF"]   = "SPEC / DIFF"
L["HISTORY_COL_SCORE"]       = "SCORE"
L["HISTORY_COL_DUR"]         = "DUR"
L["HISTORY_COL_WHEN"]        = "WHEN"
L["HISTORY_LB_BTN"]          = "Leaderboard ->"
L["HISTORY_STATS"]           = "%d fights  -  Avg: %d  -  Best: %s  -  Worst: %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d wipe%s"
L["HISTORY_NO_MATCHES"]      = "No encounters match the current filter."

---------------------------------------------------------------------------
-- UI.lua — relative time labels
---------------------------------------------------------------------------
L["TIME_JUST_NOW"]           = "just now"
L["TIME_MINUTES_AGO"]        = "%dm ago"
L["TIME_HOURS_AGO"]          = "%dh ago"
L["TIME_DAYS_AGO"]           = "%dd ago"

---------------------------------------------------------------------------
-- UI.lua — HUD
---------------------------------------------------------------------------
L["HUD_NO_FIGHT"]            = "No fight recorded yet"
L["HUD_IN_COMBAT"]           = "In combat..."
L["HUD_FIGHT_TOO_SHORT"]     = "Fight too short to record"
L["BTN_REVIEW_FIGHT"]        = "Review Fight"
L["BTN_BOSS_BOARD"]          = "Boss Board"
L["BTN_LEADERBOARD"]         = "Leaderboard"
L["VERIFY_BAR_LABEL"]        = "Verify Mode On"
L["BTN_VIEW_REPORT"]         = "View Report"
L["UPDATE_BAR_LABEL"]        = "New Version Available  (click for details)"
L["TT_MENU"]                 = "Menu"
L["TT_HIDE_HUD"]             = "Hide HUD"
L["TT_DISMISS"]              = "Dismiss"
L["TT_UPDATE_AVAILABLE"]     = "Update Available"
L["TT_UPDATE_CHECK"]         = "Check Curseforge or Wago for the latest version."
L["TT_BOSS_BOARD"]           = "Boss Board"
L["TT_BOSS_BOARD_DESC"]      = "Personal all-time boss best scores"
L["TT_LEADERBOARD"]          = "Leaderboard"
L["TT_LEADERBOARD_DESC"]     = "Guild / Party / Friends / Delves"

---------------------------------------------------------------------------
-- UI.lua — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Clean fight - nothing major to flag."
L["FIGHT_SCORE_DUR"]         = "Score: %d   Duration: %s"
L["FIGHT_COMPONENT_SCORES"]  = "Component Scores:"
L["BTN_HISTORY"]             = "History"

---------------------------------------------------------------------------
-- UI.lua — options panel
---------------------------------------------------------------------------
L["OPT_HUD_VISIBILITY"]      = "HUD Visibility:"
L["OPT_VIS_ALWAYS"]          = "Always"
L["OPT_VIS_IN_COMBAT"]       = "In Combat"
L["OPT_VIS_HIDE"]            = "Hide"
L["OPT_BEHAVIOUR"]           = "Behaviour:"
L["OPT_SHOW_POST_FIGHT"]     = "Show post-fight Review button on HUD"
L["OPT_LOCK_HUD"]            = "Lock HUD position"
L["OPT_ENCOUNTER_ADJUST"]    = "Encounter condition adjustment"
L["OPT_DEBUG_MODE"]          = "Debug mode (shows LB rejection msgs)"
L["OPT_LEADERBOARD"]         = "Leaderboard:"
L["OPT_LB_NOTE"]             = "Weekly average always counts boss encounters only. Trash pulls and target dummies are never included."
L["BTN_REPORT_ISSUES"]       = "Report Issues"

---------------------------------------------------------------------------
-- UI.lua — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei — Report a Bug\n\nCopy the link below and paste it into your browser.\nCtrl+A to select all, then Ctrl+C to copy."
L["REPORT_POPUP_BTN"]        = "Close"

---------------------------------------------------------------------------
-- UI.lua — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Ctrl+A to select all  ·  Ctrl+C to copy  ·  Paste into a GitHub comment"
L["BTN_COMPARE"]             = "Compare"

---------------------------------------------------------------------------
-- UI.lua — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Spells shown here are what Midnight Sensei is currently monitoring."
L["SPELL_LIST_NO_SPEC"]      = "No spec detected. Enter a fight first."
L["SPELL_LIST_SEC_CDS"]      = "Cooldown Spells"
L["SPELL_LIST_SEC_INT"]      = "Interrupt & Utility"
L["SPELL_LIST_SEC_ROT"]      = "Rotational Spells"
L["SPELL_LIST_SEC_UPTIME"]   = "Uptime Buffs"
L["SPELL_LIST_SEC_PROCS"]    = "Proc Buffs"
L["SPELL_LIST_SITUATIONAL"]  = "situational"
L["SPELL_LIST_SPEND_FAST"]   = "spend quickly"
L["SPELL_LIST_TARGET_UP"]    = "target %d%% uptime"
L["SPELL_LIST_METAMORPH"]    = "Requires Metamorphosis"

---------------------------------------------------------------------------
-- UI.lua — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- Verify Tools --"
L["DEBUG_SEC_CLASS"]         = "-- Class Debugging --"
L["DEBUG_SEC_RECOVERY"]      = "-- Recovery Tools --"
L["DEBUG_BTN_VERIFY_MODE"]   = "Verify Mode"
L["DEBUG_BTN_VERIFY_DESC"]   = "Toggle spell ID capture for /ms verify report"
L["DEBUG_BTN_VR"]            = "Verify Report"
L["DEBUG_BTN_VR_DESC"]       = "Export spell ID verification report to copyable window"
L["DEBUG_BTN_AUTO_VERIFY"]   = "Auto-enable Verify on Login"
L["DEBUG_BTN_AV_DESC"]       = "Verify mode turns on automatically after every reload or login"
L["DEBUG_BTN_VERSION"]       = "Version"
L["DEBUG_BTN_VERSION_DESC"]  = "Show addon version from TOC and metadata APIs"
L["DEBUG_BTN_ROT_TRACKER"]   = "Rotation Tracker"
L["DEBUG_BTN_RT_DESC"]       = "Open the Rotation Tracker window — cast counts, status, and flag explanations for each spell"
L["DEBUG_BTN_TALENT_EXP"]    = "Talent Export"
L["DEBUG_BTN_TE_DESC"]       = "Export active talent snapshot for spec DB cross-reference"
L["DEBUG_BTN_SPELLS_EXP"]    = "Spells Export"
L["DEBUG_BTN_SE_DESC"]       = "Export full spellbook snapshot for spec DB cross-reference"
L["DEBUG_BTN_BB_INGEST"]     = "Boss Board Ingest"
L["DEBUG_BTN_BBI_DESC"]      = "Seed Boss Board from encounter history"
L["DEBUG_BTN_FIX_NAME"]      = "Fix Character Name"
L["DEBUG_BTN_FN_DESC"]       = "If you renamed your character, run this"
L["DEBUG_BTN_BACKFILL"]      = "Backfill M+ Keys"
L["DEBUG_BTN_BK_DESC"]       = "Patch Mythic dungeon history with season best key levels"
L["DEBUG_BTN_CLEAN"]         = "Clean Payload"
L["DEBUG_BTN_CP_DESC"]       = "Re-broadcast all your best scores with correct format"
L["DEBUG_BTN_CLEAR_BB"]      = "Clear Boss Board"
L["DEBUG_BTN_CBB_DESC"]      = "Permanently wipes all personal boss best records — this cannot be undone"
L["DEBUG_BTN_CLEAR_HIST"]    = "Clear Fight History"
L["DEBUG_BTN_CH_DESC"]       = "Permanently deletes all recorded encounters — this cannot be undone"
L["DEBUG_BTN_RUN"]           = "Run"
L["DEBUG_BTN_TOGGLE"]        = "Toggle"

---------------------------------------------------------------------------
-- UI.lua — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Type  Confirm  to enable delete:"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Clear Boss Board"
L["DESTRUCT_CLEAR_BB_BODY"]  = "This will permanently delete all Boss Board records for this character.\nThis action cannot be undone."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Delete Boss Board"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Clear Fight History"
L["DESTRUCT_CLEAR_HIST_BODY"] = "This will permanently delete all recorded fight encounters for this character.\nThis action cannot be undone."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Delete Fight History"
L["BTN_CANCEL"]              = "Cancel"

---------------------------------------------------------------------------
-- UI.lua — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "About"
L["CREDITS_TAB_SOURCES"]     = "Sources"
L["CREDITS_TAB_CHANGELOG"]   = "Changelog"
L["CREDITS_SOURCES_INTRO"]   = "Rotational guidance is informed by the following community resources."
L["CREDITS_SOURCES_ACK"]     = "We gratefully acknowledge their contributions."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei is not affiliated with these resources."
L["CREDITS_NO_CHANGELOG"]    = "No changelog available."
L["CREDITS_ABOUT_TEXT"]      = "A combat performance coaching addon for World of Warcraft: Midnight.\nGrades your fights A+ through F across all 13 classes and 40 specs,\nwith actionable feedback tailored to your role and spec."
L["CREDITS_AUTHOR"]          = "Author:  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Features:"
L["CREDITS_FEAT_GRADING"]    = "  - Per-fight grading: cooldown usage, activity, resource management"
L["CREDITS_FEAT_TALENT"]     = "  - Talent-aware: only scores abilities you actually have equipped"
L["CREDITS_FEAT_BOSS"]       = "  - Boss detection: tracks ENCOUNTER_START/END for real boss fights"
L["CREDITS_FEAT_SOCIAL"]     = "  - Social leaderboard: guild, party, and BNet friends rankings"
L["CREDITS_FEAT_WEEKLY"]     = "  - Weekly reset: aligned to Blizzard's Tuesday 7am PDT reset"
L["CREDITS_FEAT_DELVE"]      = "  - Delve tracking: tier-based scoring for solo content"
L["CREDITS_FEAT_SYNC"]       = "  - Score sync: syncs across guild members to recover scores after reinstall"
L["CREDITS_CONTACT"]         = "Contact:  MidnightTim on GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei is a community addon, not affiliated with Blizzard."

---------------------------------------------------------------------------
-- UI.lua — FAQ
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "GETTING STARTED"
L["FAQ_HDR_UNDERSTANDING"]   = "UNDERSTANDING YOUR GRADE"
L["FAQ_HDR_ROTATIONAL"]      = "ROTATIONAL SPELL FEEDBACK"
L["FAQ_HDR_VISIBILITY"]      = "VISIBILITY OPTIONS"
L["FAQ_HDR_HISTORY"]         = "GRADE HISTORY"
L["FAQ_HDR_LEADERBOARD"]     = "LEADERBOARD"
L["FAQ_HDR_MIDNIGHT_NOTE"]   = "NOTE ON MIDNIGHT 12.0 RESTRICTIONS"
L["FAQ_HDR_BOSS_COMBAT"]     = "BOSS VS NORMAL COMBAT"
L["FAQ_HDR_TALENT_AWARE"]    = "TALENT-AWARE COOLDOWNS"
L["FAQ_HDR_ALL_COMMANDS"]    = "ALL COMMANDS"
L["FAQ_MIN_FIGHT"]           = "A fight shorter than 15 seconds is not recorded."
L["FAQ_VIS_ALWAYS"]          = "  Always: HUD always visible"
L["FAQ_VIS_COMBAT"]          = "  In Combat: HUD only shows while in combat"
L["FAQ_VIS_HIDE"]            = "  Hide: HUD hidden (accessible via /ms show)"
L["FAQ_CMD_SHOW"]            = "  /ms show         Show the HUD"
L["FAQ_CMD_HIDE"]            = "  /ms hide         Hide the HUD"
L["FAQ_CMD_HISTORY"]         = "  /ms history      Grade history & trending"
L["FAQ_CMD_LB"]              = "  /ms lb           Social leaderboard"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Remove a player from guild leaderboard"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Settings"
L["FAQ_CMD_FAQ"]             = "  /ms faq          This panel"
L["FAQ_CMD_UPDATE"]          = "  /ms update       View changelog"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Credits & about"
L["FAQ_CMD_REPORT"]          = "  /ms report       Report a bug on GitHub"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Show addon versions seen this session"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Query a player's last score directly"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Open the Rotation Tracker (cast counts + spell explanations)"

---------------------------------------------------------------------------
-- UI.lua — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Type |cffFFFFFF/ms show|r to open the HUD, |cffFFFFFF/ms hide|r to close it.\nThe HUD shows your last grade, score, and spec. After a fight you\nwill see a |cffFFFFFF>> Review Fight|r button. Right-click the HUD for quick\naccess to all features."
L["FAQ_BODY_UNDERSTANDING"]   = "Grades run from F through A+. Each spec has weighted categories:\n  - Cooldown Usage: did you press your major cooldowns on cooldown?\n  - Rotational Spells: did you use key rotation abilities each fight?\n  - Activity: were you casting consistently? (no long idle gaps)\n  - Resource Mgmt: did you overcap your resource (Rage/Energy/etc)?\n  - Buff Uptime: did you keep your self-buffs active? (specs vary)\n  - Proc Usage: did you consume procs quickly? (Frost DK, Fire Mage...)?\n  - Healer Efficiency: how much of your healing was overheal?"
L["FAQ_BODY_ROTATIONAL"]      = "In addition to cooldowns, Midnight Sensei tracks whether you used\nkey rotational spells each fight (e.g. Implosion, Rake, Obliterate).\nIf you never used one in a long enough fight, it will appear in your\nfeedback. Talent-gated spells are skipped if you don't have the talent."
L["FAQ_BODY_VIS_INTRO"]       = "Open |cffFFFFFF/ms options|r (or right-click HUD -> Options) and set:"
L["FAQ_BODY_HISTORY"]         = "Type |cffFFFFFF/ms history|r or right-click -> Grade History.\n  - Filter by This Character or All Characters\n  - Sparkline shows your last 20 fights at a glance\n  - Left-click any row to inspect full details and feedback\n  - Right-click any row to delete that entry"
L["FAQ_BODY_LEADERBOARD"]     = "Type |cffFFFFFF/ms lb|r to open the social leaderboard.\nAfter each boss fight your score broadcasts to guild, party, and\nBNet friends who also have Midnight Sensei installed.\nTabs: Party (session only), Guild (persists across sessions), Friends.\nGuild scores persist between sessions and sync across guild members —\neven if a player is offline you can still see their last recorded score.\nWeekly average counts boss encounters only — trash pulls and target\ndummies are never included in rankings.\nRight-click any guild row to remove a player. They repopulate\nautomatically when they next log in or you hit Refresh."
L["FAQ_BODY_LB_EXTRA"]        = "Each tab (Dungeons, Raids) shows location info from that content type\nonly — an LFR run will never bleed into the Dungeons tab.\nMythic+ key level is shown where available (e.g. M+15).\nAfter updating the addon, each player needs to complete one new\ndungeon or raid for their tab location to reflect the correct content.\nYour own entry updates immediately from local history — no new run needed."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard restricted enemy unit aura reads in Midnight 12.0.\nTarget debuffs (Rupture, Flame Shock, etc.) cannot be tracked directly.\nThese show in your priorityNotes as guidance but are not scored.\nAll player self-buffs, cooldowns, and rotational casts work normally."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei detects boss encounters via ENCOUNTER_START/END.\nBoss fights show a |cffFF6600[Boss]|r tag in history and encounter detail.\nFilter your history to |cffFFFFFF[Boss] Only|r to review raid/dungeon boss pulls."
L["FAQ_BODY_TALENT_AWARE"]    = "Cooldown scoring only includes spells you have learned.\nIf you don't have a talent, it won't be scored against you."

---------------------------------------------------------------------------
-- UI.lua — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Cast counts from your last fight. Each spell shows how many times it was used and why it is tracked."
L["ROT_TRACKER_NO_DATA"]     = "No fight data yet — run a fight to see tracking results."
L["ROT_TRACKER_LAST_FIGHT"]  = "Last fight: %s"
L["ROT_TRACKER_NO_FIGHT"]    = "No fight recorded yet"
L["ROT_COL_SPELL"]           = "SPELL"
L["ROT_COL_CASTS"]           = "CASTS"
L["ROT_COL_MIN_FIGHT"]       = "MIN FIGHT"
L["ROT_COL_STATUS"]          = "STATUS"
L["ROT_STATUS_CAST"]         = "CAST"
L["ROT_STATUS_MISSED"]       = "MISSED"
L["ROT_STATUS_SHORT"]        = "SHORT"
L["ROT_FLAG_COMBAT_TALENT"]  = "Requires talent; only castable during a transformation window"
L["ROT_FLAG_COMBAT_ONLY"]    = "Only castable during a transformation window (e.g. Void Metamorphosis)"
L["ROT_FLAG_TALENT_ONLY"]    = "Only tracked when this talent is active in your build"
L["ROT_FLAG_CORE"]           = "Core rotational ability — expected every fight"
L["ROT_FLAG_MIN_FIGHT"]      = "flagged missed only if fight > %ds"
L["ROT_NOT_TRACKED"]         = "Not tracked this build (talent not taken or replaced): %s"
L["ROT_LEGEND_CAST_DESC"]    = "used at least once"
L["ROT_LEGEND_MISSED_DESC"]  = "fight was long enough but spell was not used"
L["ROT_LEGEND_SHORT_DESC"]   = "fight too short to evaluate"
L["ROT_LEGEND"]              = "CAST  used at least once  MISSED  fight was long enough but spell was not used  SHORT  fight too short to evaluate"

---------------------------------------------------------------------------
-- UI.lua — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "A new version of Midnight Sensei is available.\nCheck Curseforge or Wago for the latest version."
L["SETTINGS_CATEGORY"]       = "Midnight Sensei"
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Created by Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Open Options"
L["SETTINGS_BTN_OPT_DESC"]   = "Configure HUD, play style, and more"
L["SETTINGS_BTN_HISTORY"]    = "Grade History"
L["SETTINGS_BTN_HIST_DESC"]  = "View fight history and trends"
L["SETTINGS_BTN_LB"]         = "Leaderboard"
L["SETTINGS_BTN_LB_DESC"]    = "Guild / Party / Friends / Delve rankings"
L["SETTINGS_BTN_FAQ"]        = "Help & FAQ"
L["SETTINGS_BTN_FAQ_DESC"]   = "How scoring and grading works"
L["SETTINGS_BTN_CREDITS"]    = "Credits & About"
L["SETTINGS_BTN_CRED_DESC"]  = "Author info and sources"
L["SETTINGS_LEGACY_SUB"]     = "Created by Midnight - Thrall (US)  |  /ms for commands"
L["MINIMAP_TT_TITLE"]        = "Midnight Sensei"
L["MINIMAP_TT_LEFT"]         = "Left-click: Toggle HUD"
L["MINIMAP_TT_RIGHT"]        = "Right-click: Leaderboard"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Ctrl+Right-click: Boss Board"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "Shift+Right-click: Options"

---------------------------------------------------------------------------
-- Analytics/Feedback.lua
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "You lost value from unused cooldowns%s: %s. Even consistent pressing helps."
L["FB_NEVER_PRESSED"]        = "Never pressed%s: %s — %s."
L["FB_ACTION_TANK"]          = "use on tank busters or high damage windows"
L["FB_ACTION_HEALER"]        = "align with high incoming damage windows"
L["FB_ACTION_DPS"]           = "align these with burst windows"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Your rotation is consistent, but gaps between casts (%d%% activity) are the next thing to tighten up."
L["FB_ACTIVITY_MODERATE"]    = "Activity at %d%% — roughly %d cast(s) left on the table. Queue your next spell before the current one lands."
L["FB_ACTIVITY_LOW"]         = "Activity: %d/%d GCDs (%d%%) — %s downtime, approximately %d casts lost. Find your next spell before the current one finishes."
L["FB_DOWNTIME_SIGNIFICANT"] = "significant"
L["FB_DOWNTIME_MODERATE"]    = "moderate"
L["FB_UNDERUSED"]            = "Used less than expected in a %.1fmin fight: %s — target 1 use per 2 minutes of fight time."
L["FB_ROT_NEVER_USED"]       = "Rotational spell(s) never used: %s — these are core to your %s."
L["FB_ROT_CONTEXT_TANK"]     = "survival and threat rotation"
L["FB_ROT_CONTEXT_HEALER"]   = "healing throughput"
L["FB_ROT_CONTEXT_DPS"]      = "damage output"
L["FB_ROT_LOW_USED"]         = "Could have cast more: %s — press these on every available GCD when your primary spenders are on cooldown."
L["FB_PROC_DELAYED"]         = "delayed"
L["FB_PROC_CRITICALLY"]      = "critically delayed"
L["FB_PROC_MSG"]             = "%s consumption is %s — held %.1fs on average (budget: %ds). Consume procs immediately when they appear."
L["FB_OVERCAP"]              = "Overcapped %s %d time(s) (%.1f/min) — spend %s before reaching %d to avoid wasted generation."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s was never activated — press it on cooldown every time it is available to reduce physical damage taken."
L["FB_MIT_LOW_UPTIME"]       = "%s: %d%% uptime vs %d%% target (%dpt gap, %d application(s)) — you have large windows of unmitigated physical damage. Press it the moment it comes off cooldown."
L["FB_MIT_SMALL_GAPS"]       = "%s: %d%% uptime vs %d%% target (%dpt gap) — small gaps are adding up. Use it preemptively on heavy melee sequences, not reactively."
L["FB_BUFF_LOW_UPTIME"]      = "%s: %d%% uptime vs %d%% target (%dpt gap) — reapply before it expires, not after."
L["FB_GROUP_BUFF_NOTE"]      = "%s (group buff — ensure it's active before combat)"
L["FB_OVERHEAL_HIGH"]        = "Overheal at %.1f%% (target: <%d%%) — you are spending mana on targets that do not need healing. Cast slightly later or switch to reactive spells on targets actively taking damage."
L["FB_OVERHEAL_ELEVATED"]    = "Overheal: %.1f%% (target: <%d%%) — slightly elevated. Hold casts on targets above 70%% health and prioritise HoTs over direct heals on stable groups."
L["FB_HEALER_FILL_DOWNTIME"] = "When the group is stable, fill downtime with damage spells to maintain throughput."
L["FB_SIMPLIFIED_FALLBACK"]  = "Your rotation is consistent and well-paced. Tightening burst window timing is the next performance step."
L["FB_NEAR_PERFECT"]         = "Near-perfect execution. The remaining gains are: %s."
L["FB_NEXT_TANK_PREPOS"]     = "pre-position defensives before predictable spike damage"
L["FB_NEXT_HEALER_OVERLAP"]  = "overlap cooldowns with incoming damage casts rather than reacting"
L["FB_NEXT_DPS_ALIGN"]       = "align burst windows with enemy vulnerability phases"
L["FB_NEXT_GCD_TIMING"]      = "reduce time between the GCD ending and your next cast to sub-0.2s"
L["FB_STRONG_EXECUTION"]     = "Strong execution overall. Your lowest category is %s — that is where the next points come from."
L["FB_GOOD_FOUNDATION"]      = "Good foundation — focus next on: %s."
L["FB_HINT_TANK_CDS"]        = "use defensive cooldowns on tank busters"
L["FB_HINT_PRESS_CDS"]       = "press major cooldowns more consistently"
L["FB_HINT_MIT_UPTIME"]      = "increase mitigation uptime by pressing %s more frequently"
L["FB_SOLID"]                = "Solid performance — tighten up cooldown timing to push higher."
L["FB_NOTE_INTERRUPT"]       = "Note: %s — this is your interrupt. Not used this fight — no penalty."
L["FB_NOTE_UTILITY"]         = "Note: %s — not used or detected this fight. No penalty."
L["FB_NOTE_COMBAT_UTILITY"]  = "Note: %s — stuns and deals damage in addition to utility. Use it where the situation allows; no penalty for holding it."
