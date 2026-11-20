local _, ns = ...
local Justify = {}
Justify.__index = Justify
ns.Justify = Justify

-- WoW FontStrings expose left/center/right alignment, not full justification.
-- Keep a reusable word pool and distribute inter-word space on wrapped lines.
function Justify.New(parent, font, onScroll)
    local measure = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    measure:Hide()
    return setmetatable({parent=parent,font=font,measure=measure,words={},lines={},onScroll=onScroll},Justify)
end

function Justify:Hide()
    for _, word in ipairs(self.words) do word:Hide();if word.entityButton then word.entityButton:Hide() end end
end

function Justify:Layout(text, width, size, spacing, spans, leftAligned, offset, measureOnly)
    width = math.max(1,width)
    offset=offset or 0
    measureOnly=measureOnly==true
    if self.text==text and self.width==width and self.size==size and self.spacing==spacing and self.spans==spans and self.leftAligned==leftAligned and self.offset==offset and self.measureOnly==measureOnly then
        if measureOnly then return self.height end
        for i,word in ipairs(self.words) do
            if i<=self.used then word:Show();if word.entityID then word.entityButton:Show() end
            else word:Hide();if word.entityButton then word.entityButton:Hide() end end
        end
        return self.height
    end
    self.spans,self.leftAligned,self.offset,self.measureOnly=spans,leftAligned,offset,measureOnly
    self.text,self.width,self.size,self.spacing = text,width,size,spacing
    self.used,self.lines = 0,{}
    local measure = self.measure
    measure:SetFont(self.font,size,"");measure:SetHeight(0);measure:SetWidth(width)
    measure:SetWordWrap(false);measure:SetSpacing(0)
    measure:SetText("Ag")
    local lineHeight=math.ceil(measure:GetStringHeight())
    local function wordWidth(value)
        measure:SetWidth(0);measure:SetText(value)
        if measure.GetUnboundedStringWidth then return measure:GetUnboundedStringWidth() end
        return measure:GetStringWidth()
    end
    local space=math.max(1,wordWidth("x x")-wordWidth("xx"))
    local y=0
    local function place(value,x,atY,wordWidth,wrap,entityID,entityLanguage)
        self.used=self.used+1
        if measureOnly then return end
        local region=self.words[self.used]
        if not region then
            region=self.parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
            region:SetTextColor(1,1,1);region:SetJustifyH("LEFT");region:SetJustifyV("TOP")
            if region.SetMaxLines then region:SetMaxLines(0) end
            if region.SetNonSpaceWrap then region:SetNonSpaceWrap(true) end
            if region.SetShadowColor then region:SetShadowColor(0,0,0,1);region:SetShadowOffset(1,-1) end
            self.words[self.used]=region
        end
        region:SetFont(self.font,size,"");region:SetSpacing(spacing)
        region:SetWordWrap(wrap);region:SetHeight(0);region:SetWidth(wordWidth)
        region:ClearAllPoints();region:SetPoint("TOPLEFT",self.parent,"TOPLEFT",x,-atY-offset)
        region.entityID=entityID;region.entityLanguage=entityLanguage
        region:SetTextColor(1,entityID and 0.82 or 1,entityID and 0 or 1)
        region:SetText(value)
        if entityID then
            if not region.entityButton then
                local hit=CreateFrame("Button",nil,self.parent)
                hit:SetScript("OnClick",function()
                    if region.entityID then ns.Encyclopedia:Open(region.entityID,region.entityLanguage) end
                end)
                hit:EnableMouseWheel(true)
                hit:SetScript("OnMouseWheel",function(_,delta)
                    if self.onScroll then self.onScroll(delta) else ns.Window:Scroll(-delta) end
                end)
                region.entityButton=hit
            end
            local hit=region.entityButton
            hit:ClearAllPoints();hit:SetPoint("TOPLEFT",self.parent,"TOPLEFT",x,-atY-offset)
            hit:SetSize(wordWidth,wrap and math.ceil(region:GetStringHeight()) or lineHeight)
            hit:Show()
        elseif region.entityButton then region.entityButton:Hide() end
        region:Show()
    end
    local paragraphStart=1
    for paragraph in (text:gsub("\r\n","\n"):gsub("\r","\n").."\n"):gmatch("(.-)\n") do
        local line,total={},0
        local function flush(justified)
            if #line==0 then return end
            justified=justified and not leftAligned
            local gap=(justified and #line>1) and (width-total)/(#line-1) or space
            local x=0
            local first=self.used+1
            for _,word in ipairs(line) do
                place(word.text,x,y,word.width,false,word.entityID,word.entityLanguage)
                x=x+word.width+gap
            end
            self.lines[#self.lines+1]={first=first,last=self.used,y=y,height=lineHeight,justified=justified and #line>1 or false}
            y=y+lineHeight+spacing;line,total={},0
        end
        local any=false
        for position,value in paragraph:gmatch("()(%S+)") do
            any=true
            local entityID,entityLanguage
            local first,last=paragraphStart+position-1,paragraphStart+position+#value-2
            for _,span in ipairs(spans or {}) do
                if first<=span.last and last>=span.first then entityID=span.id;entityLanguage=span.language;break end
            end
            local w=math.ceil(wordWidth(value))
            if w>width then
                flush(true)
                -- An unusually long token wraps naturally on its own line,
                -- preserving every UTF-8 character without manual splitting.
                measure:SetWordWrap(true);measure:SetWidth(width);measure:SetText(value)
                if measure.SetNonSpaceWrap then measure:SetNonSpaceWrap(true) end
                measure:SetSpacing(spacing)
                local h=math.ceil(measure:GetStringHeight())
                measure:SetWordWrap(false);measure:SetSpacing(0)
                place(value,0,y,width,true,entityID,entityLanguage)
                self.lines[#self.lines+1]={first=self.used,last=self.used,y=y,height=h,justified=false}
                y=y+h+spacing
            else
                if #line>0 and total+#line*space+w>width then flush(true) end
                line[#line+1]={text=value,width=w,entityID=entityID,entityLanguage=entityLanguage};total=total+w
            end
        end
        flush(false)
        if not any then y=y+lineHeight+spacing end
        paragraphStart=paragraphStart+#paragraph+1
    end
    self.height=math.max(0,y-spacing)
    if measureOnly then self:Hide();return self.height end
    for i=self.used+1,#self.words do self.words[i]:Hide();if self.words[i].entityButton then self.words[i].entityButton:Hide() end end
    return self.height
end
