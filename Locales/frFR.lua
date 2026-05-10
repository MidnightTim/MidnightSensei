-- MidnightSensei — Locale: frFR (Français)
-- Loaded after enUS.lua. Early-returns if the client is not French.
-- Only keys present here override the English defaults.

local locale = GetLocale()
if locale ~= "frFR" then return end
local L = MidnightSensei.L

---------------------------------------------------------------------------
-- Grade labels
---------------------------------------------------------------------------
L["GRADE_EXCEPTIONAL"]       = "Exceptionnel"
L["GRADE_EXCELLENT"]         = "Excellent"
L["GRADE_GREAT_WORK"]        = "Excellent travail"
L["GRADE_STRONG"]            = "Fort"
L["GRADE_ON_TRACK"]          = "Sur la bonne voie"
L["GRADE_SOLID"]             = "Solide"
L["GRADE_GOOD_FOUNDATION"]   = "Bonne base"
L["GRADE_ROOM_TO_GROW"]      = "Place pour progresser"
L["GRADE_KEEP_PRACTICING"]   = "Continue \xC3\xA0 t'entra\xC3\xAEner"
L["GRADE_BUILDING_HABITS"]   = "Construction d'habitudes"
L["GRADE_LEARNING_CURVE"]    = "Courbe d'apprentissage"
L["GRADE_EARLY_DAYS"]        = "D\xC3\xA9buts"
L["GRADE_FRESH_START"]       = "Nouveau d\xC3\xA9part"

---------------------------------------------------------------------------
-- Addon load / level gate
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "charg\xC3\xA9.  /ms show pour ouvrir le HUD  \xC2\xB7  /ms help pour les commandes."
L["LEVEL_GATE_WARNING"]      = "Cette extension est con\xC3\xA7ue pour les contenus de niveau 80+. Le suivi des combats et les notes sont d\xC3\xA9sactiv\xC3\xA9s jusqu'\xC3\xA0 l'atteinte du niveau 80."
L["WEEKLY_RESET_DETECTED"]   = "R\xC3\xA9initialisation hebdomadaire d\xC3\xA9tect\xC3\xA9e."

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Commandes Midnight Sensei :"
L["SLASH_HELP_SHOW"]         = "  /ms show          Afficher le HUD"
L["SLASH_HELP_HIDE"]         = "  /ms hide          Masquer le HUD"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Historique des notes & tendances"
L["SLASH_HELP_LB"]           = "  /ms lb            Classement social"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Classement personnel des boss  (alias : /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Param\xC3\xA8tres"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Aide & FAQ"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Cr\xC3\xA9dits & \xC3\x80 propos"
L["SLASH_HELP_REPORT"]       = "  /ms report        Signaler un bug sur GitHub"
L["SLASH_HELP_UPDATE"]       = "  /ms update        Afficher le journal des modifications"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Versions de l'extension vues cette session"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Consulter le dernier score d'un joueur"

---------------------------------------------------------------------------
-- Chat status messages
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "Base de donn\xC3\xA9es de guilde vide."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei \xe2\x80\x94 Entr\xC3\xA9es de la base de donn\xC3\xA9es de guilde :"
L["FRIEND_USAGE"]            = "Utilisation : /ms friend Nom  ou  /ms friend add Nom  ou  /ms friend remove Nom"
L["LB_REMOVE_USAGE"]         = "Utilisation : /ms lb remove <NomJoueur>"
L["VERSIONS_HEADER"]         = "Midnight Sensei \xe2\x80\x94 Versions vues cette session :"
L["VERSIONS_NO_DATA"]        = "Pas encore de donn\xC3\xA9es de version \xe2\x80\x94 elles sont collect\xC3\xA9es automatiquement quand les joueurs se connectent ou rejoignent votre groupe."
L["VERSIONS_YOU"]            = "(vous)"
L["VERSIONS_OUTDATED"]       = "(obsol\xC3\xA8te)"
L["SILENT_MODE_ON"]          = "Midnight Sensei : Mode silencieux ACTIV\xC3\x89 \xe2\x80\x94 tous les messages sortants de l'extension sont supprim\xC3\xA9s."
L["SILENT_MODE_OFF"]         = "Midnight Sensei : Mode silencieux D\xC3\x89SACTIV\xC3\x89 \xe2\x80\x94 fonctionnement normal repris."

---------------------------------------------------------------------------
-- Verify mode
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei Mode V\xC3\xA9rification : ACTIV\xC3\x89"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei Mode V\xC3\xA9rification : D\xC3\x89SACTIV\xC3\x89"
L["VERIFY_CAST_HINT"]        = "Lancez vos sorts normalement. Apr\xC3\xA8s le combat, tapez /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei : Aucune sp\xC3\xA9cialisation charg\xC3\xA9e."

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei : Pas encore de capture des talents \xe2\x80\x94 elle est cr\xC3\xA9\xC3\xA9e automatiquement \xC3\xA0 la connexion et au changement de sp\xC3\xA9cialisation. Si c'est votre premi\xC3\xA8re session, tapez /reload et r\xC3\xA9essayez."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei : Pas encore de capture des sorts \xe2\x80\x94 elle est cr\xC3\xA9\xC3\xA9e automatiquement \xC3\xA0 la connexion. Si c'est votre premi\xC3\xA8re session, tapez /reload et r\xC3\xA9essayez."

---------------------------------------------------------------------------
-- BossBoard — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Tableau des boss"
L["BB_DESCRIPTION"]          = "Vos meilleurs scores par boss \xC3\xA0 Midnight \xe2\x80\x94 cliquez sur une ligne pour voir le meilleur feedback de combat"
L["BB_TAB_DUNGEONS"]         = "Donjons"
L["BB_TAB_RAIDS"]            = "Raids"
L["BB_TAB_DELVES"]           = "Plong\xC3\xA9es"
L["BB_COL_DATE"]             = "DATE"
L["BB_COL_CHARACTER"]        = "PERSONNAGE"
L["BB_COL_SPEC"]             = "SP\xC3\x89C."
L["BB_COL_DIFF_BOSS"]        = "DIFF / BOSS"
L["BB_COL_SCORE"]            = "SCORE"
L["BB_NO_ENCOUNTERS"]        = "Aucune rencontre de boss enregistr\xC3\xA9e pour ce type de contenu."
L["BB_FOOTER_INFO"]          = "Kills de boss uniquement  -  niveau 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d boss enregistr\xC3\xA9%s"
L["BB_TT_BEST"]              = "Meilleur : %s  %d"
L["BB_TT_DATE"]              = "Date : %s"
L["BB_TT_KILLS"]             = "Kills suivis : %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Cliquer pour voir le feedback"

---------------------------------------------------------------------------
-- BossBoard — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Tableau des boss : Ingestion termin\xC3\xA9e \xe2\x80\x94 ajout\xC3\xA9 : %d  mis \xC3\xA0 jour : %d  ignor\xC3\xA9 : %d"
L["BB_SPEC_NOT_DETECTED"]    = "Tableau des boss : Impossible de d\xC3\xA9tecter la sp\xC3\xA9cialisation active \xe2\x80\x94 les champs personnage/sp\xC3\xA9cialisation peuvent \xC3\xAAtre incomplets. R\xC3\xA9essayez apr\xC3\xA8s vous \xC3\xAAtre compl\xC3\xA8tement connect\xC3\xA9."
L["BB_REPAIR_COMPLETE"]      = "Tableau des boss : R\xC3\xA9paration d'identit\xC3\xA9 termin\xC3\xA9e \xe2\x80\x94 corrig\xC3\xA9 : %d entr%s"
L["BB_NO_BOSSDATA"]          = "Aucune donn\xC3\xA9e bossBests trouv\xC3\xA9e."
L["BB_SPEC_UNRESOLVED"]      = "Tableau des boss : Sp\xC3\xA9cialisation pas encore d\xC3\xA9tect\xC3\xA9e \xe2\x80\x94 r\xC3\xA9essayez apr\xC3\xA8s vous \xC3\xAAtre compl\xC3\xA8tement connect\xC3\xA9."
L["BB_RENAME_COMPLETE"]      = "Correction de nom de personnage termin\xC3\xA9e (%s \xe2\x86\x92 %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Historique des notes / revoir les combats : %d rencontre%s mise \xC3\xA0 jour"
L["BB_RENAME_BB_UPDATED"]    = "  Tableau des boss : %d entr%s mise \xC3\xA0 jour ; capture partag\xC3\xA9e re-index\xC3\xA9e"
L["BB_CANNOT_READ_NAME"]     = "Impossible de lire le nom du joueur \xe2\x80\x94 r\xC3\xA9essayez apr\xC3\xA8s vous \xC3\xAAtre compl\xC3\xA8tement connect\xC3\xA9."
L["BB_NO_CHARDB"]            = "Aucune CharDB trouv\xC3\xA9e."
L["BB_NO_SNAPDATA"]          = "Aucune capture partag\xC3\xA9e trouv\xC3\xA9e."
L["BB_CLEANUP_DRY_HDR"]      = "Nettoyage : %d rencontre(s) seraient marqu\xC3\xA9es comme d\xC3\xA9faites. Ex\xC3\xA9cutez /ms debug cleanup history confirm pour appliquer."
L["BB_CLEANUP_APPLIED"]      = "Nettoyage de l'historique \xe2\x80\x94 %d d\xC3\xA9faite(s) ancienne(s) corrig\xC3\xA9e(s) ; Tableau des boss mis \xC3\xA0 jour o\xC3\xB9 les donn\xC3\xA9es d'historique \xC3\xA9taient disponibles."
L["BB_RESTORE_COMPLETE"]     = "Restauration de capture termin\xC3\xA9e \xe2\x80\x94 r\xC3\xA9cup\xC3\xA9r\xC3\xA9 : %d  d\xC3\xA9j\xC3\xA0 \xC3\xA0 jour : %d"
L["BB_RESTORE_NOTE"]         = "Les entr\xC3\xA9es restaur\xC3\xA9es ont score/note/date mais pas de feedback de combat ni de scores de composantes."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei : Tableau des boss effac\xC3\xA9."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei : Historique des combats effac\xC3\xA9."

---------------------------------------------------------------------------
-- BossBoard — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Corriger le nom du personnage"
L["FIX_NAME_OLD_LABEL"]      = "Ancien nom de personnage (trouv\xC3\xA9 dans votre historique) :"
L["FIX_NAME_NEW_LABEL"]      = "Sera remplac\xC3\xA9 par (votre nom de personnage actuel) :"
L["FIX_NAME_ERR_EMPTY"]      = "Veuillez entrer l'ancien nom de personnage."
L["FIX_NAME_ERR_SAME"]       = "Ce nom correspond \xC3\xA0 votre personnage actuel \xe2\x80\x94 rien \xC3\xA0 corriger."
L["FIX_NAME_ERR_NOT_FOUND"]  = "Aucun historique trouv\xC3\xA9 sous \"%s\". V\xC3\xA9rifiez l'orthographe, la casse et les caract\xC3\xA8res sp\xC3\xA9ciaux."
L["FIX_NAME_BTN_CONFIRM"]    = "Confirmer la correction"

---------------------------------------------------------------------------
-- Leaderboard — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Utilisation : /ms friend Nom  ou  /ms friend Nom-Royaume"
L["FRIEND_CHECKING"]         = "V\xC3\xA9rification de %s..."
L["FRIEND_OFFLINE"]          = "%s (Hors ligne) \xe2\x80\x94 Pas mis \xC3\xA0 jour ou extension non install\xC3\xA9e"
L["FRIEND_CANNOT_REACH"]     = "Impossible de joindre %s \xe2\x80\x94 v\xC3\xA9rifiez l'orthographe du nom/royaume. Erreur : %s"
L["FRIEND_LIST_FULL"]        = "Liste d'amis pleine (%d max). Supprimez d'abord quelqu'un avec un clic droit ou /ms friend remove Nom."
L["FRIEND_ALREADY_IN"]       = "%s est d\xC3\xA9j\xC3\xA0 dans votre liste d'amis."
L["FRIEND_ADDED"]            = "%s ajout\xC3\xA9 \xC3\xA0 votre liste d'amis (%d/%d)."
L["FRIEND_REMOVED"]          = "%s retir\xC3\xA9 de votre liste d'amis (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s introuvable dans la liste d'amis."
L["FRIEND_ONLINE_UPDATED"]   = "%s (En ligne) \xe2\x80\x94 Mis \xC3\xA0 jour"

---------------------------------------------------------------------------
-- UI — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - D\xC3\xA9tail de la rencontre"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Historique des notes"
L["TITLE_HUD"]               = "Midnight Sensei"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Combat termin\xC3\xA9"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Options"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei \xe2\x80\x94 Rapport de v\xC3\xA9rification"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei \xe2\x80\x94 Comparaison de v\xC3\xA9rification"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - Ma liste de sorts"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Outils de d\xC3\xA9bogage"
L["TITLE_CREDITS"]           = "Midnight Sensei - Cr\xC3\xA9dits & \xC3\x80 propos"
L["TITLE_FAQ"]               = "Midnight Sensei - Aide & FAQ"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Suivi de rotation"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei \xe2\x80\x94 Mise \xC3\xA0 jour disponible"

---------------------------------------------------------------------------
-- UI — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Voir les d\xC3\xA9tails"
L["CTX_DELETE_ENTRY"]        = "Supprimer l'entr\xC3\xA9e"
L["CTX_CANCEL"]              = "Annuler"
L["CTX_LOCK_POSITION"]       = "Verrouiller la position"
L["CTX_UNLOCK_POSITION"]     = "D\xC3\xA9verrouiller la position"
L["CTX_GRADE_HISTORY"]       = "Historique des notes"
L["CTX_LEADERBOARD"]         = "Classement"
L["CTX_BOSS_BOARD"]          = "Tableau des boss"
L["CTX_OPTIONS"]             = "Options"
L["CTX_MY_SPELL_LIST"]       = "Ma liste de sorts"
L["CTX_HELP_FAQ"]            = "Aide / FAQ"
L["CTX_CREDITS"]             = "Cr\xC3\xA9dits"
L["CTX_DEBUG_TOOLS"]         = "Outils de d\xC3\xA9bogage"
L["CTX_CLOSE_HUD"]           = "Fermer le HUD"

---------------------------------------------------------------------------
-- UI — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Dur\xC3\xA9e : %s    Note : %s  (%s)"
L["DETAIL_SCORE"]            = "Score : %d"
L["DETAIL_COMPONENT_SCORES"] = "Scores des composantes :"
L["DETAIL_FEEDBACK"]         = "Retour :"
L["DETAIL_ENC_DUNGEON"]      = "Donjon"
L["DETAIL_ENC_RAID"]         = "Raid"
L["DETAIL_ENC_DELVE"]        = "Plong\xC3\xA9e"
L["DETAIL_ENC_WORLD"]        = "Monde"
L["DETAIL_ENC_COMBAT"]       = "Combat"
L["BTN_CLOSE"]               = "Fermer"

---------------------------------------------------------------------------
-- UI — grade history panel
---------------------------------------------------------------------------
L["HISTORY_TREND_LABEL"]     = "Tendance (20 derniers) :"
L["HISTORY_FILTER_LABEL"]    = "Filtre :"
L["FILTER_THIS_CHARACTER"]   = "Ce personnage"
L["FILTER_BOSS_ONLY"]        = "[Boss] uniquement"
L["HISTORY_COL_GR"]          = "NT"
L["HISTORY_COL_CHARACTER"]   = "PERSONNAGE"
L["HISTORY_COL_SPEC_DIFF"]   = "SP\xC3\x89C. / DIFF."
L["HISTORY_COL_SCORE"]       = "SCORE"
L["HISTORY_COL_DUR"]         = "DUR\xC3\x89E"
L["HISTORY_COL_WHEN"]        = "QUAND"
L["HISTORY_LB_BTN"]          = "Classement ->"
L["HISTORY_STATS"]           = "%d combats  -  Moy : %d  -  Meilleur : %s  -  Pire : %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d d\xC3\xA9faite%s"
L["HISTORY_NO_MATCHES"]      = "Aucune rencontre ne correspond au filtre actuel."

---------------------------------------------------------------------------
-- UI — relative time labels
---------------------------------------------------------------------------
L["TIME_JUST_NOW"]           = "\xC3\xA0 l'instant"
L["TIME_MINUTES_AGO"]        = "il y a %dm"
L["TIME_HOURS_AGO"]          = "il y a %dh"
L["TIME_DAYS_AGO"]           = "il y a %dj"

---------------------------------------------------------------------------
-- UI — HUD
---------------------------------------------------------------------------
L["HUD_NO_FIGHT"]            = "Aucun combat enregistr\xC3\xA9"
L["HUD_IN_COMBAT"]           = "En combat..."
L["HUD_FIGHT_TOO_SHORT"]     = "Combat trop court pour \xC3\xAAtre enregistr\xC3\xA9"
L["BTN_REVIEW_FIGHT"]        = "Revoir le combat"
L["BTN_BOSS_BOARD"]          = "Tableau des boss"
L["BTN_LEADERBOARD"]         = "Classement"
L["VERIFY_BAR_LABEL"]        = "Mode v\xC3\xA9rification activ\xC3\xA9"
L["BTN_VIEW_REPORT"]         = "Voir le rapport"
L["UPDATE_BAR_LABEL"]        = "Nouvelle version disponible  (cliquez pour les d\xC3\xA9tails)"
L["TT_MENU"]                 = "Menu"
L["TT_HIDE_HUD"]             = "Masquer le HUD"
L["TT_DISMISS"]              = "Ignorer"
L["TT_UPDATE_AVAILABLE"]     = "Mise \xC3\xA0 jour disponible"
L["TT_UPDATE_CHECK"]         = "Consultez Curseforge ou Wago pour la derni\xC3\xA8re version."
L["TT_BOSS_BOARD"]           = "Tableau des boss"
L["TT_BOSS_BOARD_DESC"]      = "Vos meilleurs scores personnels de boss de tous les temps"
L["TT_LEADERBOARD"]          = "Classement"
L["TT_LEADERBOARD_DESC"]     = "Guilde / Groupe / Amis / Plong\xC3\xA9es"

---------------------------------------------------------------------------
-- UI — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Combat propre \xe2\x80\x94 rien de majeur \xC3\xA0 signaler."
L["FIGHT_SCORE_DUR"]         = "Score : %d   Dur\xC3\xA9e : %s"
L["FIGHT_COMPONENT_SCORES"]  = "Scores des composantes :"
L["BTN_HISTORY"]             = "Historique"

---------------------------------------------------------------------------
-- UI — options panel
---------------------------------------------------------------------------
L["OPT_HUD_VISIBILITY"]      = "Visibilit\xC3\xA9 du HUD :"
L["OPT_VIS_ALWAYS"]          = "Toujours"
L["OPT_VIS_IN_COMBAT"]       = "En combat"
L["OPT_VIS_HIDE"]            = "Masquer"
L["OPT_BEHAVIOUR"]           = "Comportement :"
L["OPT_SHOW_POST_FIGHT"]     = "Afficher le bouton de r\xC3\xA9vision post-combat sur le HUD"
L["OPT_LOCK_HUD"]            = "Verrouiller la position du HUD"
L["OPT_ENCOUNTER_ADJUST"]    = "Ajustement des conditions de rencontre"
L["OPT_DEBUG_MODE"]          = "Mode d\xC3\xA9bogage (affiche les messages de rejet LB)"
L["OPT_LEADERBOARD"]         = "Classement :"
L["OPT_LB_NOTE"]             = "La moyenne hebdomadaire ne compte que les rencontres de boss. Les pulls de trash et les mannequins d'entra\xC3\xAEnement ne sont jamais inclus."
L["BTN_REPORT_ISSUES"]       = "Signaler des probl\xC3\xA8mes"

---------------------------------------------------------------------------
-- UI — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei \xe2\x80\x94 Signaler un bug\n\nCopiez le lien ci-dessous et collez-le dans votre navigateur.\nCtrl+A pour tout s\xC3\xA9lectionner, puis Ctrl+C pour copier."
L["REPORT_POPUP_BTN"]        = "Fermer"

---------------------------------------------------------------------------
-- UI — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Ctrl+A pour tout s\xC3\xA9lectionner  \xC2\xB7  Ctrl+C pour copier  \xC2\xB7  Coller dans un commentaire GitHub"
L["BTN_COMPARE"]             = "Comparer"

---------------------------------------------------------------------------
-- UI — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Les sorts affich\xC3\xA9s ici sont actuellement surveill\xC3\xA9s par Midnight Sensei."
L["SPELL_LIST_NO_SPEC"]      = "Aucune sp\xC3\xA9cialisation d\xC3\xA9tect\xC3\xA9e. Participez d'abord \xC3\xA0 un combat."
L["SPELL_LIST_SEC_CDS"]      = "Sorts \xC3\xA0 recharge"
L["SPELL_LIST_SEC_INT"]      = "Interruption & Utilitaires"
L["SPELL_LIST_SEC_ROT"]      = "Sorts de rotation"
L["SPELL_LIST_SEC_UPTIME"]   = "Buffs de maintien"
L["SPELL_LIST_SEC_PROCS"]    = "Buffs de procs"
L["SPELL_LIST_SITUATIONAL"]  = "situationnel"
L["SPELL_LIST_SPEND_FAST"]   = "d\xC3\xA9penser rapidement"
L["SPELL_LIST_TARGET_UP"]    = "cible %d%% de maintien"
L["SPELL_LIST_METAMORPH"]    = "N\xC3\xA9cessite la M\xC3\xA9tamorphose"

---------------------------------------------------------------------------
-- UI — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- Outils de v\xC3\xA9rification --"
L["DEBUG_SEC_CLASS"]         = "-- D\xC3\xA9bogage de classe --"
L["DEBUG_SEC_RECOVERY"]      = "-- Outils de r\xC3\xA9cup\xC3\xA9ration --"
L["DEBUG_BTN_VERIFY_MODE"]   = "Mode v\xC3\xA9rification"
L["DEBUG_BTN_VERIFY_DESC"]   = "Activer/d\xC3\xA9sactiver la capture d'ID de sort pour /ms verify report"
L["DEBUG_BTN_VR"]            = "Rapport de v\xC3\xA9rification"
L["DEBUG_BTN_VR_DESC"]       = "Exporter le rapport de v\xC3\xA9rification d'ID de sort dans une fen\xC3\xAAtre copiable"
L["DEBUG_BTN_AUTO_VERIFY"]   = "Activer auto-v\xC3\xA9rification \xC3\xA0 la connexion"
L["DEBUG_BTN_AV_DESC"]       = "Le mode v\xC3\xA9rification s'active automatiquement apr\xC3\xA8s chaque rechargement ou connexion"
L["DEBUG_BTN_VERSION"]       = "Version"
L["DEBUG_BTN_VERSION_DESC"]  = "Afficher la version de l'extension depuis le TOC et les API de m\xC3\xA9tadonn\xC3\xA9es"
L["DEBUG_BTN_ROT_TRACKER"]   = "Suivi de rotation"
L["DEBUG_BTN_RT_DESC"]       = "Ouvrir la fen\xC3\xAAtre de suivi de rotation \xe2\x80\x94 nombre de lancements, statut et explications des drapeaux pour chaque sort"
L["DEBUG_BTN_TALENT_EXP"]    = "Export de talents"
L["DEBUG_BTN_TE_DESC"]       = "Exporter la capture de talents actifs pour r\xC3\xA9f\xC3\xA9rence crois\xC3\xA9e avec la base de donn\xC3\xA9es de sp\xC3\xA9cialisation"
L["DEBUG_BTN_SPELLS_EXP"]    = "Export de sorts"
L["DEBUG_BTN_SE_DESC"]       = "Exporter la capture compl\xC3\xA8te du livre de sorts pour r\xC3\xA9f\xC3\xA9rence crois\xC3\xA9e avec la base de donn\xC3\xA9es de sp\xC3\xA9cialisation"
L["DEBUG_BTN_BB_INGEST"]     = "Ingestion tableau des boss"
L["DEBUG_BTN_BBI_DESC"]      = "Alimenter le tableau des boss depuis l'historique des rencontres"
L["DEBUG_BTN_FIX_NAME"]      = "Corriger le nom du personnage"
L["DEBUG_BTN_FN_DESC"]       = "Si vous avez renomm\xC3\xA9 votre personnage, ex\xC3\xA9cutez ceci"
L["DEBUG_BTN_BACKFILL"]      = "Compl\xC3\xA9ter les cl\xC3\xA9s M+"
L["DEBUG_BTN_BK_DESC"]       = "Corriger l'historique des donjons Mythique avec les meilleures cl\xC3\xA9s de la saison"
L["DEBUG_BTN_CLEAN"]         = "Nettoyer la charge utile"
L["DEBUG_BTN_CP_DESC"]       = "Rediffuser tous vos meilleurs scores avec le bon format"
L["DEBUG_BTN_CLEAR_BB"]      = "Effacer le tableau des boss"
L["DEBUG_BTN_CBB_DESC"]      = "Supprime d\xC3\xA9finitivement tous les records personnels de boss \xe2\x80\x94 cette action est irr\xC3\xA9versible"
L["DEBUG_BTN_CLEAR_HIST"]    = "Effacer l'historique des combats"
L["DEBUG_BTN_CH_DESC"]       = "Supprime d\xC3\xA9finitivement toutes les rencontres enregistr\xC3\xA9es \xe2\x80\x94 cette action est irr\xC3\xA9versible"
L["DEBUG_BTN_RUN"]           = "Ex\xC3\xA9cuter"
L["DEBUG_BTN_TOGGLE"]        = "Basculer"

---------------------------------------------------------------------------
-- UI — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Tapez  Confirm  pour activer la suppression :"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Effacer le tableau des boss"
L["DESTRUCT_CLEAR_BB_BODY"]  = "Cela supprimera d\xC3\xA9finitivement tous les enregistrements du tableau des boss pour ce personnage.\nCette action est irr\xC3\xA9versible."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Supprimer le tableau des boss"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Effacer l'historique des combats"
L["DESTRUCT_CLEAR_HIST_BODY"] = "Cela supprimera d\xC3\xA9finitivement toutes les rencontres de combat enregistr\xC3\xA9es pour ce personnage.\nCette action est irr\xC3\xA9versible."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Supprimer l'historique des combats"
L["BTN_CANCEL"]              = "Annuler"

---------------------------------------------------------------------------
-- UI — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "\xC3\x80 propos"
L["CREDITS_TAB_SOURCES"]     = "Sources"
L["CREDITS_TAB_CHANGELOG"]   = "Journal des modifications"
L["CREDITS_SOURCES_INTRO"]   = "Les conseils de rotation s'appuient sur les ressources communautaires suivantes."
L["CREDITS_SOURCES_ACK"]     = "Nous remercions chaleureusement leurs contributions."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei n'est pas affili\xC3\xA9 \xC3\xA0 ces ressources."
L["CREDITS_NO_CHANGELOG"]    = "Aucun journal des modifications disponible."
L["CREDITS_ABOUT_TEXT"]      = "Une extension de coaching de performance au combat pour World of Warcraft : Midnight.\nNote vos combats de A+ \xC3\xA0 F pour les 13 classes et 40 sp\xC3\xA9cialisations,\navec des retours pratiques adapt\xC3\xA9s \xC3\xA0 votre r\xC3\xB4le et sp\xC3\xA9cialisation."
L["CREDITS_AUTHOR"]          = "Auteur :  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Fonctionnalit\xC3\xA9s :"
L["CREDITS_FEAT_GRADING"]    = "  - Note par combat : utilisation des recharges, activit\xC3\xA9, gestion des ressources"
L["CREDITS_FEAT_TALENT"]     = "  - Sensible aux talents : ne note que les capacit\xC3\xA9s r\xC3\xA9ellement \xC3\xA9quip\xC3\xA9es"
L["CREDITS_FEAT_BOSS"]       = "  - D\xC3\xA9tection des boss : suit ENCOUNTER_START/END pour les vrais combats de boss"
L["CREDITS_FEAT_SOCIAL"]     = "  - Classement social : classements de guilde, groupe et amis BNet"
L["CREDITS_FEAT_WEEKLY"]     = "  - R\xC3\xA9initialisation hebdomadaire : align\xC3\xA9e sur la r\xC3\xA9initialisation du mardi \xC3\xA0 16h00 CEST de Blizzard"
L["CREDITS_FEAT_DELVE"]      = "  - Suivi des plong\xC3\xA9es : notation par palier pour le contenu solo"
L["CREDITS_FEAT_SYNC"]       = "  - Synchronisation des scores : synchronise entre les membres de guilde pour r\xC3\xA9cup\xC3\xA9rer les scores apr\xC3\xA8s r\xC3\xA9installation"
L["CREDITS_CONTACT"]         = "Contact :  MidnightTim sur GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei est une extension communautaire, non affili\xC3\xA9e \xC3\xA0 Blizzard."

---------------------------------------------------------------------------
-- UI — FAQ headers
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "PREMIERS PAS"
L["FAQ_HDR_UNDERSTANDING"]   = "COMPRENDRE VOTRE NOTE"
L["FAQ_HDR_ROTATIONAL"]      = "RETOUR SUR LES SORTS DE ROTATION"
L["FAQ_HDR_VISIBILITY"]      = "OPTIONS DE VISIBILIT\xC3\x89"
L["FAQ_HDR_HISTORY"]         = "HISTORIQUE DES NOTES"
L["FAQ_HDR_LEADERBOARD"]     = "CLASSEMENT"
L["FAQ_HDR_MIDNIGHT_NOTE"]   = "NOTE SUR LES RESTRICTIONS DE MIDNIGHT 12.0"
L["FAQ_HDR_BOSS_COMBAT"]     = "BOSS VS COMBAT NORMAL"
L["FAQ_HDR_TALENT_AWARE"]    = "RECHARGES SENSIBLES AUX TALENTS"
L["FAQ_HDR_ALL_COMMANDS"]    = "TOUTES LES COMMANDES"
L["FAQ_MIN_FIGHT"]           = "Un combat de moins de 15 secondes n'est pas enregistr\xC3\xA9."
L["FAQ_VIS_ALWAYS"]          = "  Toujours : HUD toujours visible"
L["FAQ_VIS_COMBAT"]          = "  En combat : HUD visible uniquement en combat"
L["FAQ_VIS_HIDE"]            = "  Masquer : HUD masqu\xC3\xA9 (accessible via /ms show)"
L["FAQ_CMD_SHOW"]            = "  /ms show         Afficher le HUD"
L["FAQ_CMD_HIDE"]            = "  /ms hide         Masquer le HUD"
L["FAQ_CMD_HISTORY"]         = "  /ms history      Historique des notes & tendances"
L["FAQ_CMD_LB"]              = "  /ms lb           Classement social"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Retirer un joueur du classement de guilde"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Param\xC3\xA8tres"
L["FAQ_CMD_FAQ"]             = "  /ms faq          Ce panneau"
L["FAQ_CMD_UPDATE"]          = "  /ms update       Voir le journal des modifications"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Cr\xC3\xA9dits & \xC3\x80 propos"
L["FAQ_CMD_REPORT"]          = "  /ms report       Signaler un bug sur GitHub"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Versions de l'extension vues cette session"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Consulter le dernier score d'un joueur"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Ouvrir le suivi de rotation (nombre de lancements + explications des sorts)"

---------------------------------------------------------------------------
-- UI — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Tapez |cffFFFFFF/ms show|r pour ouvrir le HUD, |cffFFFFFF/ms hide|r pour le fermer.\nLe HUD affiche votre derni\xC3\xA8re note, votre score et votre sp\xC3\xA9cialisation. Apr\xC3\xA8s un combat\nvous verrez un bouton |cffFFFFFF>> Revoir le combat|r. Faites un clic droit sur le HUD pour\nacc\xC3\xA9der rapidement \xC3\xA0 toutes les fonctionnalit\xC3\xA9s."
L["FAQ_BODY_UNDERSTANDING"]   = "Les notes vont de F \xC3\xA0 A+. Chaque sp\xC3\xA9cialisation a des cat\xC3\xA9gories pond\xC3\xA9r\xC3\xA9es :\n  - Utilisation des recharges : avez-vous utilis\xC3\xA9 vos recharges majeures r\xC3\xA9guli\xC3\xA8rement ?\n  - Sorts de rotation : avez-vous utilis\xC3\xA9 les capacit\xC3\xA9s de rotation cl\xC3\xA9s \xC3\xA0 chaque combat ?\n  - Activit\xC3\xA9 : avez-vous lanc\xC3\xA9 des sorts r\xC3\xA9guli\xC3\xA8rement ? (pas de longues pauses)\n  - Gestion des ressources : avez-vous d\xC3\xA9pass\xC3\xA9 votre ressource (Rage/\xC3\x89nergie/etc.) ?\n  - Maintien des buffs : avez-vous gard\xC3\xA9 vos auto-buffs actifs ? (selon la sp\xC3\xA9c.)\n  - Utilisation des procs : avez-vous consomm\xC3\xA9 les procs rapidement ? (TK Givre, Mage Feu...) ?\n  - Efficacit\xC3\xA9 du soigneur : quelle part de vos soins \xC3\xA9tait des sursoins ?"
L["FAQ_BODY_ROTATIONAL"]      = "En plus des recharges, Midnight Sensei suit si vous avez utilis\xC3\xA9\nles sorts de rotation cl\xC3\xA9s \xC3\xA0 chaque combat (ex. Implosion, Lac\xC3\xA9ration, Oblitération).\nSi vous n'en avez jamais utilis\xC3\xA9 un dans un combat assez long, il appara\xC3\xAEtra dans votre\nretour. Les sorts li\xC3\xA9s aux talents sont ignor\xC3\xA9s si vous n'avez pas le talent."
L["FAQ_BODY_VIS_INTRO"]       = "Ouvrez |cffFFFFFF/ms options|r (ou clic droit HUD -> Options) et d\xC3\xA9finissez :"
L["FAQ_BODY_HISTORY"]         = "Tapez |cffFFFFFF/ms history|r ou clic droit -> Historique des notes.\n  - Filtrer par ce personnage ou tous les personnages\n  - La sparkline montre vos 20 derniers combats en un coup d'\xC5\x93il\n  - Clic gauche sur une ligne pour voir les d\xC3\xA9tails complets et le feedback\n  - Clic droit sur une ligne pour supprimer cette entr\xC3\xA9e"
L["FAQ_BODY_LEADERBOARD"]     = "Tapez |cffFFFFFF/ms lb|r pour ouvrir le classement social.\nApr\xC3\xA8s chaque combat de boss, votre score est diffus\xC3\xA9 \xC3\xA0 la guilde, au groupe et\naux amis BNet qui ont aussi Midnight Sensei install\xC3\xA9.\nOnglets : Groupe (session uniquement), Guilde (persiste entre sessions), Amis.\nLes scores de guilde persistent entre les sessions et se synchronisent entre les membres \xe2\x80\x94\nm\xC3\xAAme si un joueur est hors ligne, vous pouvez voir son dernier score enregistr\xC3\xA9.\nLa moyenne hebdomadaire ne compte que les rencontres de boss \xe2\x80\x94 les pulls de trash et les\nmannequins ne sont jamais inclus dans les classements.\nClic droit sur une ligne de guilde pour retirer un joueur. Il r\xC3\xA9appara\xC3\xAEt\nautomatiquement \xC3\xA0 sa prochaine connexion ou quand vous actualisez."
L["FAQ_BODY_LB_EXTRA"]        = "Chaque onglet (Donjons, Raids) affiche les informations de lieu pour ce type de contenu\nuniquement \xe2\x80\x94 une course LFR n'appara\xC3\xAEtra jamais dans l'onglet Donjons.\nLe niveau de cl\xC3\xA9 Mythique+ est affich\xC3\xA9 si disponible (ex. M+15).\nApr\xC3\xA8s une mise \xC3\xA0 jour de l'extension, chaque joueur doit compl\xC3\xA9ter un nouveau\ndonjon ou raid pour que l'emplacement de l'onglet refl\xC3\xA8te le bon contenu.\nVotre propre entr\xC3\xA9e se met \xC3\xA0 jour imm\xC3\xA9diatement depuis l'historique local \xe2\x80\x94 aucune nouvelle course n\xC3\xA9cessaire."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard a restreint la lecture des auras des unit\xC3\xA9s ennemies dans Midnight 12.0.\nLes d\xC3\xA9buffs de cible (Rupture, Choc des flammes, etc.) ne peuvent pas \xC3\xAAtre suivis directement.\nCeux-ci apparaissent dans vos priorityNotes comme conseils mais ne sont pas not\xC3\xA9s.\nTous les auto-buffs, recharges et lancements de rotation du joueur fonctionnent normalement."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei d\xC3\xA9tecte les rencontres de boss via ENCOUNTER_START/END.\nLes combats de boss affichent un tag |cffFF6600[Boss]|r dans l'historique et le d\xC3\xA9tail de rencontre.\nFiltrez votre historique sur |cffFFFFFF[Boss] uniquement|r pour revoir les pulls de boss de raid/donjon."
L["FAQ_BODY_TALENT_AWARE"]    = "La notation des recharges n'inclut que les sorts que vous avez appris.\nSi vous n'avez pas un talent, il ne sera pas compt\xC3\xA9 contre vous."

---------------------------------------------------------------------------
-- UI — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Nombre de lancements de votre dernier combat. Chaque sort indique combien de fois il a \xC3\xA9t\xC3\xA9 utilis\xC3\xA9 et pourquoi il est suivi."
L["ROT_TRACKER_NO_DATA"]     = "Pas encore de donn\xC3\xA9es de combat \xe2\x80\x94 participez \xC3\xA0 un combat pour voir les r\xC3\xA9sultats de suivi."
L["ROT_TRACKER_LAST_FIGHT"]  = "Dernier combat : %s"
L["ROT_TRACKER_NO_FIGHT"]    = "Aucun combat enregistr\xC3\xA9"
L["ROT_COL_SPELL"]           = "SORT"
L["ROT_COL_CASTS"]           = "LANCEMENTS"
L["ROT_COL_MIN_FIGHT"]       = "COMBAT MIN."
L["ROT_COL_STATUS"]          = "STATUT"
L["ROT_STATUS_CAST"]         = "LANC\xC3\x89"
L["ROT_STATUS_MISSED"]       = "MANQU\xC3\x89"
L["ROT_STATUS_SHORT"]        = "COURT"
L["ROT_FLAG_COMBAT_TALENT"]  = "N\xC3\xA9cessite un talent ; utilisable uniquement pendant une fen\xC3\xAAtre de transformation"
L["ROT_FLAG_COMBAT_ONLY"]    = "Utilisable uniquement pendant une fen\xC3\xAAtre de transformation (ex. M\xC3\xA9ta-morphose du vide)"
L["ROT_FLAG_TALENT_ONLY"]    = "Suivi uniquement quand ce talent est actif dans votre build"
L["ROT_FLAG_CORE"]           = "Capacit\xC3\xA9 de rotation principale \xe2\x80\x94 attendue \xC3\xA0 chaque combat"
L["ROT_FLAG_MIN_FIGHT"]      = "consid\xC3\xA9r\xC3\xA9 manqu\xC3\xA9 seulement si combat > %ds"
L["ROT_NOT_TRACKED"]         = "Non suivi dans ce build (talent non pris ou remplac\xC3\xA9) : %s"
L["ROT_LEGEND_CAST_DESC"]    = "utilis\xC3\xA9 au moins une fois"
L["ROT_LEGEND_MISSED_DESC"]  = "le combat \xC3\xA9tait assez long mais le sort n'a pas \xC3\xA9t\xC3\xA9 utilis\xC3\xA9"
L["ROT_LEGEND_SHORT_DESC"]   = "combat trop court pour \xC3\xAAtre \xC3\xA9valu\xC3\xA9"

---------------------------------------------------------------------------
-- UI — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "Une nouvelle version de Midnight Sensei est disponible.\nConsultez Curseforge ou Wago pour la derni\xC3\xA8re version."
L["SETTINGS_CATEGORY"]       = "Midnight Sensei"
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Cr\xC3\xA9\xC3\xA9 par Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Ouvrir les options"
L["SETTINGS_BTN_OPT_DESC"]   = "Configurer le HUD, le style de jeu et plus"
L["SETTINGS_BTN_HISTORY"]    = "Historique des notes"
L["SETTINGS_BTN_HIST_DESC"]  = "Voir l'historique des combats et les tendances"
L["SETTINGS_BTN_LB"]         = "Classement"
L["SETTINGS_BTN_LB_DESC"]    = "Classements Guilde / Groupe / Amis / Plong\xC3\xA9es"
L["SETTINGS_BTN_FAQ"]        = "Aide & FAQ"
L["SETTINGS_BTN_FAQ_DESC"]   = "Comment fonctionne le scoring et la notation"
L["SETTINGS_BTN_CREDITS"]    = "Cr\xC3\xA9dits & \xC3\x80 propos"
L["SETTINGS_BTN_CRED_DESC"]  = "Infos sur l'auteur et sources"
L["SETTINGS_LEGACY_SUB"]     = "Cr\xC3\xA9\xC3\xA9 par Midnight - Thrall (US)  |  /ms pour les commandes"
L["MINIMAP_TT_TITLE"]        = "Midnight Sensei"
L["MINIMAP_TT_LEFT"]         = "Clic gauche : Basculer le HUD"
L["MINIMAP_TT_RIGHT"]        = "Clic droit : Classement"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Ctrl+Clic droit : Tableau des boss"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "Maj+Clic droit : Options"

---------------------------------------------------------------------------
-- Analytics/Feedback
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "Vous avez perdu de la valeur avec des recharges inutilis\xC3\xA9es%s : %s. M\xC3\xAAme les appuyer r\xC3\xA9guli\xC3\xA8rement aide."
L["FB_NEVER_PRESSED"]        = "Jamais utilis\xC3\xA9%s : %s \xe2\x80\x94 %s."
L["FB_ACTION_TANK"]          = "utiliser sur les tank busters ou les fen\xC3\xAAtres de d\xC3\xA9g\xC3\xA2ts \xC3\xA9lev\xC3\xA9s"
L["FB_ACTION_HEALER"]        = "aligner avec les fen\xC3\xAAtres de d\xC3\xA9g\xC3\xA2ts entrants \xC3\xA9lev\xC3\xA9s"
L["FB_ACTION_DPS"]           = "aligner avec les fen\xC3\xAAtres de burst"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Votre rotation est r\xC3\xA9guli\xC3\xA8re, mais les \xC3\xA9carts entre les lancements (%d%% d'activit\xC3\xA9) sont la prochaine chose \xC3\xA0 am\xC3\xA9liorer."
L["FB_ACTIVITY_MODERATE"]    = "Activit\xC3\xA9 \xC3\xA0 %d%% \xe2\x80\x94 environ %d lancement(s) laiss\xC3\xA9(s) de c\xC3\xB4t\xC3\xA9. Pr\xC3\xA9parez votre prochain sort avant que l'actuel atterrisse."
L["FB_ACTIVITY_LOW"]         = "Activit\xC3\xA9 : %d/%d GCDs (%d%%) \xe2\x80\x94 %s temps d'arr\xC3\xAAt, environ %d lancements perdus. Trouvez votre prochain sort avant que l'actuel se termine."
L["FB_DOWNTIME_SIGNIFICANT"] = "significatif"
L["FB_DOWNTIME_MODERATE"]    = "mod\xC3\xA9r\xC3\xA9"
L["FB_UNDERUSED"]            = "Utilis\xC3\xA9 moins que pr\xC3\xA9vu dans un combat de %.1fmin : %s \xe2\x80\x94 visez 1 utilisation par 2 minutes de combat."
L["FB_ROT_NEVER_USED"]       = "Sort(s) de rotation jamais utilis\xC3\xA9(s) : %s \xe2\x80\x94 ils sont essentiels \xC3\xA0 votre %s."
L["FB_ROT_CONTEXT_TANK"]     = "rotation de survie et de menace"
L["FB_ROT_CONTEXT_HEALER"]   = "d\xC3\xA9bit de soins"
L["FB_ROT_CONTEXT_DPS"]      = "production de d\xC3\xA9g\xC3\xA2ts"
L["FB_ROT_LOW_USED"]         = "Aurait pu lancer davantage : %s \xe2\x80\x94 utilisez ces sorts \xC3\xA0 chaque GCD disponible quand vos d\xC3\xA9penseurs principaux sont en recharge."
L["FB_PROC_DELAYED"]         = "retard\xC3\xA9"
L["FB_PROC_CRITICALLY"]      = "critiquement retard\xC3\xA9"
L["FB_PROC_MSG"]             = "La consommation de %s est %s \xe2\x80\x94 maintenu %.1fs en moyenne (budget : %ds). Consommez les procs imm\xC3\xA9diatement quand ils apparaissent."
L["FB_OVERCAP"]              = "%s d\xC3\xA9pass\xC3\xA9 %d fois (%.1f/min) \xe2\x80\x94 d\xC3\xA9pensez %s avant d'atteindre %d pour \xC3\xA9viter la g\xC3\xA9n\xC3\xA9ration gaspill\xC3\xA9e."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s n'a jamais \xC3\xA9t\xC3\xA9 activ\xC3\xA9 \xe2\x80\x94 appuyez dessus \xC3\xA0 chaque fois qu'il est disponible pour r\xC3\xA9duire les d\xC3\xA9g\xC3\xA2ts physiques subis."
L["FB_MIT_LOW_UPTIME"]       = "%s : %d%% de maintien vs %d%% cible (%dpt d'\xC3\xA9cart, %d application(s)) \xe2\x80\x94 vous avez de grandes fen\xC3\xAAtres de d\xC3\xA9g\xC3\xA2ts physiques non att\xC3\xA9nu\xC3\xA9s. Appuyez dessus d\xC3\xA8s qu'il sort de recharge."
L["FB_MIT_SMALL_GAPS"]       = "%s : %d%% de maintien vs %d%% cible (%dpt d'\xC3\xA9cart) \xe2\x80\x94 les petits \xC3\xA9carts s'accumulent. Utilisez-le de fa\xC3\xA7on pr\xC3\xA9ventive sur les s\xC3\xA9quences de m\xC3\xAAl\xC3\xA9e lourdes, pas de fa\xC3\xA7on r\xC3\xA9active."
L["FB_BUFF_LOW_UPTIME"]      = "%s : %d%% de maintien vs %d%% cible (%dpt d'\xC3\xA9cart) \xe2\x80\x94 r\xC3\xA9appliquez avant qu'il expire, pas apr\xC3\xA8s."
L["FB_GROUP_BUFF_NOTE"]      = "%s (buff de groupe \xe2\x80\x94 assurez-vous qu'il est actif avant le combat)"
L["FB_OVERHEAL_HIGH"]        = "Sursoins \xC3\xA0 %.1f%% (cible : <%d%%) \xe2\x80\x94 vous d\xC3\xA9pensez du mana sur des cibles qui n'ont pas besoin de soins. Lancez l\xC3\xA9g\xC3\xA8rement plus tard ou passez aux sorts r\xC3\xA9actifs sur des cibles qui subissent activement des d\xC3\xA9g\xC3\xA2ts."
L["FB_OVERHEAL_ELEVATED"]    = "Sursoins : %.1f%% (cible : <%d%%) \xe2\x80\x94 l\xC3\xA9g\xC3\xA8rement \xC3\xA9lev\xC3\xA9. Retenez les lancements sur les cibles au-dessus de 70%% de sant\xC3\xA9 et privil\xC3\xA9giez les HoTs aux soins directs sur les groupes stables."
L["FB_HEALER_FILL_DOWNTIME"] = "Quand le groupe est stable, remplissez le temps d'arr\xC3\xAAt avec des sorts de d\xC3\xA9g\xC3\xA2ts pour maintenir le d\xC3\xA9bit."
L["FB_SIMPLIFIED_FALLBACK"]  = "Votre rotation est r\xC3\xA9guli\xC3\xA8re et bien ryth\xC3\xA9me. Affiner le timing des fen\xC3\xAAtres de burst est la prochaine \xC3\xA9tape de performance."
L["FB_NEAR_PERFECT"]         = "Ex\xC3\xA9cution quasi parfaite. Les gains restants sont : %s."
L["FB_NEXT_TANK_PREPOS"]     = "pr\xC3\xA9-positionner les d\xC3\xA9fensives avant les d\xC3\xA9g\xC3\xA2ts de pointe pr\xC3\xA9visibles"
L["FB_NEXT_HEALER_OVERLAP"]  = "chevaucher les recharges avec les incantations de d\xC3\xA9g\xC3\xA2ts entrants plut\xC3\xB4t que de r\xC3\xA9agir"
L["FB_NEXT_DPS_ALIGN"]       = "aligner les fen\xC3\xAAtres de burst avec les phases de vuln\xC3\xA9rabilit\xC3\xA9 ennemie"
L["FB_NEXT_GCD_TIMING"]      = "r\xC3\xA9duire le temps entre la fin du GCD et votre prochain lancement en dessous de 0,2s"
L["FB_STRONG_EXECUTION"]     = "Ex\xC3\xA9cution globalement forte. Votre cat\xC3\xA9gorie la plus faible est %s \xe2\x80\x94 c'est l\xC3\xA0 que viennent les prochains points."
L["FB_GOOD_FOUNDATION"]      = "Bonne base \xe2\x80\x94 concentrez-vous ensuite sur : %s."
L["FB_HINT_TANK_CDS"]        = "utiliser les recharges d\xC3\xA9fensives sur les tank busters"
L["FB_HINT_PRESS_CDS"]       = "appuyer plus r\xC3\xA9guli\xC3\xA8rement sur les recharges majeures"
L["FB_HINT_MIT_UPTIME"]      = "augmenter le maintien de l'att\xC3\xA9nuation en appuyant plus souvent sur %s"
L["FB_SOLID"]                = "Performance solide \xe2\x80\x94 affinez le timing des recharges pour progresser."
L["FB_NOTE_INTERRUPT"]       = "Note : %s \xe2\x80\x94 c'est votre interruption. Non utilis\xC3\xA9 pendant ce combat \xe2\x80\x94 aucune p\xC3\xA9nalit\xC3\xA9."
L["FB_NOTE_UTILITY"]         = "Note : %s \xe2\x80\x94 non utilis\xC3\xA9 ou non d\xC3\xA9tect\xC3\xA9 pendant ce combat. Aucune p\xC3\xA9nalit\xC3\xA9."
L["FB_NOTE_COMBAT_UTILITY"]  = "Note : %s \xe2\x80\x94 \xC3\xA9tourdit et inflige des d\xC3\xA9g\xC3\xA2ts en plus de l'utilitaire. Utilisez-le quand la situation le permet ; aucune p\xC3\xA9nalit\xC3\xA9 pour le retenir."
