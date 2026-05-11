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
L["GRADE_STRONG"]            = "Sólido"
L["GRADE_ON_TRACK"]          = "En camino"
L["GRADE_SOLID"]             = "Consistente"
L["GRADE_GOOD_FOUNDATION"]   = "Buena base"
L["GRADE_ROOM_TO_GROW"]      = "Hay margen de mejora"
L["GRADE_KEEP_PRACTICING"]   = "Sigue practicando"
L["GRADE_BUILDING_HABITS"]   = "Desarrollando hábitos"
L["GRADE_LEARNING_CURVE"]    = "Curva de aprendizaje"
L["GRADE_EARLY_DAYS"]        = "Primeros pasos"
L["GRADE_FRESH_START"]       = "Nuevo comienzo"

---------------------------------------------------------------------------
-- Addon load / level gate
---------------------------------------------------------------------------
L["ADDON_LOADED"]            = "cargado.  /ms show para abrir el HUD  ·  /ms help para los comandos."
L["LEVEL_GATE_WARNING"]      = "Este addon está diseñado para contenido de nivel 80+. El seguimiento de combate y las calificaciones están desactivados hasta alcanzar el nivel 80."
L["WEEKLY_RESET_DETECTED"]   = "Reinicio Semanal Detectado."

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]       = "Comandos de Midnight Sensei:"
L["SLASH_HELP_SHOW"]         = "  /ms show          Mostrar el HUD"
L["SLASH_HELP_HIDE"]         = "  /ms hide          Ocultar el HUD"
L["SLASH_HELP_HISTORY"]      = "  /ms history       Historial de calificaciones y tendencias"
L["SLASH_HELP_LB"]           = "  /ms lb            Clasificación social"
L["SLASH_HELP_BOSSBOARD"]    = "  /ms bossboard     Clasificación personal de jefes  (alias: /ms bb)"
L["SLASH_HELP_OPTIONS"]      = "  /ms options       Panel de configuración"
L["SLASH_HELP_FAQ"]          = "  /ms faq           Ayuda y preguntas frecuentes"
L["SLASH_HELP_CREDITS"]      = "  /ms credits       Créditos e información"
L["SLASH_HELP_REPORT"]       = "  /ms report        Reportar un error en GitHub"
L["SLASH_HELP_UPDATE"]       = "  /ms update        Mostrar registro de cambios"
L["SLASH_HELP_VERSIONS"]     = "  /ms versions      Mostrar versiones del addon vistas en esta sesión"
L["SLASH_HELP_FRIEND"]       = "  /ms friend <n>    Consultar la última puntuación de un jugador directamente"

---------------------------------------------------------------------------
-- Chat status messages
---------------------------------------------------------------------------
L["GUILD_DB_EMPTY"]          = "La base de datos del gremio está vacía."
L["GUILD_DB_KEYS_HEADER"]    = "Midnight Sensei — Claves de la base de datos del gremio:"
L["FRIEND_USAGE"]            = "Uso: /ms friend Nombre  o  /ms friend add Nombre  o  /ms friend remove Nombre"
L["LB_REMOVE_USAGE"]         = "Uso: /ms lb remove <NombreJugador>"
L["VERSIONS_HEADER"]         = "Midnight Sensei — Versiones vistas en esta sesión:"
L["VERSIONS_NO_DATA"]        = "Aún no hay datos de versión — se recopilan automáticamente cuando los jugadores inician sesión o se unen a tu grupo."
L["VERSIONS_YOU"]            = "(tú)"
L["VERSIONS_OUTDATED"]       = "(desactualizado)"
L["SILENT_MODE_ON"]          = "Midnight Sensei: Modo silencioso ACTIVADO — todos los mensajes salientes del addon están suprimidos."
L["SILENT_MODE_OFF"]         = "Midnight Sensei: Modo silencioso DESACTIVADO — operación normal reanudada."

---------------------------------------------------------------------------
-- Verify mode
---------------------------------------------------------------------------
L["VERIFY_MODE_ON"]          = "Midnight Sensei Modo Verificación: ACTIVADO"
L["VERIFY_MODE_OFF"]         = "Midnight Sensei Modo Verificación: DESACTIVADO"
L["VERIFY_CAST_HINT"]        = "Lanza tus hechizos con normalidad. Tras el combate escribe /ms verify report."
L["VERIFY_NO_SPEC"]          = "Midnight Sensei: No se ha cargado ninguna especialización."

---------------------------------------------------------------------------
-- Snapshots
---------------------------------------------------------------------------
L["TALENT_SNAP_NOT_READY"]   = "Midnight Sensei: Aún no hay instantánea de talentos — se genera automáticamente al iniciar sesión y al cambiar de especialización. Si es tu primera sesión, escribe /reload e inténtalo de nuevo."
L["SPELL_SNAP_NOT_READY"]    = "Midnight Sensei: Aún no hay instantánea de hechizos — se genera automáticamente al iniciar sesión. Si es tu primera sesión, escribe /reload e inténtalo de nuevo."

---------------------------------------------------------------------------
-- BossBoard — window & columns
---------------------------------------------------------------------------
L["BB_TITLE"]                = "Midnight Sensei - Tabla de Jefes"
L["BB_DESCRIPTION"]          = "Tu puntuación más alta por jefe en Midnight — haz clic en cualquier fila para revisar tu mejor retroalimentación"
L["BB_TAB_DUNGEONS"]         = "Mazmorras"
L["BB_TAB_RAIDS"]            = "Bandas"
L["BB_TAB_DELVES"]           = "Delves"
L["BB_COL_DATE"]             = "FECHA"
L["BB_COL_CHARACTER"]        = "PERSONAJE"
L["BB_COL_SPEC"]             = "ESPEC"
L["BB_COL_DIFF_BOSS"]        = "DIF / JEFE"
L["BB_COL_SCORE"]            = "PUNTUACIÓN"
L["BB_NO_ENCOUNTERS"]        = "Aún no se han registrado encuentros con jefes para este tipo de contenido."
L["BB_FOOTER_INFO"]          = "Solo kills de jefes  -  nivel 80+  -  /ms bossboard"
L["BB_ENTRY_COUNT"]          = "%d jefe%s registrado"
L["BB_TT_BEST"]              = "Mejor: %s  %d"
L["BB_TT_DATE"]              = "Fecha: %s"
L["BB_TT_KILLS"]             = "Kills rastreados: %d"
L["BB_TT_CLICK_FEEDBACK"]    = "Haz clic para ver retroalimentación"

---------------------------------------------------------------------------
-- BossBoard — status / print messages
---------------------------------------------------------------------------
L["BB_INGEST_COMPLETE"]      = "Tabla de Jefes: Incorporación completa — añadidos: %d  actualizados: %d  omitidos: %d"
L["BB_SPEC_NOT_DETECTED"]    = "Tabla de Jefes: No se pudo detectar la especialización activa — los campos pueden estar incompletos. Inténtalo de nuevo tras cargar completamente."
L["BB_REPAIR_COMPLETE"]      = "Tabla de Jefes: Reparación de identidad completa — corregidas: %d entr%s"
L["BB_NO_BOSSDATA"]          = "No se encontraron datos de mejores jefes."
L["BB_SPEC_UNRESOLVED"]      = "Tabla de Jefes: Especialización no detectada aún — inténtalo de nuevo tras cargar completamente."
L["BB_RENAME_COMPLETE"]      = "Corrección de nombre de personaje completa (%s → %s)"
L["BB_RENAME_ENC_UPDATED"]   = "  Historial de calificaciones / revisión de combates: %d encuentro%s actualizado"
L["BB_RENAME_BB_UPDATED"]    = "  Tabla de Jefes: %d entr%s actualizada; instantánea compartida re-indexada"
L["BB_CANNOT_READ_NAME"]     = "No se pudo leer el nombre del jugador — inténtalo de nuevo tras cargar completamente."
L["BB_NO_CHARDB"]            = "No se encontró CharDB."
L["BB_NO_SNAPDATA"]          = "No se encontró instantánea compartida."
L["BB_CLEANUP_DRY_HDR"]      = "Limpieza: %d encuentro(s) serían marcados como fracasos. Ejecuta /ms debug cleanup history confirm para aplicar."
L["BB_CLEANUP_APPLIED"]      = "Limpieza de historial — %d fracaso(s) legado(s) corregido(s); Tabla de Jefes actualizada donde había datos de historial."
L["BB_RESTORE_COMPLETE"]     = "Restauración de instantánea completa — recuperados: %d  ya actuales: %d"
L["BB_RESTORE_NOTE"]         = "Las entradas restauradas tienen puntuación/calificación/fecha pero no retroalimentación de combate ni puntuaciones por componente."
L["BB_BOSS_BOARD_CLEARED"]   = "Midnight Sensei: Tabla de Jefes borrada."
L["BB_FIGHT_HIST_CLEARED"]   = "Midnight Sensei: Historial de combates borrado."

---------------------------------------------------------------------------
-- BossBoard — Fix Name dialog
---------------------------------------------------------------------------
L["FIX_NAME_TITLE"]          = "Corregir Nombre de Personaje"
L["FIX_NAME_OLD_LABEL"]      = "Nombre antiguo del personaje (encontrado en tu historial):"
L["FIX_NAME_NEW_LABEL"]      = "Será reemplazado por (tu nombre de personaje actual):"
L["FIX_NAME_ERR_EMPTY"]      = "Por favor, introduce el nombre antiguo del personaje."
L["FIX_NAME_ERR_SAME"]       = "Ese nombre coincide con tu personaje actual — no hay nada que corregir."
L["FIX_NAME_ERR_NOT_FOUND"]  = "No se encontró historial bajo \"%s\". Comprueba la ortografía, las mayúsculas y cualquier carácter especial."
L["FIX_NAME_BTN_CONFIRM"]    = "Confirmar Corrección"

---------------------------------------------------------------------------
-- Leaderboard — friend management
---------------------------------------------------------------------------
L["FRIEND_QUERY_USAGE"]      = "Uso: /ms friend Nombre  o  /ms friend Nombre-Reino"
L["FRIEND_CHECKING"]         = "Verificando %s..."
L["FRIEND_OFFLINE"]          = "%s (Sin conexión) — No actualizado o addon no instalado"
L["FRIEND_CANNOT_REACH"]     = "No se pudo contactar con %s — comprueba el nombre/reino. Error: %s"
L["FRIEND_LIST_FULL"]        = "La lista de amigos está llena (%d máx.). Elimina a alguien primero con clic derecho o /ms friend remove Nombre."
L["FRIEND_ALREADY_IN"]       = "%s ya está en tu lista de amigos."
L["FRIEND_ADDED"]            = "%s añadido a tu lista de amigos (%d/%d)."
L["FRIEND_REMOVED"]          = "%s eliminado de tu lista de amigos (%d/%d)."
L["FRIEND_NOT_FOUND"]        = "%s no encontrado en la lista de amigos."
L["FRIEND_ONLINE_UPDATED"]   = "%s (En línea) — Actualizado"

---------------------------------------------------------------------------
-- UI — window titles
---------------------------------------------------------------------------
L["TITLE_ENCOUNTER_DETAIL"]  = "Midnight Sensei - Detalle del Encuentro"
L["TITLE_GRADE_HISTORY"]     = "Midnight Sensei - Historial de Calificaciones"
L["TITLE_FIGHT_COMPLETE"]    = "Midnight Sensei - Combate Completado"
L["TITLE_OPTIONS"]           = "Midnight Sensei - Opciones"
L["TITLE_VERIFY_REPORT"]     = "Midnight Sensei — Informe de Verificación"
L["TITLE_VERIFY_COMPARE"]    = "Midnight Sensei — Comparación de Verificación"
L["TITLE_SPELL_LIST"]        = "Midnight Sensei - Mis Hechizos"
L["TITLE_DEBUG_TOOLS"]       = "Midnight Sensei - Herramientas de Depuración"
L["TITLE_CREDITS"]           = "Midnight Sensei - Créditos e Información"
L["TITLE_FAQ"]               = "Midnight Sensei - Ayuda y Preguntas Frecuentes"
L["TITLE_ROT_TRACKER"]       = "Midnight Sensei - Seguidor de Rotación"
L["TITLE_UPDATE_POPUP"]      = "Midnight Sensei — Actualización Disponible"

---------------------------------------------------------------------------
-- UI — context menus
---------------------------------------------------------------------------
L["CTX_INSPECT_DETAILS"]     = "Inspeccionar Detalles"
L["CTX_DELETE_ENTRY"]        = "Eliminar Entrada"
L["CTX_CANCEL"]              = "Cancelar"
L["CTX_LOCK_POSITION"]       = "Bloquear Posición"
L["CTX_UNLOCK_POSITION"]     = "Desbloquear Posición"
L["CTX_GRADE_HISTORY"]       = "Historial de Calificaciones"
L["CTX_LEADERBOARD"]         = "Clasificación"
L["CTX_BOSS_BOARD"]          = "Tabla de Jefes"
L["CTX_OPTIONS"]             = "Opciones"
L["CTX_MY_SPELL_LIST"]       = "Mis Hechizos"
L["CTX_HELP_FAQ"]            = "Ayuda / FAQ"
L["CTX_CREDITS"]             = "Créditos"
L["CTX_DEBUG_TOOLS"]         = "Herramientas de Depuración"
L["CTX_CLOSE_HUD"]           = "Cerrar HUD"

---------------------------------------------------------------------------
-- UI — encounter detail panel
---------------------------------------------------------------------------
L["DETAIL_DURATION_GRADE"]   = "Duración: %s    Calificación: %s  (%s)"
L["DETAIL_SCORE"]            = "Puntuación: %d"
L["DETAIL_COMPONENT_SCORES"] = "Puntuaciones por Componente:"
L["DETAIL_FEEDBACK"]         = "Retroalimentación:"
L["DETAIL_ENC_DUNGEON"]      = "Mazmorra"
L["DETAIL_ENC_RAID"]         = "Banda"
L["DETAIL_ENC_WORLD"]        = "Mundo"
L["DETAIL_ENC_COMBAT"]       = "Combate"
L["BTN_CLOSE"]               = "Cerrar"

---------------------------------------------------------------------------
-- UI — grade history panel
---------------------------------------------------------------------------
L["HISTORY_TREND_LABEL"]     = "Tendencia (últimas 20):"
L["HISTORY_FILTER_LABEL"]    = "Filtro:"
L["FILTER_THIS_CHARACTER"]   = "Este Personaje"
L["FILTER_BOSS_ONLY"]        = "Solo [Jefe]"
L["HISTORY_COL_GR"]          = "CAL"
L["HISTORY_COL_CHARACTER"]   = "PERSONAJE"
L["HISTORY_COL_SPEC_DIFF"]   = "ESPEC / DIF"
L["HISTORY_COL_SCORE"]       = "PUNTUACIÓN"
L["HISTORY_COL_WHEN"]        = "CUÁNDO"
L["HISTORY_LB_BTN"]          = "Clasificación ->"
L["HISTORY_STATS"]           = "%d combates  -  Prom: %d  -  Mejor: %s  -  Peor: %s"
L["HISTORY_WIPES_SUFFIX"]    = "%d fracaso%s"
L["HISTORY_NO_MATCHES"]      = "Ningún encuentro coincide con el filtro actual."

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
L["HUD_NO_FIGHT"]            = "Aún no hay combate registrado"
L["HUD_IN_COMBAT"]           = "En combate..."
L["HUD_FIGHT_TOO_SHORT"]     = "Combate demasiado corto para registrar"
L["BTN_REVIEW_FIGHT"]        = "Revisar Combate"
L["BTN_BOSS_BOARD"]          = "Tabla de Jefes"
L["BTN_LEADERBOARD"]         = "Clasificación"
L["VERIFY_BAR_LABEL"]        = "Modo Verificación Activado"
L["BTN_VIEW_REPORT"]         = "Ver Informe"
L["UPDATE_BAR_LABEL"]        = "Nueva Versión Disponible  (haz clic para más detalles)"
L["TT_MENU"]                 = "Menú"
L["TT_HIDE_HUD"]             = "Ocultar HUD"
L["TT_DISMISS"]              = "Descartar"
L["TT_UPDATE_AVAILABLE"]     = "Actualización Disponible"
L["TT_UPDATE_CHECK"]         = "Consulta Curseforge o Wago para la última versión."
L["TT_BOSS_BOARD"]           = "Tabla de Jefes"
L["TT_BOSS_BOARD_DESC"]      = "Mejores puntuaciones personales por jefe"
L["TT_LEADERBOARD"]          = "Clasificación"
L["TT_LEADERBOARD_DESC"]     = "Gremio / Grupo / Amigos / Delves"

---------------------------------------------------------------------------
-- UI — fight complete panel
---------------------------------------------------------------------------
L["FIGHT_CLEAN"]             = "Combate limpio - nada importante que señalar."
L["FIGHT_SCORE_DUR"]         = "Puntuación: %d   Duración: %s"
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
L["OPT_SHOW_POST_FIGHT"]     = "Mostrar botón de revisión post-combate en el HUD"
L["OPT_LOCK_HUD"]            = "Bloquear posición del HUD"
L["OPT_ENCOUNTER_ADJUST"]    = "Ajuste de condición del encuentro"
L["OPT_DEBUG_MODE"]          = "Modo depuración (muestra mensajes de rechazo de clasificación)"
L["OPT_LEADERBOARD"]         = "Clasificación:"
L["OPT_LB_NOTE"]             = "El promedio semanal siempre cuenta solo encuentros con jefes. Los tirones de trash y los muñecos de entrenamiento nunca se incluyen."
L["BTN_REPORT_ISSUES"]       = "Reportar Problemas"

---------------------------------------------------------------------------
-- UI — bug report popup
---------------------------------------------------------------------------
L["REPORT_POPUP_TEXT"]       = "Midnight Sensei — Reportar un Error\n\nCopia el enlace de abajo y pégalo en tu navegador.\nCtrl+A para seleccionar todo, luego Ctrl+C para copiar."
L["REPORT_POPUP_BTN"]        = "Cerrar"

---------------------------------------------------------------------------
-- UI — verify export
---------------------------------------------------------------------------
L["VERIFY_EXPORT_HINT"]      = "Ctrl+A para seleccionar todo  ·  Ctrl+C para copiar  ·  Pega en un comentario de GitHub"
L["BTN_COMPARE"]             = "Comparar"

---------------------------------------------------------------------------
-- UI — spell list
---------------------------------------------------------------------------
L["SPELL_LIST_SUBTITLE"]     = "Los hechizos mostrados aquí son los que Midnight Sensei está monitoreando actualmente."
L["SPELL_LIST_NO_SPEC"]      = "No se detectó especialización. Entra en un combate primero."
L["SPELL_LIST_SEC_CDS"]      = "Hechizos de Recarga"
L["SPELL_LIST_SEC_INT"]      = "Interrupción y Utilidad"
L["SPELL_LIST_SEC_ROT"]      = "Hechizos Rotacionales"
L["SPELL_LIST_SEC_UPTIME"]   = "Potenciadores de Tiempo Activo"
L["SPELL_LIST_SEC_PROCS"]    = "Potenciadores por Proc"
L["SPELL_LIST_SITUATIONAL"]  = "situacional"
L["SPELL_LIST_SPEND_FAST"]   = "gastar rápido"
L["SPELL_LIST_TARGET_UP"]    = "objetivo %d%% de tiempo activo"
L["SPELL_LIST_METAMORPH"]    = "Requiere Metamorfosis"

---------------------------------------------------------------------------
-- UI — debug tools
---------------------------------------------------------------------------
L["DEBUG_SEC_VERIFY"]        = "-- Herramientas de Verificación --"
L["DEBUG_SEC_CLASS"]         = "-- Depuración de Clase --"
L["DEBUG_SEC_RECOVERY"]      = "-- Herramientas de Recuperación --"
L["DEBUG_BTN_VERIFY_MODE"]   = "Modo Verificación"
L["DEBUG_BTN_VERIFY_DESC"]   = "Alternar captura de IDs de hechizos para /ms verify report"
L["DEBUG_BTN_VR"]            = "Informe de Verificación"
L["DEBUG_BTN_VR_DESC"]       = "Exportar informe de verificación de IDs de hechizos a ventana copiable"
L["DEBUG_BTN_AUTO_VERIFY"]   = "Activar Verificación automáticamente al iniciar sesión"
L["DEBUG_BTN_AV_DESC"]       = "El modo verificación se activa automáticamente tras cada recarga o inicio de sesión"
L["DEBUG_BTN_VERSION"]       = "Versión"
L["DEBUG_BTN_VERSION_DESC"]  = "Mostrar versión del addon desde TOC y APIs de metadatos"
L["DEBUG_BTN_ROT_TRACKER"]   = "Seguidor de Rotación"
L["DEBUG_BTN_RT_DESC"]       = "Abrir la ventana del Seguidor de Rotación — conteo de lanzamientos, estado y explicaciones para cada hechizo"
L["DEBUG_BTN_TALENT_EXP"]    = "Exportar Talentos"
L["DEBUG_BTN_TE_DESC"]       = "Exportar instantánea de talentos activos para referencia cruzada con la base de datos"
L["DEBUG_BTN_SPELLS_EXP"]    = "Exportar Hechizos"
L["DEBUG_BTN_SE_DESC"]       = "Exportar instantánea completa del libro de hechizos para referencia cruzada"
L["DEBUG_BTN_BB_INGEST"]     = "Incorporar Tabla de Jefes"
L["DEBUG_BTN_BBI_DESC"]      = "Poblar la Tabla de Jefes desde el historial de encuentros"
L["DEBUG_BTN_FIX_NAME"]      = "Corregir Nombre de Personaje"
L["DEBUG_BTN_FN_DESC"]       = "Ejecuta esto si cambiaste el nombre de tu personaje"
L["DEBUG_BTN_BACKFILL"]      = "Rellenar Llaves M+"
L["DEBUG_BTN_BK_DESC"]       = "Actualizar el historial de mazmorras Míticas con los mejores niveles de llave de la temporada"
L["DEBUG_BTN_CLEAN"]         = "Limpiar Datos"
L["DEBUG_BTN_CP_DESC"]       = "Retransmitir todas tus mejores puntuaciones con el formato correcto"
L["DEBUG_BTN_CLEAR_BB"]      = "Borrar Tabla de Jefes"
L["DEBUG_BTN_CBB_DESC"]      = "Elimina permanentemente todos los registros personales de jefes — esta acción no se puede deshacer"
L["DEBUG_BTN_CLEAR_HIST"]    = "Borrar Historial de Combates"
L["DEBUG_BTN_CH_DESC"]       = "Elimina permanentemente todos los encuentros registrados — esta acción no se puede deshacer"
L["DEBUG_BTN_RUN"]           = "Ejecutar"
L["DEBUG_BTN_TOGGLE"]        = "Alternar"

---------------------------------------------------------------------------
-- UI — destructive confirm dialog
---------------------------------------------------------------------------
L["DESTRUCT_CONFIRM_PROMPT"] = "Escribe  Confirmar  para habilitar la eliminación:"
L["DESTRUCT_CLEAR_BB_TITLE"] = "Borrar Tabla de Jefes"
L["DESTRUCT_CLEAR_BB_BODY"]  = "Esto eliminará permanentemente todos los registros de la Tabla de Jefes para este personaje.\nEsta acción no se puede deshacer."
L["DESTRUCT_CLEAR_BB_BTN"]   = "Eliminar Tabla de Jefes"
L["DESTRUCT_CLEAR_HIST_TITLE"]= "Borrar Historial de Combates"
L["DESTRUCT_CLEAR_HIST_BODY"] = "Esto eliminará permanentemente todos los encuentros de combate registrados para este personaje.\nEsta acción no se puede deshacer."
L["DESTRUCT_CLEAR_HIST_BTN"] = "Eliminar Historial de Combates"
L["BTN_CANCEL"]              = "Cancelar"

---------------------------------------------------------------------------
-- UI — credits
---------------------------------------------------------------------------
L["CREDITS_TAB_ABOUT"]       = "Acerca de"
L["CREDITS_TAB_SOURCES"]     = "Fuentes"
L["CREDITS_TAB_CHANGELOG"]   = "Registro de Cambios"
L["CREDITS_SOURCES_INTRO"]   = "La orientación rotacional se basa en los siguientes recursos de la comunidad."
L["CREDITS_SOURCES_ACK"]     = "Agradecemos sus contribuciones."
L["CREDITS_NOT_AFFILIATED"]  = "Midnight Sensei no está afiliado a estos recursos."
L["CREDITS_NO_CHANGELOG"]    = "No hay registro de cambios disponible."
L["CREDITS_ABOUT_TEXT"]      = "Un addon de coaching de rendimiento en combate para World of Warcraft: Midnight.\nCalifica tus combates de A+ a F en las 13 clases y 40 especializaciones,\ncon retroalimentación práctica adaptada a tu rol y especialización."
L["CREDITS_AUTHOR"]          = "Autor:  Midnight - Thrall (US)"
L["CREDITS_FEATURES"]        = "Características:"
L["CREDITS_FEAT_GRADING"]    = "  - Calificación por combate: uso de recargas, actividad, gestión de recursos"
L["CREDITS_FEAT_TALENT"]     = "  - Consciente de talentos: solo punta habilidades que tienes activas"
L["CREDITS_FEAT_BOSS"]       = "  - Detección de jefes: rastrea ENCOUNTER_START/END para combates reales con jefes"
L["CREDITS_FEAT_SOCIAL"]     = "  - Clasificación social: rankings de gremio, grupo y amigos de BNet"
L["CREDITS_FEAT_WEEKLY"]     = "  - Reinicio semanal: alineado con el reinicio de Blizzard los martes a las 7am PDT"
L["CREDITS_FEAT_DELVE"]      = "  - Seguimiento de Delves: puntuación basada en nivel para contenido en solitario"
L["CREDITS_FEAT_SYNC"]       = "  - Sincronización de puntuaciones: sincroniza entre miembros del gremio para recuperar puntuaciones tras reinstalar"
L["CREDITS_CONTACT"]         = "Contacto:  MidnightTim en GitHub (MidnightTim/MidnightSensei)"
L["CREDITS_DISCLAIMER"]      = "Midnight Sensei es un addon de la comunidad, no afiliado a Blizzard."

---------------------------------------------------------------------------
-- UI — FAQ
---------------------------------------------------------------------------
L["FAQ_HDR_GETTING_STARTED"] = "PRIMEROS PASOS"
L["FAQ_HDR_UNDERSTANDING"]   = "ENTENDIENDO TU CALIFICACIÓN"
L["FAQ_HDR_ROTATIONAL"]      = "RETROALIMENTACIÓN DE HECHIZOS ROTACIONALES"
L["FAQ_HDR_VISIBILITY"]      = "OPCIONES DE VISIBILIDAD"
L["FAQ_HDR_HISTORY"]         = "HISTORIAL DE CALIFICACIONES"
L["FAQ_HDR_LEADERBOARD"]     = "CLASIFICACIÓN"
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
L["FAQ_CMD_LB"]              = "  /ms lb           Clasificación social"
L["FAQ_CMD_LB_REMOVE"]       = "  /ms lb remove    Eliminar un jugador de la clasificación del gremio"
L["FAQ_CMD_OPTIONS"]         = "  /ms options      Configuración"
L["FAQ_CMD_FAQ"]             = "  /ms faq          Este panel"
L["FAQ_CMD_UPDATE"]          = "  /ms update       Ver registro de cambios"
L["FAQ_CMD_CREDITS"]         = "  /ms credits      Créditos e información"
L["FAQ_CMD_REPORT"]          = "  /ms report       Reportar un error en GitHub"
L["FAQ_CMD_VERSIONS"]        = "  /ms versions     Mostrar versiones del addon vistas en esta sesión"
L["FAQ_CMD_FRIEND"]          = "  /ms friend <n>   Consultar la última puntuación de un jugador directamente"
L["FAQ_CMD_TRACKER"]         = "  /ms tracker      Abrir el Seguidor de Rotación (conteo de lanzamientos + explicaciones de hechizos)"

---------------------------------------------------------------------------
-- UI — FAQ body paragraphs
---------------------------------------------------------------------------
L["FAQ_BODY_GETTING_STARTED"] = "Escribe |cffFFFFFF/ms show|r para abrir el HUD, |cffFFFFFF/ms hide|r para cerrarlo.\nEl HUD muestra tu última calificación, puntuación y especialización. Después de un combate\nverás un botón |cffFFFFFF>> Revisar Combate|r. Haz clic derecho en el HUD para acceder\nrápidamente a todas las funciones."
L["FAQ_BODY_UNDERSTANDING"]   = "Las calificaciones van de F a A+. Cada especialización tiene categorías ponderadas:\n  - Uso de Recargas: ¿presionaste tus recargas principales en recarga?\n  - Hechizos Rotacionales: ¿usaste habilidades clave cada combate?\n  - Actividad: ¿lanzaste de forma consistente? (sin largos periodos inactivos)\n  - Gestión de Recursos: ¿superaste el límite de tu recurso (Ira/Energía/etc.)?\n  - Uptime de Buff: ¿mantuviste activos tus buffs propios? (varía por especialización)\n  - Uso de Procs: ¿consumiste procs rápido? (DK Escarcha, Mago Fuego...)\n  - Eficiencia de Sanador: ¿cuánta de tu curación fue sobreuración?"
L["FAQ_BODY_ROTATIONAL"]      = "Además de las recargas, Midnight Sensei rastrea si usaste\nhechizos rotacionales clave en cada combate (p. ej., Implosin, Arranque, Golpe Oblicuo).\nSi nunca usaste uno en un combate suficientemente largo, aparecerá en tu\nretroalimentación. Los hechizos de talento se omiten si no tienes el talento."
L["FAQ_BODY_VIS_INTRO"]       = "Abre |cffFFFFFF/ms options|r (o clic derecho en HUD -> Opciones) y configura:"
L["FAQ_BODY_HISTORY"]         = "Escribe |cffFFFFFF/ms history|r o clic derecho -> Historial de Calificaciones.\n  - Filtra por Este Personaje o Todos los Personajes\n  - El gráfico muestra tus últimos 20 combates de un vistazo\n  - Clic izquierdo en cualquier fila para ver detalles completos y retroalimentación\n  - Clic derecho en cualquier fila para eliminar esa entrada"
L["FAQ_BODY_LEADERBOARD"]     = "Escribe |cffFFFFFF/ms lb|r para abrir la clasificación social.\nDespus de cada combate con jefe, tu puntuación se transmite al gremio, grupo y\namigos de BNet que también tienen Midnight Sensei instalado.\nPestañas: Grupo (solo sesión), Gremio (persiste entre sesiones), Amigos.\nLas puntuaciones del gremio persisten entre sesiones y se sincronizan —\nincluso si un jugador está desconectado puedes ver su última puntuación registrada.\nEl promedio semanal cuenta solo encuentros con jefes — las peleas de basura y\nmaniquis de entrenamiento nunca se incluyen en los rankings.\nHaz clic derecho en cualquier fila del gremio para eliminar un jugador. Se volverán a\nagregar automáticamente cuando inicien sesión o presiones Actualizar."
L["FAQ_BODY_LB_EXTRA"]        = "Cada pestaña (Mazmorras, Incursiones) muestra información de ubicación de ese tipo de contenido\nsolamente — una ejecución de LFR nunca aparecerá en la pestaña de Mazmorras.\nEl nivel de llave Mítica+ se muestra cuando está disponible (p. ej., M+15).\nDespués de actualizar el addon, cada jugador necesita completar una nueva\nmazmorra o incursión para que la ubicación refleje el contenido correcto.\nTu propia entrada se actualiza inmediatamente desde el historial local."
L["FAQ_BODY_MIDNIGHT_NOTE"]   = "Blizzard restringió la lectura de auras de unidades enemigas en Midnight 12.0.\nLos debuffs del objetivo (Ruptura, Choque de Llamas, etc.) no pueden rastrearse directamente.\nEstos aparecen en tus priorityNotes como guía pero no se puntuan.\nTodos los buffs propios, recargas y lanzamientos rotacionales funcionan normalmente."
L["FAQ_BODY_BOSS_COMBAT"]     = "Midnight Sensei detecta encuentros con jefes mediante ENCOUNTER_START/END.\nLos combates con jefes muestran una etiqueta |cffFF6600[Jefe]|r en el historial y detalle del encuentro.\nFiltra tu historial a |cffFFFFFF[Solo Jefes]|r para revisar los intentos en jefes de mazmorra/incursión."
L["FAQ_BODY_TALENT_AWARE"]    = "La puntuación de recargas solo incluye hechizos que hayas aprendido.\nSi no tienes un talento, no se contará en tu contra."

---------------------------------------------------------------------------
-- UI — rotation tracker
---------------------------------------------------------------------------
L["ROT_TRACKER_SUBTITLE"]    = "Conteo de lanzamientos de tu último combate. Cada hechizo muestra cuántas veces se usó y por qué se rastrea."
L["ROT_TRACKER_NO_DATA"]     = "Sin datos de combate aún — participa en un combate para ver los resultados."
L["ROT_TRACKER_LAST_FIGHT"]  = "Último combate: %s"
L["ROT_TRACKER_NO_FIGHT"]    = "Aún no hay combate registrado"
L["ROT_COL_SPELL"]           = "HECHIZO"
L["ROT_COL_CASTS"]           = "LANZAMIENTOS"
L["ROT_COL_MIN_FIGHT"]       = "MIN COMBATE"
L["ROT_COL_STATUS"]          = "ESTADO"
L["ROT_STATUS_CAST"]         = "LANZADO"
L["ROT_STATUS_MISSED"]       = "FALLADO"
L["ROT_STATUS_SHORT"]        = "CORTO"
L["ROT_FLAG_COMBAT_TALENT"]  = "Requiere talento; solo lanzable durante una ventana de transformación"
L["ROT_FLAG_COMBAT_ONLY"]    = "Solo lanzable durante una ventana de transformación (p. ej., Metamorfosis del Vacío)"
L["ROT_FLAG_TALENT_ONLY"]    = "Solo se rastrea cuando este talento está activo en tu build"
L["ROT_FLAG_CORE"]           = "Habilidad rotacional básica — esperada en cada combate"
L["ROT_FLAG_MIN_FIGHT"]      = "marcado como fallado solo si el combate dura > %ds"
L["ROT_NOT_TRACKED"]         = "No rastreado en este build (talento no tomado o reemplazado): %s"
L["ROT_LEGEND_CAST_DESC"]    = "usado al menos una vez"
L["ROT_LEGEND_MISSED_DESC"]  = "el combate fue suficientemente largo pero el hechizo no se usó"
L["ROT_LEGEND_SHORT_DESC"]   = "combate demasiado corto para evaluar"
L["ROT_LEGEND"]              = "LANZADO  usado al menos una vez  FALLADO  el combate fue suficientemente largo pero el hechizo no se usó  CORTO  combate demasiado corto para evaluar"

---------------------------------------------------------------------------
-- UI — update popup / WoW settings / minimap
---------------------------------------------------------------------------
L["UPDATE_POPUP_MSG"]        = "Hay una nueva versión de Midnight Sensei disponible.\nConsulta Curseforge o Wago para la última versión."
L["SETTINGS_HEADER"]         = "Midnight Sensei v%s  Creado por Midnight - Thrall (US)"
L["SETTINGS_BTN_OPTIONS"]    = "Abrir Opciones"
L["SETTINGS_BTN_OPT_DESC"]   = "Configurar HUD, estilo de juego y más"
L["SETTINGS_BTN_HISTORY"]    = "Historial de Calificaciones"
L["SETTINGS_BTN_HIST_DESC"]  = "Ver historial de combates y tendencias"
L["SETTINGS_BTN_LB"]         = "Clasificación"
L["SETTINGS_BTN_LB_DESC"]    = "Rankings de Gremio / Grupo / Amigos / Delve"
L["SETTINGS_BTN_FAQ"]        = "Ayuda y Preguntas Frecuentes"
L["SETTINGS_BTN_FAQ_DESC"]   = "Cómo funciona la puntuación y calificación"
L["SETTINGS_BTN_CREDITS"]    = "Créditos e Información"
L["SETTINGS_BTN_CRED_DESC"]  = "Información del autor y fuentes"
L["SETTINGS_LEGACY_SUB"]     = "Creado por Midnight - Thrall (US)  |  /ms para comandos"
L["MINIMAP_TT_LEFT"]         = "Clic izquierdo: Mostrar/Ocultar HUD"
L["MINIMAP_TT_RIGHT"]        = "Clic derecho: Clasificación"
L["MINIMAP_TT_CTRL_RIGHT"]   = "Ctrl+Clic derecho: Tabla de Jefes"
L["MINIMAP_TT_SHIFT_RIGHT"]  = "Mayús+Clic derecho: Opciones"

---------------------------------------------------------------------------
-- Analytics/Feedback
---------------------------------------------------------------------------
L["FB_NEVER_PRESSED_SIMP"]   = "Perdiste valor por recargas sin usar%s: %s. Incluso presionarlas constantemente ayuda."
L["FB_NEVER_PRESSED"]        = "Nunca presionaste%s: %s — %s."
L["FB_ACTION_TANK"]          = "úsalas en tank-busters o ventanas de alto daño"
L["FB_ACTION_HEALER"]        = "alineáalas con ventanas de alto daño entrante"
L["FB_ACTION_DPS"]           = "alineáalas con ventanas de burst"
L["FB_ACTIVITY_SIMPLIFIED"]  = "Tu rotación es consistente, pero los espacios entre lanzamientos (%d%% de actividad) son lo siguiente que debes ajustar."
L["FB_ACTIVITY_MODERATE"]    = "Actividad al %d%% — aproximadamente %d lanzamiento(s) desperdiciados. Prepara tu siguiente hechizo antes de que el actual aterrice."
L["FB_ACTIVITY_LOW"]         = "Actividad: %d/%d GCDs (%d%%) — tiempo de inactividad %s, aproximadamente %d lanzamientos perdidos. Encuentra tu siguiente hechizo antes de que el actual termine."
L["FB_DOWNTIME_SIGNIFICANT"] = "significativo"
L["FB_DOWNTIME_MODERATE"]    = "moderado"
L["FB_UNDERUSED"]            = "Usado menos de lo esperado en un combate de %.1f min: %s — objetivo 1 uso por cada 2 minutos de combate."
L["FB_ROT_NEVER_USED"]       = "Hechizo(s) rotacional(es) nunca usados: %s — son fundamentales para tu %s."
L["FB_ROT_CONTEXT_TANK"]     = "rotación de supervivencia y amenaza"
L["FB_ROT_CONTEXT_HEALER"]   = "rendimiento de curación"
L["FB_ROT_CONTEXT_DPS"]      = "producción de daño"
L["FB_ROT_LOW_USED"]         = "Podrías haber lanzado más: %s — presíonalo en cada GCD disponible cuando tus gastadores principales están en recarga."
L["FB_PROC_DELAYED"]         = "retrasado"
L["FB_PROC_CRITICALLY"]      = "críticamente retrasado"
L["FB_PROC_MSG"]             = "El consumo de %s está %s — retenido %.1f s en promedio (presupuesto: %d s). Consume los procs inmediatamente cuando aparezcan."
L["FB_OVERCAP"]              = "Supercargaste %s %d vez/veces (%.1f/min) — gasta %s antes de alcanzar %d para evitar generación desperdiciada."
L["FB_MIT_NEVER_ACTIVATED"]  = "%s nunca fue activado — presíonalo en cada recarga disponible para reducir el daño físico recibido."
L["FB_MIT_LOW_UPTIME"]       = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt, %d aplicación(es)) — tienes grandes ventanas de daño físico sin mitigar. Presíonalo en el momento en que salga de recarga."
L["FB_MIT_SMALL_GAPS"]       = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt) — los pequeños espacios se acumulan. Úsalo preventivamente en secuencias de cuerpo a cuerpo intensas, no reactivamente."
L["FB_BUFF_LOW_UPTIME"]      = "%s: %d%% de tiempo activo vs %d%% objetivo (diferencia de %d pt) — reaplicar antes de que expire, no después."
L["FB_GROUP_BUFF_NOTE"]      = "%s (potenciador de grupo — asíate de que esté activo antes del combate)"
L["FB_OVERHEAL_HIGH"]        = "Curación excesiva al %.1f%% (objetivo: <%d%%) — estás gastando maná en objetivos que no necesitan curación. Lanza un poco después o cambia a hechizos reactivos en objetivos que reciben daño activamente."
L["FB_OVERHEAL_ELEVATED"]    = "Curación excesiva: %.1f%% (objetivo: <%d%%) — ligeramente elevada. Retén lanzamientos en objetivos con más del 70%% de salud y prioriza los HoTs sobre las curaciones directas en grupos estables."
L["FB_HEALER_FILL_DOWNTIME"] = "Cuando el grupo esté estable, llena el tiempo de inactividad con hechizos de daño para mantener el rendimiento."
L["FB_SIMPLIFIED_FALLBACK"]  = "Tu rotación es consistente y bien coordinada. Ajustar el timing de las ventanas de burst es el siguiente paso de rendimiento."
L["FB_NEAR_PERFECT"]         = "Ejecución casi perfecta. Las ganancias restantes son: %s."
L["FB_NEXT_TANK_PREPOS"]     = "pre-posicionar defensivas antes de daño pico predecible"
L["FB_NEXT_HEALER_OVERLAP"]  = "superponer recargas con los lanzamientos de daño entrante en lugar de reaccionar"
L["FB_NEXT_DPS_ALIGN"]       = "alinear ventanas de burst con las fases de vulnerabilidad del enemigo"
L["FB_NEXT_GCD_TIMING"]      = "reducir el tiempo entre el fin del GCD y tu siguiente lanzamiento a menos de 0.2s"
L["FB_STRONG_EXECUTION"]     = "Ejecución sólida en general. Tu categoría más baja es %s — ahí es donde vienen los próximos puntos."
L["FB_GOOD_FOUNDATION"]      = "Buena base — céntrate a continuación en: %s."
L["FB_HINT_TANK_CDS"]        = "usar recargas defensivas en tank-busters"
L["FB_HINT_PRESS_CDS"]       = "presionar las recargas principales de manera más consistente"
L["FB_HINT_MIT_UPTIME"]      = "aumentar el tiempo activo de mitigación presionando %s con más frecuencia"
L["FB_SOLID"]                = "Rendimiento sólido — ajusta el timing de las recargas para subir más."
L["FB_NOTE_INTERRUPT"]       = "Nota: %s — esta es tu interrupción. No usada en este combate — sin penalización."
L["FB_NOTE_UTILITY"]         = "Nota: %s — no usada o detectada en este combate. Sin penalización."
L["FB_NOTE_COMBAT_UTILITY"]  = "Nota: %s — aturde y causa daño además de utilidad. Úsalo cuando la situación lo permita; sin penalización por guardarlo."
