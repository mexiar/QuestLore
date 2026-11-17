local _, ns = ...
local Options = {}
ns.Options = Options

function Options:Sync()
    if not self.slider then return end
    self.syncing = true
    self.slider:SetValue(ns.db.fontSize)
    self.syncing = false
    self.value:SetText(ns.L("Tamaño del texto: ") .. ns.db.fontSize)
    self.description:SetText(ns.L("El contexto de tus misiones. Las preferencias se guardan para este personaje."))
    self.preview:SetText(ns.L("Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal."))
    self.reset:SetText(ns.L("Restablecer texto"))
    if self.historyButton then self.historyButton:SetText(ns.L("Ver historial")) end
    if self.historyPanel then self:SyncHistory() end
    self.languageLabel:SetText(ns.L("Idioma del relato"))
    self.languageNotice:SetText(ns.L("Idiomas base: inglés y español latinoamericano. La revisión de nombres originales en español sigue en curso. Francés, alemán y portugués de Brasil son traducciones automáticas provisionales del inglés y conservan los nombres propios en inglés. Los idiomas beta se eligen manualmente. Si falta una traducción, se muestra inglés."))
    for _, choice in ipairs(self.languageChoices) do
        choice:SetChecked((ns.db.language or "auto")==choice.language)
        choice.label:SetText(ns.L(choice.caption))
    end
    self.preview:SetFont(ns.Window.fontName, ns.db.fontSize, "")
    if self.polestar then
        self.polestar:SetChecked(ns.db.followPolestar == true)
        self.polestar.label:SetText(ns.L("Seguir la misión activa de Polestar"))
        local status = ns.PolestarBridge:IsAvailable()
            and "Polestar tiene prioridad. Su misión se comprueba cada segundo y al actualizar tus misiones."
            or "Polestar no está disponible. Se usará el seguimiento habitual."
        self.polestarStatus:SetText(ns.L(status))
    end
    if self.attachment then
        local available = ns.Tracker and ns.Tracker:IsAvailable()
        self.attachment:SetChecked(ns.db.attachToTracker == true)
        self.attachment:SetEnabled(available == true)
        self.attachment.label:SetText(ns.L("Adjuntar al final del rastreador de misiones"))
        local status = not available and "Requiere ForeverCore para adjuntar el relato al rastreador."
            or (ns.Tracker.pending and "El cambio se aplicará al salir de combate.")
            or "Desactiva esta opción para mover y redimensionar la ventana libremente."
        self.attachmentStatus:SetText(ns.L(status))
    end
    self:Layout()
end

-- All options live in a scroll child; wrapped translations and large previews
-- contribute their measured height instead of covering later controls.
function Options:Layout()
    if not self.content then return end
    local width = math.max(240, (self.panel:GetWidth() or 600)-34)
    self.content:SetWidth(width)
    local function at(widget, y, inset)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", inset or 16, -y)
    end
    local function paragraph(widget, y, inset)
        at(widget, y, inset)
        widget:SetWidth(math.max(100, width-(inset or 16)-16))
        return y+widget:GetStringHeight()
    end
    local y = paragraph(self.description, 52)+22
    at(self.languageLabel,y); y=y+24
    for _, choice in ipairs(self.languageChoices) do at(choice,y); y=y+28 end
    y=paragraph(self.languageNotice,y+8)+24
    at(self.value,y); y=y+28
    at(self.slider,y); y=y+42
    y=paragraph(self.preview,y)+20
    at(self.reset,y); y=y+44
    at(self.attachment,y); y=y+34
    y=paragraph(self.attachmentStatus,y,48)+24
    at(self.polestar,y); y=y+34
    y=paragraph(self.polestarStatus,y,48)+24
    at(self.historyButton,y)
    self.content:SetHeight(y+52)
    if self.scroll.UpdateScrollChildRect then self.scroll:UpdateScrollChildRect() end
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(),self.scroll:GetVerticalScrollRange()))
end

function Options:Create()
    if self.panel then return end
    local panel = CreateFrame("Frame", "QuestLoreOptionsPanel", UIParent)
    panel:Hide()
    panel.name = "QuestLore"
    self.panel = panel
    local categoryPanel = panel
    local scroll = CreateFrame("ScrollFrame", "QuestLoreOptionsScroll", categoryPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", -30, 8)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScrollRange(), scroll:GetVerticalScroll()-delta*48)))
    end)
    panel = CreateFrame("Frame", nil, scroll)
    panel:SetSize(550, 1000)
    scroll:SetScrollChild(panel)
    self.content, self.scroll = panel, scroll
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("QuestLore")
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", 16, -52)
    description:SetPoint("TOPRIGHT", -16, -52)
    description:SetJustifyH("LEFT")
    self.description = description
    self.languageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.languageLabel:SetPoint("TOPLEFT", 16, -96)
    self.languageChoices = {}
    for i, choice in ipairs({{"auto","Automático (idioma del juego)"},{"es","Español (Latinoamérica)"},{"en","English"},{"fr","Français (traduction)"},{"de","Deutsch (Übersetzung)"},{"pt","Português (Brasil, tradução)"}}) do
        local button = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        button:SetPoint("TOPLEFT", 16, -120-(i-1)*28)
        button.language, button.caption = choice[1], choice[2]
        button.label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        button.label:SetPoint("LEFT", button, "RIGHT", 2, 0)
        button:SetScript("OnClick", function() ns.Locale.Set(button.language) end)
        self.languageChoices[i] = button
    end

    self.languageNotice = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.languageNotice:SetJustifyH("LEFT")
    self.languageNotice:SetWordWrap(true)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, -184)
    self.value = label
    local slider = CreateFrame("Slider", "QuestLoreFontSizeSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -212)
    slider:SetSize(240, 18)
    slider:SetMinMaxValues(ns.Window.MIN_FONT, ns.Window.MAX_FONT)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(tostring(ns.Window.MIN_FONT))
    slider.High:SetText(tostring(ns.Window.MAX_FONT))
    self.slider = slider
    slider:SetScript("OnValueChanged", function(_, value)
        if not self.syncing then ns.Window:SetFontSize(value) end
    end)
    local preview = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    preview:SetPoint("TOPLEFT", 16, -252)
    preview:SetPoint("TOPRIGHT", -16, -252)
    preview:SetJustifyH("LEFT")
    preview:SetText("Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal.")
    preview:SetWordWrap(true)
    self.preview = preview
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 16, -340)
    reset:SetSize(180, 24)
    reset:SetText("Restablecer texto")
    reset:SetScript("OnClick", function() ns.Window:SetFontSize(ns.Window.DEFAULT_FONT) end)
    self.reset = reset
    local attachment = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    attachment:SetPoint("TOPLEFT", 16, -384)
    attachment.label = attachment:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    attachment.label:SetPoint("LEFT", attachment, "RIGHT", 2, 0)
    attachment.label:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    attachment.label:SetJustifyH("LEFT")
    attachment:SetScript("OnClick", function()
        if ns.Tracker then ns.Tracker:SetAttached(not ns.db.attachToTracker) end
        self:Sync()
    end)
    self.attachment = attachment
    self.attachmentStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.attachmentStatus:SetPoint("TOPLEFT", 48, -418)
    self.attachmentStatus:SetPoint("TOPRIGHT", -16, -418)
    self.attachmentStatus:SetJustifyH("LEFT")
    self.attachmentStatus:SetWordWrap(true)
    local polestar = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    polestar:SetPoint("TOPLEFT", 16, -466)
    polestar.label = polestar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    polestar.label:SetPoint("LEFT", polestar, "RIGHT", 2, 0)
    polestar.label:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    polestar.label:SetJustifyH("LEFT")
    polestar:SetScript("OnClick", function() ns.PolestarBridge:SetEnabled(not ns.db.followPolestar) end)
    self.polestar = polestar
    self.polestarStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.polestarStatus:SetPoint("TOPLEFT", 48, -500)
    self.polestarStatus:SetPoint("TOPRIGHT", -16, -500)
    self.polestarStatus:SetJustifyH("LEFT")
    self.polestarStatus:SetWordWrap(true)
    self.historyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    self.historyButton:SetPoint("TOPLEFT", 16, -554)
    self.historyButton:SetSize(180, 24)
    self.historyButton:SetScript("OnClick", function() self:OpenHistory() end)
    categoryPanel:SetScript("OnShow", function() self:Sync() end)
    categoryPanel:SetScript("OnSizeChanged", function() self:Sync() end)
    self:Sync()

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(categoryPanel, categoryPanel.name)
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(categoryPanel)
    end
    self:CreateHistory()
end


function Options:SyncHistory()
    if not self.historyPanel then return end
    self.historyHeading:SetText(ns.L("Historial de relatos"))
    self.historyDescription:SetText(ns.L("Selecciona un relato de la lista. El historial se guarda para este personaje."))
    local entries = ns.history.entries
    local selected = self.historyKey and ns.history:Find(self.historyKey)
    selected = selected or (#entries > 0 and #entries or nil)
    self.historyKey = selected and entries[selected].key or nil
    for i, entry in ipairs(entries) do
        local button = self.historyRows[i]
        if not button then
            button = CreateFrame("Button", nil, self.historyListContent, "UIPanelButtonTemplate")
            button:SetPoint("TOPLEFT", 0, -(i-1)*34)
            button:SetSize(190, 30)
            button:SetScript("OnClick", function() self.historyKey = ns.history.entries[i].key; self:SyncHistory() end)
            self.historyRows[i] = button
        end
        button:SetText(entry.title)
        button:SetEnabled(i ~= selected)
        button:Show()
    end
    for i=#entries+1,#self.historyRows do self.historyRows[i]:Hide() end
    self.historyListContent:SetHeight(math.max(1, #entries*34))
    local entry = selected and entries[selected]
    local key = entry and entry.key
    self.historyTitle:SetText(entry and entry.title or ns.L("Aún no hay relatos guardados."))
    self.historyBody:SetText(entry and entry.body or "")
    self.historyBody:SetFont(ns.Window.fontName, ns.db.fontSize, "")
    local width = math.max(100, (self.historyPanel:GetWidth() or 700)-300)
    self.historyDetailContent:SetWidth(width)
    self.historyTitle:SetWidth(width)
    self.historyBody:SetWidth(width)
    local titleHeight = self.historyTitle:GetStringHeight()
    self.historyBody:ClearAllPoints()
    self.historyBody:SetPoint("TOPLEFT", 0, -titleHeight-12)
    self.historyDetailContent:SetHeight(titleHeight+12+self.historyBody:GetStringHeight()+12)
    if self.historyDetail.UpdateScrollChildRect then self.historyDetail:UpdateScrollChildRect() end
    if self.historyList.UpdateScrollChildRect then self.historyList:UpdateScrollChildRect() end
    if self.historyRenderedKey ~= key then self.historyDetail:SetVerticalScroll(0) end
    self.historyRenderedKey = key
end

function Options:OpenHistory()
    self:SyncHistory()
    if InCombatLockdown and InCombatLockdown() then return end
    local id = self.historyCategory and self.historyCategory:GetID()
    if ForeverCore and type(ForeverCore.OpenSettingsPanel) == "function" then
        ForeverCore.OpenSettingsPanel(id)
    elseif C_SettingsUtil and type(C_SettingsUtil.OpenSettingsPanel) == "function" and type(securecallfunction) == "function" then
        securecallfunction(C_SettingsUtil.OpenSettingsPanel, id)
    elseif Settings and Settings.OpenToCategory and self.historyCategory then
        Settings.OpenToCategory(id)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.historyPanel)
    end
end

function Options:MoveHistory(direction)
    local index = self.historyKey and ns.history:Find(self.historyKey) or #ns.history.entries
    local entry = ns.history.entries[math.max(1, math.min(#ns.history.entries, index + (direction < 0 and -1 or 1)))]
    self.historyKey = entry and entry.key or nil
    self:OpenHistory()
end

function Options:CreateHistory()
    local panel = CreateFrame("Frame", "QuestLoreHistoryPanel", UIParent)
    panel:Hide(); panel.name = "QuestLore · " .. ns.L("Historial")
    self.historyPanel, self.historyRows = panel, {}
    self.historyHeading = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    self.historyHeading:SetPoint("TOPLEFT", 16, -16)
    self.historyDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.historyDescription:SetPoint("TOPLEFT", 16, -52)
    self.historyDescription:SetPoint("TOPRIGHT", -16, -52)
    self.historyDescription:SetJustifyH("LEFT")
    self.historyDescription:SetWordWrap(true)
    local function scroll(name, left, right)
        local frame = CreateFrame("ScrollFrame", name, panel, "UIPanelScrollFrameTemplate")
        frame:SetPoint("TOPLEFT", left, -100)
        if right then frame:SetPoint("BOTTOMRIGHT", -40, 24) else frame:SetSize(190, 350); frame:SetPoint("BOTTOMLEFT", left, 24) end
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            frame:SetVerticalScroll(math.max(0, math.min(frame:GetVerticalScrollRange(), frame:GetVerticalScroll()-delta*48)))
        end)
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(190, 1); frame:SetScrollChild(content)
        return frame, content
    end
    self.historyList, self.historyListContent = scroll("QuestLoreHistoryList", 16, false)
    self.historyDetail, self.historyDetailContent = scroll("QuestLoreHistoryDetail", 260, true)
    self.historyTitle = self.historyDetailContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    self.historyTitle:SetPoint("TOPLEFT", 0, 0); self.historyTitle:SetJustifyH("LEFT"); self.historyTitle:SetWordWrap(true)
    self.historyBody = self.historyDetailContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.historyBody:SetJustifyH("LEFT"); self.historyBody:SetWordWrap(true)
    panel:SetScript("OnShow", function() self:SyncHistory() end)
    panel:SetScript("OnSizeChanged", function() self:SyncHistory() end)
    if Settings and Settings.RegisterCanvasLayoutSubcategory and self.category then
        self.historyCategory = Settings.RegisterCanvasLayoutSubcategory(self.category, panel, panel.name)
    elseif InterfaceOptions_AddCategory then
        panel.parent = "QuestLore"
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        self.historyCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(self.historyCategory)
    end
    self:SyncHistory()
end
