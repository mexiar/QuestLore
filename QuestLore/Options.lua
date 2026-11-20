local _, ns = ...
local Options = {}
ns.Options = Options


local function copyableLink(parent,url)
    local box=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    box:SetAutoFocus(false);box:SetFontObject("GameFontHighlightSmall")
    box:SetText(url)
    box:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    box:SetScript("OnTextChanged",function(self,userInput)
        if userInput then self:SetText(url);self:HighlightText() end
    end)
    return box
end

function Options:Sync()
    if not self.slider then return end
    self.syncing = true
    self.slider:SetValue(ns.db.fontSize)
    if self.backgroundSlider then self.backgroundSlider:SetValue(ns.db.backgroundTransparency or 50) end
    self.syncing = false
    self.value:SetText(ns.L("Tamaño del texto: ") .. ns.db.fontSize)
    self.description:SetText(ns.L("El contexto de tus misiones. Las preferencias se guardan para este personaje."))
    self.preview:SetText(ns.L("Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal."))
    self.reset:SetText(ns.L("Restablecer texto"))
    self.fullTextToggle:SetChecked(ns.db.showFullTextButton~=false)
    self.fullTextToggle.label:SetText(ns.L("Mostrar botón de texto completo"))
    self.backgroundToggle:SetChecked(ns.db.backgroundEnabled==true)
    self.backgroundToggle.label:SetText(ns.L("Mostrar fondo"))
    self.backgroundSlider:SetEnabled(ns.db.backgroundEnabled==true)
    self.backgroundValue:SetText(ns.L("Transparencia del fondo: ")..(ns.db.backgroundTransparency or 50).."%")
    self.backgroundSlider.Low:SetText(ns.L("Opaco"))
    self.backgroundSlider.High:SetText(ns.L("Transparente"))
    if self.historyButton then self.historyButton:SetText(ns.L("Ver historial")) end
    if self.updateNotices then
        self.updatesHeading:SetText(ns.L("Novedades de QuestLore"))
        self.updateNotices:SetChecked(ns.db.showUpdateNotices~=false)
        self.updateNotices.label:SetText(ns.L("Mostrar avisos de actualización"))
        self.updatesButton:SetText(ns.L("Ver novedades"))
    end
    if self.contactHeading then
        self.contactHeading:SetText(ns.L("Errores y novedades"))
        self.contactDescription:SetText(ns.L("Reporta errores y sigue las novedades de QuestLore en X: @alejandrosena. Selecciona y copia el enlace para abrirlo en tu navegador."))
    end
    if self.updatesPanel then self:SyncUpdates() end
    if ns.Encyclopedia then ns.Encyclopedia:Localize() end
    if self.historyPanel then self:SyncHistory() end
    self.languageLabel:SetText(ns.L("Idioma del relato"))
    self.uiLanguageLabel:SetText(ns.L("Idioma de la interfaz"))
    self.uiLanguageNotice:SetText(ns.L("El idioma de la interfaz es independiente del idioma de los resúmenes."))
    for _, choice in ipairs(self.uiLanguageChoices) do
        choice:SetChecked((ns.db.uiLanguage or "auto")==choice.language)
        choice.label:SetText(ns.L(choice.caption))
    end
    self.languageNotice:SetText(ns.L("Resúmenes y enciclopedia en inglés y español latinoamericano. Polaco: resúmenes aportados por la comunidad y enciclopedia traducida del inglés. Francés, alemán y portugués de Brasil: traducciones provisionales del inglés. Las traducciones conservan los nombres propios en inglés. Los títulos de misión y el texto completo usan el idioma del juego. Los idiomas adicionales se eligen manualmente."))
    for _, choice in ipairs(self.languageChoices) do
        choice:SetChecked((ns.db.language or "auto")==choice.language)
        choice.label:SetText(ns.L(choice.caption))
    end
    self.preview:SetFont(ns.Window.fontName, ns.db.fontSize, "")
    if self.polestar then
        self.polestar:SetChecked(ns.db.followPolestar == true)
        self.polestar.label:SetText(ns.L("Seguir la misión activa de Polestar"))
        local status = ns.PolestarBridge:IsAvailable()
            and "La misión seleccionada o en foco tiene prioridad. Polestar se usa cuando no hay una misión en foco."
            or "Polestar no está disponible. Se usará el seguimiento habitual."
        self.polestarStatus:SetText(ns.L(status))
    end
    if self.restedXP then
        self.restedXP:SetChecked(ns.db.followRestedXP == true)
        self.restedXP.label:SetText(ns.L("Seguir la misión activa de RestedXP"))
        self.restedXPStatus:SetText(ns.L(ns.RestedXPBridge:IsAvailable()
            and "RestedXP sigue su objetivo de misión o un paso con una sola misión activa. Polestar tiene prioridad si ambos están activados."
            or "RestedXP no está disponible. Se usará el seguimiento habitual."))
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
    local function choices(widgets, y)
        for _, choice in ipairs(widgets) do
            at(choice,y)
            choice.label:SetWidth(math.max(100,width-64))
            choice.label:SetHeight(0)
            y=y+math.max(28,choice.label:GetStringHeight()+8)
        end
        return y
    end
    local function checkbox(widget, y)
        at(widget,y)
        widget.label:SetWidth(math.max(100,width-64))
        widget.label:SetHeight(0)
        return y+math.max(34,widget.label:GetStringHeight()+8)
    end
    local function action(widget, y)
        at(widget,y)
        local buttonWidth=math.min(260,width-32)
        local height=24
        local text=widget.GetFontString and widget:GetFontString()
        if text then
            text:SetWidth(buttonWidth-24); text:SetWordWrap(true); text:SetHeight(0)
            height=math.max(height,math.ceil(text:GetStringHeight())+12)
        end
        widget:SetSize(buttonWidth,height)
        return y+height+20
    end
    local y = paragraph(self.description, 52)+22
    y=paragraph(self.uiLanguageLabel,y)+8
    y=choices(self.uiLanguageChoices,y)
    y=paragraph(self.uiLanguageNotice,y+8)+24
    y=paragraph(self.languageLabel,y)+8
    y=choices(self.languageChoices,y)
    y=paragraph(self.languageNotice,y+8)+24
    at(self.value,y); y=y+28
    at(self.slider,y); y=y+42
    y=paragraph(self.preview,y)+20
    y=action(self.reset,y)
    y=checkbox(self.fullTextToggle,y)
    y=checkbox(self.backgroundToggle,y)
    y=paragraph(self.backgroundValue,y)+12
    at(self.backgroundSlider,y); self.backgroundSlider:SetWidth(math.min(260,width-32)); y=y+48
    y=checkbox(self.attachment,y)
    y=paragraph(self.attachmentStatus,y,48)+24
    y=checkbox(self.polestar,y)
    y=paragraph(self.polestarStatus,y,48)+24
    y=checkbox(self.restedXP,y)
    y=paragraph(self.restedXPStatus,y,48)+24
    y=action(self.historyButton,y)
    if self.updateNotices then
        y=paragraph(self.updatesHeading,y)+12
        y=checkbox(self.updateNotices,y)
        y=action(self.updatesButton,y)
    end
    if self.contactHeading then
        y=paragraph(self.contactHeading,y+8)+12
        y=paragraph(self.contactDescription,y)+12
        at(self.contactLink,y);self.contactLink:SetSize(math.max(100,width-40),24)
        y=y+44
    end
    self.content:SetHeight(y+12)
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
    self.uiLanguageLabel = panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.uiLanguageLabel:SetJustifyH("LEFT"); self.uiLanguageLabel:SetWordWrap(true)
    self.uiLanguageChoices = {}
    for _, choice in ipairs({{"auto","Automático (idioma del juego)"},{"es","Español (Latinoamérica)"},{"en","English"},{"fr","Français"},{"de","Deutsch"},{"pt","Português (Brasil)"},{"pl","Polski"},{"ru","Русский"}}) do
        local button=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
        button.language,button.caption=choice[1],choice[2]
        button.label=button:CreateFontString(nil,"ARTWORK","GameFontHighlight")
        button.label:SetPoint("TOPLEFT",button,"TOPRIGHT",2,-4)
        button.label:SetJustifyH("LEFT"); button.label:SetWordWrap(true)
        button:SetScript("OnClick",function() ns.Locale.SetUI(button.language) end)
        self.uiLanguageChoices[#self.uiLanguageChoices+1]=button
    end
    self.uiLanguageNotice=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    self.uiLanguageNotice:SetJustifyH("LEFT"); self.uiLanguageNotice:SetWordWrap(true)
    self.languageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.languageLabel:SetJustifyH("LEFT"); self.languageLabel:SetWordWrap(true)
    self.languageLabel:SetPoint("TOPLEFT", 16, -96)
    self.languageChoices = {}
    for i, choice in ipairs({{"auto","Automático (idioma del juego)"},{"es","Español (Latinoamérica)"},{"en","English"},{"fr","Français (traduction)"},{"de","Deutsch (Übersetzung)"},{"pt","Português (Brasil, tradução)"},{"pl","Polski"},{"ru","Русский (перевод)"}}) do
        local button = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        button:SetPoint("TOPLEFT", 16, -120-(i-1)*28)
        button.language, button.caption = choice[1], choice[2]
        button.label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        button.label:SetPoint("TOPLEFT", button, "TOPRIGHT", 2, -4)
        button.label:SetJustifyH("LEFT"); button.label:SetWordWrap(true)
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
    preview:SetText(ns.L("Has recuperado tu voluntad. Ahora debes encontrar tu lugar entre los Renegados y ayudar a proteger Tirisfal."))
    preview:SetWordWrap(true)
    self.preview = preview
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 16, -340)
    reset:SetSize(180, 24)
    reset:SetText(ns.L("Restablecer texto"))
    reset:SetScript("OnClick", function() ns.Window:SetFontSize(ns.Window.DEFAULT_FONT) end)
    self.reset = reset
    local fullTextToggle=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
    fullTextToggle.label=fullTextToggle:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    fullTextToggle.label:SetPoint("TOPLEFT",fullTextToggle,"TOPRIGHT",2,-4)
    fullTextToggle.label:SetJustifyH("LEFT");fullTextToggle.label:SetWordWrap(true)
    fullTextToggle:SetScript("OnClick",function() ns.Window:SetShowFullTextButton(not ns.db.showFullTextButton) end)
    self.fullTextToggle=fullTextToggle
    local backgroundToggle=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
    backgroundToggle.label=backgroundToggle:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    backgroundToggle.label:SetPoint("TOPLEFT",backgroundToggle,"TOPRIGHT",2,-4)
    backgroundToggle.label:SetJustifyH("LEFT"); backgroundToggle.label:SetWordWrap(true)
    backgroundToggle:SetScript("OnClick",function() ns.Window:SetBackground(not ns.db.backgroundEnabled) end)
    self.backgroundToggle=backgroundToggle
    self.backgroundValue=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.backgroundValue:SetJustifyH("LEFT"); self.backgroundValue:SetWordWrap(true)
    local backgroundSlider=CreateFrame("Slider","QuestLoreBackgroundSlider",panel,"OptionsSliderTemplate")
    backgroundSlider:SetSize(260,18); backgroundSlider:SetMinMaxValues(0,100)
    backgroundSlider:SetValueStep(1); backgroundSlider:SetObeyStepOnDrag(true)
    backgroundSlider:SetScript("OnValueChanged",function(_,value)
        if not self.syncing then ns.Window:SetBackground(ns.db.backgroundEnabled,value) end
    end)
    self.backgroundSlider=backgroundSlider
    local attachment = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    attachment:SetPoint("TOPLEFT", 16, -384)
    attachment.label = attachment:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    attachment.label:SetPoint("TOPLEFT", attachment, "TOPRIGHT", 2, -4)
    attachment.label:SetJustifyH("LEFT")
    attachment.label:SetWordWrap(true)
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
    polestar.label:SetPoint("TOPLEFT", polestar, "TOPRIGHT", 2, -4)
    polestar.label:SetJustifyH("LEFT")
    polestar.label:SetWordWrap(true)
    polestar:SetScript("OnClick", function() ns.PolestarBridge:SetEnabled(not ns.db.followPolestar) end)
    self.polestar = polestar
    self.polestarStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.polestarStatus:SetPoint("TOPLEFT", 48, -500)
    self.polestarStatus:SetPoint("TOPRIGHT", -16, -500)
    self.polestarStatus:SetJustifyH("LEFT")
    self.polestarStatus:SetWordWrap(true)
    local restedXP = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    restedXP.label = restedXP:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    restedXP.label:SetPoint("TOPLEFT", restedXP, "TOPRIGHT", 2, -4)
    restedXP.label:SetJustifyH("LEFT")
    restedXP.label:SetWordWrap(true)
    restedXP:SetScript("OnClick", function() ns.RestedXPBridge:SetEnabled(not ns.db.followRestedXP) end)
    self.restedXP = restedXP
    self.restedXPStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.restedXPStatus:SetJustifyH("LEFT")
    self.restedXPStatus:SetWordWrap(true)
    self.historyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    self.historyButton:SetPoint("TOPLEFT", 16, -554)
    self.historyButton:SetSize(180, 24)
    self.historyButton:SetScript("OnClick", function() self:OpenHistory() end)
    self.updatesHeading=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.updatesHeading:SetJustifyH("LEFT");self.updatesHeading:SetWordWrap(true)
    self.updateNotices=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
    self.updateNotices.label=self.updateNotices:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    self.updateNotices.label:SetPoint("TOPLEFT",self.updateNotices,"TOPRIGHT",2,-4)
    self.updateNotices.label:SetJustifyH("LEFT");self.updateNotices.label:SetWordWrap(true)
    self.updateNotices:SetScript("OnClick",function()
        local enabled=ns.db.showUpdateNotices==false
        if ns.Updates then ns.Updates:SetNoticesEnabled(enabled)
        else ns.db.showUpdateNotices=enabled;ns.Window:RefreshUpdateNotice();self:Sync() end
    end)
    self.updatesButton=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    self.updatesButton:SetScript("OnClick",function()
        if ns.Updates then ns.Updates:Open() else self:OpenUpdates() end
    end)
    self.contactHeading=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.contactHeading:SetJustifyH("LEFT");self.contactHeading:SetWordWrap(true)
    self.contactDescription=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    self.contactDescription:SetJustifyH("LEFT");self.contactDescription:SetWordWrap(true)
    self.contactLink=copyableLink(panel,"https://x.com/alejandrosena")
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
    self:CreateUpdates()
end

function Options:SyncUpdates()
    if not self.updatesPanel then return end
    self.updatesPanel.name="QuestLore · "..ns.L("Novedades")
    if self.updatesCategory and self.updatesCategory.SetName then self.updatesCategory:SetName(self.updatesPanel.name) end
    self.updatesTitle:SetText(ns.L("Últimas cinco versiones"))
    local release=ns.ReleaseNotes or {}
    self.updatesVersion:SetText(ns.L("Versión instalada: ")..(release.version or ""))
    local notes=release.notes or {}
    self.updatesBody:SetText(ns.Updates:Changelog())
    self.updatesLinkLabel:SetText(ns.L("Ver todo el changelog en CurseForge"))
    local width=math.max(100,self.updatesPanel:GetWidth()-64)
    self.updatesTitle:SetWidth(width);self.updatesTitle:SetHeight(0)
    local headingHeight=math.ceil(self.updatesTitle:GetStringHeight())
    self.updatesVersion:ClearAllPoints();self.updatesVersion:SetPoint("TOPLEFT",16,-16-headingHeight-10)
    self.updatesVersion:SetWidth(width);self.updatesVersion:SetHeight(0)
    local top=16+headingHeight+10+math.ceil(self.updatesVersion:GetStringHeight())+12
    self.updatesLinkLabel:ClearAllPoints();self.updatesLinkLabel:SetPoint("TOPLEFT",16,-top)
    self.updatesLinkLabel:SetWidth(width);self.updatesLinkLabel:SetHeight(0)
    top=top+math.ceil(self.updatesLinkLabel:GetStringHeight())+8
    self.updatesLink:ClearAllPoints();self.updatesLink:SetPoint("TOPLEFT",16,-top)
    self.updatesLink:SetSize(width,24)
    top=top+44
    self.updatesScroll:ClearAllPoints()
    self.updatesScroll:SetPoint("TOPLEFT",16,-top)
    self.updatesScroll:SetPoint("BOTTOMRIGHT",-32,24)
    self.updatesContent:SetWidth(width)
    self.updatesBody:SetFont(ns.Window.fontName,ns.db.fontSize,"")
    self.updatesBody:SetWidth(width);self.updatesBody:SetHeight(0)
    local height=math.ceil(self.updatesBody:GetStringHeight())+16
    self.updatesContent:SetHeight(math.max(1,height))
    if self.updatesScroll.UpdateScrollChildRect then self.updatesScroll:UpdateScrollChildRect() end
    self.updatesRange=math.max(0,height-self.updatesScroll:GetHeight())
    self.updatesScroll:SetVerticalScroll(math.min(self.updatesScroll:GetVerticalScroll(),self.updatesRange))
    if self.updatesScroll.ScrollBar then
        if self.updatesRange>0 then self.updatesScroll.ScrollBar:Show() else self.updatesScroll.ScrollBar:Hide() end
    end
end

function Options:OpenUpdates()
    if InCombatLockdown and InCombatLockdown() then return false end
    self:SyncUpdates()
    self.updatesScroll:SetVerticalScroll(0)
    local id=self.updatesCategory and self.updatesCategory:GetID()
    if ForeverCore and type(ForeverCore.OpenSettingsPanel)=="function" then
        ForeverCore.OpenSettingsPanel(id)
    elseif C_SettingsUtil and type(C_SettingsUtil.OpenSettingsPanel)=="function" and type(securecallfunction)=="function" then
        securecallfunction(C_SettingsUtil.OpenSettingsPanel,id)
    elseif Settings and Settings.OpenToCategory and self.updatesCategory then
        Settings.OpenToCategory(id)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.updatesPanel)
    else return false end
    return true
end

function Options:CreateUpdates()
    local panel=CreateFrame("Frame","QuestLoreUpdatesPanel",UIParent)
    panel:Hide();panel.name="QuestLore · "..ns.L("Novedades")
    self.updatesPanel=panel
    self.updatesTitle=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightHuge")
    self.updatesTitle:SetPoint("TOPLEFT",16,-16);self.updatesTitle:SetJustifyH("LEFT");self.updatesTitle:SetWordWrap(true)
    self.updatesVersion=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.updatesVersion:SetJustifyH("LEFT");self.updatesVersion:SetWordWrap(true)
    -- WoW cannot open arbitrary web URLs; provide a selectable link to copy.
    self.updatesLinkLabel=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self.updatesLinkLabel:SetJustifyH("LEFT");self.updatesLinkLabel:SetWordWrap(true)
    self.updatesLink=copyableLink(panel,"https://www.curseforge.com/wow/addons/questlore/files")
    local scroll=CreateFrame("ScrollFrame","QuestLoreUpdatesScroll",panel,"UIPanelScrollFrameTemplate")
    self.updatesScroll=scroll;scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(_,delta)
        scroll:SetVerticalScroll(math.max(0,math.min(self.updatesRange or 0,scroll:GetVerticalScroll()-delta*48)))
    end)
    self.updatesContent=CreateFrame("Frame",nil,scroll);self.updatesContent:SetSize(500,1)
    scroll:SetScrollChild(self.updatesContent)
    self.updatesBody=self.updatesContent:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    self.updatesBody:SetPoint("TOPLEFT",0,0);self.updatesBody:SetJustifyH("LEFT");self.updatesBody:SetWordWrap(true);self.updatesBody:SetSpacing(3)
    panel:SetScript("OnShow",function()
        self:SyncUpdates()
        if ns.Updates then ns.Updates:Dismiss() end
    end)
    panel:SetScript("OnSizeChanged",function() self:SyncUpdates() end)
    if Settings and Settings.RegisterCanvasLayoutSubcategory and self.category then
        self.updatesCategory=Settings.RegisterCanvasLayoutSubcategory(self.category,panel,panel.name)
    elseif InterfaceOptions_AddCategory then
        panel.parent="QuestLore";InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        self.updatesCategory=Settings.RegisterCanvasLayoutCategory(panel,panel.name)
        Settings.RegisterAddOnCategory(self.updatesCategory)
    end
    self:SyncUpdates()
end


function Options:ScrollHistory(delta)
    self.historyScroll:SetVerticalScroll(math.max(0,math.min(self.historyRange or 0,self.historyScroll:GetVerticalScroll()-delta*48)))
    self:UpdateHistoryVisible()
end

-- Row containers retain cheap geometry; expensive per-word regions and hit
-- buttons belong to a shared pool whose size follows the visible viewport.
function Options:ReleaseHistoryRich(row)
    local slot=row.richSlot
    if not slot then return end
    slot.rich:Hide()
    for _,word in ipairs(slot.rich.words) do
        word.entityID,word.entityLanguage=nil,nil
    end
    -- A reused renderer must rebuild its word identities even if two entries
    -- happen to share their text and dimensions.
    slot.rich.text,slot.rich.spans=nil,nil
    slot.rich.used=0
    slot.host:Hide()
    slot.host:SetParent(self.historyContent)
    slot.row=nil
    row.rich,row.richSlot=nil,nil
end

function Options:AcquireHistoryRich(row)
    if row.richSlot then
        row.richSlot.host:SetSize(row.width,row.height)
        return row.richSlot.rich
    end
    local pool=self.historyRichPool
    local slot
    for _,candidate in ipairs(pool) do
        if not candidate.row then slot=candidate;break end
    end
    if not slot then
        local host=CreateFrame("Frame",nil,self.historyContent)
        slot={host=host,rich=ns.Justify.New(host,ns.Window.fontName,function(delta) self:ScrollHistory(delta) end)}
        pool[#pool+1]=slot
    end
    slot.row=row
    slot.host:SetParent(row)
    slot.host:ClearAllPoints();slot.host:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
    slot.host:SetSize(row.width,row.height);slot.host:Show()
    row.richSlot,row.rich=slot,slot.rich
    return slot.rich
end

function Options:UpdateHistoryVisible()
    if not self.historyScroll then return end
    local visible=self.historyPanel:IsVisible()
    local top=self.historyScroll:GetVerticalScroll()
    local bottom=top+self.historyScroll:GetHeight()
    -- Release all departed rows before borrowing any slots for newly visible
    -- ones, including when jumping directly to a distant archive entry.
    for _,row in ipairs(self.historyRows) do
        row.richVisible=visible and row:IsShown() and row.spans and #row.spans>0
            and row.y+row.height>=top and row.y<=bottom
        if not row.richVisible then self:ReleaseHistoryRich(row) end
    end
    if not visible then return end
    for _,row in ipairs(self.historyRows) do
        if row.richVisible then
            local rich=self:AcquireHistoryRich(row)
            rich:Layout(row.entry.body,row.width,ns.db.fontSize,3,row.spans,true,row.bodyTop)
        end
    end
end

function Options:CreateHistoryRow()
    local row=CreateFrame("Frame",nil,self.historyContent)
    row.title=row:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    row.title:SetPoint("TOPLEFT",0,0);row.title:SetJustifyH("LEFT");row.title:SetWordWrap(true)
    row.body=row:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    row.body:SetJustifyH("LEFT");row.body:SetWordWrap(true);row.body:SetSpacing(3)
    row.read=CreateFrame("Button",nil,row)
    row.readLabel=row.read:CreateFontString(nil,"OVERLAY","GameFontNormal")
    row.readLabel:SetPoint("LEFT",row.read,"LEFT",0,0);row.readLabel:SetJustifyH("LEFT");row.readLabel:SetWordWrap(true)
    row.read:SetFontString(row.readLabel)
    if row.read.SetMotionScriptsWhileDisabled then row.read:SetMotionScriptsWhileDisabled(true) end
    row.read:SetScript("OnClick",function()
        if row.entry and ns.FullText:CanRead(row.entry.id) then ns.FullText:Open(row.entry.id,"history") end
    end)
    row.read:SetScript("OnEnter",function(button)
        if row.entry and not ns.FullText:CanRead(row.entry.id) then
            GameTooltip:SetOwner(button,"ANCHOR_TOP");GameTooltip:SetText(ns.L("El texto completo solo está disponible para misiones activas."));GameTooltip:Show()
        end
    end)
    row.read:SetScript("OnLeave",function() GameTooltip:Hide() end)
    row.line=row:CreateTexture(nil,"ARTWORK");row.line:SetPoint("BOTTOMLEFT",0,0);row.line:SetPoint("BOTTOMRIGHT",0,0)
    row.line:SetHeight(1);row.line:SetColorTexture(1,0.82,0,0.3)
    return row
end

function Options:SyncHistory(force)
    if not self.historyPanel then return end
    self.historyPanel.name="QuestLore · "..ns.L("Historial")
    if self.historyCategory and self.historyCategory.SetName then self.historyCategory:SetName(self.historyPanel.name) end
    self.historyHeading:SetText(ns.L("Historial de relatos"))
    self.historyDescription:SetText(ns.L("Tus relatos más recientes primero. El texto completo solo está disponible mientras la misión siga activa."))
    self.historyDescription:SetWidth(math.max(100,self.historyPanel:GetWidth()-32));self.historyDescription:SetHeight(0)
    self.historyScroll:ClearAllPoints()
    self.historyScroll:SetPoint("TOPLEFT",16,-52-math.ceil(self.historyDescription:GetStringHeight())-20)
    self.historyScroll:SetPoint("BOTTOMRIGHT",-32,24)
    if not force and not self.historyPanel:IsVisible() then self.historyDirty=true;return end
    self.historyDirty=false
    self.historyBuilt=true
    local entries=ns.history.entries
    if not (self.historyKey and ns.history:Find(self.historyKey)) then self.historyKey=entries[#entries] and entries[#entries].key end
    local width=math.max(100,self.historyPanel:GetWidth()-64)
    self.historyContent:SetWidth(width)
    self.historyByKey={}
    local y=0
    for position=1,#entries do
        local entry=entries[#entries-position+1]
        local row=self.historyRows[position]
        if not row then row=self:CreateHistoryRow();self.historyRows[position]=row end
        local showFullText=ns.db.showFullTextButton~=false
        local changed=row.lastBody~=entry.body or row.lastTitle~=entry.title or row.lastID~=entry.id or row.width~=width or row.fontSize~=ns.db.fontSize or row.uiLanguage~=ns.Locale.GetUI() or row.language~=entry.language or row.showFullText~=showFullText
        local spansChanged=row.lastBody~=entry.body or row.lastID~=entry.id or row.language~=entry.language
        row.showFullText=showFullText
        row.entry=entry;row.y=y
        self.historyByKey[entry.key]=row
        if changed then
            row.lastBody,row.lastTitle,row.width,row.fontSize,row.uiLanguage,row.language=entry.body,entry.title,width,ns.db.fontSize,ns.Locale.GetUI(),entry.language
            row.lastID=entry.id
            row.title:SetText(entry.title);row.title:SetFont(ns.Window.fontName,ns.db.fontSize,"");row.title:SetWidth(width);row.title:SetHeight(0)
            row.body:SetText(entry.body);row.body:SetFont(ns.Window.fontName,ns.db.fontSize,"");row.body:SetWidth(width);row.body:SetHeight(0)
            row.bodyTop=math.ceil(row.title:GetStringHeight())+10
            row.body:ClearAllPoints();row.body:SetPoint("TOPLEFT",0,-row.bodyTop)
            if spansChanged then row.spans=ns.Encyclopedia.FindSpans(entry.body,entry.language,entry.id) end
            local bodyHeight
            if #row.spans>0 then
                row.body:Hide()
                self.historyMeasureRich=self.historyMeasureRich or ns.Justify.New(self.historyContent,ns.Window.fontName)
                bodyHeight=self.historyMeasureRich:Layout(entry.body,width,ns.db.fontSize,3,row.spans,true,row.bodyTop,true)
            else
                row.body:Show();self:ReleaseHistoryRich(row)
                bodyHeight=math.ceil(row.body:GetStringHeight())
            end
            row.read:SetText(ns.L("Leer texto completo"));row.readLabel:SetWidth(width);row.readLabel:SetHeight(0)
            local actionHeight=entry.id and showFullText and math.max(22,math.ceil(row.readLabel:GetStringHeight())) or 0
            row.read:ClearAllPoints();row.read:SetPoint("TOPLEFT",0,-row.bodyTop-bodyHeight-10);row.read:SetSize(width,math.max(1,actionHeight))
            row.height=row.bodyTop+bodyHeight+(entry.id and showFullText and 10+actionHeight or 0)+24
        end
        local readable=ns.FullText:CanRead(entry.id)
        row.read:SetEnabled(readable)
        if readable then row.readLabel:SetTextColor(1,0.82,0) else row.readLabel:SetTextColor(0.6,0.6,0.6) end
        if entry.id and showFullText then row.read:Show() else row.read:Hide() end
        row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-y);row:SetSize(width,row.height);row:Show()
        if position<#entries then row.line:Show() else row.line:Hide() end
        y=y+row.height+20
    end
    for i=#entries+1,#self.historyRows do local row=self.historyRows[i];row:Hide();self:ReleaseHistoryRich(row) end
    self.historyEmpty:SetText(ns.L("Aún no hay relatos guardados."))
    if #entries==0 then self.historyEmpty:Show() else self.historyEmpty:Hide() end
    self.historyContent:SetHeight(math.max(1,y))
    self.historyRange=math.max(0,y-self.historyScroll:GetHeight())
    if self.historyScroll.UpdateScrollChildRect then self.historyScroll:UpdateScrollChildRect() end
    self.historyScroll:SetVerticalScroll(math.min(self.historyScroll:GetVerticalScroll(),self.historyRange))
    if self.historyScroll.ScrollBar then
        if self.historyRange>0 then self.historyScroll.ScrollBar:Show() else self.historyScroll.ScrollBar:Hide() end
    end
    self:UpdateHistoryVisible()
end

function Options:OpenHistory(key)
    self:SyncHistory(true)
    local row=key and self.historyByKey[key]
    self.historyScroll:SetVerticalScroll(row and math.min(row.y,self.historyRange or 0) or 0)
    self:UpdateHistoryVisible()
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
    self:OpenHistory(self.historyKey)
end

function Options:CreateHistory()
    local panel = CreateFrame("Frame", "QuestLoreHistoryPanel", UIParent)
    panel:Hide(); panel.name = "QuestLore · " .. ns.L("Historial")
    self.historyPanel, self.historyRows, self.historyRichPool = panel, {}, {}
    self.historyHeading = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    self.historyHeading:SetPoint("TOPLEFT", 16, -16)
    self.historyDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.historyDescription:SetPoint("TOPLEFT", 16, -52)
    self.historyDescription:SetPoint("TOPRIGHT", -16, -52)
    self.historyDescription:SetJustifyH("LEFT")
    self.historyDescription:SetWordWrap(true)
    self.historyScroll=CreateFrame("ScrollFrame","QuestLoreHistoryFeed",panel,"UIPanelScrollFrameTemplate")
    self.historyScroll:SetPoint("TOPLEFT",16,-100);self.historyScroll:SetPoint("BOTTOMRIGHT",-32,24)
    self.historyScroll:EnableMouseWheel(true)
    self.historyScroll:SetScript("OnMouseWheel",function(_,delta) self:ScrollHistory(delta) end)
    self.historyScroll:HookScript("OnVerticalScroll",function() self:UpdateHistoryVisible() end)
    self.historyContent=CreateFrame("Frame",nil,self.historyScroll)
    self.historyContent:SetSize(500,1);self.historyScroll:SetScrollChild(self.historyContent)
    self.historyEmpty=self.historyContent:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    self.historyEmpty:SetPoint("TOPLEFT",0,0)
    panel:SetScript("OnHide",function() for _,row in ipairs(self.historyRows) do self:ReleaseHistoryRich(row) end end)
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
