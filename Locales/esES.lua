-- MidnightSensei — Locale: esES / esMX (Spanish)
-- Loaded after enUS.lua. Early-returns if the client is not Spanish.
-- Only keys present here override the English defaults.
-- To add another language: copy this file, change the GetLocale() check, translate.

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end
local L = MidnightSensei.L

---------------------------------------------------------------------------
-- Grade labels
---------------------------------------------------------------------------
L["GRADE_EXCEPTIONAL"]       = "Excepcional"
L["GRADE_EXCELLENT"]         = "Excelente"
L["GRADE_GREAT_WORK"]        = "Gran trabajo"
L["GRADE_STRONG"]            = "S\xC3\xB3lido"
L["GRADE_ON_TRACK"]          = "En camino"
L["GRADE_SOLID"]             = "Consistente"
L["GRADE_GOOD_FOUNDATION"]   = "Buena base"
L["GRADE_ROOM_TO_GROW"]      = "Hay margen de mejora"
L["GRADE_KEEP_PRACTICING"]   = "Sigue practicando"
L["GRADE_BUILDING_HABITS"]   = "Desarrollando h\xC3\xA1bitos"
L["GRADE_LEARNING_CURVE"]    = "Curva de aprendizaje"
L["GRADE_EARLY_DAYS"]        = "Primeros pasos"
L["GRADE_FRESH_START"]       = "Nuevo comienzo"

---------------------------------------------------------------------------
-- Addon load / level gate
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "cargado.  /ms show para abrir el HUD  \xC2\xB7  /ms help para los comandos."
L["LEVEL_GATE_WARNING"]      = "Este addon est\xC3\xA1 dise\xC3\xB1ado para contenido de nivel 80+. El seguimiento de combate y las calificaciones est\xC3\xA1n desactivados hasta alcanzar el nivel 80."
L["WEEKLY_RESET_DETECTED"]   = "Reinicio Semanal Detectado."

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Comandos de Midnight Sensei:"
L["SLASH_HELP_SHOW"]         = "  /ms show          Mostrar el HUD"
L["SLASH_HELP_HIDE"]         = "  /ms hide          Ocultar el HUD"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Historial de calificaciones y tendencias"
L["SLASH_HELP_LB"]           = "  /ms lb            Clasificaci\xC3\xB3n social"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Clasificaci\xC3\xB3n personal de jefes  (alias: /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Panel de configuraci\xC3\xB3n"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Ayuda y preguntas frecuentes"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Cr\xC3\xA9ditos e informaci\xC3\xB3n"
L["SLASH_HELP_REPORT"]       = "  /ms report        Reportar un error en GitHub"
L["SLASH_HELP_UPDATE"]       = "  /ms update        Mostrar registro de cambios"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Mostrar versiones del addon vistas en esta sesi\xC3\xB3n"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Consultar la \xC3\xBAltima puntuaci\xC3\xB3n de un jugador directamente"

---------------------------------------------------------------------------
-- Chat status messages
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "La base de datos del gremio est\xC3\xA1 vac\xC3\xADa."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei \xe2\x80\x94 Claves de la base de datos del gremio:"
L["FRIEND_USAGE"]            = "Uso: /ms friend Nombre  o  /ms friend add Nombre  o  /ms friend remove Nombre"
L["LB_REMOVE_USAGE"]         = "Uso: /ms lb remove <NombreJugador>"
L["VERSIONS_HEADER"]         = "Midnight Sensei \xe2\x80\x94 Versiones vistas en esta sesi\xC3\xB3n:"
L["VERSIONS_NO_DATA"]        = "A\xC3\xBAn no hay datos de versi\xC3\xB3n \xe2\x80\x94 se recopilan autom\xC3\xA1ticamente cuando los jugadores inician sesi\xC3\xB3n o se unen a tu grupo."
L["VERSIONS_YOU"]            = "(t\xC3\xBA)"
L["VERSIONS_OUTDATED"]       = "(desactualizado)"
L["SILENT_MODE_ON"]          = "Midnight Sensei: Modo silencioso ACTIVADO \xe2\x80\x94 todos los mensajes salientes del addon est\xC3\xA1n suprimidos."
L["SILENT_MODE_OFF"]         = "Midnight Sensei: Modo silencioso DESACTIVADO \xe2\x80\x94 operaci\xC3\xB3n normal reanudada."

---------------------------------------------------------------------------
-- Verify mode
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei Modo Verificaci\xC3\xB3n: ACTIVADO"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei Modo Verificaci\xC3\xB3n: DESACTIVADO"
L["VERIFY_CAST_HINT"]        = "Lanza tus hechizos con normalidad. Tras el combate escribe /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei: No se ha cargado ninguna especializaci\xC3\xB3n."

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei: A\xC3\xBAn no hay instant\xC3\xA1nea de talentos \xe2\x80\x94 se genera autom\xC3\xA1ticamente al iniciar sesi\xC3\xB3n y al cambiar de especializaci\xC3\xB3n. Si es tu primera sesi\xC3\xB3n, escribe /reload e int\xC3\xA9ntalo de nuevo."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei: A\xC3\xBAn no hay instant\xC3\xA1nea de hechizos \xe2\x80\x94 se genera autom\xC3\xA1ticamente al iniciar sesi\xC3\xB3n. Si es tu primera sesi\xC3\xB3n, escribe /reload e int\xC3\xA9ntalo de nuevo."

---------------------------------------------------------------------------
-- BossBoard — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Tabla de Jefes"
L["BB_DESCRIPTION"]          = "Tu puntuaci\xC3\xB3n m\xC3\xA1s alta por jefe en Midnight \xe2\x80\x94 haz clic en cualquier fila para revisar tu mejor retroalimentaci\xC3\xB3n"
L["BB_TAB_DUNGEONS"]         = "Mazmorras"
L["BB_TAB_RAIDS"]            = "Bandas"
L["BB_TAB_DELVES"]           = "Delves"
L["BB_COL_DATE"]             = "FECHA"
L["BB_COL_CHARACTER"]        = "PERSONAJE"
L["BB_COL_SPEC"]             = "ESPEC"
L["BB_COL_DIFF_BOSS"]        = "DIF / JEFE"
L["BB_COL_SCORE"]            = "PUNTUACI\xC3\x93N"
L["BB_NO_ENCOUNTERS"]        = "A\xC3\xBAn no se han registrado encuentros con jefes para este tipo de contenido."
L["BB_FOOTER_INFO"]          = "Solo kills de jefes  -  nivel 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d jefe%s registrado"
L["BB_TT_BEST"]              = "Mejor: %s  %d"
L["BB_TT_DATE"]              = "Fecha: %s"
L["BB_TT_KILLS"]             = "Kills rastreados: %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Haz clic para ver retroalimentaci\xC3\xB3n"

---------------------------------------------------------------------------
-- BossBoard — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Tabla de Jefes: Incorporaci\xC3\xB3n completa \xe2\x80\x94 a\xC3\xB1adidos: %d  actualizados: %d  omitidos: %d"
L["BB_SPEC_NOT_DETECTED"]    = "Tabla de Jefes: No se pudo detectar la especializaci\xC3\xB3n activa \xe2\x80\x94 los campos pueden estar incompletos. Int\xC3\xA9ntalo de nuevo tras cargar completamente."
L["BB_REPAIR_COMPLETE"]      = "Tabla de Jefes: Reparaci\xC3\xB3n de identidad completa \xe2\x80\x94 corregidas: %d entr%s"
L["BB_NO_BOSSDATA"]          = "No se encontraron datos de mejores jefes."
L["BB_SPEC_UNRESOLVED"]      = "Tabla de Jefes: Especializaci\xC3\xB3n no detectada a\xC3\xBAn \xe2\x80\x94 int\xC3\xA9ntalo de nuevo tras cargar completamente."
L["BB_RENAME_COMPLETE"]      = "Correcci\xC3\xB3n de nombre de personaje completa (%s \xe2\x86\x92 %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Historial de calificaciones / revisi\xC3\xB3n de combates: %d encuentro%s actualizado"
L["BB_RENAME_BB_UPDATED"]    = "  Tabla de Jefes: %d entr%s actualizada; instant\xC3\xA1nea compartida re-indexada"
L["BB_CANNOT_READ_NAME"]     = "No se pudo leer el nombre del jugador \xe2\x80\x94 int\xC3\xA9ntalo de nuevo tras cargar completamente."
L["BB_NO_CHARDB"]            = "No se encontr\xC3\xB3 CharDB."
L["BB_NO_SNAPDATA"]          = "No se encontr\xC3\xB3 instant\xC3\xA1nea compartida."
L["BB_CLEANUP_DRY_HDR"]      = "Limpieza: %d encuentro(s) ser\xC3\xADan marcados como fracasos. Ejecuta /ms debug cleanup history confirm para aplicar."
L["BB_CLEANUP_APPLIED"]      = "Limpieza de historial \xe2\x80\x94 %d fracaso(s) legado(s) corregido(s); Tabla de Jefes actualizada donde hab\xC3\xADa datos de historial."
L["BB_RESTORE_COMPLETE"]     = "Restauraci\xC3\xB3n de instant\xC3\xA1nea completa \xe2\x80\x94 recuperados: %d  ya actuales: %d"
L["BB_RESTORE_NOTE"]         = "Las entradas restauradas tienen puntuaci\xC3\xB3n/calificaci\xC3\xB3n/fecha pero no retroalimentaci\xC3\xB3n de combate ni puntuaciones por componente."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei: Tabla de Jefes borrada."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei: Historial de combates borrado."

---------------------------------------------------------------------------
-- BossBoard — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Corregir Nombre de Personaje"
L["FIX_NAME_OLD_LABEL"]      = "Nombre antiguo del personaje (encontrado en tu historial):"
L["FIX_NAME_NEW_LABEL"]      = "Ser\xC3\xA1 reemplazado por (tu nombre de personaje actual):"
L["FIX_NAME_ERR_EMPTY"]      = "Por favor, introduce el nombre antiguo del personaje."
L["FIX_NAME_ERR_SAME"]       = "Ese nombre coincide con tu personaje actual \xe2\x80\x94 no hay nada que corregir."
L["FIX_NAME_ERR_NOT_FOUND"]  = "No se encontr\xC3\xB3 historial bajo \"%s\". Comprueba la ortograf\xC3\xADa, las may\xC3\xBasculas y cualquier car\xC3\xA1cter especial."
L["FIX_NAME_BTN_CONFIRM"]    = "Confirmar Correcci\xC3\xB3n"

---------------------------------------------------------------------------
-- Leaderboard — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Uso: /ms friend Nombre  o  /ms friend Nombre-Reino"
L["FRIEND_CHECKING"]         = "Verificando %s..."
L["FRIEND_OFFLINE"]          = "%s (Sin conexi\xC3\xB3n) \xe2\x80\x94 No actualizado o addon no instalado"
L["FRIEND_CANNOT_REACH"]     = "No se pudo contactar con %s \xe2\x80\x94 comprueba el nombre/reino. Error: %s"
L["FRIEND_LIST_FULL"]        = "La lista de amigos est\xC3\xA1 llena (%d m\xC3\xA1x.). Elimina a alguien primero con clic derecho o /ms friend remove Nombre."
L["FRIEND_ALREADY_IN"]       = "%s ya est\xC3\xA1 en tu lista de amigos."
L["FRIEND_ADDED"]            = "%s a\xC3\xB1adido a tu lista de amigos (%d/%d)."
L["FRIEND_REMOVED"]          = "%s eliminado de tu lista de amigos (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s no encontrado en la lista de amigos."
L["FRIEND_ONLINE_UPDATED"]   = "%s (En l\xC3\xADnea) \xe2\x80\x94 Actualizado"

---------------------------------------------------------------------------
-- UI — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - Detalle del Encuentro"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Historial de Calificaciones"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Combate Completado"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Opciones"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei \xe2\x80\x94 Informe de Verificaci\xC3\xB3n"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei \xe2\x80\x94 Comparaci\xC3\xB3n de Verificaci\xC3\xB3n"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - Mis Hechizos"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Herramientas de Depuraci\xC3\xB3n"
L["TITLE_CREDITS"]           = "Midnight Sensei - Cr\xC3\xA9ditos e Informaci\xC3\xB3n"
L["TITLE_FAQ"]               = "Midnight Sensei - Ayuda y Preguntas Frecuentes"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Seguidor de Rotaci\xC3\xB3n"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei \xe2\x80\x94 Actualizaci\xC3\xB3n Disponible"

---------------------------------------------------------------------------
-- UI — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Inspeccionar Detalles"
L["CTX_DELETE_ENTRY"]        = "Eliminar Entrada"
L["CTX_CANCEL"]              = "Cancelar"
L["CTX_LOCK_POSITION"]       = "Bloquear Posici\xC3\xB3n"
L["CTX_UNLOCK_POSITION"]     = "Desbloquear Posici\xC3\xB3n"
L["CTX_GRADE_HISTORY"]       = "Historial de Calificaciones"
L["CTX_LEADERBOARD"]         = "Clasificaci\xC3\xB3n"
L["CTX_BOSS_BOARD"]          = "Tabla de Jefes"
L["CTX_OPTIONS"]             = "Opciones"
L["CTX_MY_SPELL_LIST"]       = "Mis Hechizos"
L["CTX_HELP_FAQ"]            = "Ayuda / FAQ"
L["CTX_CREDITS"]             = "Cr\xC3\xA9ditos"
L["CTX_DEBUG_TOOLS"]         = "Herramientas de Depuraci\xC3\xB3n"
L["CTX_CLOSE_HUD"]           = "Cerrar HUD"

---------------------------------------------------------------------------
-- UI — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Duraci\xC3\xB3n: %s    Calificaci\xC3\xB3n: %s  (%s)"
L["DETAIL_SCORE"]            = "Puntuaci\xC3\xB3n: %d"
L["DETAIL_COMPONENT_SCORES"] = "Puntuaciones por Componente:"
L["DETAIL_FEEDBACK"]         = "Retroalimentaci\xC3\xB3n:"
L["DETAIL_ENC_DUNGEON"]      = "Mazmorra"
L["DETAIL_ENC_RAID"]         = "Banda"
L["DETAIL_ENC_WORLD"]        = "Mundo"
L["DETAIL_ENC_COMBAT"]       = "Combate"
L["BTN_CLOSE"]               = "Cerrar"

---------------------------------------------------------------------------
-- UI — grade history panel
---------------------------------------------------------------------------
L["HISTORY_TREND_LABEL"]     = "Tendencia (\xC3\xBAltimas 20):"
L["HISTORY_FILTER_LABEL"]    = "Filtro:"
L["FILTER_THIS_CHARACTER"]   = "Este Personaje"
L["FILTER_BOSS_ONLY"]        = "Solo [Jefe]"
L["HISTORY_COL_GR"]          = "CAL"
L["HISTORY_COL_CHARACTER"]   = "PERSONAJE"
L["HISTORY_COL_SPEC_DIFF"]   = "ESPEC / DIF"
L["HISTORY_COL_SCORE"]       = "PUNTUACI\xC3\x93N"
L["HISTORY_COL_WHEN"]        = "CU\xC3\x81NDO"
L["HISTORY_LB_BTN"]          = "Clasificaci\xC3\xB3n ->"
L["HISTORY_STATS"]           = "%d combates  -  Prom: %d  -  Mejor: %s  -  Peor: %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d fracaso%s"
L["HISTORY_NO_MATCHES"]      = "Ning\xC3\xBAn encuentro coincide con el filtro actual."

---------------------------------------------------------------------------
-- UI — relative time labels
---------------------------------------------------------------------------
L["TIME_JUST_NOW"]           = "ahora mismo"
L["TIME_MINUTES_AGO"]        = "hace %dm"
L["TIME_HOURS_AGO"]          = "hace %dh"
L["TIME_DAYS_AGO"]           = "hace %dd"

---------------------------------------------------------------------------
-- UI — HUD
---------------------------------------------------------------------------
L["HUD_NO_FIGHT"]            = "A\xC3\xBAn no hay combate registrado"
L["HUD_IN_COMBAT"]           = "En combate..."
L["HUD_FIGHT_TOO_SHORT"]     = "Combate demasiado corto para registrar"
L["BTN_REVIEW_FIGHT"]        = "Revisar Combate"
L["BTN_BOSS_BOARD"]          = "Tabla de Jefes"
L["BTN_LEADERBOARD"]         = "Clasificaci\xC3\xB3n"
L["VERIFY_BAR_LABEL"]        = "Modo Verificaci\xC3\xB3n Activado"
L["BTN_VIEW_REPORT"]         = "Ver Informe"
L["UPDATE_BAR_LABEL"]        = "Nueva Versi\xC3\xB3n Disponible  (haz clic para m\xC3\xA1s detalles)"
L["TT_MENU"]                 = "Men\xC3\xBA"
L["TT_HIDE_HUD"]             = "Ocultar HUD"
L["TT_DISMISS"]              = "Descartar"
L["TT_UPDATE_AVAILABLE"]     = "Actualizaci\xC3\xB3n Disponible"
L["TT_UPDATE_CHECK"]         = "Consulta Curseforge o Wago para la \xC3\xBAltima versi\xC3\xB3n."
L["TT_BOSS_BOARD"]           = "Tabla de Jefes"
L["TT_BOSS_BOARD_DESC"]      = "Mejores puntuaciones personales por jefe"
L["TT_LEADERBOARD"]          = "Clasificaci\xC3\xB3n"
L["TT_LEADERBOARD_DESC"]     = "Gremio / Grupo / Amigos / Delves"

---------------------------------------------------------------------------
-- UI — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Combate limpio - nada importante que se\xC3\xB1alar."
L["FIGHT_SCORE_DUR"]         = "Puntuaci\xC3\xB3n: %d   Duraci\xC3\xB3n: %s"
L["FIGHT_COMPONENT_SCORES"]  = "Puntuaciones por Componente:"
L["BTN_HISTORY"]             = "Historial"

---------------------------------------------------------------------------
-- UI — options panel
---------------------------------------------------------------------------
L["OPT_HUD_VISIBILITY"]      = "Visibilidad del HUD:"
L["OPT_VIS_ALWAYS"]          = "Siempre"
L["OPT_VIS_IN_COMBAT"]       = "En Combate"
L["OPT_VIS_HIDE"]            = "Ocultar"
L["OPT_BEHAVIOUR"]           = "Comportamiento:"
L["OPT_SHOW_POST_FIGHT"]     = "Mostrar bot\xC3\xB3n de revisi\xC3\xB3n post-combate en el HUD"
L["OPT_LOCK_HUD"]            = "Bloquear posici\xC3\xB3n del HUD"
L["OPT_ENCOUNTER_ADJUST"]    = "Ajuste de condici\xC3\xB3n del encuentro"
L["OPT_DEBUG_MODE"]          = "Modo depuraci\xC3\xB3n (muestra mensajes de rechazo de clasificaci\xC3\xB3n)"
L["OPT_LEADERBOARD"]         = "Clasificaci\xC3\xB3n:"
L["OPT_LB_NOTE"]             = "El promedio semanal siempre cuenta solo encuentros con jefes. Los tirones de trash y los mu\xC3\xB1ecos de entrenamiento nunca se incluyen."
L["BTN_REPORT_ISSUES"]       = "Reportar Problemas"

---------------------------------------------------------------------------
-- UI — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei \xe2\x80\x94 Reportar un Error\n\nCopia el enlace de abajo y p\xC3\xA9galo en tu navegador.\nCtrl+A para seleccionar todo, luego Ctrl+C para copiar."
L["REPORT_POPUP_BTN"]        = "Cerrar"

---------------------------------------------------------------------------
-- UI — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Ctrl+A para seleccionar todo  \xC2\xB7  Ctrl+C para copiar  \xC2\xB7  Pega en un comentario de GitHub"
L["BTN_COMPARE"]             = "Comparar"

---------------------------------------------------------------------------
-- UI — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Los hechizos mostrados aqu\xC3\xAD son los que Midnight Sensei est\xC3\xA1 monitoreando actualmente."
L["SPELL_LIST_NO_SPEC"]      = "No se detect\xC3\xB3 especializaci\xC3\xB3n. Entra en un combate primero."
L["SPELL_LIST_SEC_CDS"]      = "Hechizos de Recarga"
L["SPELL_LIST_SEC_INT"]      = "Interrupci\xC3\xB3n y Utilidad"
L["SPELL_LIST_SEC_ROT"]      = "Hechizos Rotacionales"
L["SPELL_LIST_SEC_UPTIME"]   = "Potenciadores de Tiempo Activo"
L["SPELL_LIST_SEC_PROCS"]    = "Potenciadores por Proc"
L["SPELL_LIST_SITUATIONAL"]  = "situacional"
L["SPELL_LIST_SPEND_FAST"]   = "gastar r\xC3\xA1pido"
L["SPELL_LIST_TARGET_UP"]    = "objetivo %d%% de tiempo activo"
L["SPELL_LIST_METAMORPH"]    = "Requiere Metamorfosis"

---------------------------------------------------------------------------
-- UI — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- Herramientas de Verificaci\xC3\xB3n --"
L["DEBUG_SEC_CLASS"]         = "-- Depuraci\xC3\xB3n de Clase --"
L["DEBUG_SEC_RECOVERY"]      = "-- Herramientas de Recuperaci\xC3\xB3n --"
L["DEBUG_BTN_VERIFY_MODE"]   = "Modo Verificaci\xC3\xB3n"
L["DEBUG_BTN_VERIFY_DESC"]   = "Alternar captura de IDs de hechizos para /ms verify report"
L["DEBUG_BTN_VR"]            = "Informe de Verificaci\xC3\xB3n"
L["DEBUG_BTN_VR_DESC"]       = "Exportar informe de verificaci\xC3\xB3n de IDs de hechizos a ventana copiable"
L["DEBUG_BTN_AUTO_VERIFY"]   = "Activar Verificaci\xC3\xB3n autom\xC3\xA1ticamente al iniciar sesi\xC3\xB3n"
L["DEBUG_BTN_AV_DESC"]       = "El modo verificaci\xC3\xB3n se activa autom\xC3\xA1ticamente tras cada recarga o inicio de sesi\xC3\xB3n"
L["DEBUG_BTN_VERSION"]       = "Versi\xC3\xB3n"
L["DEBUG_BTN_VERSION_DESC"]  = "Mostrar versi\xC3\xB3n del addon desde TOC y APIs de metadatos"
L["DEBUG_BTN_ROT_TRACKER"]   = "Seguidor de Rotaci\xC3\xB3n"
L["DEBUG_BTN_RT_DESC"]       = "Abrir la ventana del Seguidor de Rotaci\xC3\xB3n \xe2\x80\x94 conteo de lanzamientos, estado y explicaciones para cada hechizo"
L["DEBUG_BTN_TALENT_EXP"]    = "Exportar Talentos"
L["DEBUG_BTN_TE_DESC"]       = "Exportar instant\xC3\xA1nea de talentos activos para referencia cruzada con la base de datos"
L["DEBUG_BTN_SPELLS_EXP"]    = "Exportar Hechizos"
L["DEBUG_BTN_SE_DESC"]       = "Exportar instant\xC3\xA1nea completa del libro de hechizos para referencia cruzada"
L["DEBUG_BTN_BB_INGEST"]     = "Incorporar Tabla de Jefes"
L["DEBUG_BTN_BBI_DESC"]      = "Poblar la Tabla de Jefes desde el historial de encuentros"
L["DEBUG_BTN_FIX_NAME"]      = "Corregir Nombre de Personaje"
L["DEBUG_BTN_FN_DESC"]       = "Ejecuta esto si cambiaste el nombre de tu personaje"
L["DEBUG_BTN_BACKFILL"]      = "Rellenar Llaves M+"
L["DEBUG_BTN_BK_DESC"]       = "Actualizar el historial de mazmorras M\xC3\xADticas con los mejores niveles de llave de la temporada"
L["DEBUG_BTN_CLEAN"]         = "Limpiar Datos"
L["DEBUG_BTN_CP_DESC"]       = "Retransmitir todas tus mejores puntuaciones con el formato correcto"
L["DEBUG_BTN_CLEAR_BB"]      = "Borrar Tabla de Jefes"
L["DEBUG_BTN_CBB_DESC"]      = "Elimina permanentemente todos los registros personales de jefes \xe2\x80\x94 esta acci\xC3\xB3n no se puede deshacer"
L["DEBUG_BTN_CLEAR_HIST"]    = "Borrar Historial de Combates"
L["DEBUG_BTN_CH_DESC"]       = "Elimina permanentemente todos los encuentros registrados \xe2\x80\x94 esta acci\xC3\xB3n no se puede deshacer"
L["DEBUG_BTN_RUN"]           = "Ejecutar"
L["DEBUG_BTN_TOGGLE"]        = "Alternar"

---------------------------------------------------------------------------
-- UI — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Escribe  Confirmar  para habilitar la eliminaci\xC3\xB3n:"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Borrar Tabla de Jefes"
L["DESTRUCT_CLEAR_BB_BODY"]  = "Esto eliminar\xC3\xA1 permanentemente todos los registros de la Tabla de Jefes para este personaje.\nEsta acci\xC3\xB3n no se puede deshacer."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Eliminar Tabla de Jefes"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Borrar Historial de Combates"
L["DESTRUCT_CLEAR_HIST_BODY"] = "Esto eliminar\xC3\xA1 permanentemente todos los encuentros de combate registrados para este personaje.\nEsta acci\xC3\xB3n no se puede deshacer."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Eliminar Historial de Combates"
L["BTN_CANCEL"]              = "Cancelar"

---------------------------------------------------------------------------
-- UI — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "Acerca de"
L["CREDITS_TAB_SOURCES"]     = "Fuentes"
L["CREDITS_TAB_CHANGELOG"]   = "Registro de Cambios"
L["CREDITS_SOURCES_INTRO"]   = "La orientaci\xC3\xB3n rotacional se basa en los siguientes recursos de la comunidad."
L["CREDITS_SOURCES_ACK"]     = "Agradecemos sus contribuciones."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei no est\xC3\xA1 afiliado a estos recursos."
L["CREDITS_NO_CHANGELOG"]    = "No hay registro de cambios disponible."
L["CREDITS_ABOUT_TEXT"]      = "Un addon de coaching de rendimiento en combate para World of Warcraft: Midnight.\nCalifica tus combates de A+ a F en las 13 clases y 40 especializaciones,\ncon retroalimentaci\xC3\xB3n pr\xC3\xA1ctica adaptada a tu rol y especializaci\xC3\xB3n."
L["CREDITS_AUTHOR"]          = "Autor:  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Caracter\xC3\xADsticas:"
L["CREDITS_FEAT_GRADING"]    = "  - Calificaci\xC3\xB3n por combate: uso de recargas, actividad, gesti\xC3\xB3n de recursos"
L["CREDITS_FEAT_TALENT"]     = "  - Consciente de talentos: solo punta habilidades que tienes activas"
L["CREDITS_FEAT_BOSS"]       = "  - Detecci\xC3\xB3n de jefes: rastrea ENCOUNTER_START/END para combates reales con jefes"
L["CREDITS_FEAT_SOCIAL"]     = "  - Clasificaci\xC3\xB3n social: rankings de gremio, grupo y amigos de BNet"
L["CREDITS_FEAT_WEEKLY"]     = "  - Reinicio semanal: alineado con el reinicio de Blizzard los martes a las 7am PDT"
L["CREDITS_FEAT_DELVE"]      = "  - Seguimiento de Delves: puntuaci\xC3\xB3n basada en nivel para contenido en solitario"
L["CREDITS_FEAT_SYNC"]       = "  - Sincronizaci\xC3\xB3n de puntuaciones: sincroniza entre miembros del gremio para recuperar puntuaciones tras reinstalar"
L["CREDITS_CONTACT"]         = "Contacto:  MidnightTim en GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei es un addon de la comunidad, no afiliado a Blizzard."

---------------------------------------------------------------------------
-- UI — FAQ
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "PRIMEROS PASOS"
L["FAQ_HDR_UNDERSTANDING"]   = "ENTENDIENDO TU CALIFICACI\xC3\x93N"
L["FAQ_HDR_ROTATIONAL"]      = "RETROALIMENTACI\xC3\x93N DE HECHIZOS ROTACIONALES"
L["FAQ_HDR_VISIBILITY"]      = "OPCIONES DE VISIBILIDAD"
L["FAQ_HDR_HISTORY"]         = "HISTORIAL DE CALIFICACIONES"
L["FAQ_HDR_LEADERBOARD"]     = "CLASIFICACI\xC3\x93N"
L["FAQ_HDR_MIDNIGHT_NOTE"]   = "NOTA SOBRE RESTRICCIONES DE MIDNIGHT 12.0"
L["FAQ_HDR_BOSS_COMBAT"]     = "JEFE VS COMBATE NORMAL"
L["FAQ_HDR_TALENT_AWARE"]    = "RECARGAS CONSCIENTES DE TALENTOS"
L["FAQ_HDR_ALL_COMMANDS"]    = "TODOS LOS COMANDOS"
L["FAQ_MIN_FIGHT"]           = "Un combate de menos de 15 segundos no se registra."
L["FAQ_VIS_ALWAYS"]          = "  Siempre: HUD siempre visible"
L["FAQ_VIS_COMBAT"]          = "  En Combate: el HUD solo se muestra durante el combate"
L["FAQ_VIS_HIDE"]            = "  Ocultar: HUD oculto (accesible con /ms show)"
L["FAQ_CMD_SHOW"]            = "  /ms show         Mostrar el HUD"
L["FAQ_CMD_HIDE"]            = "  /ms hide         Ocultar el HUD"
L["FAQ_CMD_HISTORY"]         = "  /ms history      Historial de calificaciones y tendencias"
L["FAQ_CMD_LB"]              = "  /ms lb           Clasificaci\xC3\xB3n social"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Eliminar un jugador de la clasificaci\xC3\xB3n del gremio"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Configuraci\xC3\xB3n"
L["FAQ_CMD_FAQ"]             = "  /ms faq          Este panel"
L["FAQ_CMD_UPDATE"]          = "  /ms update       Ver registro de cambios"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Cr\xC3\xA9ditos e informaci\xC3\xB3n"
L["FAQ_CMD_REPORT"]          = "  /ms report       Reportar un error en GitHub"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Mostrar versiones del addon vistas en esta sesi\xC3\xB3n"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Consultar la \xC3\xBAltima puntuaci\xC3\xB3n de un jugador directamente"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Abrir el Seguidor de Rotaci\xC3\xB3n (conteo de lanzamientos + explicaciones de hechizos)"

---------------------------------------------------------------------------
-- UI — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Escribe |cffFFFFFF/ms show|r para abrir el HUD, |cffFFFFFF/ms hide|r para cerrarlo.\nEl HUD muestra tu \xC3\xBAltima calificaci\xC3\xB3n, puntuaci\xC3\xB3n y especializaci\xC3\xB3n. Despu\xC3\xA9s de un combate\nver\xC3\xA1s un bot\xC3\xB3n |cffFFFFFF>> Revisar Combate|r. Haz clic derecho en el HUD para acceder\nr\xC3\xA1pidamente a todas las funciones."
L["FAQ_BODY_UNDERSTANDING"]   = "Las calificaciones van de F a A+. Cada especializaci\xC3\xB3n tiene categor\xC3\xADas ponderadas:\n  - Uso de Recargas: \xC2\xBFpresionaste tus recargas principales en recarga?\n  - Hechizos Rotacionales: \xC2\xBFusaste habilidades clave cada combate?\n  - Actividad: \xC2\xBFlanzaste de forma consistente? (sin largos periodos inactivos)\n  - Gesti\xC3\xB3n de Recursos: \xC2\xBFsuperaste el l\xC3\xADmite de tu recurso (Ira/Energ\xC3\xADa/etc.)?\n  - Uptime de Buff: \xC2\xBFmantuviste activos tus buffs propios? (var\xC3\xADa por especializaci\xC3\xB3n)\n  - Uso de Procs: \xC2\xBFconsumiste procs r\xC3\xA1pido? (DK Escarcha, Mago Fuego...)\n  - Eficiencia de Sanador: \xC2\xBFcu\xC3\xA1nta de tu curaci\xC3\xB3n fue sobreuraci\xC3\xB3n?"
L["FAQ_BODY_ROTATIONAL"]      = "Adem\xC3\xA1s de las recargas, Midnight Sensei rastrea si usaste\nhechizos rotacionales clave en cada combate (p. ej., Implosin, Arranque, Golpe Oblicuo).\nSi nunca usaste uno en un combate suficientemente largo, aparecer\xC3\xA1 en tu\nretroalimentaci\xC3\xB3n. Los hechizos de talento se omiten si no tienes el talento."
L["FAQ_BODY_VIS_INTRO"]       = "Abre |cffFFFFFF/ms options|r (o clic derecho en HUD -> Opciones) y configura:"
L["FAQ_BODY_HISTORY"]         = "Escribe |cffFFFFFF/ms history|r o clic derecho -> Historial de Calificaciones.\n  - Filtra por Este Personaje o Todos los Personajes\n  - El gr\xC3\xA1fico muestra tus \xC3\xBAltimos 20 combates de un vistazo\n  - Clic izquierdo en cualquier fila para ver detalles completos y retroalimentaci\xC3\xB3n\n  - Clic derecho en cualquier fila para eliminar esa entrada"
L["FAQ_BODY_LEADERBOARD"]     = "Escribe |cffFFFFFF/ms lb|r para abrir la clasificaci\xC3\xB3n social.\nDespus de cada combate con jefe, tu puntuaci\xC3\xB3n se transmite al gremio, grupo y\namigos de BNet que tambi\xC3\xA9n tienen Midnight Sensei instalado.\nPesta\xC3\xB1as: Grupo (solo sesi\xC3\xB3n), Gremio (persiste entre sesiones), Amigos.\nLas puntuaciones del gremio persisten entre sesiones y se sincronizan \xe2\x80\x94\nincluso si un jugador est\xC3\xA1 desconectado puedes ver su \xC3\xBAltima puntuaci\xC3\xB3n registrada.\nEl promedio semanal cuenta solo encuentros con jefes \xe2\x80\x94 las peleas de basura y\nmaniquis de entrenamiento nunca se incluyen en los rankings.\nHaz clic derecho en cualquier fila del gremio para eliminar un jugador. Se volver\xC3\xA1n a\nagregar autom\xC3\xA1ticamente cuando inicien sesi\xC3\xB3n o presiones Actualizar."
L["FAQ_BODY_LB_EXTRA"]        = "Cada pesta\xC3\xB1a (Mazmorras, Incursiones) muestra informaci\xC3\xB3n de ubicaci\xC3\xB3n de ese tipo de contenido\nsolamente \xe2\x80\x94 una ejecuci\xC3\xB3n de LFR nunca aparecer\xC3\xA1 en la pesta\xC3\xB1a de Mazmorras.\nEl nivel de llave M\xC3\xADtica+ se muestra cuando est\xC3\xA1 disponible (p. ej., M+15).\nDespu\xC3\xA9s de actualizar el addon, cada jugador necesita completar una nueva\nmazmorra o incursi\xC3\xB3n para que la ubicaci\xC3\xB3n refleje el contenido correcto.\nTu propia entrada se actualiza inmediatamente desde el historial local."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard restringi\xC3\xB3 la lectura de auras de unidades enemigas en Midnight 12.0.\nLos debuffs del objetivo (Ruptura, Choque de Llamas, etc.) no pueden rastrearse directamente.\nEstos aparecen en tus priorityNotes como gu\xC3\xADa pero no se puntuan.\nTodos los buffs propios, recargas y lanzamientos rotacionales funcionan normalmente."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei detecta encuentros con jefes mediante ENCOUNTER_START/END.\nLos combates con jefes muestran una etiqueta |cffFF6600[Jefe]|r en el historial y detalle del encuentro.\nFiltra tu historial a |cffFFFFFF[Solo Jefes]|r para revisar los intentos en jefes de mazmorra/incursi\xC3\xB3n."
L["FAQ_BODY_TALENT_AWARE"]    = "La puntuaci\xC3\xB3n de recargas solo incluye hechizos que hayas aprendido.\nSi no tienes un talento, no se contar\xC3\xA1 en tu contra."

---------------------------------------------------------------------------
-- UI — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Conteo de lanzamientos de tu \xC3\xBAltimo combate. Cada hechizo muestra cu\xC3\xA1ntas veces se us\xC3\xB3 y por qu\xC3\xA9 se rastrea."
L["ROT_TRACKER_NO_DATA"]     = "Sin datos de combate a\xC3\xBAn \xe2\x80\x94 participa en un combate para ver los resultados."
L["ROT_TRACKER_LAST_FIGHT"]  = "\xC3\x9Altimo combate: %s"
L["ROT_TRACKER_NO_FIGHT"]    = "A\xC3\xBAn no hay combate registrado"
L["ROT_COL_SPELL"]           = "HECHIZO"
L["ROT_COL_CASTS"]           = "LANZAMIENTOS"
L["ROT_COL_MIN_FIGHT"]       = "MIN COMBATE"
L["ROT_COL_STATUS"]          = "ESTADO"
L["ROT_STATUS_CAST"]         = "LANZADO"
L["ROT_STATUS_MISSED"]       = "FALLADO"
L["ROT_STATUS_SHORT"]        = "CORTO"
L["ROT_FLAG_COMBAT_TALENT"]  = "Requiere talento; solo lanzable durante una ventana de transformaci\xC3\xB3n"
L["ROT_FLAG_COMBAT_ONLY"]    = "Solo lanzable durante una ventana de transformaci\xC3\xB3n (p. ej., Metamorfosis del Vac\xC3\xADo)"
L["ROT_FLAG_TALENT_ONLY"]    = "Solo se rastrea cuando este talento est\xC3\xA1 activo en tu build"
L["ROT_FLAG_CORE"]           = "Habilidad rotacional b\xC3\xA1sica \xe2\x80\x94 esperada en cada combate"
L["ROT_FLAG_MIN_FIGHT"]      = "marcado como fallado solo si el combate dura > %ds"
L["ROT_NOT_TRACKED"]         = "No rastreado en este build (talento no tomado o reemplazado): %s"
L["ROT_LEGEND_CAST_DESC"]    = "usado al menos una vez"
L["ROT_LEGEND_MISSED_DESC"]  = "el combate fue suficientemente largo pero el hechizo no se us\xC3\xB3"
L["ROT_LEGEND_SHORT_DESC"]   = "combate demasiado corto para evaluar"
L["ROT_LEGEND"]              = "LANZADO  usado al menos una vez  FALLADO  el combate fue suficientemente largo pero el hechizo no se us\xC3\xB3  CORTO  combate demasiado corto para evaluar"

---------------------------------------------------------------------------
-- UI — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "Hay una nueva versi\xC3\xB3n de Midnight Sensei disponible.\nConsulta Curseforge o Wago para la \xC3\xBAltima versi\xC3\xB3n."
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Creado por Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Abrir Opciones"
L["SETTINGS_BTN_OPT_DESC"]   = "Configurar HUD, estilo de juego y m\xC3\xA1s"
L["SETTINGS_BTN_HISTORY"]    = "Historial de Calificaciones"
L["SETTINGS_BTN_HIST_DESC"]  = "Ver historial de combates y tendencias"
L["SETTINGS_BTN_LB"]         = "Clasificaci\xC3\xB3n"
L["SETTINGS_BTN_LB_DESC"]    = "Rankings de Gremio / Grupo / Amigos / Delve"
L["SETTINGS_BTN_FAQ"]        = "Ayuda y Preguntas Frecuentes"
L["SETTINGS_BTN_FAQ_DESC"]   = "C\xC3\xB3mo funciona la puntuaci\xC3\xB3n y calificaci\xC3\xB3n"
L["SETTINGS_BTN_CREDITS"]    = "Cr\xC3\xA9ditos e Informaci\xC3\xB3n"
L["SETTINGS_BTN_CRED_DESC"]  = "Informaci\xC3\xB3n del autor y fuentes"
L["SETTINGS_LEGACY_SUB"]     = "Creado por Midnight - Thrall (US)  |  /ms para comandos"
L["MINIMAP_TT_LEFT"]         = "Clic izquierdo: Mostrar/Ocultar HUD"
L["MINIMAP_TT_RIGHT"]        = "Clic derecho: Clasificaci\xC3\xB3n"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Ctrl+Clic derecho: Tabla de Jefes"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "May\xC3\xBAs+Clic derecho: Opciones"

---------------------------------------------------------------------------
-- Analytics/Feedback
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "Perdiste valor por recargas sin usar%s: %s. Incluso presionarlas constantemente ayuda."
L["FB_NEVER_PRESSED"]        = "Nunca presionaste%s: %s \xe2\x80\x94 %s."
L["FB_ACTION_TANK"]          = "\xC3\xBAsalas en tank-busters o ventanas de alto da\xC3\xB1o"
L["FB_ACTION_HEALER"]        = "aline\xC3\xA1alas con ventanas de alto da\xC3\xB1o entrante"
L["FB_ACTION_DPS"]           = "aline\xC3\xA1alas con ventanas de burst"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Tu rotaci\xC3\xB3n es consistente, pero los espacios entre lanzamientos (%d%% de actividad) son lo siguiente que debes ajustar."
L["FB_ACTIVITY_MODERATE"]    = "Actividad al %d%% \xe2\x80\x94 aproximadamente %d lanzamiento(s) desperdiciados. Prepara tu siguiente hechizo antes de que el actual aterrice."
L["FB_ACTIVITY_LOW"]         = "Actividad: %d/%d GCDs (%d%%) \xe2\x80\x94 tiempo de inactividad %s, aproximadamente %d lanzamientos perdidos. Encuentra tu siguiente hechizo antes de que el actual termine."
L["FB_DOWNTIME_SIGNIFICANT"] = "significativo"
L["FB_DOWNTIME_MODERATE"]    = "moderado"
L["FB_UNDERUSED"]            = "Usado menos de lo esperado en un combate de %.1f min: %s \xe2\x80\x94 objetivo 1 uso por cada 2 minutos de combate."
L["FB_ROT_NEVER_USED"]       = "Hechizo(s) rotacional(es) nunca usados: %s \xe2\x80\x94 son fundamentales para tu %s."
L["FB_ROT_CONTEXT_TANK"]     = "rotaci\xC3\xB3n de supervivencia y amenaza"
L["FB_ROT_CONTEXT_HEALER"]   = "rendimiento de curaci\xC3\xB3n"
L["FB_ROT_CONTEXT_DPS"]      = "producci\xC3\xB3n de da\xC3\xB1o"
L["FB_ROT_LOW_USED"]         = "Podr\xC3\xADas haber lanzado m\xC3\xA1s: %s \xe2\x80\x94 pres\xC3\xADonalo en cada GCD disponible cuando tus gastadores principales est\xC3\xA1n en recarga."
L["FB_PROC_DELAYED"]         = "retrasado"
L["FB_PROC_CRITICALLY"]      = "cr\xC3\xADticamente retrasado"
L["FB_PROC_MSG"]             = "El consumo de %s est\xC3\xA1 %s \xe2\x80\x94 retenido %.1f s en promedio (presupuesto: %d s). Consume los procs inmediatamente cuando aparezcan."
L["FB_OVERCAP"]              = "Supercargaste %s %d vez/veces (%.1f/min) \xe2\x80\x94 gasta %s antes de alcanzar %d para evitar generaci\xC3\xB3n desperdiciada."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s nunca fue activado \xe2\x80\x94 pres\xC3\xADonalo en cada recarga disponible para reducir el da\xC3\xB1o f\xC3\xADsico recibido."
L["FB_MIT_LOW_UPTIME"]       = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt, %d aplicaci\xC3\xB3n(es)) \xe2\x80\x94 tienes grandes ventanas de da\xC3\xB1o f\xC3\xADsico sin mitigar. Pres\xC3\xADonalo en el momento en que salga de recarga."
L["FB_MIT_SMALL_GAPS"]       = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt) \xe2\x80\x94 los peque\xC3\xB1os espacios se acumulan. \xC3\x9Asalo preventivamente en secuencias de cuerpo a cuerpo intensas, no reactivamente."
L["FB_BUFF_LOW_UPTIME"]      = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt) \xe2\x80\x94 reaplicar antes de que expire, no despu\xC3\xA9s."
L["FB_GROUP_BUFF_NOTE"]      = "%s (potenciador de grupo \xe2\x80\x94 as\xC3\xADate de que est\xC3\xA9 activo antes del combate)"
L["FB_OVERHEAL_HIGH"]        = "Curaci\xC3\xB3n excesiva al %.1f%% (objetivo: <%d%%) \xe2\x80\x94 est\xC3\xA1s gastando man\xC3\xA1 en objetivos que no necesitan curaci\xC3\xB3n. Lanza un poco despu\xC3\xA9s o cambia a hechizos reactivos en objetivos que reciben da\xC3\xB1o activamente."
L["FB_OVERHEAL_ELEVATED"]    = "Curaci\xC3\xB3n excesiva: %.1f%% (objetivo: <%d%%) \xe2\x80\x94 ligeramente elevada. Ret\xC3\xA9n lanzamientos en objetivos con m\xC3\xA1s del 70%% de salud y prioriza los HoTs sobre las curaciones directas en grupos estables."
L["FB_HEALER_FILL_DOWNTIME"] = "Cuando el grupo est\xC3\xA9 estable, llena el tiempo de inactividad con hechizos de da\xC3\xB1o para mantener el rendimiento."
L["FB_SIMPLIFIED_FALLBACK"]  = "Tu rotaci\xC3\xB3n es consistente y bien coordinada. Ajustar el timing de las ventanas de burst es el siguiente paso de rendimiento."
L["FB_NEAR_PERFECT"]         = "Ejecuci\xC3\xB3n casi perfecta. Las ganancias restantes son: %s."
L["FB_NEXT_TANK_PREPOS"]     = "pre-posicionar defensivas antes de da\xC3\xB1o pico predecible"
L["FB_NEXT_HEALER_OVERLAP"]  = "superponer recargas con los lanzamientos de da\xC3\xB1o entrante en lugar de reaccionar"
L["FB_NEXT_DPS_ALIGN"]       = "alinear ventanas de burst con las fases de vulnerabilidad del enemigo"
L["FB_NEXT_GCD_TIMING"]      = "reducir el tiempo entre el fin del GCD y tu siguiente lanzamiento a menos de 0.2s"
L["FB_STRONG_EXECUTION"]     = "Ejecuci\xC3\xB3n s\xC3\xB3lida en general. Tu categor\xC3\xADa m\xC3\xA1s baja es %s \xe2\x80\x94 ah\xC3\xAD es donde vienen los pr\xC3\xB3ximos puntos."
L["FB_GOOD_FOUNDATION"]      = "Buena base \xe2\x80\x94 c\xC3\xA9ntrate a continuaci\xC3\xB3n en: %s."
L["FB_HINT_TANK_CDS"]        = "usar recargas defensivas en tank-busters"
L["FB_HINT_PRESS_CDS"]       = "presionar las recargas principales de manera m\xC3\xA1s consistente"
L["FB_HINT_MIT_UPTIME"]      = "aumentar el tiempo activo de mitigaci\xC3\xB3n presionando %s con m\xC3\xA1s frecuencia"
L["FB_SOLID"]                = "Rendimiento s\xC3\xB3lido \xe2\x80\x94 ajusta el timing de las recargas para subir m\xC3\xA1s."
L["FB_NOTE_INTERRUPT"]       = "Nota: %s \xe2\x80\x94 esta es tu interrupci\xC3\xB3n. No usada en este combate \xe2\x80\x94 sin penalizaci\xC3\xB3n."
L["FB_NOTE_UTILITY"]         = "Nota: %s \xe2\x80\x94 no usada o detectada en este combate. Sin penalizaci\xC3\xB3n."
L["FB_NOTE_COMBAT_UTILITY"]  = "Nota: %s \xe2\x80\x94 aturde y causa da\xC3\xB1o adem\xC3\xA1s de utilidad. \xC3\x9Asalo cuando la situaci\xC3\xB3n lo permita; sin penalizaci\xC3\xB3n por guardarlo."
