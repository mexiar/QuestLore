local _, ns = ...
local Window = {}
ns.Window = Window
Window.MIN_FONT, Window.MAX_FONT, Window.DEFAULT_FONT = 12, 24, 14
Window.HEADER_HEIGHT, Window.EXPANDED_HEIGHT = 26, 310
Window.CONTENT_TOP, Window.FOOTER_HEIGHT = 10, 8

local palette = {
    text = { 1, 1, 1 },
    muted = { 0.72, 0.72, 0.72 },
    gold = { 1, 0.82, 0 },
}

-- Use the same section art as ObjectiveTrackerModuleHeaderTemplate. Lore is a
-- separate, unprotected frame; it never joins the native secure module list.
local function hasAtlas(atlas)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
    return ok and info ~= nil
end

local function shadow(text)
    if text.SetShadowColor then text:SetShadowColor(0, 0, 0, 1) end
    if text.SetShadowOffset then text:SetShadowOffset(1, -1) end
end

local function textButton(parent, name, label, size)
    local button = CreateFrame("Button", name, parent)
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetTextColor(unpack(palette.gold))
    shadow(text)
    if button.SetFontString then button:SetFontString(text) end
    if button.SetNormalFontObject then button:SetNormalFontObject(GameFontNormal) end
    if button.SetHighlightFontObject then button:SetHighlightFontObject(GameFontHighlight) end
    if button.SetDisabledFontObject then button:SetDisabledFontObject(GameFontDisable) end
    button.label = text
    button:SetText(label)
    return button
end

local function tooltip(button, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(type(text) == "function" and text() or ns.L(text))
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function Window:SyncScrollbar()
    local bar = self.scroll.ScrollBar
    if bar then
        if self.needsScroll and not ns.db.minimized then bar:Show() else bar:Hide() end
    end
end

-- Native scroll ranges and wrapped font geometry can settle a frame later.
-- Recheck once after changes, without adding a continuous layout timer.
function Window:QueueLayout()
    if self.layoutQueued then return end
    self.layoutQueued = true
    C_Timer.After(0, function()
        self.layoutQueued = false
        if not self.frame:IsVisible() then self.pendingScrollFraction = nil; return end
        self.settlingLayout = true
        self:Layout()
        self.settlingLayout = false
        self.pendingScrollFraction = nil
    end)
end

function Window:GetHeaderHeight()
    return self.headerHeight or self.HEADER_HEIGHT
end

function Window:ApplyPresentation(width, height)
    self.wideLayout = not self.attachedLayout and width > height
    local label = self.headerLabel
    label:ClearAllPoints()
    label:SetHeight(0)
    if self.wideLayout then
        label:SetPoint("LEFT",self.header,"LEFT",32,0)
        label:SetPoint("RIGHT",self.header,"RIGHT",-32,0)
        label:SetWidth(math.max(1,width-64))
        label:SetJustifyH("CENTER")
        label:SetText(self.currentTitle or "Lore")
        self.headerHeight=math.max(self.HEADER_HEIGHT,math.ceil(label:GetStringHeight())+4)
        self.title:Hide();self.body:Hide()
        if self.headerArt then self.headerArt:Hide();self.wideDivider:Show() end
    else
        label:SetPoint("LEFT",7,0);label:SetPoint("RIGHT",-26,0)
        label:SetWidth(math.max(1,width-33))
        label:SetJustifyH("LEFT");label:SetText("Lore")
        self.headerHeight=self.HEADER_HEIGHT
        self.title:Show();self.body:Show();self.justified:Hide()
        if self.headerArt then self.headerArt:Show();self.wideDivider:Hide() end
    end
    self.header:SetHeight(self.headerHeight)
    if not ns.db.minimized and not self.attachedLayout then
        -- A wrapped header still leaves at least one readable body line.
        local minimum=math.max(self.minHeight,self.headerHeight+self.CONTENT_TOP+self.FOOTER_HEIGHT+math.ceil(ns.db.fontSize*1.5)+6)
        local applying=self.applyingSize;self.applyingSize=true
        self.frame:SetResizeBounds(self.minWidth,minimum,self.maxWidth,self.maxHeight)
        if height<minimum then self.frame:SetHeight(minimum);self.expandedHeight=minimum end
        self.applyingSize=applying
    end
    if ns.db.minimized and self.frame:GetHeight()~=self.headerHeight then
        local applying=self.applyingSize;self.applyingSize=true
        self.frame:SetResizeBounds(self.attachedLayout and 1 or self.minWidth,self.headerHeight,self.maxWidth,self.maxHeight)
        self.frame:SetHeight(self.headerHeight);self.applyingSize=applying
    end
    return ns.db.minimized and self.expandedHeight or self.frame:GetHeight()
end

function Window:MeasureContent(width)
    self.content:SetWidth(width)
    self.title:SetWidth(width)
    self.body:SetWidth(width)
    self.title:SetHeight(0)
    self.body:SetHeight(0)
    if self.wideLayout then
        self.body:ClearAllPoints();self.body:SetPoint("TOPLEFT",self.content,"TOPLEFT",0,0)
        local height=self.justified:Layout(self.body:GetText() or "",width,ns.db.fontSize,math.max(2,math.floor(ns.db.fontSize/4)))+6
        self.content:SetHeight(height)
        return height
    end
    local titleHeight = math.ceil(self.title:GetStringHeight())
    self.title:SetHeight(titleHeight)
    self.body:ClearAllPoints()
    self.body:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -titleHeight - 8)
    local height = titleHeight + 8 + math.ceil(self.body:GetStringHeight()) + 6
    self.content:SetHeight(height)
    return height
end

function Window:Layout()
    if self.layingOut then return end
    self.layingOut = true
    local previousNatural, previousWidth = self.naturalContentHeight, self.layoutWidth
    local width = self.frame:GetWidth()
    local height = ns.db.minimized and self.expandedHeight or self.frame:GetHeight()
    height=self:ApplyPresentation(width,height)
    local viewport = math.max(0, height - self:GetHeaderHeight() - self.CONTENT_TOP - self.FOOTER_HEIGHT)
    self.layoutWidth, self.viewportHeight = width, viewport
    -- Decide fit at full width first. The scroll gutter must never influence
    -- the height requested from the host, or trap the layout in a narrow state.
    local natural = self:MeasureContent(math.max(1, width - 16))
    self.naturalContentHeight = natural
    self.needsScroll = natural > viewport + 0.01
    local contentHeight = self.needsScroll and self:MeasureContent(math.max(1, width - 40)) or natural
    self.scrollRange = self.needsScroll and math.max(0, contentHeight - viewport) or 0
    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", 8, -self:GetHeaderHeight() - self.CONTENT_TOP)
    self.scroll:SetPoint("BOTTOMRIGHT", self.needsScroll and -32 or -8, self.FOOTER_HEIGHT)
    if self.scroll.UpdateScrollChildRect then self.scroll:UpdateScrollChildRect() end
    local offset = self.scroll:GetVerticalScroll()
    if self.pendingScrollFraction then offset = self.pendingScrollFraction * self.scrollRange end
    self.scroll:SetVerticalScroll(math.max(0, math.min(offset, self.scrollRange)))
    self:SyncScrollbar()
    self.layingOut = false
    if not self.applyingAttachedLayout and ns.Tracker and ns.Tracker.Changed
        and (not self.settlingLayout or natural ~= previousNatural or width ~= previousWidth) then
        ns.Tracker:Changed()
    end
end

function Window:UpdateHoverControls(inside)
    if not self.grip then return end
    if inside==nil then
        inside=MouseIsOver and MouseIsOver(self.frame) or false
    end
    self.hovered=inside==true
    local visible=not self.attachedLayout and not ns.db.minimized and (self.hovered or self.resizing)
    -- Keep the transparent hit region active so moving onto the corner also
    -- reveals it; attached/minimized windows still hide the button entirely.
    self.grip:SetAlpha(visible and 1 or 0)
    self.minimize:SetAlpha((self.attachedLayout or self.hovered) and 1 or 0)
end

function Window:FinishResize()
    if not self.resizing then return end
    self.frame:StopMovingOrSizing()
    self.resizing = false
    if not ns.db.minimized and not self.attachedLayout then
        self.expandedHeight = self.frame:GetHeight()
        ns.db.size = { width = self.frame:GetWidth(), height = self.expandedHeight }
    end
    self:SavePosition()
    self:Layout()
    self:UpdateHoverControls()
end

function Window:SetFontSize(value)
    value = tonumber(value) or self.DEFAULT_FONT
    if value ~= value then value = self.DEFAULT_FONT end
    value = math.max(self.MIN_FONT, math.min(self.MAX_FONT, math.floor(value + 0.5)))
    local range = self.scrollRange or 0
    self.pendingScrollFraction = range > 0 and math.max(0, math.min(1, self.scroll:GetVerticalScroll() / range)) or 0
    ns.db.fontSize = value
    self.title:SetFont(self.fontName, value, "")
    self.body:SetFont(self.fontName, value, "")
    self.body:SetSpacing(math.max(2, math.floor(value / 4)))
    self:Layout()
    self:QueueLayout()
    if ns.FullText then ns.FullText:Refresh() end
    if ns.Options then ns.Options:Sync() end
end

function Window:Scroll(direction)
    if not self.frame or not self.frame:IsShown() or ns.db.minimized then return end
    self.pendingScrollFraction = nil
    local nextValue = self.scroll:GetVerticalScroll() + direction * 54
    self.scroll:SetVerticalScroll(math.max(0, math.min(self.scrollRange or 0, nextValue)))
end

function Window:SavePosition()
    if self.attachedLayout then return end
    local left, top = self.frame:GetLeft(), self.frame:GetTop()
    if left and top then ns.db.position = { point = "TOPLEFT", x = left, y = top } end
end

function Window:ResetPosition()
    ns.db.position = nil
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", UIParent:GetWidth() * 0.23, 0)
end

function Window:SetMinimized(value, initial)
    self:FinishResize()
    local left, top
    if not initial then left, top = self.frame:GetLeft(), self.frame:GetTop() end
    ns.db.minimized = value == true
    if ns.db.minimized and ns.FullText then ns.FullText:Close() end
    if self.fullTextButton then
        if self.fullTextEligible and not ns.db.minimized then self.fullTextButton:Show() else self.fullTextButton:Hide() end
    end
    self.applyingSize = true
    self.frame:SetResizeBounds(self.attachedLayout and 1 or self.minWidth,
        (ns.db.minimized or self.attachedLayout) and self:GetHeaderHeight() or self.minHeight,
        self.maxWidth, self.maxHeight)
    self.frame:SetHeight(ns.db.minimized and self:GetHeaderHeight() or self.expandedHeight)
    self.applyingSize = false
    if left and top and not self.attachedLayout then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        self:SavePosition()
    end
    if ns.db.minimized then
        self.scroll:Hide()
        self.grip:Hide()
        self:UpdateMinimizeButton()
    else
        self.scroll:Show()
        if not self.attachedLayout then self.grip:Show() end
        self:UpdateMinimizeButton()
    end
    self:Layout()
    self:UpdateHoverControls()
    if not initial and ns.ready then ns.QueueRefresh() end
end

function Window:UpdateMinimizeButton()
    if self.nativeMinimize then
        local state = ns.db.minimized and "expand" or "collapse"
        self.minimizeNormal:SetAtlas("ui-questtrackerbutton-secondary-" .. state)
        self.minimizePushed:SetAtlas("ui-questtrackerbutton-secondary-" .. state .. "-pressed")
        self.minimize:SetText("")
    else
        self.minimize:SetText(ns.db.minimized and "+" or "-")
    end
end

function Window:GetDesiredAttachedHeight()
    if ns.db.minimized then return self.HEADER_HEIGHT end
    return self.HEADER_HEIGHT + self.CONTENT_TOP + (self.naturalContentHeight or self.content:GetHeight()) + self.FOOTER_HEIGHT
end

function Window:SetAttachedLayout(width, height)
    self:FinishResize()
    self.attachedLayout, self.applyingAttachedLayout, self.applyingSize = true, true, true
    self.frame:SetResizeBounds(1, self.HEADER_HEIGHT, self.maxWidth, self.maxHeight)
    self.expandedHeight = math.max(self.HEADER_HEIGHT, height)
    self.frame:SetSize(width, ns.db.minimized and self.HEADER_HEIGHT or self.expandedHeight)
    self.applyingSize = false
    self.grip:Hide()
    self:UpdateHoverControls()
    self:Layout()
    self:QueueLayout()
    self.applyingAttachedLayout = false
end

function Window:RestoreDetachedLayout()
    self.attachedLayout, self.applyingAttachedLayout, self.applyingSize = false, true, true
    if self.frame.SetParent then self.frame:SetParent(UIParent) end
    local size = ns.db.size
    self.expandedHeight = size.height
    self.frame:SetResizeBounds(self.minWidth, ns.db.minimized and self:GetHeaderHeight() or self.minHeight,
        self.maxWidth, self.maxHeight)
    self.frame:SetSize(size.width, ns.db.minimized and self:GetHeaderHeight() or self.expandedHeight)
    self.frame:ClearAllPoints()
    local position = ns.db.position
    if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
        self.frame:SetPoint(position.point == "TOPLEFT" and "TOPLEFT" or "CENTER", UIParent,
            position.point == "TOPLEFT" and "BOTTOMLEFT" or "CENTER", position.x, position.y)
    else self:ResetPosition() end
    self.applyingSize = false
    if not ns.db.minimized then self.grip:Show() end
    self:UpdateHoverControls()
    self:Layout()
    self:QueueLayout()
    self.applyingAttachedLayout = false
end

function Window:Create()
    if ns.db.fontDefaultsVersion ~= 2 then
        ns.db.fontSize = math.max(self.MIN_FONT, math.min(self.MAX_FONT, (tonumber(ns.db.fontSize) or 16) - 2))
        ns.db.fontDefaultsVersion = 2
    end
    local frame = CreateFrame("Frame", "QuestLoreWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    local screenWidth=math.max(160,UIParent:GetWidth()-20)
    self.maxWidth,self.maxHeight=nil,math.max(100,UIParent:GetHeight()-20)
    self.minWidth,self.minHeight=math.min(320,screenWidth),math.min(80,self.maxHeight)
    local function dimension(value, fallback, low, high)
        value = tonumber(value) or fallback
        if value ~= value or value==math.huge or value==-math.huge then value = fallback end
        return math.max(low, high and math.min(high,value) or value)
    end
    local saved = type(ns.db.size) == "table" and ns.db.size or {}
    local width = dimension(saved.width, 380, self.minWidth, self.maxWidth)
    self.expandedHeight = dimension(saved.height, self.EXPANDED_HEIGHT, self.minHeight, self.maxHeight)
    ns.db.size = { width = width, height = self.expandedHeight }
    frame:SetSize(width, self.expandedHeight)
    frame:SetResizable(true)
    frame:SetResizeBounds(self.minWidth, self.minHeight, self.maxWidth, self.maxHeight)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    -- No filled background or outer border: the world remains visible behind
    -- the title and narrative, just as it does behind tracked objectives.
    self.frame = frame
    local position = ns.db.position
    if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
        frame:SetPoint(position.point == "TOPLEFT" and "TOPLEFT" or "CENTER", UIParent,
            position.point == "TOPLEFT" and "BOTTOMLEFT" or "CENTER", position.x, position.y)
    else self:ResetPosition() end

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 0, 0); header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(self.HEADER_HEIGHT)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() if not self.attachedLayout then frame:StartMoving() end end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); self:SavePosition() end)
    self.header = header
    self.fontName = GameFontNormal:GetFont()
    if hasAtlas("UI-QuestTracker-Secondary-Objective-Header") then
        local art = header:CreateTexture(nil, "BACKGROUND")
        -- Native quest headers centre this atlas at its original size. Its
        -- decorative rule extends beyond the module's text column on both
        -- sides; stretching it inside the column incorrectly adds margins.
        art:SetAtlas("UI-QuestTracker-Secondary-Objective-Header", true)
        art:SetPoint("CENTER", header, "CENTER", 0, 0)
        self.headerArt = art
    else
        local divider = header:CreateTexture(nil, "BORDER")
        divider:SetColorTexture(0.65, 0.46, 0.12, 0.75)
        divider:SetHeight(1)
        divider:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        divider:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        self.divider = divider
    end
    local headerLabel = header:CreateFontString(nil, "OVERLAY", "ObjectiveTrackerHeaderFont")
    headerLabel:SetPoint("LEFT", 7, 0); headerLabel:SetPoint("RIGHT", -26, 0)
    headerLabel:SetJustifyH("LEFT"); headerLabel:SetTextColor(unpack(palette.gold))
    headerLabel:SetText("Lore"); shadow(headerLabel)
    self.headerLabel = headerLabel
    headerLabel:SetWordWrap(true)
    if headerLabel.SetMaxLines then headerLabel:SetMaxLines(0) end
    self.wideDivider=header:CreateTexture(nil,"BORDER")
    self.wideDivider:SetColorTexture(0.65,0.46,0.12,0.75)
    self.wideDivider:SetHeight(1)
    self.wideDivider:SetPoint("BOTTOMLEFT",header,"BOTTOMLEFT",0,0)
    self.wideDivider:SetPoint("BOTTOMRIGHT",header,"BOTTOMRIGHT",0,0)
    self.wideDivider:Hide()
    self.minimize = textButton(header, "QuestLoreMinimizeButton", "-", 16)
    self.minimize:SetSize(24, 24); self.minimize:SetPoint("RIGHT", header, "RIGHT", 6, 0)
    self.minimize:SetScript("OnClick", function() self:SetMinimized(not ns.db.minimized) end)
    tooltip(self.minimize, function() return ns.L(ns.db.minimized and "Restaurar ventana" or "Minimizar ventana") end)
    if hasAtlas("ui-questtrackerbutton-secondary-collapse") then
        self.nativeMinimize = true
        self.minimizeNormal = self.minimize:CreateTexture(nil, "ARTWORK")
        self.minimizePushed = self.minimize:CreateTexture(nil, "ARTWORK")
        self.minimizeHighlight = self.minimize:CreateTexture(nil, "HIGHLIGHT")
        for _, texture in ipairs({self.minimizeNormal, self.minimizePushed, self.minimizeHighlight}) do
            texture:SetPoint("CENTER", self.minimize, "CENTER", 0, 0)
            texture:SetSize(16, 16)
        end
        self.minimizeHighlight:SetAtlas("ui-questtrackerbutton-yellow-highlight")
        self.minimize:SetNormalTexture(self.minimizeNormal)
        self.minimize:SetPushedTexture(self.minimizePushed)
        self.minimize:SetHighlightTexture(self.minimizeHighlight, "ADD")
    end
    local scroll = CreateFrame("ScrollFrame", "QuestLoreScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -self.HEADER_HEIGHT - self.CONTENT_TOP)
    scroll:SetPoint("BOTTOMRIGHT", -32, self.FOOTER_HEIGHT)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) self:Scroll(-delta) end)
    scroll:HookScript("OnScrollRangeChanged", function()
        self:SyncScrollbar()
        if not self.layingOut and self.pendingScrollFraction then
            self.scroll:SetVerticalScroll(self.pendingScrollFraction * (self.scrollRange or 0))
        end
    end)
    scroll:HookScript("OnSizeChanged", function() if not self.layingOut then self:QueueLayout() end end)
    scroll:HookScript("OnShow", function() self:SyncScrollbar(); self:QueueLayout() end)
    if scroll.ScrollBar then
        scroll.ScrollBar:HookScript("OnShow", function(bar)
            if not self.needsScroll or ns.db.minimized then bar:Hide() end
        end)
    end
    self.scroll = scroll
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(frame:GetWidth() - 40, 1); scroll:SetScrollChild(content)
    self.content = content
    local title = content:CreateFontString(nil, "OVERLAY", "ObjectiveTrackerLineFont")
    title:SetPoint("TOPLEFT", 0, 0); title:SetWidth(content:GetWidth())
    title:SetJustifyH("LEFT"); title:SetJustifyV("TOP"); title:SetWordWrap(true)
    title:SetTextColor(unpack(palette.gold)); shadow(title)
    if title.SetMaxLines then title:SetMaxLines(0) end
    if title.SetNonSpaceWrap then title:SetNonSpaceWrap(true) end
    self.title = title
    local body = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    body:SetPoint("TOPLEFT", 0, 0); body:SetWidth(content:GetWidth())
    body:SetTextColor(unpack(palette.text)); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true)
    shadow(body)
    if body.SetMaxLines then body:SetMaxLines(0) end
    if body.SetNonSpaceWrap then body:SetNonSpaceWrap(true) end
    self.body = body
    self.justified=ns.Justify.New(content,self.fontName)

    local fullTextButton = textButton(frame, "QuestLoreReadFullTextButton", ns.L("Leer texto completo"))
    fullTextButton:SetSize(190, 22)
    fullTextButton:SetPoint("BOTTOMLEFT", 8, 5)
    fullTextButton:SetScript("OnClick", function() ns.FullText:Open(self.currentID) end)
    fullTextButton:Hide()
    self.fullTextButton = fullTextButton

    local grip = CreateFrame("Button", "QuestLoreResizeGrip", frame)
    grip:SetSize(20, 20); grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    tooltip(grip, "Arrastra para cambiar el tamaño")
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or ns.db.minimized or self.attachedLayout then return end
        local left, top = frame:GetLeft(), frame:GetTop()
        if left and top then
            frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
        self.resizing = true
        self:UpdateHoverControls(true)
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function() self:FinishResize() end)
    grip:SetScript("OnHide", function() self:FinishResize() end)
    self.grip = grip
    grip:SetAlpha(0)
    local function watch(region)
        if not region then return end
        region:HookScript("OnEnter",function() self:UpdateHoverControls(true) end)
        region:HookScript("OnLeave",function() self:UpdateHoverControls() end)
    end
    watch(frame);watch(header);watch(scroll);watch(content);watch(self.minimize);watch(grip);watch(fullTextButton)
    if scroll.ScrollBar then
        watch(scroll.ScrollBar)
        watch(scroll.ScrollBar.ScrollUpButton);watch(scroll.ScrollBar.ScrollDownButton)
    end
    frame:SetScript("OnSizeChanged", function(_, _, height)
        if self.applyingSize then return end
        if not ns.db.minimized then self.expandedHeight = height end
        self:Layout()
        self:QueueLayout()
    end)
    frame:SetScript("OnShow", function() self:UpdateHoverControls(); if ns.ready then ns.QueueRefresh() end end)
    frame:SetScript("OnHide", function() self:FinishResize();self:UpdateHoverControls(false) end)
    self:SetFontSize(ns.db.fontSize)
    self:SetMinimized(ns.db.minimized, true)
end

function Window:Render(model)
    local changedQuest = self.currentKey ~= model.key
    self.currentID, self.currentKey, self.currentTitle = model.id, model.key, model.title
    self:RefreshFullText()
    if changedQuest then self.pendingScrollFraction = nil; self.scroll:SetVerticalScroll(0) end
    self.title:SetText(model.title); self.body:SetText(model.body)
    self:Layout()
    self:QueueLayout()
end

function Window:RefreshFullText()
    if not self.fullTextButton then return end
    local previous = self.fullTextEligible
    self.fullTextEligible = ns.FullText and ns.FullText:CanRead(self.currentID) or false
    self.FOOTER_HEIGHT = self.fullTextEligible and 30 or 8
    self.fullTextButton:SetText(ns.L("Leer texto completo"))
    if self.fullTextEligible and not ns.db.minimized then self.fullTextButton:Show() else self.fullTextButton:Hide() end
    if ns.FullText then ns.FullText:Refresh() end
    if previous ~= self.fullTextEligible then self:QueueLayout() end
end

function Window:Localize()
    -- The tracker always follows the live quest; history lives in Options.
    self:RefreshFullText()
    if self.frame then self:Layout(); self:QueueLayout() end
end
