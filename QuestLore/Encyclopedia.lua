local _, ns = ...
local Encyclopedia = {language="es",entries=ns.EncyclopediaData}
ns.Encyclopedia = Encyclopedia
local function finite(value)
    return type(value)=="number" and value==value and value>-math.huge and value<math.huge
end

function Encyclopedia:SaveGeometry()
    if not self.frame or not ns.db then return end
    local frame=self.frame
    local width,height,left,top=frame:GetWidth(),frame:GetHeight(),frame:GetLeft(),frame:GetTop()
    if not finite(width) or not finite(height) or width<=0 or height<=0 or not finite(left) or not finite(top) then return end
    -- Save in UIParent units, including if another addon scaled this frame.
    local scale=frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local ratio=finite(scale) and scale>0 and finite(parentScale) and parentScale>0 and scale/parentScale or 1
    if not finite(ratio) or ratio<=0 then return end
    width,height,left,top=width*ratio,height*ratio,left*ratio,top*ratio
    if not finite(width) or not finite(height) or width<=0 or height<=0 or not finite(left) or not finite(top) then return end
    ns.db.encyclopediaWindow={width=width,height=height,x=left,y=top}
end
-- Index localized aliases by their first three bytes. Matching visits only word
-- starts in the displayed text, not every alias in the encyclopedia.
local localized={es=Encyclopedia.entries,en={},fr={},de={},pt={},pl={},ru={}}
local indexes={es={},en={}}
local englishOwners,polishAmbiguousForms
local polishEndings={"owi","em","a"}
local polishApostrophes={"", "'", "’", "‘"}
local function polishStemEligible(alias,apostrophe)
    if #alias<4 then return false end
    if apostrophe~="" then return alias:sub(-1):match("[A-Za-z]")~=nil end
    return alias:sub(-1):match("[bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]")~=nil
end
for id,entry in pairs(Encyclopedia.entries) do
    if entry.en then
        local english=entry.en
        english.kind=entry.kind;english.references=entry.references;english.questIDs=entry.questIDs
        localized.en[id]=english
        for _,language in ipairs({"fr","de","pt","pl","ru"}) do
            local translated=entry[language]
            if translated then
                translated.kind=entry.kind;translated.references=entry.references;translated.questIDs=entry.questIDs
                translated.aliases=english.aliases;translated.aliasQuestIDs=english.aliasQuestIDs
                localized[language][id]=translated
            end
        end
    end
end
for _,language in ipairs({"es","en"}) do
    local entries=localized[language]
    local groups={}
    for id,entry in pairs(entries) do
        for _,alias in ipairs(entry.aliases) do
            groups[alias]=groups[alias] or {}
            groups[alias][id]=true
        end
    end
    for alias,owners in pairs(groups) do
        local prefix=alias:sub(1,3)
        indexes[language][prefix]=indexes[language][prefix] or {}
        local bucket=indexes[language][prefix]
        local count=0;for _ in pairs(owners) do count=count+1 end
        bucket[#bucket+1]={text=alias,owners=owners,multiple=count>1}
    end
    if language=="en" then englishOwners=groups end
    for _,bucket in pairs(indexes[language]) do
        table.sort(bucket,function(a,b) if #a.text==#b.text then return a.text<b.text end return #a.text>#b.text end)
    end
end
-- A Polish case form must not steal the exact name of a different character.
-- Keep these rare collisions plain rather than guessing from spelling alone.
polishAmbiguousForms={}
for stem,owners in pairs(englishOwners) do
    local character=false
    for id in pairs(owners) do if localized.en[id].kind=="Personaje" then character=true;break end end
    if character then
        for _,apostrophe in ipairs(polishApostrophes) do
            if polishStemEligible(stem,apostrophe) then
                for _,ending in ipairs(polishEndings) do
                    local form=stem..apostrophe..ending
                    for other in pairs(englishOwners[form] or {}) do
                        if not owners[other] then polishAmbiguousForms[form]=true;break end
                    end
                end
            end
        end
    end
end
englishOwners=nil
-- These translations deliberately retain English proper names. Reuse their
-- immutable index and identity rules rather than allocating additional indexes.
for _,language in ipairs({"fr","de","pt","pl","ru"}) do
    if next(localized[language]) then indexes[language]=indexes.en end
end
Encyclopedia.localized=localized
local function word(character) return character~="" and character:find("[%w_\128-\255]")~=nil end
local apostrophes={"'","’","‘"}
local punctuation={"—","–","…","«","»","“","”","¡","¿","\194\160"}
local function leftBoundary(text,first,language)
    for _,mark in ipairs(apostrophes) do
        if text:sub(first-#mark,first-1)==mark then
            -- French elisions precede proper names (l'Alliance, d'Orgrimmar).
            -- Only complete grammatical prefixes qualify, never fragments of
            -- names such as Jin'Elune or Elune'ara.
            if language=="fr" then
                local prefixEnd=first-#mark-1
                for _,prefix in ipairs({"l","L","d","D","qu","Qu","QU"}) do
                    local start=prefixEnd-#prefix+1
                    if text:sub(start,prefixEnd)==prefix and not word(text:sub(start-1,start-1)) then return true end
                end
            end
            return not word(text:sub(first-#mark-1,first-#mark-1))
        end
    end
    for _,mark in ipairs(punctuation) do if text:sub(first-#mark,first-1)==mark then return true end end
    return not word(text:sub(first-1,first-1))
end
local function rightBoundary(text,last,language)
    -- German proper names may take a bare genitive s (Orgrimmars, Thralls).
    -- Only one terminal s qualifies; other languages and longer word suffixes
    -- keep literal boundaries. The linked span remains the canonical name.
    if language=="de" and text:sub(last+1,last+1)=="s" and rightBoundary(text,last+1) then return true end
    for _,mark in ipairs(apostrophes) do
        if text:sub(last+1,last+#mark)==mark then
            local following=last+#mark+1
            local nextChar=text:sub(following,following)
            return not word(nextChar) or (nextChar=="s" and not word(text:sub(following+1,following+1)))
        end
    end
    for _,mark in ipairs(punctuation) do if text:sub(last+1,last+#mark)==mark then return true end end
    return not word(text:sub(last+1,last+1))
end
local function polishEnding(text,last,alias)
    for _,apostrophe in ipairs(polishApostrophes) do
        if polishStemEligible(alias,apostrophe) then
            for _,ending in ipairs(polishEndings) do
                local suffix=apostrophe..ending
                if text:sub(last+1,last+#suffix)==suffix and rightBoundary(text,last+#suffix) then return true end
            end
        end
    end
    return false
end
local function englishContext(questID)
    local row=questID and ns.Narratives and ns.Narratives[questID]
    local body=row and row.en
    local ids={}
    if type(body)=="string" then
        -- Resolve the original with the same longest-name and scope rules.
        -- A short name inside someone else's full name is not authorization.
        for _,span in ipairs(Encyclopedia.FindSpans(body,"en",questID)) do ids[span.id]=true end
    end
    return ids
end
function Encyclopedia.FindSpans(text,language,questID,references)
    local index=indexes[language]
    if not index or type(text)~="string" then return {} end
    text=text:gsub("\r\n","\n"):gsub("\r","\n")
    local candidates={}
    local englishIDs
    local position=1
    while position<=#text do
        local bucket=index[text:sub(position,position+2)]
        if bucket and leftBoundary(text,position,language) then
            for _,alias in ipairs(bucket) do
                local last=position+#alias.text-1
                local exact=text:sub(position,last)==alias.text
                local boundary=exact and rightBoundary(text,last,language)
                local polishForm=exact and not boundary and language=="pl" and polishEnding(text,last,alias.text)
                if exact and (boundary or polishForm) then
                    local selected,ambiguous
                    for id in pairs(alias.owners) do
                        local entry=localized[language][id]
                        if entry then
                            local scope=(entry.aliasQuestIDs and entry.aliasQuestIDs[alias.text]) or entry.questIDs
                            local reviewed=(scope and scope[questID]) or (references and references[id])
                            local eligible=reviewed or (not alias.multiple and not scope)
                            -- Only undeformed character-name stems in a proven
                            -- narrative or explicitly reviewed context qualify.
                            local caseAllowed=not polishForm
                            if eligible and polishForm and entry.kind=="Personaje" then
                                if reviewed then caseAllowed=true else
                                    englishIDs=englishIDs or englishContext(questID)
                                    caseAllowed=englishIDs[id]
                                end
                            end
                            if eligible and caseAllowed then
                                if selected then ambiguous=true else selected=id end
                            end
                        end
                    end
                    if language=="pl" and polishAmbiguousForms[alias.text] then ambiguous=true end
                    candidates[#candidates+1]={first=position,last=last,id=selected and not ambiguous and selected or false,language=language}
                    break
                end
            end
        end
        position=position+1
    end
    -- Prefer the longest entity across overlapping phrases: “the Light” must
    -- not steal the start of “Light’s Hope”. Ambiguous longer names reserve
    -- their span so a shorter, different definition cannot replace them.
    table.sort(candidates,function(a,b)
        local lengthA,lengthB=a.last-a.first,b.last-b.first
        if lengthA==lengthB then return a.first<b.first end
        return lengthA>lengthB
    end)
    local chosen,found={},{}
    for _,candidate in ipairs(candidates) do
        local overlap=false
        for _,other in ipairs(chosen) do
            if candidate.first<=other.last and candidate.last>=other.first then overlap=true;break end
        end
        if not overlap then
            chosen[#chosen+1]=candidate
            if candidate.id then found[#found+1]=candidate end
        end
    end
    table.sort(found,function(a,b) return a.first<b.first end)
    return found
end
function Encyclopedia:Layout()
    if not self.frame then return end
    local width=math.max(1,self.frame:GetWidth()-64)
    self.content:SetWidth(width);self.title:SetWidth(width);self.title:SetHeight(0)
    self.body:SetFont(ns.Window.fontName,ns.db.fontSize,"")
    self.body:SetWidth(width);self.body:SetHeight(0)
    local h=math.ceil(self.title:GetStringHeight())+26
    self.body:ClearAllPoints();self.body:SetPoint("TOPLEFT",0,-h)
    local bodyHeight
    if self.spans and #self.spans>0 then
        self.body:Hide()
        bodyHeight=self.rich:Layout(self.body:GetText() or "",width,ns.db.fontSize,3,self.spans,true,h)
    else
        self.body:Show();self.rich:Hide()
        bodyHeight=math.ceil(self.body:GetStringHeight())
    end
    self.content:SetHeight(h+bodyHeight+16)
    if self.scroll.UpdateScrollChildRect then self.scroll:UpdateScrollChildRect() end
    self.range=math.max(0,self.content:GetHeight()-self.scroll:GetHeight())
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(),self.range))
    if self.scroll.ScrollBar then if self.range>0 then self.scroll.ScrollBar:Show() else self.scroll.ScrollBar:Hide() end end
end
function Encyclopedia:Localize()
    if not self.frame then return end
    self.heading:SetText(ns.L("Enciclopedia"))
    local entry=self.entries[self.currentID]
    if entry then self.kind:SetText(ns.L(entry.kind)) end
    self:Layout()
end
function Encyclopedia:Create()
    if self.frame then return end
    local frame=CreateFrame("Frame","QuestLoreEncyclopedia",UIParent,"BackdropTemplate")
    local screenWidth,screenHeight=UIParent:GetWidth(),UIParent:GetHeight()
    if not finite(screenWidth) or screenWidth<=0 then screenWidth=1920 end
    if not finite(screenHeight) or screenHeight<=0 then screenHeight=1080 end
    local maxWidth,maxHeight=math.max(1,screenWidth-24),math.max(1,screenHeight-40)
    local minWidth,minHeight=math.min(320,maxWidth),math.min(240,maxHeight)
    local saved=type(ns.db.encyclopediaWindow)=="table" and ns.db.encyclopediaWindow or {}
    local function dimension(value,fallback,minimum,maximum)
        return math.max(minimum,math.min(maximum,finite(value) and value or fallback))
    end
    local width=dimension(saved.width,680,minWidth,maxWidth)
    local height=dimension(saved.height,460,minHeight,maxHeight)
    frame:Hide();frame:SetSize(width,height)
    frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
    if finite(saved.x) and finite(saved.y) then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",math.max(0,math.min(screenWidth-width,saved.x)),math.max(height,math.min(screenHeight,saved.y)))
    end
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function() frame:StartMoving() end)
    frame:SetScript("OnDragStop",function() frame:StopMovingOrSizing();self:SaveGeometry() end)
    frame:SetResizable(true);frame:SetResizeBounds(minWidth,minHeight,maxWidth,maxHeight)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
    self.frame=frame
    self.heading=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");self.heading:SetPoint("TOPLEFT",22,-20)
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5)
    close:SetScript("OnClick",function() frame:Hide() end);self.close=close
    local scroll=CreateFrame("ScrollFrame","QuestLoreEncyclopediaScroll",frame,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",22,-52);scroll:SetPoint("BOTTOMRIGHT",-32,24)
    self.scroll=scroll
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(400,1);scroll:SetScrollChild(content);self.content=content
    self.title=content:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");self.title:SetPoint("TOPLEFT",0,0)
    self.title:SetJustifyH("LEFT");self.title:SetWordWrap(true)
    self.kind=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");self.kind:SetPoint("TOPLEFT",self.title,"BOTTOMLEFT",0,-5)
    self.body=content:CreateFontString(nil,"OVERLAY","GameFontHighlight");self.body:SetJustifyH("LEFT");self.body:SetWordWrap(true)
    self.body:SetFont(ns.Window.fontName,ns.db.fontSize,"");self.body:SetSpacing(3)
    self.rich=ns.Justify.New(content,ns.Window.fontName,function(delta)
        scroll:SetVerticalScroll(math.max(0,math.min(self.range or 0,scroll:GetVerticalScroll()-delta*48)))
    end)
    scroll:EnableMouseWheel(true);scroll:SetScript("OnMouseWheel",function(_,delta) scroll:SetVerticalScroll(math.max(0,math.min(self.range or 0,scroll:GetVerticalScroll()-delta*48))) end)
    local grip=CreateFrame("Button",nil,frame);grip:SetSize(20,20);grip:SetPoint("BOTTOMRIGHT",-7,7)
    self.grip=grip
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then frame:StartSizing("BOTTOMRIGHT") end end)
    grip:SetScript("OnMouseUp",function() frame:StopMovingOrSizing();self:SaveGeometry();self:Layout() end)
    frame:SetScript("OnSizeChanged",function() self:Layout() end)
    frame:SetScript("OnHide",function() frame:StopMovingOrSizing();self:SaveGeometry() end)
    self:Localize()
end
function Encyclopedia:Open(id,language)
    language=language or self.language or "es"
    local entries=localized[language]
    local entry=id and entries and entries[id]
    if not entry then return false end
    self:Create();self.currentID=id;self.language=language;self.entries=entries
    self.title:SetText(entry.title);self.body:SetText(entry.body)
    self.spans={}
    local context={[id]=true}
    for target in pairs(entry.references or {}) do context[target]=true end
    for _,span in ipairs(self.FindSpans(entry.body,language,nil,context)) do
        if entry.references and entry.references[span.id] and span.id~=id then self.spans[#self.spans+1]=span end
    end
    self.body:SetFont(ns.Window.fontName,ns.db.fontSize,"")
    self:Localize();self.scroll:SetVerticalScroll(0);self.frame:Show()
    return true
end
