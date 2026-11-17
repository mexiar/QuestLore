local _, ns = ...
local Locale = {}
ns.Locale = Locale
local english = {
 ["Seguir la misión activa de Polestar"]="Follow Polestar's active quest",
 ["Polestar no está disponible. Se usará el seguimiento habitual."]="Polestar is unavailable. Normal quest selection will be used.",
 ["Polestar tiene prioridad. Su misión se comprueba cada segundo y al actualizar tus misiones."]="Polestar takes priority. Its quest is checked every second and when your quest log updates.",
 ["Ver historial"]="View history",
 ["Historial de relatos"]="Story history",
 ["Selecciona un relato de la lista. El historial se guarda para este personaje."]="Select a story from the list. History is saved for this character.",
 ["Aún no hay relatos guardados."]="No stories have been saved yet.",
 ["Adjuntar al final del rastreador de misiones"]="Attach below the quest tracker",
 ["Requiere ForeverCore para adjuntar el relato al rastreador."]="ForeverCore is required to attach the story to the quest tracker.",
 ["El cambio se aplicará al salir de combate."]="The change will apply after combat ends.",
 ["Desactiva esta opción para mover y redimensionar la ventana libremente."]="Turn this off to move and resize the window freely.",
 ["Tu lugar en Azeroth"]="Your place in Azeroth",
 ["Selecciona una misión"]="Select a quest",
 ["Abre el diario y selecciona una misión, o sigue una para leer por qué estás haciéndola."]="Select a quest in your journal or track one to read why you are doing it.",
 ["Cargando el relato de la misión…"]="Loading the quest story…",
 ["Todavía no hay relato disponible para esta misión. Prueba a abrir sus detalles en el diario."]="This quest's story is not available yet. Try opening its details in the quest journal.",
 ["Tu aventura"]="Your adventure",
 ["Preparando el relato de tu personaje…"]="Preparing your character's story…",
 ["Sin misiones activas"]="No active quests",
 ["Has comenzado tu aventura. Selecciona una misión para leer su contexto. Puedes consultar tus relatos anteriores en las opciones de QuestLore."]="Your adventure has begun. Select a quest to read its context. You can find previous stories in the QuestLore options.",
 ["Minimizar ventana"]="Minimize window", ["Restaurar ventana"]="Restore window",
 ["Relato anterior"]="Previous story", ["Relato siguiente"]="Next story",
 ["Volver al contexto actual de tu personaje"]="Return to your character's current context",
 ["Arrastra para cambiar el tamaño"]="Drag to resize", ["Actual"]="Current",
 ["Actual · nuevo"]="Current · new", ["Historial"]="History",
 ["Tamaño del texto: "]="Text size: ", ["Restablecer texto"]="Reset text size",
 ["Idioma del relato"]="Story language", ["Automático (idioma del juego)"]="Automatic (game language)",
 ["Español"]="Español", ["English"]="English",
 ["El contexto de tus misiones. Las preferencias se guardan para este personaje."]="The context behind your quests. Settings are saved for this character.",
 ["Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal."]="You have regained your free will. Now you must find your place among the Forsaken and help protect Tirisfal.",
 ["Todavía no se pudo leer tu raza y tu clase. El contexto aparecerá cuando tu personaje termine de cargar."]="Your race and class are not available yet. Your story will appear when your character finishes loading.",
 ["Este relato todavía no tiene una traducción al idioma elegido."]="This story has not been translated into the selected language yet.",
 ["Misión "]="Quest ", ["Resumen narrativo · sin adelantar la historia"]="Narrative summary · no story spoilers",
 ["Extracto del relato de la misión"]="Quest story excerpt", ["Descripción de la misión"]="Quest description",
}
local chinese = {
 ["Seguir la misión activa de Polestar"]="跟随 Polestar 当前任务",
 ["Polestar no está disponible. Se usará el seguimiento habitual."]="Polestar 不可用，将使用常规任务选择。",
 ["Polestar tiene prioridad. Su misión se comprueba cada segundo y al actualizar tus misiones."]="Polestar 优先。每秒及任务日志更新时检查它的任务。",
 ["Ver historial"]="查看历史",
 ["Historial de relatos"]="剧情历史",
 ["Selecciona un relato de la lista. El historial se guarda para este personaje."]="从列表中选择一段剧情。历史按角色保存。",
 ["Aún no hay relatos guardados."]="还没有保存的剧情。",
 ["Adjuntar al final del rastreador de misiones"]="附在任务追踪栏下方",
 ["Requiere ForeverCore para adjuntar el relato al rastreador."]="需要 ForeverCore 才能附在任务追踪栏上。",
 ["El cambio se aplicará al salir de combate."]="脱离战斗后生效。",
 ["Desactiva esta opción para mover y redimensionar la ventana libremente."]="关闭此项可自由移动和调整窗口大小。",
 ["Tu lugar en Azeroth"]="你在艾泽拉斯的位置",
 ["Selecciona una misión"]="选择一个任务",
 ["Abre el diario y selecciona una misión, o sigue una para leer por qué estás haciéndola."]="在任务日志中选中或追踪一个任务，就能读到它背后的来龙去脉。",
 ["Cargando el relato de la misión…"]="正在载入任务剧情……",
 ["Todavía no hay relato disponible para esta misión. Prueba a abrir sus detalles en el diario."]="这个任务暂时没有剧情。试试在任务日志里打开它的详情。",
 ["Tu aventura"]="你的冒险",
 ["Preparando el relato de tu personaje…"]="正在准备你的角色故事……",
 ["Sin misiones activas"]="没有进行中的任务",
 ["Has comenzado tu aventura. Selecciona una misión para leer su contexto. Puedes consultar tus relatos anteriores en las opciones de QuestLore."]="你的冒险已经开始。选择一个任务即可阅读它的背景；以前读过的剧情可在 QuestLore 设置中查看。",
 ["Minimizar ventana"]="最小化窗口", ["Restaurar ventana"]="还原窗口",
 ["Relato anterior"]="上一段", ["Relato siguiente"]="下一段",
 ["Volver al contexto actual de tu personaje"]="回到角色当前的剧情",
 ["Arrastra para cambiar el tamaño"]="拖动调整大小", ["Actual"]="当前",
 ["Actual · nuevo"]="当前 · 新", ["Historial"]="历史",
 ["Tamaño del texto: "]="文字大小：", ["Restablecer texto"]="重置文字大小",
 ["Idioma del relato"]="剧情语言", ["Automático (idioma del juego)"]="自动（跟随游戏）",
 ["Español"]="Español", ["English"]="English",
 ["El contexto de tus misiones. Las preferencias se guardan para este personaje."]="你所做任务的前因后果。设置按角色保存。",
 ["Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal."]="你已挣脱束缚，重获自由意志。如今，你须在被遗忘者中寻得立足之地，守护提瑞斯法林地。",
 ["Todavía no se pudo leer tu raza y tu clase. El contexto aparecerá cuando tu personaje termine de cargar."]="暂时读不到你的种族和职业。角色载入完成后，背景故事就会出现。",
 ["Este relato todavía no tiene una traducción al idioma elegido."]="这段剧情还没有所选语言的译文。",
 ["Misión "]="任务 ", ["Resumen narrativo · sin adelantar la historia"]="剧情概要 · 无剧透",
 ["Extracto del relato de la misión"]="任务剧情节选", ["Descripción de la misión"]="任务描述",
}
-- Explicit branch avoids Lua's boolean result for the short language code.
function Locale.Resolve(value)
    if value == "es" or (type(value)=="string" and value:sub(1,2)=="es") then return "es" end
    if value == "zh" or (type(value)=="string" and value:sub(1,2)=="zh") then return "zh" end
    return "en"
end
function Locale.Get()
    local choice = ns.db and ns.db.language
    if choice == "es" or choice == "en" or choice == "zh" then return choice end
    return Locale.Resolve(ns.locale or (GetLocale and GetLocale()) or "esMX")
end
function ns.L(key, language)
    language = language or Locale.Get()
    if language == "en" then return english[key] or key end
    if language == "zh" then return chinese[key] or english[key] or key end
    return key
end
function Locale.Set(choice)
    if choice ~= "auto" and choice ~= "es" and choice ~= "en" and choice ~= "zh" then return end
    ns.db.language = choice
    if ns.ready then ns.history:Relocalize() end
    if ns.Options then ns.Options:Sync() end
    if ns.ready then
        if ns.Window.Localize then ns.Window:Localize() end
        ns.QueueRefresh()
    end
end
