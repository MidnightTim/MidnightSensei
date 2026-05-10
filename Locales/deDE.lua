-- MidnightSensei — Locale: deDE (Deutsch)
-- Loaded after enUS.lua. Early-returns if the client is not German.
-- Only keys present here override the English defaults.

local locale = GetLocale()
if locale ~= "deDE" then return end
local L = MidnightSensei.L

---------------------------------------------------------------------------
-- Grade labels
---------------------------------------------------------------------------
L["GRADE_EXCEPTIONAL"]       = "Außergew\xC3\xB6hnlich"
L["GRADE_EXCELLENT"]         = "Ausgezeichnet"
L["GRADE_GREAT_WORK"]        = "Hervorragend"
L["GRADE_STRONG"]            = "Stark"
L["GRADE_ON_TRACK"]          = "Auf Kurs"
L["GRADE_SOLID"]             = "Solide"
L["GRADE_GOOD_FOUNDATION"]   = "Gute Grundlage"
L["GRADE_ROOM_TO_GROW"]      = "Raum f\xC3\xBCr Verbesserung"
L["GRADE_KEEP_PRACTICING"]   = "Weiter \xC3\xBCben"
L["GRADE_BUILDING_HABITS"]   = "Gewohnheiten aufbauen"
L["GRADE_LEARNING_CURVE"]    = "Lernkurve"
L["GRADE_EARLY_DAYS"]        = "Erste Schritte"
L["GRADE_FRESH_START"]       = "Neuer Anfang"

---------------------------------------------------------------------------
-- Addon load / level gate
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "geladen.  /ms show zum \xC3\x96ffnen des HUD  \xC2\xB7  /ms help f\xC3\xBCr Befehle."
L["LEVEL_GATE_WARNING"]      = "Dieses Addon ist f\xC3\xBCr Level-80+-Inhalte ausgelegt. Kampfverfolgung und Bewertung sind deaktiviert, bis Level 80 erreicht ist."
L["WEEKLY_RESET_DETECTED"]   = "W\xC3\xB6chentlicher Reset erkannt."

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Midnight Sensei Befehle:"
L["SLASH_HELP_SHOW"]         = "  /ms show          HUD anzeigen"
L["SLASH_HELP_HIDE"]         = "  /ms hide          HUD ausblenden"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Kampfhistorie & Trends"
L["SLASH_HELP_LB"]           = "  /ms lb            Soziale Rangliste"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Pers\xC3\xB6nliche Boss-Bestenliste  (Alias: /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Einstellungen"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Hilfe & FAQ"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Credits & \xC3\x9Cber"
L["SLASH_HELP_REPORT"]       = "  /ms report        Fehler auf GitHub melden"
L["SLASH_HELP_UPDATE"]       = "  /ms update        \xC3\x84nderungsprotokoll anzeigen"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Addon-Versionen dieser Sitzung anzeigen"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Letzten Score eines Spielers abfragen"

---------------------------------------------------------------------------
-- Chat status messages
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "Gilden-Datenbank ist leer."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei \xe2\x80\x94 Gilden-Datenbank Eintr\xC3\xA4ge:"
L["FRIEND_USAGE"]            = "Verwendung: /ms friend Name  oder  /ms friend add Name  oder  /ms friend remove Name"
L["LB_REMOVE_USAGE"]         = "Verwendung: /ms lb remove <Spielername>"
L["VERSIONS_HEADER"]         = "Midnight Sensei \xe2\x80\x94 Versionen dieser Sitzung:"
L["VERSIONS_NO_DATA"]        = "Noch keine Versionsdaten \xe2\x80\x94 Versionen werden automatisch gesammelt, wenn Spieler einloggen oder deiner Gruppe beitreten."
L["VERSIONS_YOU"]            = "(du)"
L["VERSIONS_OUTDATED"]       = "(veraltet)"
L["SILENT_MODE_ON"]          = "Midnight Sensei: Stiller Modus EIN \xe2\x80\x94 alle ausgehenden Addon-Nachrichten unterdr\xC3\xBCckt."
L["SILENT_MODE_OFF"]         = "Midnight Sensei: Stiller Modus AUS \xe2\x80\x94 normaler Betrieb wiederhergestellt."

---------------------------------------------------------------------------
-- Verify mode
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei \xC3\x9Cberpr\xC3\xBCfungsmodus: EIN"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei \xC3\x9Cberpr\xC3\xBCfungsmodus: AUS"
L["VERIFY_CAST_HINT"]        = "Wirke deine Zauber normal. Nach dem Kampf tippe /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei: Keine Spezialisierung geladen."

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei: Noch kein Talent-Snapshot \xe2\x80\x94 wird automatisch beim Einloggen und Spezialisierungswechsel erstellt. Falls dies deine erste Sitzung ist, tippe /reload und versuche es erneut."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei: Noch kein Zauber-Snapshot \xe2\x80\x94 wird automatisch beim Einloggen erstellt. Falls dies deine erste Sitzung ist, tippe /reload und versuche es erneut."

---------------------------------------------------------------------------
-- BossBoard — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Boss-Brett"
L["BB_DESCRIPTION"]          = "Dein aller h\xC3\xB6chster Score pro Boss in Midnight \xe2\x80\x94 klicke auf eine Zeile um dein bestes Kampf-Feedback zu sehen"
L["BB_TAB_DUNGEONS"]         = "Dungeons"
L["BB_TAB_RAIDS"]            = "Schlachtz\xC3\xBCge"
L["BB_TAB_DELVES"]           = "Tiefen"
L["BB_COL_DATE"]             = "DATUM"
L["BB_COL_CHARACTER"]        = "CHARAKTER"
L["BB_COL_SPEC"]             = "SPEZ."
L["BB_COL_DIFF_BOSS"]        = "SCHW. / BOSS"
L["BB_COL_SCORE"]            = "SCORE"
L["BB_NO_ENCOUNTERS"]        = "Noch keine Boss-Begegnungen f\xC3\xBCr diesen Inhaltstyp aufgezeichnet."
L["BB_FOOTER_INFO"]          = "Nur Boss-Kills  -  Level 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d Boss%s aufgezeichnet"
L["BB_TT_BEST"]              = "Bester: %s  %d"
L["BB_TT_DATE"]              = "Datum: %s"
L["BB_TT_KILLS"]             = "Verfolgte Kills: %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Klicken zum Anzeigen des Feedbacks"

---------------------------------------------------------------------------
-- BossBoard — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Boss-Brett: Ingest abgeschlossen \xe2\x80\x94 hinzugef\xC3\xBCgt: %d  aktualisiert: %d  \xC3\xBCbersprungen: %d"
L["BB_SPEC_NOT_DETECTED"]    = "Boss-Brett: Aktive Spezialisierung konnte nicht erkannt werden \xe2\x80\x94 Charakter-/Spezialisierungsfelder k\xC3\xB6nnen unvollst\xC3\xA4ndig sein. Versuche es erneut nach dem vollst\xC3\xA4ndigen Einloggen."
L["BB_REPAIR_COMPLETE"]      = "Boss-Brett: Identit\xC3\xA4tsreparatur abgeschlossen \xe2\x80\x94 gepatcht: %d Eintr%s"
L["BB_NO_BOSSDATA"]          = "Keine bossBests-Daten gefunden."
L["BB_SPEC_UNRESOLVED"]      = "Boss-Brett: Spezialisierung noch nicht erkannt \xe2\x80\x94 versuche es nach dem vollst\xC3\xA4ndigen Einloggen erneut."
L["BB_RENAME_COMPLETE"]      = "Charakterumbenennung abgeschlossen (%s \xe2\x86\x92 %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Kampfhistorie / K\xC3\xA4mpfe ansehen: %d Begegnung%s aktualisiert"
L["BB_RENAME_BB_UPDATED"]    = "  Boss-Brett: %d Eintr%s aktualisiert; geteilter Snapshot neu indexiert"
L["BB_CANNOT_READ_NAME"]     = "Spielername konnte nicht gelesen werden \xe2\x80\x94 versuche es nach dem vollst\xC3\xA4ndigen Einloggen erneut."
L["BB_NO_CHARDB"]            = "Keine CharDB gefunden."
L["BB_NO_SNAPDATA"]          = "Kein geteilter Snapshot gefunden."
L["BB_CLEANUP_DRY_HDR"]      = "Bereinigung: %d Begegnung(en) w\xC3\xBCrden als Niederlagen markiert. F\xC3\xBChre /ms debug cleanup history confirm aus um anzuwenden."
L["BB_CLEANUP_APPLIED"]      = "Historienbereinigung \xe2\x80\x94 %d veraltete Niederlage(n) korrigiert; Boss-Brett aktualisiert wo Historiendaten verf\xC3\xBCgbar waren."
L["BB_RESTORE_COMPLETE"]     = "Snapshot-Wiederherstellung abgeschlossen \xe2\x80\x94 wiederhergestellt: %d  bereits aktuell: %d"
L["BB_RESTORE_NOTE"]         = "Wiederhergestellte Eintr\xC3\xA4ge haben Score/Note/Datum aber kein Kampf-Feedback oder Komponenten-Scores."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei: Boss-Brett geleert."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei: Kampfhistorie geleert."

---------------------------------------------------------------------------
-- BossBoard — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Charakternamen korrigieren"
L["FIX_NAME_OLD_LABEL"]      = "Alter Charaktername (in deiner Historie gefunden):"
L["FIX_NAME_NEW_LABEL"]      = "Wird ersetzt durch (dein aktueller Charaktername):"
L["FIX_NAME_ERR_EMPTY"]      = "Bitte gib den alten Charakternamen ein."
L["FIX_NAME_ERR_SAME"]       = "Dieser Name stimmt mit deinem aktuellen Charakter \xC3\xBCberein \xe2\x80\x94 nichts zu korrigieren."
L["FIX_NAME_ERR_NOT_FOUND"]  = "Keine Historie unter \"%s\" gefunden. \xC3\x9Cberpr\xC3\xBCfe Schreibweise, Gro\xC3\x9F-/Kleinschreibung und Sonderzeichen."
L["FIX_NAME_BTN_CONFIRM"]    = "Korrektur best\xC3\xA4tigen"

---------------------------------------------------------------------------
-- Leaderboard — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Verwendung: /ms friend Name  oder  /ms friend Name-Realm"
L["FRIEND_CHECKING"]         = "\xC3\x9Cberpr\xC3\xBCfe %s..."
L["FRIEND_OFFLINE"]          = "%s (Offline) \xe2\x80\x94 Nicht aktualisiert oder Addon nicht installiert"
L["FRIEND_CANNOT_REACH"]     = "Konnte %s nicht erreichen \xe2\x80\x94 \xC3\xBCberpr\xC3\xBCfe Name/Realm-Schreibweise. Fehler: %s"
L["FRIEND_LIST_FULL"]        = "Freundesliste ist voll (%d max). Entferne zuerst jemanden mit Rechtsklick oder /ms friend remove Name."
L["FRIEND_ALREADY_IN"]       = "%s ist bereits in deiner Freundesliste."
L["FRIEND_ADDED"]            = "%s zur Freundesliste hinzugef\xC3\xBCgt (%d/%d)."
L["FRIEND_REMOVED"]          = "%s aus der Freundesliste entfernt (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s nicht in der Freundesliste gefunden."
L["FRIEND_ONLINE_UPDATED"]   = "%s (Online) \xe2\x80\x94 Aktualisiert"

---------------------------------------------------------------------------
-- UI — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - Begegnungsdetails"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Kampfhistorie"
L["TITLE_HUD"]               = "Midnight Sensei"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Kampf abgeschlossen"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Optionen"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei \xe2\x80\x94 \xC3\x9Cberpr\xC3\xBCfungsbericht"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei \xe2\x80\x94 \xC3\x9Cberpr\xC3\xBCfungsvergleich"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - Meine Zauberliste"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Debug-Werkzeuge"
L["TITLE_CREDITS"]           = "Midnight Sensei - Credits & \xC3\x9Cber"
L["TITLE_FAQ"]               = "Midnight Sensei - Hilfe & FAQ"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Rotations-Tracker"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei \xe2\x80\x94 Update verf\xC3\xBCgbar"

---------------------------------------------------------------------------
-- UI — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Details ansehen"
L["CTX_DELETE_ENTRY"]        = "Eintrag l\xC3\xB6schen"
L["CTX_CANCEL"]              = "Abbrechen"
L["CTX_LOCK_POSITION"]       = "Position sperren"
L["CTX_UNLOCK_POSITION"]     = "Position entsperren"
L["CTX_GRADE_HISTORY"]       = "Kampfhistorie"
L["CTX_LEADERBOARD"]         = "Rangliste"
L["CTX_BOSS_BOARD"]          = "Boss-Brett"
L["CTX_OPTIONS"]             = "Optionen"
L["CTX_MY_SPELL_LIST"]       = "Meine Zauberliste"
L["CTX_HELP_FAQ"]            = "Hilfe / FAQ"
L["CTX_CREDITS"]             = "Credits"
L["CTX_DEBUG_TOOLS"]         = "Debug-Werkzeuge"
L["CTX_CLOSE_HUD"]           = "HUD schlie\xC3\x9Fen"

---------------------------------------------------------------------------
-- UI — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Dauer: %s    Note: %s  (%s)"
L["DETAIL_SCORE"]            = "Score: %d"
L["DETAIL_COMPONENT_SCORES"] = "Komponenten-Scores:"
L["DETAIL_FEEDBACK"]         = "Feedback:"
L["DETAIL_ENC_DUNGEON"]      = "Dungeon"
L["DETAIL_ENC_RAID"]         = "Schlachtzug"
L["DETAIL_ENC_DELVE"]        = "Tiefe"
L["DETAIL_ENC_WORLD"]        = "Welt"
L["DETAIL_ENC_COMBAT"]       = "Kampf"
L["BTN_CLOSE"]               = "Schlie\xC3\x9Fen"

---------------------------------------------------------------------------
-- UI — grade history panel
---------------------------------------------------------------------------
L["HISTORY_TREND_LABEL"]     = "Trend (letzte 20):"
L["HISTORY_FILTER_LABEL"]    = "Filter:"
L["FILTER_THIS_CHARACTER"]   = "Dieser Charakter"
L["FILTER_BOSS_ONLY"]        = "Nur [Boss]"
L["HISTORY_COL_GR"]          = "N"
L["HISTORY_COL_CHARACTER"]   = "CHARAKTER"
L["HISTORY_COL_SPEC_DIFF"]   = "SPEZ. / SCHW."
L["HISTORY_COL_SCORE"]       = "SCORE"
L["HISTORY_COL_DUR"]         = "DAUER"
L["HISTORY_COL_WHEN"]        = "WANN"
L["HISTORY_LB_BTN"]          = "Rangliste ->"
L["HISTORY_STATS"]           = "%d K\xC3\xA4mpfe  -  Avg: %d  -  Bester: %s  -  Schlechtester: %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d Niederlage%s"
L["HISTORY_NO_MATCHES"]      = "Keine Begegnungen entsprechen dem aktuellen Filter."

---------------------------------------------------------------------------
-- UI — relative time labels
---------------------------------------------------------------------------
L["TIME_JUST_NOW"]           = "gerade eben"
L["TIME_MINUTES_AGO"]        = "vor %dm"
L["TIME_HOURS_AGO"]          = "vor %dh"
L["TIME_DAYS_AGO"]           = "vor %dt"

---------------------------------------------------------------------------
-- UI — HUD
---------------------------------------------------------------------------
L["HUD_NO_FIGHT"]            = "Noch kein Kampf aufgezeichnet"
L["HUD_IN_COMBAT"]           = "Im Kampf..."
L["HUD_FIGHT_TOO_SHORT"]     = "Kampf zu kurz f\xC3\xBCr Aufzeichnung"
L["BTN_REVIEW_FIGHT"]        = "Kampf ansehen"
L["BTN_BOSS_BOARD"]          = "Boss-Brett"
L["BTN_LEADERBOARD"]         = "Rangliste"
L["VERIFY_BAR_LABEL"]        = "\xC3\x9Cberpr\xC3\xBCfungsmodus aktiv"
L["BTN_VIEW_REPORT"]         = "Bericht anzeigen"
L["UPDATE_BAR_LABEL"]        = "Neue Version verf\xC3\xBCgbar  (Klicken f\xC3\xBCr Details)"
L["TT_MENU"]                 = "Men\xC3\xBC"
L["TT_HIDE_HUD"]             = "HUD ausblenden"
L["TT_DISMISS"]              = "Schlie\xC3\x9Fen"
L["TT_UPDATE_AVAILABLE"]     = "Update verf\xC3\xBCgbar"
L["TT_UPDATE_CHECK"]         = "Pr\xC3\xBCfe Curseforge oder Wago auf die neueste Version."
L["TT_BOSS_BOARD"]           = "Boss-Brett"
L["TT_BOSS_BOARD_DESC"]      = "Pers\xC3\xB6nliche Boss-Bestscores aller Zeiten"
L["TT_LEADERBOARD"]          = "Rangliste"
L["TT_LEADERBOARD_DESC"]     = "Gilde / Gruppe / Freunde / Tiefen"

---------------------------------------------------------------------------
-- UI — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Sauberer Kampf \xe2\x80\x94 nichts Wesentliches zu beanstanden."
L["FIGHT_SCORE_DUR"]         = "Score: %d   Dauer: %s"
L["FIGHT_COMPONENT_SCORES"]  = "Komponenten-Scores:"
L["BTN_HISTORY"]             = "Historie"

---------------------------------------------------------------------------
-- UI — options panel
---------------------------------------------------------------------------
L["OPT_HUD_VISIBILITY"]      = "HUD-Sichtbarkeit:"
L["OPT_VIS_ALWAYS"]          = "Immer"
L["OPT_VIS_IN_COMBAT"]       = "Im Kampf"
L["OPT_VIS_HIDE"]            = "Ausblenden"
L["OPT_BEHAVIOUR"]           = "Verhalten:"
L["OPT_SHOW_POST_FIGHT"]     = "Nach-Kampf-\xC3\x9Cberpr\xC3\xBCfungsschaltfl\xC3\xA4che im HUD anzeigen"
L["OPT_LOCK_HUD"]            = "HUD-Position sperren"
L["OPT_ENCOUNTER_ADJUST"]    = "Begegnungsbedingungsanpassung"
L["OPT_DEBUG_MODE"]          = "Debug-Modus (zeigt LB-Ablehnungsmeldungen)"
L["OPT_LEADERBOARD"]         = "Rangliste:"
L["OPT_LB_NOTE"]             = "Wochendurchschnitt z\xC3\xA4hlt immer nur Boss-Begegnungen. Trash-Pulls und \xC3\x9Cbungspuppen werden nie einbezogen."
L["BTN_REPORT_ISSUES"]       = "Probleme melden"

---------------------------------------------------------------------------
-- UI — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei \xe2\x80\x94 Fehler melden\n\nKopiere den Link unten und f\xC3\xBCge ihn in deinen Browser ein.\nStrg+A zum Alles ausw\xC3\xA4hlen, dann Strg+C zum Kopieren."
L["REPORT_POPUP_BTN"]        = "Schlie\xC3\x9Fen"

---------------------------------------------------------------------------
-- UI — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Strg+A zum Alles ausw\xC3\xA4hlen  \xC2\xB7  Strg+C zum Kopieren  \xC2\xB7  In einen GitHub-Kommentar einf\xC3\xBCgen"
L["BTN_COMPARE"]             = "Vergleichen"

---------------------------------------------------------------------------
-- UI — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Hier angezeigte Zauber werden derzeit von Midnight Sensei \xC3\xBCberwacht."
L["SPELL_LIST_NO_SPEC"]      = "Keine Spezialisierung erkannt. F\xC3\xBChre zuerst einen Kampf durch."
L["SPELL_LIST_SEC_CDS"]      = "Abklingzeit-Zauber"
L["SPELL_LIST_SEC_INT"]      = "Unterbrechung & Hilfsf\xC3\xA4higkeiten"
L["SPELL_LIST_SEC_ROT"]      = "Rotationszauber"
L["SPELL_LIST_SEC_UPTIME"]   = "Uptime-Buffs"
L["SPELL_LIST_SEC_PROCS"]    = "Proc-Buffs"
L["SPELL_LIST_SITUATIONAL"]  = "situativ"
L["SPELL_LIST_SPEND_FAST"]   = "schnell ausgeben"
L["SPELL_LIST_TARGET_UP"]    = "Ziel: %d%% Uptime"
L["SPELL_LIST_METAMORPH"]    = "Erfordert Metamorphose"

---------------------------------------------------------------------------
-- UI — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- \xC3\x9Cberpr\xC3\xBCfungs-Werkzeuge --"
L["DEBUG_SEC_CLASS"]         = "-- Klassen-Debug --"
L["DEBUG_SEC_RECOVERY"]      = "-- Wiederherstellungs-Werkzeuge --"
L["DEBUG_BTN_VERIFY_MODE"]   = "\xC3\x9Cberpr\xC3\xBCfungsmodus"
L["DEBUG_BTN_VERIFY_DESC"]   = "Zauber-ID-Erfassung f\xC3\xBCr /ms verify report umschalten"
L["DEBUG_BTN_VR"]            = "\xC3\x9Cberpr\xC3\xBCfungsbericht"
L["DEBUG_BTN_VR_DESC"]       = "Zauber-ID-\xC3\x9Cberpr\xC3\xBCfungsbericht in kopierbares Fenster exportieren"
L["DEBUG_BTN_AUTO_VERIFY"]   = "\xC3\x9Cberpr\xC3\xBCfung beim Login automatisch aktivieren"
L["DEBUG_BTN_AV_DESC"]       = "\xC3\x9Cberpr\xC3\xBCfungsmodus aktiviert sich nach jedem Reload oder Login automatisch"
L["DEBUG_BTN_VERSION"]       = "Version"
L["DEBUG_BTN_VERSION_DESC"]  = "Addon-Version aus TOC und Metadaten-APIs anzeigen"
L["DEBUG_BTN_ROT_TRACKER"]   = "Rotations-Tracker"
L["DEBUG_BTN_RT_DESC"]       = "Rotations-Tracker-Fenster \xC3\xB6ffnen \xe2\x80\x94 Wirkanzahl, Status und Flaggenerl\xC3\xA4uterungen f\xC3\xBCr jeden Zauber"
L["DEBUG_BTN_TALENT_EXP"]    = "Talent-Export"
L["DEBUG_BTN_TE_DESC"]       = "Aktiven Talent-Snapshot f\xC3\xBCr Spez.-DB-Quervergleich exportieren"
L["DEBUG_BTN_SPELLS_EXP"]    = "Zauber-Export"
L["DEBUG_BTN_SE_DESC"]       = "Vollst\xC3\xA4ndigen Zauberbuch-Snapshot f\xC3\xBCr Spez.-DB-Quervergleich exportieren"
L["DEBUG_BTN_BB_INGEST"]     = "Boss-Brett-Ingest"
L["DEBUG_BTN_BBI_DESC"]      = "Boss-Brett aus Begegnungshistorie bef\xC3\xBCllen"
L["DEBUG_BTN_FIX_NAME"]      = "Charakternamen korrigieren"
L["DEBUG_BTN_FN_DESC"]       = "Wenn du deinen Charakter umbenannt hast, starte dies"
L["DEBUG_BTN_BACKFILL"]      = "M+-Schl\xC3\xBCssel nachf\xC3\xBCllen"
L["DEBUG_BTN_BK_DESC"]       = "Mythischer Dungeon-Verlauf mit saisonalen Bestschl\xC3\xBCsseln patchen"
L["DEBUG_BTN_CLEAN"]         = "Payload bereinigen"
L["DEBUG_BTN_CP_DESC"]       = "Alle deine Bestscores mit korrektem Format erneut senden"
L["DEBUG_BTN_CLEAR_BB"]      = "Boss-Brett leeren"
L["DEBUG_BTN_CBB_DESC"]      = "L\xC3\xB6scht dauerhaft alle pers\xC3\xB6nlichen Boss-Bestrekorde \xe2\x80\x94 kann nicht r\xC3\xBCckg\xC3\xA4ngig gemacht werden"
L["DEBUG_BTN_CLEAR_HIST"]    = "Kampfhistorie leeren"
L["DEBUG_BTN_CH_DESC"]       = "L\xC3\xB6scht dauerhaft alle aufgezeichneten Begegnungen \xe2\x80\x94 kann nicht r\xC3\xBCckg\xC3\xA4ngig gemacht werden"
L["DEBUG_BTN_RUN"]           = "Ausf\xC3\xBChren"
L["DEBUG_BTN_TOGGLE"]        = "Umschalten"

---------------------------------------------------------------------------
-- UI — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Tippe  Confirm  um das L\xC3\xB6schen zu aktivieren:"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Boss-Brett leeren"
L["DESTRUCT_CLEAR_BB_BODY"]  = "Dies l\xC3\xB6scht dauerhaft alle Boss-Brett-Eintr\xC3\xA4ge f\xC3\xBCr diesen Charakter.\nDiese Aktion kann nicht r\xC3\xBCckg\xC3\xA4ngig gemacht werden."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Boss-Brett l\xC3\xB6schen"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Kampfhistorie leeren"
L["DESTRUCT_CLEAR_HIST_BODY"] = "Dies l\xC3\xB6scht dauerhaft alle aufgezeichneten Kampfbegegnungen f\xC3\xBCr diesen Charakter.\nDiese Aktion kann nicht r\xC3\xBCckg\xC3\xA4ngig gemacht werden."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Kampfhistorie l\xC3\xB6schen"
L["BTN_CANCEL"]              = "Abbrechen"

---------------------------------------------------------------------------
-- UI — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "\xC3\x9Cber"
L["CREDITS_TAB_SOURCES"]     = "Quellen"
L["CREDITS_TAB_CHANGELOG"]   = "\xC3\x84nderungsprotokoll"
L["CREDITS_SOURCES_INTRO"]   = "Rotationshinweise basieren auf folgenden Community-Ressourcen."
L["CREDITS_SOURCES_ACK"]     = "Wir danken herzlich f\xC3\xBCr ihre Beitr\xC3\xA4ge."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei ist nicht mit diesen Ressourcen verbunden."
L["CREDITS_NO_CHANGELOG"]    = "Kein \xC3\x84nderungsprotokoll verf\xC3\xBCgbar."
L["CREDITS_ABOUT_TEXT"]      = "Ein Kampfleistungs-Coaching-Addon f\xC3\xBCr World of Warcraft: Midnight.\nBewertet deine K\xC3\xA4mpfe von A+ bis F f\xC3\xBCr alle 13 Klassen und 40 Spez.,\nmit umsetzbarem Feedback, angepasst an Rolle und Spezialisierung."
L["CREDITS_AUTHOR"]          = "Autor:  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Features:"
L["CREDITS_FEAT_GRADING"]    = "  - Kampfbewertung: Abklingzeit-Nutzung, Aktivit\xC3\xA4t, Ressourcenverwaltung"
L["CREDITS_FEAT_TALENT"]     = "  - Talentbewusst: bewertet nur tats\xC3\xA4chlich ausr\xC3\xBCstete F\xC3\xA4higkeiten"
L["CREDITS_FEAT_BOSS"]       = "  - Boss-Erkennung: verfolgt ENCOUNTER_START/END f\xC3\xBCr echte Boss-K\xC3\xA4mpfe"
L["CREDITS_FEAT_SOCIAL"]     = "  - Soziale Rangliste: Gilde, Gruppe und BNet-Freunde Rankings"
L["CREDITS_FEAT_WEEKLY"]     = "  - W\xC3\xB6chentlicher Reset: abgestimmt auf Blizzards Dienstag 16:00 Uhr MESZ"
L["CREDITS_FEAT_DELVE"]      = "  - Tiefen-Verfolgung: tier-basiertes Scoring f\xC3\xBCr Solo-Inhalte"
L["CREDITS_FEAT_SYNC"]       = "  - Score-Synchronisation: synchronisiert zwischen Gildenmitgliedern zur Wiederherstellung nach Neuinstallation"
L["CREDITS_CONTACT"]         = "Kontakt:  MidnightTim auf GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei ist ein Community-Addon, nicht verbunden mit Blizzard."

---------------------------------------------------------------------------
-- UI — FAQ headers
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "ERSTE SCHRITTE"
L["FAQ_HDR_UNDERSTANDING"]   = "DEINE NOTE VERSTEHEN"
L["FAQ_HDR_ROTATIONAL"]      = "ROTATIONSZAUBER-FEEDBACK"
L["FAQ_HDR_VISIBILITY"]      = "SICHTBARKEITSOPTIONEN"
L["FAQ_HDR_HISTORY"]         = "KAMPFHISTORIE"
L["FAQ_HDR_LEADERBOARD"]     = "RANGLISTE"
L["FAQ_HDR_MIDNIGHT_NOTE"]   = "HINWEIS ZU MIDNIGHT 12.0 EINSCHR\xC3\x84NKUNGEN"
L["FAQ_HDR_BOSS_COMBAT"]     = "BOSS- VS. NORMALER KAMPF"
L["FAQ_HDR_TALENT_AWARE"]    = "TALENTBEWUSSTE ABKLINGZEITEN"
L["FAQ_HDR_ALL_COMMANDS"]    = "ALLE BEFEHLE"
L["FAQ_MIN_FIGHT"]           = "Ein Kampf k\xC3\xBCrzer als 15 Sekunden wird nicht aufgezeichnet."
L["FAQ_VIS_ALWAYS"]          = "  Immer: HUD immer sichtbar"
L["FAQ_VIS_COMBAT"]          = "  Im Kampf: HUD nur w\xC3\xA4hrend des Kampfes sichtbar"
L["FAQ_VIS_HIDE"]            = "  Ausblenden: HUD versteckt (zug\xC3\xA4nglich via /ms show)"
L["FAQ_CMD_SHOW"]            = "  /ms show         HUD anzeigen"
L["FAQ_CMD_HIDE"]            = "  /ms hide         HUD ausblenden"
L["FAQ_CMD_HISTORY"]         = "  /ms history      Kampfhistorie & Trends"
L["FAQ_CMD_LB"]              = "  /ms lb           Soziale Rangliste"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Spieler aus Gilden-Rangliste entfernen"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Einstellungen"
L["FAQ_CMD_FAQ"]             = "  /ms faq          Diese Seite"
L["FAQ_CMD_UPDATE"]          = "  /ms update       \xC3\x84nderungsprotokoll anzeigen"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Credits & \xC3\x9Cber"
L["FAQ_CMD_REPORT"]          = "  /ms report       Fehler auf GitHub melden"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Addon-Versionen dieser Sitzung anzeigen"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Letzten Score eines Spielers abfragen"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Rotations-Tracker \xC3\xB6ffnen (Wirkanzahl + Zaubererl\xC3\xA4uterungen)"

---------------------------------------------------------------------------
-- UI — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Tippe |cffFFFFFF/ms show|r um das HUD zu \xC3\xB6ffnen, |cffFFFFFF/ms hide|r um es zu schlie\xC3\x9Fen.\nDas HUD zeigt deine letzte Note, deinen Score und deine Spez. Nach einem Kampf\nsiehst du eine |cffFFFFFF>> Kampf ansehen|r Schaltfl\xC3\xA4che. Rechtsklicke das HUD f\xC3\xBCr schnellen\nZugriff auf alle Funktionen."
L["FAQ_BODY_UNDERSTANDING"]   = "Noten reichen von F bis A+. Jede Spezialisierung hat gewichtete Kategorien:\n  - Abklingzeit-Nutzung: hast du deine wichtigsten Abklingzeiten genutzt?\n  - Rotationszauber: hast du Schl\xC3\xBCsselrotationsf\xC3\xA4higkeiten in jedem Kampf eingesetzt?\n  - Aktivit\xC3\xA4t: hast du gleichm\xC3\xA4\xC3\x9Fig gewirkt? (keine langen Leerlaufphasen)\n  - Ressourcenverwaltung: hast du deine Ressource \xC3\xBCberf\xC3\xBCllt (Wut/Energie/etc.)?\n  - Buff-Uptime: hast du deine Selbstbuffs aktiv gehalten? (je nach Spez.)\n  - Proc-Nutzung: hast du Procs schnell verbraucht? (Frost-TK, Feuer-Magier...)?\n  - Heiler-Effizienz: wie viel deiner Heilung war \xC3\x9Cberheilen?"
L["FAQ_BODY_ROTATIONAL"]      = "Zus\xC3\xA4tzlich zu Abklingzeiten verfolgt Midnight Sensei, ob du\nSchl\xC3\xBCssel-Rotationszauber in jedem Kampf eingesetzt hast (z.B. Implosion, Zerrei\xC3\x9Fen, Vernichten).\nWenn du einen in einem ausreichend langen Kampf nie eingesetzt hast, erscheint er in\ndeinem Feedback. Talentgebundene Zauber werden \xC3\xBCbersprungen, wenn du das Talent nicht hast."
L["FAQ_BODY_VIS_INTRO"]       = "\xC3\x96ffne |cffFFFFFF/ms options|r (oder Rechtsklick HUD -> Optionen) und setze:"
L["FAQ_BODY_HISTORY"]         = "Tippe |cffFFFFFF/ms history|r oder Rechtsklick -> Kampfhistorie.\n  - Nach diesem Charakter oder allen Charakteren filtern\n  - Sparkline zeigt deine letzten 20 K\xC3\xA4mpfe auf einen Blick\n  - Linksklick auf eine Zeile um vollst\xC3\xA4ndige Details und Feedback zu sehen\n  - Rechtsklick auf eine Zeile um diesen Eintrag zu l\xC3\xB6schen"
L["FAQ_BODY_LEADERBOARD"]     = "Tippe |cffFFFFFF/ms lb|r um die soziale Rangliste zu \xC3\xB6ffnen.\nNach jedem Boss-Kampf wird dein Score an Gilde, Gruppe und\nBNet-Freunde mit installiertem Midnight Sensei gesendet.\nTabs: Gruppe (nur Sitzung), Gilde (sitzungs\xC3\xBCbergreifend), Freunde.\nGilden-Scores bleiben zwischen Sitzungen erhalten und synchronisieren zwischen Gildenmitgliedern \xe2\x80\x94\nsogar wenn ein Spieler offline ist, kannst du seinen letzten aufgezeichneten Score sehen.\nWochendurchschnitt z\xC3\xA4hlt nur Boss-Begegnungen \xe2\x80\x94 Trash-Pulls und \xC3\x9Cbungspuppen\nwerden nie in die Rangliste einbezogen.\nRechtsklick auf eine Gildenzeile um einen Spieler zu entfernen. Sie erscheinen\nautomatisch wieder beim n\xC3\xA4chsten Einloggen oder Aktualisieren."
L["FAQ_BODY_LB_EXTRA"]        = "Jeder Tab (Dungeons, Schlachtz\xC3\xBCge) zeigt Ortsinformationen nur f\xC3\xBCr diesen Inhaltstyp\n\xe2\x80\x94 ein LFR-Run erscheint nie im Dungeons-Tab.\nMythisch+-Schl\xC3\xBCsselstufe wird angezeigt wenn verf\xC3\xBCgbar (z.B. M+15).\nNach einem Addon-Update muss jeder Spieler einen neuen\nDungeon oder Schlachtzug abschlie\xC3\x9Fen damit der Tab-Ort korrekt angezeigt wird.\nDein eigener Eintrag aktualisiert sich sofort aus der lokalen Historie \xe2\x80\x94 kein neuer Run n\xC3\xB6tig."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard hat feindliche Einheits-Aura-Abfragen in Midnight 12.0 eingeschr\xC3\xA4nkt.\nZiel-Debuffs (Ausbluten, Flammenschock, etc.) k\xC3\xB6nnen nicht direkt verfolgt werden.\nDiese erscheinen in deinen priorityNotes als Hinweise, werden aber nicht bewertet.\nAlle Spieler-Selbstbuffs, Abklingzeiten und Rotationswirkungen funktionieren normal."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei erkennt Boss-Begegnungen \xC3\xBCber ENCOUNTER_START/END.\nBoss-K\xC3\xA4mpfe zeigen ein |cffFF6600[Boss]|r Tag in Historie und Begegnungsdetails.\nFiltere deine Historie nach |cffFFFFFF[Boss] Nur|r um Raid-/Dungeon-Boss-Versuche zu \xC3\xBCberpr\xC3\xBCfen."
L["FAQ_BODY_TALENT_AWARE"]    = "Abklingzeit-Scoring umfasst nur Zauber die du erlernt hast.\nWenn du ein Talent nicht hast, wird es nicht gegen dich gewertet."

---------------------------------------------------------------------------
-- UI — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Wirkanzahl aus deinem letzten Kampf. Jeder Zauber zeigt wie oft er benutzt wurde und warum er verfolgt wird."
L["ROT_TRACKER_NO_DATA"]     = "Noch keine Kampfdaten \xe2\x80\x94 f\xC3\xBChre einen Kampf durch um Tracking-Ergebnisse zu sehen."
L["ROT_TRACKER_LAST_FIGHT"]  = "Letzter Kampf: %s"
L["ROT_TRACKER_NO_FIGHT"]    = "Noch kein Kampf aufgezeichnet"
L["ROT_COL_SPELL"]           = "ZAUBER"
L["ROT_COL_CASTS"]           = "WIRKUNGEN"
L["ROT_COL_MIN_FIGHT"]       = "MIN. KAMPF"
L["ROT_COL_STATUS"]          = "STATUS"
L["ROT_STATUS_CAST"]         = "GEWIRKT"
L["ROT_STATUS_MISSED"]       = "VERPASST"
L["ROT_STATUS_SHORT"]        = "KURZ"
L["ROT_FLAG_COMBAT_TALENT"]  = "Erfordert Talent; nur wirbar w\xC3\xA4hrend eines Verwandlungsfensters"
L["ROT_FLAG_COMBAT_ONLY"]    = "Nur wirbar w\xC3\xA4hrend eines Verwandlungsfensters (z.B. Leere Metamorphose)"
L["ROT_FLAG_TALENT_ONLY"]    = "Wird nur verfolgt wenn dieses Talent in deinem Build aktiv ist"
L["ROT_FLAG_CORE"]           = "Kern-Rotationsf\xC3\xA4higkeit \xe2\x80\x94 erwartet in jedem Kampf"
L["ROT_FLAG_MIN_FIGHT"]      = "als verpasst gewertet nur wenn Kampf > %ds"
L["ROT_NOT_TRACKED"]         = "In diesem Build nicht verfolgt (Talent nicht genommen oder ersetzt): %s"
L["ROT_LEGEND_CAST_DESC"]    = "mindestens einmal gewirkt"
L["ROT_LEGEND_MISSED_DESC"]  = "Kampf war lang genug aber Zauber wurde nicht gewirkt"
L["ROT_LEGEND_SHORT_DESC"]   = "Kampf zu kurz zum Bewerten"

---------------------------------------------------------------------------
-- UI — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "Eine neue Version von Midnight Sensei ist verf\xC3\xBCgbar.\nPr\xC3\xBCfe Curseforge oder Wago auf die neueste Version."
L["SETTINGS_CATEGORY"]       = "Midnight Sensei"
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Erstellt von Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Optionen \xC3\xB6ffnen"
L["SETTINGS_BTN_OPT_DESC"]   = "HUD, Spielstil und mehr konfigurieren"
L["SETTINGS_BTN_HISTORY"]    = "Kampfhistorie"
L["SETTINGS_BTN_HIST_DESC"]  = "Kampfhistorie und Trends anzeigen"
L["SETTINGS_BTN_LB"]         = "Rangliste"
L["SETTINGS_BTN_LB_DESC"]    = "Gilde / Gruppe / Freunde / Tiefen Rankings"
L["SETTINGS_BTN_FAQ"]        = "Hilfe & FAQ"
L["SETTINGS_BTN_FAQ_DESC"]   = "Wie Scoring und Bewertung funktioniert"
L["SETTINGS_BTN_CREDITS"]    = "Credits & \xC3\x9Cber"
L["SETTINGS_BTN_CRED_DESC"]  = "Autor-Infos und Quellen"
L["SETTINGS_LEGACY_SUB"]     = "Erstellt von Midnight - Thrall (US)  |  /ms f\xC3\xBCr Befehle"
L["MINIMAP_TT_TITLE"]        = "Midnight Sensei"
L["MINIMAP_TT_LEFT"]         = "Linksklick: HUD umschalten"
L["MINIMAP_TT_RIGHT"]        = "Rechtsklick: Rangliste"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Strg+Rechtsklick: Boss-Brett"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "Umschalt+Rechtsklick: Optionen"

---------------------------------------------------------------------------
-- Analytics/Feedback
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "Du hast Abklingzeit-Potenzial verschenkt durch ungenutzte Abklingzeiten%s: %s. Gleichm\xC3\xA4\xC3\x9Figes Dr\xC3\xBCcken hilft."
L["FB_NEVER_PRESSED"]        = "Nie gedr\xC3\xBCckt%s: %s \xe2\x80\x94 %s."
L["FB_ACTION_TANK"]          = "bei Tank-Busters oder hohen Schadensfenstern einsetzen"
L["FB_ACTION_HEALER"]        = "mit hohen eingehenden Schadensfenstern ausrichten"
L["FB_ACTION_DPS"]           = "mit Burst-Fenstern ausrichten"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Deine Rotation ist gleichm\xC3\xA4\xC3\x9Fig, aber L\xC3\xBCcken zwischen Wirkungen (%d%% Aktivit\xC3\xA4t) sind die n\xC3\xA4chste Sache die zu verbessern ist."
L["FB_ACTIVITY_MODERATE"]    = "Aktivit\xC3\xA4t bei %d%% \xe2\x80\x94 ca. %d Wirkung(en) ungenutzt. Stelle deine n\xC3\xA4chste Wirkung in die Warteschlange bevor die aktuelle landet."
L["FB_ACTIVITY_LOW"]         = "Aktivit\xC3\xA4t: %d/%d GCDs (%d%%) \xe2\x80\x94 %s Ausfallzeit, ca. %d Wirkungen verloren. Finde deinen n\xC3\xA4chsten Zauber bevor der aktuelle endet."
L["FB_DOWNTIME_SIGNIFICANT"] = "erheblich"
L["FB_DOWNTIME_MODERATE"]    = "m\xC3\xA4\xC3\x9Fig"
L["FB_UNDERUSED"]            = "Seltener als erwartet in einem %.1fmin-Kampf eingesetzt: %s \xe2\x80\x94 Ziel: 1 Einsatz pro 2 Minuten Kampfzeit."
L["FB_ROT_NEVER_USED"]       = "Rotationszauber nie eingesetzt: %s \xe2\x80\x94 diese sind entscheidend f\xC3\xBCr deine %s."
L["FB_ROT_CONTEXT_TANK"]     = "\xC3\x9Cberlebens- und Bedrohungsrotation"
L["FB_ROT_CONTEXT_HEALER"]   = "Heilungsdurchsatz"
L["FB_ROT_CONTEXT_DPS"]      = "Schadensaussto\xC3\x9F"
L["FB_ROT_LOW_USED"]         = "H\xC3\xA4tte mehr wirken k\xC3\xB6nnen: %s \xe2\x80\x94 wirke diese bei jedem verf\xC3\xBCgbaren GCD wenn deine prim\xC3\xA4ren Ausgaben-Zauber auf Abklingzeit sind."
L["FB_PROC_DELAYED"]         = "verz\xC3\xB6gert"
L["FB_PROC_CRITICALLY"]      = "kritisch verz\xC3\xB6gert"
L["FB_PROC_MSG"]             = "%s-Verbrauch ist %s \xe2\x80\x94 durchschnittlich %.1fs gehalten (Budget: %ds). Verbrauche Procs sofort wenn sie erscheinen."
L["FB_OVERCAP"]              = "%s %d-mal \xC3\xBCberf\xC3\xBCllt (%.1f/min) \xe2\x80\x94 gib %s aus bevor %d erreicht wird um verschwendete Generierung zu vermeiden."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s wurde nie aktiviert \xe2\x80\x94 dr\xC3\xBCcke es bei jeder verf\xC3\xBCgbaren Gelegenheit um erlittenen physischen Schaden zu reduzieren."
L["FB_MIT_LOW_UPTIME"]       = "%s: %d%% Uptime vs %d%% Ziel (%dpt L\xC3\xBCcke, %d Anwendung(en)) \xe2\x80\x94 du hast gro\xC3\x9Fe Fenster mit ungemildertem physischen Schaden. Dr\xC3\xBCcke es sofort wenn es von der Abklingzeit kommt."
L["FB_MIT_SMALL_GAPS"]       = "%s: %d%% Uptime vs %d%% Ziel (%dpt L\xC3\xBCcke) \xe2\x80\x94 kleine L\xC3\xBCcken summieren sich. Benutze es vorbeugend bei schweren Nahkampfsequenzen, nicht reaktiv."
L["FB_BUFF_LOW_UPTIME"]      = "%s: %d%% Uptime vs %d%% Ziel (%dpt L\xC3\xBCcke) \xe2\x80\x94 erneuere es bevor es abl\xC3\xA4uft, nicht danach."
L["FB_GROUP_BUFF_NOTE"]      = "%s (Gruppen-Buff \xe2\x80\x94 stelle sicher dass er vor dem Kampf aktiv ist)"
L["FB_OVERHEAL_HIGH"]        = "\xC3\x9Cberheilen bei %.1f%% (Ziel: <%d%%) \xe2\x80\x94 du gibst Mana f\xC3\xBCr Ziele aus die keine Heilung brauchen. Wirke etwas sp\xC3\xA4ter oder wechsle zu reaktiven Zaubern auf Ziele die aktiv Schaden nehmen."
L["FB_OVERHEAL_ELEVATED"]    = "\xC3\x9Cberheilen: %.1f%% (Ziel: <%d%%) \xe2\x80\x94 leicht erh\xC3\xB6ht. Halte Wirkungen auf Ziele \xC3\xBCber 70%% zur\xC3\xBCck und bevorzuge HoTs gegen\xC3\xBCber Direktheilungen bei stabilen Gruppen."
L["FB_HEALER_FILL_DOWNTIME"] = "Wenn die Gruppe stabil ist, f\xC3\xBClle Ausfallzeit mit Schadenszaubern um den Durchsatz aufrechtzuerhalten."
L["FB_SIMPLIFIED_FALLBACK"]  = "Deine Rotation ist gleichm\xC3\xA4\xC3\x9Fig und gut getaktet. Das Verfeinern des Burst-Fenster-Timings ist der n\xC3\xA4chste Leistungsschritt."
L["FB_NEAR_PERFECT"]         = "Nahezu perfekte Ausf\xC3\xBChrung. Die verbleibenden Gewinne sind: %s."
L["FB_NEXT_TANK_PREPOS"]     = "Defensive vorpositionieren vor vorhersehbarem Spike-Schaden"
L["FB_NEXT_HEALER_OVERLAP"]  = "Abklingzeiten mit eingehenden Schadensimpulsen \xC3\xBCberlappen statt zu reagieren"
L["FB_NEXT_DPS_ALIGN"]       = "Burst-Fenster mit feindlichen Verwundbarheitsphasen ausrichten"
L["FB_NEXT_GCD_TIMING"]      = "Zeit zwischen GCD-Ende und n\xC3\xA4chster Wirkung auf unter 0,2s reduzieren"
L["FB_STRONG_EXECUTION"]     = "Insgesamt starke Ausf\xC3\xBChrung. Deine schw\xC3\xA4chste Kategorie ist %s \xe2\x80\x94 dort kommen die n\xC3\xA4chsten Punkte her."
L["FB_GOOD_FOUNDATION"]      = "Gute Grundlage \xe2\x80\x94 als n\xC3\xA4chstes konzentrieren auf: %s."
L["FB_HINT_TANK_CDS"]        = "Defensive Abklingzeiten bei Tank-Busters nutzen"
L["FB_HINT_PRESS_CDS"]       = "Wichtige Abklingzeiten gleichm\xC3\xA4\xC3\x9Figer dr\xC3\xBCcken"
L["FB_HINT_MIT_UPTIME"]      = "Milderungs-Uptime erh\xC3\xB6hen indem %s h\xC3\xA4ufiger gedr\xC3\xBCckt wird"
L["FB_SOLID"]                = "Solide Leistung \xe2\x80\x94 verfeinere das Abklingzeit-Timing um h\xC3\xB6her zu kommen."
L["FB_NOTE_INTERRUPT"]       = "Hinweis: %s \xe2\x80\x94 das ist deine Unterbrechung. In diesem Kampf nicht genutzt \xe2\x80\x94 keine Strafe."
L["FB_NOTE_UTILITY"]         = "Hinweis: %s \xe2\x80\x94 in diesem Kampf nicht genutzt oder erkannt. Keine Strafe."
L["FB_NOTE_COMBAT_UTILITY"]  = "Hinweis: %s \xe2\x80\x94 bet\xC3\xA4ubt und verursacht zus\xC3\xA4tzlich Schaden. Nutze es situativ; keine Strafe f\xC3\xBCr das Zur\xC3\xBCckhalten."
