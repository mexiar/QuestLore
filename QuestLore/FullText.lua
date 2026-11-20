local _, ns = ...
local FullText = {}
ns.FullText = FullText

local function tooltip(button, key)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(ns.L(key)); GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end

function FullText:SaveGeometry()
    if not self.frame or not ns.db then return end
    local left, top = self.frame:GetLeft(), self.frame:GetTop()
    if not finite(left) or not finite(top) then return end
    ns.db.fullTextWindow = {width=self.frame:GetWidth(),height=self.frame:GetHeight(),x=left,y=top}
end

-- Original dialogue exists only in the live API response and visible widgets.
-- It never joins narrative models, history entries or SavedVariables.
function FullText:CanRead(id)
    return type(id) == "number" and ns.API.isActive(id) == true
end

function FullText:Close()
    self.id = nil
    self.context = nil
    if not self.frame then return end
    self.title:SetText("")
    self.body:SetText("")
    self.frame:Hide()
end

function FullText:Layout()
    if not self.frame or self.layingOut then return end
    self.layingOut = true
    self.title:SetWidth(math.max(1, self.frame:GetWidth() - 72))
    self.title:SetHeight(0)
    local titleHeight = math.ceil(self.title:GetStringHeight())
    self.title:SetHeight(titleHeight)
    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 22, -20-titleHeight-14)
    self.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -42, 24)
    local width = math.max(1, self.scroll:GetWidth() - 26)
    self.body:SetWidth(width)
    self.body:SetHeight(0)
    local height = math.ceil(self.body:GetStringHeight()) + 12
    self.content:SetSize(width, math.max(1, height))
    if self.scroll.UpdateScrollChildRect then self.scroll:UpdateScrollChildRect() end
    self.range = math.max(0, height - self.scroll:GetHeight())
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(), self.range))
    if self.scroll.ScrollBar then
        if self.range > 0 then self.scroll.ScrollBar:Show() else self.scroll.ScrollBar:Hide() end
    end
    self.layingOut = false
end

function FullText:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", "QuestLoreFullTextWindow", UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetSize(math.min(520, UIParent:GetWidth() - 24), math.min(580, UIParent:GetHeight() - 40))
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(math.min(320, UIParent:GetWidth()-24), math.min(200, UIParent:GetHeight()-40),
        UIParent:GetWidth()-24, UIParent:GetHeight()-40)
    local saved = type(ns.db.fullTextWindow)=="table" and ns.db.fullTextWindow or {}
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local function dimension(value, fallback, minimum, maximum)
        return math.max(minimum, math.min(maximum, finite(value) and value or fallback))
    end
    local width = dimension(saved.width,520,math.min(320,screenWidth-24),screenWidth-24)
    local height = dimension(saved.height,580,math.min(200,screenHeight-40),screenHeight-40)
    frame:SetSize(width,height)
    if finite(saved.x) and finite(saved.y) then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",
            math.max(0,math.min(screenWidth-width,saved.x)),
            math.max(height,math.min(screenHeight,saved.y)))
    end
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); self:SaveGeometry() end)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32,
        edgeSize=32, insets={left=11,right=12,top=12,bottom=11}})
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 22, -20)
    title:SetPoint("TOPRIGHT", -50, -20)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(true)
    local scroll = CreateFrame("ScrollFrame", "QuestLoreFullTextScrollFrame", frame, "UIPanelScrollFrameTemplate")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT")
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    if body.SetMaxLines then body:SetMaxLines(0) end
    if body.SetNonSpaceWrap then body:SetNonSpaceWrap(true) end
    body:SetSpacing(3)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(32, 32)
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() self:Close() end)
    tooltip(close,"Cerrar")
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(20, 20)
    grip:SetPoint("BOTTOMRIGHT", -7, 7)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    tooltip(grip,"Arrastra para cambiar el tamaño")
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        self:SaveGeometry()
        self:Layout()
    end)
    frame:SetScript("OnSizeChanged", function() self:Layout() end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        scroll:SetVerticalScroll(math.max(0, math.min(self.range or 0, scroll:GetVerticalScroll() - delta * 54)))
    end)
    scroll:SetScript("OnSizeChanged", function() self:Layout() end)
    if scroll.ScrollBar then
        scroll.ScrollBar:HookScript("OnShow", function(bar)
            if (self.range or 0) <= 0 then bar:Hide() end
        end)
    end
    frame:SetScript("OnHide", function()
        frame:StopMovingOrSizing()
        self:SaveGeometry()
        self.id = nil
        self.context = nil
        title:SetText("")
        body:SetText("")
        -- Hiding UIParent (Alt+Z) also fires OnHide without clearing this
        -- frame's own shown flag. Do not restore an empty reader afterwards.
        if frame:IsShown() then frame:Hide() end
    end)
    self.frame, self.title, self.grip = frame, title, grip
    self.scroll, self.content, self.body, self.close = scroll, content, body, close
end

function FullText:Refresh()
    if not self.id then return end
    if not self:CanRead(self.id) or not ns.Window or (self.context~="history" and ns.Window.currentID ~= self.id) then
        self:Close()
        return
    end
    local original = ns.API.ReadOriginal(self.id)
    if not original or original.id ~= self.id then self:Close(); return end
    self.title:SetText(original.title or "")
    local description = original.description or ""
    local objectives = original.objectives or ""
    if type(objectives) == "table" then objectives = table.concat(objectives, "\n") end
    self.body:SetText(description .. (description ~= "" and objectives ~= "" and "\n\n" or "") .. objectives)
    if ns.Window.fontName and ns.db.fontSize then
        self.body:SetFont(ns.Window.fontName, ns.db.fontSize, "")
        self.body:SetSpacing(math.max(2, math.floor(ns.db.fontSize/4)))
    end
    self:Layout()
end

function FullText:Open(id,context)
    if not self:CanRead(id) or not ns.Window or (context~="history" and ns.Window.currentID ~= id) then return false end
    self:Create()
    self.id = id
    self.context = context=="history" and "history" or "live"
    self.scroll:SetVerticalScroll(0)
    self:Refresh()
    if not self.id then return false end
    self.frame:Show()
    self:Layout()
    -- Native wrapped font geometry can settle after showing the panel.
    C_Timer.After(0, function() if self.id == id and self.frame:IsShown() then self:Layout() end end)
    return true
end
