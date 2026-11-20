local addonName, ns = ...
local events = CreateFrame("Frame")
local pending, requested, hooked = false, {}, {}
local logReady = false
local selectionPending = false
local selectionMode, selectionTargetID
local lastSelectedID

-- Source dialogue is a session-only cache, never a SavedVariables archive.
function ns.PruneQuestSources()
    for id in pairs(ns.questSources or {}) do
        if not ns.API.isActive(id) then ns.questSources[id] = nil end
    end
end

function ns.LocalizeBindings()
    BINDING_HEADER_QUESTLORE = "QuestLore"
    BINDING_NAME_QUESTLORE_TOGGLE = ns.L("Mostrar el relato")
    BINDING_NAME_QUESTLORE_SCROLL_UP = ns.L("Subir el relato")
    BINDING_NAME_QUESTLORE_SCROLL_DOWN = ns.L("Bajar el relato")
    BINDING_NAME_QUESTLORE_HISTORY = ns.L("Abrir el historial")
    BINDING_NAME_QUESTLORE_FONT_SMALLER = ns.L("Reducir tamaño del texto")
    BINDING_NAME_QUESTLORE_FONT_LARGER = ns.L("Ampliar tamaño del texto")
end
ns.LocalizeBindings()

function ns.SetVisible(visible)
    ns.db.visible = visible
    if ns.Tracker then ns.Tracker:Changed() end
    if visible then
        ns.Window.frame:Show()
        ns.QueueRefresh()
    else
        if ns.FullText then ns.FullText:Close() end
        ns.Window.frame:Hide()
    end
end

function QuestLore_Toggle()
    -- Keep the original binding name for compatibility; it only shows the window.
    if ns.ready then ns.SetVisible(true) end
end

function QuestLore_Scroll(direction)
    if ns.ready then ns.Window:Scroll(direction) end
end

function QuestLore_FontSize(direction)
    if ns.ready then ns.Window:SetFontSize(ns.db.fontSize + direction) end
end

function ns.Display()
    local model = ns.history.live
    if model then ns.Window:Render(model) end
    if ns.Options and ns.Options.historyPanel and ns.Options.historyPanel:IsVisible() then ns.Options:SyncHistory() end
end

-- Compatibility for old bindings: archive navigation never replaces live Lore.
function QuestLore_Navigate(direction)
    if ns.ready then ns.Options:MoveHistory(direction) end
end

function QuestLore_Current()
    if ns.ready then ns.QueueRefresh() end
end

function QuestLore_History()
    if ns.ready then ns.Options:OpenHistory() end
end

function ns.ClearSelectionContext()
    selectionMode, selectionTargetID = nil, nil
end

function ns.FocusedQuestID()
    -- The latest explicit interaction wins over a stale, still-open journal.
    if selectionMode == "tracked" then
        local id = ns.API.superTracked()
        if ns.API.isActive(id) then return id end
    elseif selectionMode == "selected" and ns.API.isLogVisible() then
        if ns.API.isActive(selectionTargetID) then return selectionTargetID end
    end
    selectionMode, selectionTargetID = nil, nil
    if ns.API.isLogVisible() then
        local id=ns.API.selected()
        if ns.API.isActive(id) then return id end
    end
    local id=ns.API.superTracked()
    if ns.API.isActive(id) then return id end
end

local function resolveContext()
    local focused=ns.FocusedQuestID()
    if focused then return focused end
    local polestarID = ns.PolestarBridge:QuestID()
    if polestarID then return polestarID end
    local restedID = ns.RestedXPBridge:QuestID()
    if restedID then return restedID end
    return ns.Model.Resolve(ns.API)
end

function ns.Refresh()
    if not ns.ready or not ns.db.visible or not ns.Window.frame:IsVisible() then return end
    local questID = resolveContext()
    local quest = questID and ns.API.Read(questID) or nil
    if quest then
        local cached = ns.questSources[questID]
        if ns.Text.Clean(quest.description) == "" and ns.Text.Clean(quest.objectives) == "" and cached then
            quest.description = cached.description
            quest.title = quest.title or cached.title
            quest.objectives, quest.sourceLocale = cached.objectives, cached.sourceLocale
        end
        if ns.Text.Clean(quest.description) ~= "" or ns.Text.Clean(quest.objectives) ~= "" then
            ns.questSources[questID] = { title = quest.title, description = quest.description,
                objectives = quest.objectives, sourceLocale = quest.sourceLocale }
            requested[questID] = nil
        elseif not requested[questID] then
            -- Bounded, per-quest retries. Never continuously poll the client.
            requested[questID] = "pending"
            ns.API.Request(questID)
            C_Timer.After(0.8, ns.QueueRefresh)
            C_Timer.After(3, function()
                if requested[questID] == "pending" then
                    requested[questID] = "done"
                    ns.QueueRefresh()
                end
            end)
        end
        quest.loading = requested[questID] == "pending"
    end
    local model = ns.Model.Build(quest, ns.Locale.Get())
    local hasQuests = ns.API.HasQuests()
    if quest or hasQuests == true then ns.db.adventureStarted = true end
    if not quest and hasQuests == false then
        if logReady and not ns.db.adventureStarted then
            model = ns.Origins.Build(ns.API.Profile())
        elseif logReady then
            model = {key="empty",kind="empty",source="",title=ns.L("Sin misiones activas"),
                body=ns.L("Has comenzado tu aventura. Selecciona una misión para leer su contexto. Puedes consultar tus relatos anteriores en las opciones de QuestLore.")}
        else
            model = {
                key = "preparing", title = ns.L("Tu aventura"), kind = "loading", source = "",
                body = ns.L("Preparando el relato de tu personaje…"),
            }
        end
    end
    if ns.db.minimized then
        ns.history.live = model
        if selectionPending then ns.history.cursor = nil end
    else
        ns.history:Update(model, true)
        selectionPending = false
    end
    ns.Display()
end

function ns.QueueRefresh()
    if not ns.ready or pending then return end
    pending = true
    C_Timer.After(0.08, function() pending = false; ns.Refresh() end)
end

function ns.SelectContext(id, mode)
    selectionPending = true
    selectionMode, selectionTargetID = mode or "selected", id or ns.API.selected()
    ns.QueueRefresh()
end

local function installHooks()
    local function hookFunction(name, callback)
        if not hooked[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, callback or ns.QueueRefresh)
            hooked[name] = true
        end
    end
    -- ShowQuestDetails is also called by ordinary quest-log repainting.
    hookFunction("QuestMapFrame_ShowQuestDetails")
    hookFunction("QuestMapFrame_OpenToQuestDetails", ns.SelectContext)
    hookFunction("QuestMapLogTitleButton_OnClick", function(button, mouseButton)
        local modified = (IsShiftKeyDown and IsShiftKeyDown()) or (IsModifiedClick and IsModifiedClick("CHATLINK"))
        if mouseButton == "LeftButton" and not modified and ns.API.isActive(button.questID) then
            ns.SelectContext(button.questID, "selected")
        end
    end)
    hookFunction("QuestMapFrame_CloseQuestDetails")
    if not hooked.selected and C_QuestLog and type(C_QuestLog.SetSelectedQuest) == "function" then
        lastSelectedID = ns.API.selected()
        hooksecurefunc(C_QuestLog, "SetSelectedQuest", function(id)
            local changed = id ~= lastSelectedID
            lastSelectedID = id
            if changed and selectionMode ~= "tracked" and ns.API.isActive(id) then
                ns.SelectContext(id, "selected")
            else
                ns.QueueRefresh()
            end
        end)
        hooked.selected = true
    end
    if not hooked.superTracked and C_SuperTrack and type(C_SuperTrack.SetSuperTrackedQuestID) == "function" then
        hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function(id)
            if ns.API.isActive(id) then ns.SelectContext(id, "tracked")
            else
                if selectionMode=="tracked" then ns.ClearSelectionContext() end
                ns.QueueRefresh()
            end
        end)
        hooked.superTracked = true
    end
    if QuestMapFrame and not hooked.map then
        QuestMapFrame:HookScript("OnShow", ns.QueueRefresh)
        QuestMapFrame:HookScript("OnHide", ns.QueueRefresh)
        hooked.map = true
    end
end

local function initialise()
    local existingInstall=type(QuestLoreCharacterDB)=="table" and type(QuestLoreCharacterDB.locale)=="string" and QuestLoreCharacterDB.build~=nil
    QuestLoreCharacterDB = type(QuestLoreCharacterDB) == "table" and QuestLoreCharacterDB or {}
    ns.db = QuestLoreCharacterDB
    if ns.db.attachToTracker == nil then ns.db.attachToTracker = true end
    if ns.db.showFullTextButton == nil then ns.db.showFullTextButton = true end
    if ns.db.followPolestar == nil then ns.db.followPolestar = true end
    if ns.db.followRestedXP == nil then ns.db.followRestedXP = true end
    ns.locale = GetLocale()
    ns.Locale.InitialiseUI()
    ns.LocalizeBindings()
    local profile = ns.API.Profile()
    if profile.level and profile.level > 1 then ns.db.adventureStarted = true end
    local _, build = ns.API.Call(GetBuildInfo)
    ns.questSources = {}
    -- Remove raw dialogue saved by older releases; it is not migrated into
    -- history or retained after abandoning/completing a quest.
    ns.db.quests, ns.db.questCache = nil, nil
    ns.db.locale = ns.locale
    ns.db.build = build
    if ns.db.visible == nil then ns.db.visible = true end
    ns.history = ns.History.New(ns.db.history)
    ns.db.history = ns.history.entries
    for _, entry in ipairs(ns.db.history) do
        if entry.id then ns.db.adventureStarted = true; break end
    end
    if ns.Updates then ns.Updates:Initialise(existingInstall) end
    ns.Window:Create()
    if ns.Tracker then ns.Tracker:Create() end
    ns.Options:Create()
    ns.ready = true
    installHooks()
    ns.PolestarBridge:Sync()
    ns.RestedXPBridge:Sync()
    ns.SetVisible(ns.db.visible)
end

events:SetScript("OnEvent", function(_, event, a, b)
    if event == "QUEST_LOG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then logReady = true end
    if event == "PLAYER_LOGIN" then
        initialise()
    elseif event == "ADDON_LOADED" then
        if ns.ready then installHooks(); ns.PolestarBridge:Sync(); ns.RestedXPBridge:Sync() end
    elseif ns.ready then
        -- Full original dialogue belongs only to the current active quest.
        -- Validate it even while the summary window is hidden/minimized.
        ns.PruneQuestSources()
        if ns.Window.RefreshFullText then ns.Window:RefreshFullText() end
        if event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" then
            ns.questSources[a] = nil
            requested[a] = nil
            if ns.FullText and ns.FullText.id == a then ns.FullText:Close() end
        elseif event == "QUEST_DATA_LOAD_RESULT" and b == false then
            requested[a] = "done"
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Permit a new bounded attempt after zoning/reconnecting.
            requested = {}
        end
        ns.QueueRefresh()
    end
end)

for _, event in ipairs({
    "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE",
    "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_WATCH_LIST_CHANGED",
    "SUPER_TRACKING_CHANGED", "QUEST_DATA_LOAD_RESULT",
}) do events:RegisterEvent(event) end

SLASH_QUESTLORE1 = "/lore"
SLASH_QUESTLORE2 = "/questlore"
SlashCmdList.QUESTLORE = function(command)
    if not ns.ready then return end
    command = ns.Text.Fold(command):gsub("^%s+", ""):gsub("%s+$", "")
    local font = command:match("^fuente%s+([%d%.]+)$")
    if font then
        ns.Window:SetFontSize(font)
    elseif command == "reset" then
        ns.Window:ResetPosition()
        ns.SetVisible(true)
    elseif command == "actualizar" or command == "refresh" then
        requested = {}
        ns.SetVisible(true)
    else
        QuestLore_Toggle()
    end
end
