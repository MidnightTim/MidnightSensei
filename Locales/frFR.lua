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
L["GRADE_KEEP_PRACTICING"]   = "Continue à t'entraîner"
L["GRADE_BUILDING_HABITS"]   = "Construction d'habitudes"
L["GRADE_LEARNING_CURVE"]    = "Courbe d'apprentissage"
L["GRADE_EARLY_DAYS"]        = "Débuts"
L["GRADE_FRESH_START"]       = "Nouveau départ"

---------------------------------------------------------------------------
-- Addon load / level gate
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "chargé.  /ms show pour ouvrir le HUD  ·  /ms help pour les commandes."
L["LEVEL_GATE_WARNING"]      = "Cette extension est conçue pour les contenus de niveau 80+. Le suivi des combats et les notes sont désactivés jusqu'à l'atteinte du niveau 80."
L["WEEKLY_RESET_DETECTED"]   = "Réinitialisation hebdomadaire détectée."

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Commandes Midnight Sensei :"
L["SLASH_HELP_SHOW"]         = "  /ms show          Afficher le HUD"
L["SLASH_HELP_HIDE"]         = "  /ms hide          Masquer le HUD"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Historique des notes & tendances"
L["SLASH_HELP_LB"]           = "  /ms lb            Classement social"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Classement personnel des boss  (alias : /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Paramètres"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Aide & FAQ"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Crédits & À propos"
L["SLASH_HELP_REPORT"]       = "  /ms report        Signaler un bug sur GitHub"
L["SLASH_HELP_UPDATE"]       = "  /ms update        Afficher le journal des modifications"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Versions de l'extension vues cette session"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Consulter le dernier score d'un joueur"

---------------------------------------------------------------------------
-- Chat status messages
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "Base de données de guilde vide."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei — Entrées de la base de données de guilde :"
L["FRIEND_USAGE"]            = "Utilisation : /ms friend Nom  ou  /ms friend add Nom  ou  /ms friend remove Nom"
L["LB_REMOVE_USAGE"]         = "Utilisation : /ms lb remove <NomJoueur>"
L["VERSIONS_HEADER"]         = "Midnight Sensei — Versions vues cette session :"
L["VERSIONS_NO_DATA"]        = "Pas encore de données de version — elles sont collectées automatiquement quand les joueurs se connectent ou rejoignent votre groupe."
L["VERSIONS_YOU"]            = "(vous)"
L["VERSIONS_OUTDATED"]       = "(obsolète)"
L["SILENT_MODE_ON"]          = "Midnight Sensei : Mode silencieux ACTIVÉ — tous les messages sortants de l'extension sont supprimés."
L["SILENT_MODE_OFF"]         = "Midnight Sensei : Mode silencieux DÉSACTIVÉ — fonctionnement normal repris."

---------------------------------------------------------------------------
-- Verify mode
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei Mode Vérification : ACTIVÉ"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei Mode Vérification : DÉSACTIVÉ"
L["VERIFY_CAST_HINT"]        = "Lancez vos sorts normalement. Après le combat, tapez /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei : Aucune spécialisation chargée."

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei : Pas encore de capture des talents — elle est créée automatiquement à la connexion et au changement de spécialisation. Si c'est votre première session, tapez /reload et réessayez."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei : Pas encore de capture des sorts — elle est créée automatiquement à la connexion. Si c'est votre première session, tapez /reload et réessayez."

---------------------------------------------------------------------------
-- BossBoard — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Tableau des boss"
L["BB_DESCRIPTION"]          = "Vos meilleurs scores par boss à Midnight — cliquez sur une ligne pour voir le meilleur feedback de combat"
L["BB_TAB_DUNGEONS"]         = "Donjons"
L["BB_TAB_RAIDS"]            = "Raids"
L["BB_TAB_DELVES"]           = "Plongées"
L["BB_COL_DATE"]             = "DATE"
L["BB_COL_CHARACTER"]        = "PERSONNAGE"
L["BB_COL_SPEC"]             = "SPÉC."
L["BB_COL_DIFF_BOSS"]        = "DIFF / BOSS"
L["BB_COL_SCORE"]            = "SCORE"
L["BB_NO_ENCOUNTERS"]        = "Aucune rencontre de boss enregistrée pour ce type de contenu."
L["BB_FOOTER_INFO"]          = "Kills de boss uniquement  -  niveau 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d boss enregistré%s"
L["BB_TT_BEST"]              = "Meilleur : %s  %d"
L["BB_TT_DATE"]              = "Date : %s"
L["BB_TT_KILLS"]             = "Kills suivis : %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Cliquer pour voir le feedback"

---------------------------------------------------------------------------
-- BossBoard — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Tableau des boss : Ingestion terminée — ajouté : %d  mis à jour : %d  ignoré : %d"
L["BB_SPEC_NOT_DETECTED"]    = "Tableau des boss : Impossible de détecter la spécialisation active — les champs personnage/spécialisation peuvent être incomplets. Réessayez après vous être complètement connecté."
L["BB_REPAIR_COMPLETE"]      = "Tableau des boss : Réparation d'identité terminée — corrigé : %d entr%s"
L["BB_NO_BOSSDATA"]          = "Aucune donnée bossBests trouvée."
L["BB_SPEC_UNRESOLVED"]      = "Tableau des boss : Spécialisation pas encore détectée — réessayez après vous être complètement connecté."
L["BB_RENAME_COMPLETE"]      = "Correction de nom de personnage terminée (%s → %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Historique des notes / revoir les combats : %d rencontre%s mise à jour"
L["BB_RENAME_BB_UPDATED"]    = "  Tableau des boss : %d entr%s mise à jour ; capture partagée re-indexée"
L["BB_CANNOT_READ_NAME"]     = "Impossible de lire le nom du joueur — réessayez après vous être complètement connecté."
L["BB_NO_CHARDB"]            = "Aucune CharDB trouvée."
L["BB_NO_SNAPDATA"]          = "Aucune capture partagée trouvée."
L["BB_CLEANUP_DRY_HDR"]      = "Nettoyage : %d rencontre(s) seraient marquées comme défaites. Exécutez /ms debug cleanup history confirm pour appliquer."
L["BB_CLEANUP_APPLIED"]      = "Nettoyage de l'historique — %d défaite(s) ancienne(s) corrigée(s) ; Tableau des boss mis à jour où les données d'historique étaient disponibles."
L["BB_RESTORE_COMPLETE"]     = "Restauration de capture terminée — récupéré : %d  déjà à jour : %d"
L["BB_RESTORE_NOTE"]         = "Les entrées restaurées ont score/note/date mais pas de feedback de combat ni de scores de composantes."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei : Tableau des boss effacé."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei : Historique des combats effacé."

---------------------------------------------------------------------------
-- BossBoard — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Corriger le nom du personnage"
L["FIX_NAME_OLD_LABEL"]      = "Ancien nom de personnage (trouvé dans votre historique) :"
L["FIX_NAME_NEW_LABEL"]      = "Sera remplacé par (votre nom de personnage actuel) :"
L["FIX_NAME_ERR_EMPTY"]      = "Veuillez entrer l'ancien nom de personnage."
L["FIX_NAME_ERR_SAME"]       = "Ce nom correspond à votre personnage actuel — rien à corriger."
L["FIX_NAME_ERR_NOT_FOUND"]  = "Aucun historique trouvé sous \"%s\". Vérifiez l'orthographe, la casse et les caractères spéciaux."
L["FIX_NAME_BTN_CONFIRM"]    = "Confirmer la correction"

---------------------------------------------------------------------------
-- Leaderboard — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Utilisation : /ms friend Nom  ou  /ms friend Nom-Royaume"
L["FRIEND_CHECKING"]         = "Vérification de %s..."
L["FRIEND_OFFLINE"]          = "%s (Hors ligne) — Pas mis à jour ou extension non installée"
L["FRIEND_CANNOT_REACH"]     = "Impossible de joindre %s — vérifiez l'orthographe du nom/royaume. Erreur : %s"
L["FRIEND_LIST_FULL"]        = "Liste d'amis pleine (%d max). Supprimez d'abord quelqu'un avec un clic droit ou /ms friend remove Nom."
L["FRIEND_ALREADY_IN"]       = "%s est déjà dans votre liste d'amis."
L["FRIEND_ADDED"]            = "%s ajouté à votre liste d'amis (%d/%d)."
L["FRIEND_REMOVED"]          = "%s retiré de votre liste d'amis (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s introuvable dans la liste d'amis."
L["FRIEND_ONLINE_UPDATED"]   = "%s (En ligne) — Mis à jour"

---------------------------------------------------------------------------
-- UI — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - Détail de la rencontre"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Historique des notes"
L["TITLE_HUD"]               = "Midnight Sensei"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Combat terminé"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Options"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei — Rapport de vérification"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei — Comparaison de vérification"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - Ma liste de sorts"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Outils de débogage"
L["TITLE_CREDITS"]           = "Midnight Sensei - Crédits & À propos"
L["TITLE_FAQ"]               = "Midnight Sensei - Aide & FAQ"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Suivi de rotation"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei — Mise à jour disponible"

---------------------------------------------------------------------------
-- UI — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Voir les détails"
L["CTX_DELETE_ENTRY"]        = "Supprimer l'entrée"
L["CTX_CANCEL"]              = "Annuler"
L["CTX_LOCK_POSITION"]       = "Verrouiller la position"
L["CTX_UNLOCK_POSITION"]     = "Déverrouiller la position"
L["CTX_GRADE_HISTORY"]       = "Historique des notes"
L["CTX_LEADERBOARD"]         = "Classement"
L["CTX_BOSS_BOARD"]          = "Tableau des boss"
L["CTX_OPTIONS"]             = "Options"
L["CTX_MY_SPELL_LIST"]       = "Ma liste de sorts"
L["CTX_HELP_FAQ"]            = "Aide / FAQ"
L["CTX_CREDITS"]             = "Crédits"
L["CTX_DEBUG_TOOLS"]         = "Outils de débogage"
L["CTX_CLOSE_HUD"]           = "Fermer le HUD"

---------------------------------------------------------------------------
-- UI — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Durée : %s    Note : %s  (%s)"
L["DETAIL_SCORE"]            = "Score : %d"
L["DETAIL_COMPONENT_SCORES"] = "Scores des composantes :"
L["DETAIL_FEEDBACK"]         = "Retour :"
L["DETAIL_ENC_DUNGEON"]      = "Donjon"
L["DETAIL_ENC_RAID"]         = "Raid"
L["DETAIL_ENC_DELVE"]        = "Plongée"
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
L["HISTORY_COL_SPEC_DIFF"]   = "SPÉC. / DIFF."
L["HISTORY_COL_SCORE"]       = "SCORE"
L["HISTORY_COL_DUR"]         = "DURÉE"
L["HISTORY_COL_WHEN"]        = "QUAND"
L["HISTORY_LB_BTN"]          = "Classement ->"
L["HISTORY_STATS"]           = "%d combats  -  Moy : %d  -  Meilleur : %s  -  Pire : %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d défaite%s"
L["HISTORY_NO_MATCHES"]      = "Aucune rencontre ne correspond au filtre actuel."

---------------------------------------------------------------------------
-- UI — relative time labels
---------------------------------------------------------------------------
L["TIME_JUST_NOW"]           = "à l'instant"
L["TIME_MINUTES_AGO"]        = "il y a %dm"
L["TIME_HOURS_AGO"]          = "il y a %dh"
L["TIME_DAYS_AGO"]           = "il y a %dj"

---------------------------------------------------------------------------
-- UI — HUD
---------------------------------------------------------------------------
L["HUD_NO_FIGHT"]            = "Aucun combat enregistré"
L["HUD_IN_COMBAT"]           = "En combat..."
L["HUD_FIGHT_TOO_SHORT"]     = "Combat trop court pour être enregistré"
L["BTN_REVIEW_FIGHT"]        = "Revoir le combat"
L["BTN_BOSS_BOARD"]          = "Tableau des boss"
L["BTN_LEADERBOARD"]         = "Classement"
L["VERIFY_BAR_LABEL"]        = "Mode vérification activé"
L["BTN_VIEW_REPORT"]         = "Voir le rapport"
L["UPDATE_BAR_LABEL"]        = "Nouvelle version disponible  (cliquez pour les détails)"
L["TT_MENU"]                 = "Menu"
L["TT_HIDE_HUD"]             = "Masquer le HUD"
L["TT_DISMISS"]              = "Ignorer"
L["TT_UPDATE_AVAILABLE"]     = "Mise à jour disponible"
L["TT_UPDATE_CHECK"]         = "Consultez Curseforge ou Wago pour la dernière version."
L["TT_BOSS_BOARD"]           = "Tableau des boss"
L["TT_BOSS_BOARD_DESC"]      = "Vos meilleurs scores personnels de boss de tous les temps"
L["TT_LEADERBOARD"]          = "Classement"
L["TT_LEADERBOARD_DESC"]     = "Guilde / Groupe / Amis / Plongées"

---------------------------------------------------------------------------
-- UI — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Combat propre — rien de majeur à signaler."
L["FIGHT_SCORE_DUR"]         = "Score : %d   Durée : %s"
L["FIGHT_COMPONENT_SCORES"]  = "Scores des composantes :"
L["BTN_HISTORY"]             = "Historique"

---------------------------------------------------------------------------
-- UI — options panel
---------------------------------------------------------------------------
L["OPT_HUD_VISIBILITY"]      = "Visibilité du HUD :"
L["OPT_VIS_ALWAYS"]          = "Toujours"
L["OPT_VIS_IN_COMBAT"]       = "En combat"
L["OPT_VIS_HIDE"]            = "Masquer"
L["OPT_BEHAVIOUR"]           = "Comportement :"
L["OPT_SHOW_POST_FIGHT"]     = "Afficher le bouton de révision post-combat sur le HUD"
L["OPT_LOCK_HUD"]            = "Verrouiller la position du HUD"
L["OPT_ENCOUNTER_ADJUST"]    = "Ajustement des conditions de rencontre"
L["OPT_DEBUG_MODE"]          = "Mode débogage (affiche les messages de rejet LB)"
L["OPT_LEADERBOARD"]         = "Classement :"
L["OPT_LB_NOTE"]             = "La moyenne hebdomadaire ne compte que les rencontres de boss. Les pulls de trash et les mannequins d'entraînement ne sont jamais inclus."
L["BTN_REPORT_ISSUES"]       = "Signaler des problèmes"

---------------------------------------------------------------------------
-- UI — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei — Signaler un bug\n\nCopiez le lien ci-dessous et collez-le dans votre navigateur.\nCtrl+A pour tout sélectionner, puis Ctrl+C pour copier."
L["REPORT_POPUP_BTN"]        = "Fermer"

---------------------------------------------------------------------------
-- UI — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Ctrl+A pour tout sélectionner  ·  Ctrl+C pour copier  ·  Coller dans un commentaire GitHub"
L["BTN_COMPARE"]             = "Comparer"

---------------------------------------------------------------------------
-- UI — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Les sorts affichés ici sont actuellement surveillés par Midnight Sensei."
L["SPELL_LIST_NO_SPEC"]      = "Aucune spécialisation détectée. Participez d'abord à un combat."
L["SPELL_LIST_SEC_CDS"]      = "Sorts à recharge"
L["SPELL_LIST_SEC_INT"]      = "Interruption & Utilitaires"
L["SPELL_LIST_SEC_ROT"]      = "Sorts de rotation"
L["SPELL_LIST_SEC_UPTIME"]   = "Buffs de maintien"
L["SPELL_LIST_SEC_PROCS"]    = "Buffs de procs"
L["SPELL_LIST_SITUATIONAL"]  = "situationnel"
L["SPELL_LIST_SPEND_FAST"]   = "dépenser rapidement"
L["SPELL_LIST_TARGET_UP"]    = "cible %d%% de maintien"
L["SPELL_LIST_METAMORPH"]    = "Nécessite la Métamorphose"

---------------------------------------------------------------------------
-- UI — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- Outils de vérification --"
L["DEBUG_SEC_CLASS"]         = "-- Débogage de classe --"
L["DEBUG_SEC_RECOVERY"]      = "-- Outils de récupération --"
L["DEBUG_BTN_VERIFY_MODE"]   = "Mode vérification"
L["DEBUG_BTN_VERIFY_DESC"]   = "Activer/désactiver la capture d'ID de sort pour /ms verify report"
L["DEBUG_BTN_VR"]            = "Rapport de vérification"
L["DEBUG_BTN_VR_DESC"]       = "Exporter le rapport de vérification d'ID de sort dans une fenêtre copiable"
L["DEBUG_BTN_AUTO_VERIFY"]   = "Activer auto-vérification à la connexion"
L["DEBUG_BTN_AV_DESC"]       = "Le mode vérification s'active automatiquement après chaque rechargement ou connexion"
L["DEBUG_BTN_VERSION"]       = "Version"
L["DEBUG_BTN_VERSION_DESC"]  = "Afficher la version de l'extension depuis le TOC et les API de métadonnées"
L["DEBUG_BTN_ROT_TRACKER"]   = "Suivi de rotation"
L["DEBUG_BTN_RT_DESC"]       = "Ouvrir la fenêtre de suivi de rotation — nombre de lancements, statut et explications des drapeaux pour chaque sort"
L["DEBUG_BTN_TALENT_EXP"]    = "Export de talents"
L["DEBUG_BTN_TE_DESC"]       = "Exporter la capture de talents actifs pour référence croisée avec la base de données de spécialisation"
L["DEBUG_BTN_SPELLS_EXP"]    = "Export de sorts"
L["DEBUG_BTN_SE_DESC"]       = "Exporter la capture complète du livre de sorts pour référence croisée avec la base de données de spécialisation"
L["DEBUG_BTN_BB_INGEST"]     = "Ingestion tableau des boss"
L["DEBUG_BTN_BBI_DESC"]      = "Alimenter le tableau des boss depuis l'historique des rencontres"
L["DEBUG_BTN_FIX_NAME"]      = "Corriger le nom du personnage"
L["DEBUG_BTN_FN_DESC"]       = "Si vous avez renommé votre personnage, exécutez ceci"
L["DEBUG_BTN_BACKFILL"]      = "Compléter les clés M+"
L["DEBUG_BTN_BK_DESC"]       = "Corriger l'historique des donjons Mythique avec les meilleures clés de la saison"
L["DEBUG_BTN_CLEAN"]         = "Nettoyer la charge utile"
L["DEBUG_BTN_CP_DESC"]       = "Rediffuser tous vos meilleurs scores avec le bon format"
L["DEBUG_BTN_CLEAR_BB"]      = "Effacer le tableau des boss"
L["DEBUG_BTN_CBB_DESC"]      = "Supprime définitivement tous les records personnels de boss — cette action est irréversible"
L["DEBUG_BTN_CLEAR_HIST"]    = "Effacer l'historique des combats"
L["DEBUG_BTN_CH_DESC"]       = "Supprime définitivement toutes les rencontres enregistrées — cette action est irréversible"
L["DEBUG_BTN_RUN"]           = "Exécuter"
L["DEBUG_BTN_TOGGLE"]        = "Basculer"

---------------------------------------------------------------------------
-- UI — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Tapez  Confirm  pour activer la suppression :"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Effacer le tableau des boss"
L["DESTRUCT_CLEAR_BB_BODY"]  = "Cela supprimera définitivement tous les enregistrements du tableau des boss pour ce personnage.\nCette action est irréversible."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Supprimer le tableau des boss"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Effacer l'historique des combats"
L["DESTRUCT_CLEAR_HIST_BODY"] = "Cela supprimera définitivement toutes les rencontres de combat enregistrées pour ce personnage.\nCette action est irréversible."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Supprimer l'historique des combats"
L["BTN_CANCEL"]              = "Annuler"

---------------------------------------------------------------------------
-- UI — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "À propos"
L["CREDITS_TAB_SOURCES"]     = "Sources"
L["CREDITS_TAB_CHANGELOG"]   = "Journal des modifications"
L["CREDITS_SOURCES_INTRO"]   = "Les conseils de rotation s'appuient sur les ressources communautaires suivantes."
L["CREDITS_SOURCES_ACK"]     = "Nous remercions chaleureusement leurs contributions."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei n'est pas affilié à ces ressources."
L["CREDITS_NO_CHANGELOG"]    = "Aucun journal des modifications disponible."
L["CREDITS_ABOUT_TEXT"]      = "Une extension de coaching de performance au combat pour World of Warcraft : Midnight.\nNote vos combats de A+ à F pour les 13 classes et 40 spécialisations,\navec des retours pratiques adaptés à votre rôle et spécialisation."
L["CREDITS_AUTHOR"]          = "Auteur :  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Fonctionnalités :"
L["CREDITS_FEAT_GRADING"]    = "  - Note par combat : utilisation des recharges, activité, gestion des ressources"
L["CREDITS_FEAT_TALENT"]     = "  - Sensible aux talents : ne note que les capacités réellement équipées"
L["CREDITS_FEAT_BOSS"]       = "  - Détection des boss : suit ENCOUNTER_START/END pour les vrais combats de boss"
L["CREDITS_FEAT_SOCIAL"]     = "  - Classement social : classements de guilde, groupe et amis BNet"
L["CREDITS_FEAT_WEEKLY"]     = "  - Réinitialisation hebdomadaire : alignée sur la réinitialisation du mardi à 16h00 CEST de Blizzard"
L["CREDITS_FEAT_DELVE"]      = "  - Suivi des plongées : notation par palier pour le contenu solo"
L["CREDITS_FEAT_SYNC"]       = "  - Synchronisation des scores : synchronise entre les membres de guilde pour récupérer les scores après réinstallation"
L["CREDITS_CONTACT"]         = "Contact :  MidnightTim sur GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei est une extension communautaire, non affiliée à Blizzard."

---------------------------------------------------------------------------
-- UI — FAQ headers
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "PREMIERS PAS"
L["FAQ_HDR_UNDERSTANDING"]   = "COMPRENDRE VOTRE NOTE"
L["FAQ_HDR_ROTATIONAL"]      = "RETOUR SUR LES SORTS DE ROTATION"
L["FAQ_HDR_VISIBILITY"]      = "OPTIONS DE VISIBILITÉ"
L["FAQ_HDR_HISTORY"]         = "HISTORIQUE DES NOTES"
L["FAQ_HDR_LEADERBOARD"]     = "CLASSEMENT"
L["FAQ_HDR_MIDNIGHT_NOTE"]   = "NOTE SUR LES RESTRICTIONS DE MIDNIGHT 12.0"
L["FAQ_HDR_BOSS_COMBAT"]     = "BOSS VS COMBAT NORMAL"
L["FAQ_HDR_TALENT_AWARE"]    = "RECHARGES SENSIBLES AUX TALENTS"
L["FAQ_HDR_ALL_COMMANDS"]    = "TOUTES LES COMMANDES"
L["FAQ_MIN_FIGHT"]           = "Un combat de moins de 15 secondes n'est pas enregistré."
L["FAQ_VIS_ALWAYS"]          = "  Toujours : HUD toujours visible"
L["FAQ_VIS_COMBAT"]          = "  En combat : HUD visible uniquement en combat"
L["FAQ_VIS_HIDE"]            = "  Masquer : HUD masqué (accessible via /ms show)"
L["FAQ_CMD_SHOW"]            = "  /ms show         Afficher le HUD"
L["FAQ_CMD_HIDE"]            = "  /ms hide         Masquer le HUD"
L["FAQ_CMD_HISTORY"]         = "  /ms history      Historique des notes & tendances"
L["FAQ_CMD_LB"]              = "  /ms lb           Classement social"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Retirer un joueur du classement de guilde"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Paramètres"
L["FAQ_CMD_FAQ"]             = "  /ms faq          Ce panneau"
L["FAQ_CMD_UPDATE"]          = "  /ms update       Voir le journal des modifications"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Crédits & À propos"
L["FAQ_CMD_REPORT"]          = "  /ms report       Signaler un bug sur GitHub"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Versions de l'extension vues cette session"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Consulter le dernier score d'un joueur"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Ouvrir le suivi de rotation (nombre de lancements + explications des sorts)"

---------------------------------------------------------------------------
-- UI — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Tapez |cffFFFFFF/ms show|r pour ouvrir le HUD, |cffFFFFFF/ms hide|r pour le fermer.\nLe HUD affiche votre dernière note, votre score et votre spécialisation. Après un combat\nvous verrez un bouton |cffFFFFFF>> Revoir le combat|r. Faites un clic droit sur le HUD pour\naccéder rapidement à toutes les fonctionnalités."
L["FAQ_BODY_UNDERSTANDING"]   = "Les notes vont de F à A+. Chaque spécialisation a des catégories pondérées :\n  - Utilisation des recharges : avez-vous utilisé vos recharges majeures régulièrement ?\n  - Sorts de rotation : avez-vous utilisé les capacités de rotation clés à chaque combat ?\n  - Activité : avez-vous lancé des sorts régulièrement ? (pas de longues pauses)\n  - Gestion des ressources : avez-vous dépassé votre ressource (Rage/Énergie/etc.) ?\n  - Maintien des buffs : avez-vous gardé vos auto-buffs actifs ? (selon la spéc.)\n  - Utilisation des procs : avez-vous consommé les procs rapidement ? (TK Givre, Mage Feu...) ?\n  - Efficacité du soigneur : quelle part de vos soins était des sursoins ?"
L["FAQ_BODY_ROTATIONAL"]      = "En plus des recharges, Midnight Sensei suit si vous avez utilisé\nles sorts de rotation clés à chaque combat (ex. Implosion, Lacération, Oblitération).\nSi vous n'en avez jamais utilisé un dans un combat assez long, il apparaîtra dans votre\nretour. Les sorts liés aux talents sont ignorés si vous n'avez pas le talent."
L["FAQ_BODY_VIS_INTRO"]       = "Ouvrez |cffFFFFFF/ms options|r (ou clic droit HUD -> Options) et définissez :"
L["FAQ_BODY_HISTORY"]         = "Tapez |cffFFFFFF/ms history|r ou clic droit -> Historique des notes.\n  - Filtrer par ce personnage ou tous les personnages\n  - La sparkline montre vos 20 derniers combats en un coup d'œil\n  - Clic gauche sur une ligne pour voir les détails complets et le feedback\n  - Clic droit sur une ligne pour supprimer cette entrée"
L["FAQ_BODY_LEADERBOARD"]     = "Tapez |cffFFFFFF/ms lb|r pour ouvrir le classement social.\nAprès chaque combat de boss, votre score est diffusé à la guilde, au groupe et\naux amis BNet qui ont aussi Midnight Sensei installé.\nOnglets : Groupe (session uniquement), Guilde (persiste entre sessions), Amis.\nLes scores de guilde persistent entre les sessions et se synchronisent entre les membres —\nmême si un joueur est hors ligne, vous pouvez voir son dernier score enregistré.\nLa moyenne hebdomadaire ne compte que les rencontres de boss — les pulls de trash et les\nmannequins ne sont jamais inclus dans les classements.\nClic droit sur une ligne de guilde pour retirer un joueur. Il réapparaît\nautomatiquement à sa prochaine connexion ou quand vous actualisez."
L["FAQ_BODY_LB_EXTRA"]        = "Chaque onglet (Donjons, Raids) affiche les informations de lieu pour ce type de contenu\nuniquement — une course LFR n'apparaîtra jamais dans l'onglet Donjons.\nLe niveau de clé Mythique+ est affiché si disponible (ex. M+15).\nAprès une mise à jour de l'extension, chaque joueur doit compléter un nouveau\ndonjon ou raid pour que l'emplacement de l'onglet reflète le bon contenu.\nVotre propre entrée se met à jour immédiatement depuis l'historique local — aucune nouvelle course nécessaire."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard a restreint la lecture des auras des unités ennemies dans Midnight 12.0.\nLes débuffs de cible (Rupture, Choc des flammes, etc.) ne peuvent pas être suivis directement.\nCeux-ci apparaissent dans vos priorityNotes comme conseils mais ne sont pas notés.\nTous les auto-buffs, recharges et lancements de rotation du joueur fonctionnent normalement."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei détecte les rencontres de boss via ENCOUNTER_START/END.\nLes combats de boss affichent un tag |cffFF6600[Boss]|r dans l'historique et le détail de rencontre.\nFiltrez votre historique sur |cffFFFFFF[Boss] uniquement|r pour revoir les pulls de boss de raid/donjon."
L["FAQ_BODY_TALENT_AWARE"]    = "La notation des recharges n'inclut que les sorts que vous avez appris.\nSi vous n'avez pas un talent, il ne sera pas compté contre vous."

---------------------------------------------------------------------------
-- UI — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Nombre de lancements de votre dernier combat. Chaque sort indique combien de fois il a été utilisé et pourquoi il est suivi."
L["ROT_TRACKER_NO_DATA"]     = "Pas encore de données de combat — participez à un combat pour voir les résultats de suivi."
L["ROT_TRACKER_LAST_FIGHT"]  = "Dernier combat : %s"
L["ROT_TRACKER_NO_FIGHT"]    = "Aucun combat enregistré"
L["ROT_COL_SPELL"]           = "SORT"
L["ROT_COL_CASTS"]           = "LANCEMENTS"
L["ROT_COL_MIN_FIGHT"]       = "COMBAT MIN."
L["ROT_COL_STATUS"]          = "STATUT"
L["ROT_STATUS_CAST"]         = "LANCÉ"
L["ROT_STATUS_MISSED"]       = "MANQUÉ"
L["ROT_STATUS_SHORT"]        = "COURT"
L["ROT_FLAG_COMBAT_TALENT"]  = "Nécessite un talent ; utilisable uniquement pendant une fenêtre de transformation"
L["ROT_FLAG_COMBAT_ONLY"]    = "Utilisable uniquement pendant une fenêtre de transformation (ex. Méta-morphose du vide)"
L["ROT_FLAG_TALENT_ONLY"]    = "Suivi uniquement quand ce talent est actif dans votre build"
L["ROT_FLAG_CORE"]           = "Capacité de rotation principale — attendue à chaque combat"
L["ROT_FLAG_MIN_FIGHT"]      = "considéré manqué seulement si combat > %ds"
L["ROT_NOT_TRACKED"]         = "Non suivi dans ce build (talent non pris ou remplacé) : %s"
L["ROT_LEGEND_CAST_DESC"]    = "utilisé au moins une fois"
L["ROT_LEGEND_MISSED_DESC"]  = "le combat était assez long mais le sort n'a pas été utilisé"
L["ROT_LEGEND_SHORT_DESC"]   = "combat trop court pour être évalué"

---------------------------------------------------------------------------
-- UI — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "Une nouvelle version de Midnight Sensei est disponible.\nConsultez Curseforge ou Wago pour la dernière version."
L["SETTINGS_CATEGORY"]       = "Midnight Sensei"
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Créé par Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Ouvrir les options"
L["SETTINGS_BTN_OPT_DESC"]   = "Configurer le HUD, le style de jeu et plus"
L["SETTINGS_BTN_HISTORY"]    = "Historique des notes"
L["SETTINGS_BTN_HIST_DESC"]  = "Voir l'historique des combats et les tendances"
L["SETTINGS_BTN_LB"]         = "Classement"
L["SETTINGS_BTN_LB_DESC"]    = "Classements Guilde / Groupe / Amis / Plongées"
L["SETTINGS_BTN_FAQ"]        = "Aide & FAQ"
L["SETTINGS_BTN_FAQ_DESC"]   = "Comment fonctionne le scoring et la notation"
L["SETTINGS_BTN_CREDITS"]    = "Crédits & À propos"
L["SETTINGS_BTN_CRED_DESC"]  = "Infos sur l'auteur et sources"
L["SETTINGS_LEGACY_SUB"]     = "Créé par Midnight - Thrall (US)  |  /ms pour les commandes"
L["MINIMAP_TT_TITLE"]        = "Midnight Sensei"
L["MINIMAP_TT_LEFT"]         = "Clic gauche : Basculer le HUD"
L["MINIMAP_TT_RIGHT"]        = "Clic droit : Classement"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Ctrl+Clic droit : Tableau des boss"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "Maj+Clic droit : Options"

---------------------------------------------------------------------------
-- Analytics/Feedback
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "Vous avez perdu de la valeur avec des recharges inutilisées%s : %s. Même les appuyer régulièrement aide."
L["FB_NEVER_PRESSED"]        = "Jamais utilisé%s : %s — %s."
L["FB_ACTION_TANK"]          = "utiliser sur les tank busters ou les fenêtres de dégâts élevés"
L["FB_ACTION_HEALER"]        = "aligner avec les fenêtres de dégâts entrants élevés"
L["FB_ACTION_DPS"]           = "aligner avec les fenêtres de burst"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Votre rotation est régulière, mais les écarts entre les lancements (%d%% d'activité) sont la prochaine chose à améliorer."
L["FB_ACTIVITY_MODERATE"]    = "Activité à %d%% — environ %d lancement(s) laissé(s) de côté. Préparez votre prochain sort avant que l'actuel atterrisse."
L["FB_ACTIVITY_LOW"]         = "Activité : %d/%d GCDs (%d%%) — %s temps d'arrêt, environ %d lancements perdus. Trouvez votre prochain sort avant que l'actuel se termine."
L["FB_DOWNTIME_SIGNIFICANT"] = "significatif"
L["FB_DOWNTIME_MODERATE"]    = "modéré"
L["FB_UNDERUSED"]            = "Utilisé moins que prévu dans un combat de %.1fmin : %s — visez 1 utilisation par 2 minutes de combat."
L["FB_ROT_NEVER_USED"]       = "Sort(s) de rotation jamais utilisé(s) : %s — ils sont essentiels à votre %s."
L["FB_ROT_CONTEXT_TANK"]     = "rotation de survie et de menace"
L["FB_ROT_CONTEXT_HEALER"]   = "débit de soins"
L["FB_ROT_CONTEXT_DPS"]      = "production de dégâts"
L["FB_ROT_LOW_USED"]         = "Aurait pu lancer davantage : %s — utilisez ces sorts à chaque GCD disponible quand vos dépenseurs principaux sont en recharge."
L["FB_PROC_DELAYED"]         = "retardé"
L["FB_PROC_CRITICALLY"]      = "critiquement retardé"
L["FB_PROC_MSG"]             = "La consommation de %s est %s — maintenu %.1fs en moyenne (budget : %ds). Consommez les procs immédiatement quand ils apparaissent."
L["FB_OVERCAP"]              = "%s dépassé %d fois (%.1f/min) — dépensez %s avant d'atteindre %d pour éviter la génération gaspillée."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s n'a jamais été activé — appuyez dessus à chaque fois qu'il est disponible pour réduire les dégâts physiques subis."
L["FB_MIT_LOW_UPTIME"]       = "%s : %d%% de maintien vs %d%% cible (%dpt d'écart, %d application(s)) — vous avez de grandes fenêtres de dégâts physiques non atténués. Appuyez dessus dès qu'il sort de recharge."
L["FB_MIT_SMALL_GAPS"]       = "%s : %d%% de maintien vs %d%% cible (%dpt d'écart) — les petits écarts s'accumulent. Utilisez-le de façon préventive sur les séquences de mêlée lourdes, pas de façon réactive."
L["FB_BUFF_LOW_UPTIME"]      = "%s : %d%% de maintien vs %d%% cible (%dpt d'écart) — réappliquez avant qu'il expire, pas après."
L["FB_GROUP_BUFF_NOTE"]      = "%s (buff de groupe — assurez-vous qu'il est actif avant le combat)"
L["FB_OVERHEAL_HIGH"]        = "Sursoins à %.1f%% (cible : <%d%%) — vous dépensez du mana sur des cibles qui n'ont pas besoin de soins. Lancez légèrement plus tard ou passez aux sorts réactifs sur des cibles qui subissent activement des dégâts."
L["FB_OVERHEAL_ELEVATED"]    = "Sursoins : %.1f%% (cible : <%d%%) — légèrement élevé. Retenez les lancements sur les cibles au-dessus de 70%% de santé et privilégiez les HoTs aux soins directs sur les groupes stables."
L["FB_HEALER_FILL_DOWNTIME"] = "Quand le groupe est stable, remplissez le temps d'arrêt avec des sorts de dégâts pour maintenir le débit."
L["FB_SIMPLIFIED_FALLBACK"]  = "Votre rotation est régulière et bien rythéme. Affiner le timing des fenêtres de burst est la prochaine étape de performance."
L["FB_NEAR_PERFECT"]         = "Exécution quasi parfaite. Les gains restants sont : %s."
L["FB_NEXT_TANK_PREPOS"]     = "pré-positionner les défensives avant les dégâts de pointe prévisibles"
L["FB_NEXT_HEALER_OVERLAP"]  = "chevaucher les recharges avec les incantations de dégâts entrants plutôt que de réagir"
L["FB_NEXT_DPS_ALIGN"]       = "aligner les fenêtres de burst avec les phases de vulnérabilité ennemie"
L["FB_NEXT_GCD_TIMING"]      = "réduire le temps entre la fin du GCD et votre prochain lancement en dessous de 0,2s"
L["FB_STRONG_EXECUTION"]     = "Exécution globalement forte. Votre catégorie la plus faible est %s — c'est là que viennent les prochains points."
L["FB_GOOD_FOUNDATION"]      = "Bonne base — concentrez-vous ensuite sur : %s."
L["FB_HINT_TANK_CDS"]        = "utiliser les recharges défensives sur les tank busters"
L["FB_HINT_PRESS_CDS"]       = "appuyer plus régulièrement sur les recharges majeures"
L["FB_HINT_MIT_UPTIME"]      = "augmenter le maintien de l'atténuation en appuyant plus souvent sur %s"
L["FB_SOLID"]                = "Performance solide — affinez le timing des recharges pour progresser."
L["FB_NOTE_INTERRUPT"]       = "Note : %s — c'est votre interruption. Non utilisé pendant ce combat — aucune pénalité."
L["FB_NOTE_UTILITY"]         = "Note : %s — non utilisé ou non détecté pendant ce combat. Aucune pénalité."
L["FB_NOTE_COMBAT_UTILITY"]  = "Note : %s — étourdit et inflige des dégâts en plus de l'utilitaire. Utilisez-le quand la situation le permet ; aucune pénalité pour le retenir."
