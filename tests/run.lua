local root = arg[1] or "."
local count = 0
local function check(condition, message)
    count = count + 1
    if not condition then error("FAILED: " .. message, 2) end
end
local function equal(a, b, message) check(a == b, message .. " (" .. tostring(a) .. " ~= " .. tostring(b) .. ")") end
local function loadModule(file, ns) assert(loadfile(root .. "/QuestLore/" .. file))("QuestLore", ns) end
assert(loadfile(root .. "/tests/source_api.lua"))(root)
local ns = {}
loadModule("Text.lua", ns)
loadModule("Locale.lua", ns)
loadModule("Stories.lua", ns)
loadModule("Stories_Undead.lua", ns)
loadModule("Stories_ForeverTirisfal.lua", ns)
loadModule("Narratives.lua", ns)
loadModule("Origins_Stories.lua", ns)
loadModule("Origins.lua", ns)
loadModule("Model.lua", ns)
loadModule("History.lua", ns)

equal(ns.Text.Fold("CORRUPCIÓN Y MUERTE ÁÉÍÓÚ Ñ"), "corrupcion y muerte aeiou n", "Spanish folding")
equal(ns.Text.Clean("|cffff0000Hola|r |Hquest:1|h[misión]|h |Ticon:16|t$B$n"),
    "Hola [misión]\n\naventurero", "safe game markup stripping")
equal(ns.Text.Clean("$Gpreparado:preparada; $C $R"), "preparado aventurero viajero", "quest tokens")
check(not ns.Text.Clean("Una $1oa desconocida"):find("%$"), "unresolved tokens removed")
equal(ns.Text.Clean("<Recuperás un colgante de la caja.>"),"Recuperás un colgante de la caja.","quest action text remains available as narrative context")
local narrative = "Saludos. Los cultivos están envenenados y el pueblo se quedará sin alimento. " ..
    "Necesitamos investigar el agua para proteger a las familias. Mata a 12 enemigos y vuelve con 8 flores."
local extracted, kind = ns.Text.Extract(narrative)
equal(kind, "extract", "description fallback is labeled an extract")
check(extracted:find("cultivos", 1, true), "fallback retains conflict")
check(extracted:find("investigar", 1, true), "fallback retains purpose")
check(not extracted:find("12", 1, true), "fallback excludes mechanical count")
local basic, basicKind = ns.Text.Extract("Mata a 12 enemigos.")
equal(basicKind, "description", "mechanical text is not presented as extra lore")
equal(basic, "Mata a 12 enemigos.", "mechanical text remains truthful")
equal(ns.Model.Build(nil, "esMX").kind, "empty", "empty log")
equal(ns.Model.Build({id = 1, loading = true}, "esMX").kind, "loading", "loading state")
equal(ns.Model.Build({id = 1}, "esMX").kind, "missing", "missing text is not invented")
local unknown = ns.Model.Build({id = 999999, title = "Una misión", description = narrative}, "esMX")
equal(unknown.kind, "extract", "unwritten quest gets meaningful extraction")
local quest = {id = 12, title = "La Milicia Popular", description = "La Milicia Popular solo quiere defender estas tierras."}
equal(ns.Model.Build(quest, "esMX").kind, "story", "esMX story")
equal(ns.Model.Build(quest, "esES").kind, "story", "esES story")
check(ns.Model.Build(quest, "enUS").body:find("People",1,true), "English narrative is available for a covered quest")
quest.description = "El rey te envía a una isla nueva."
check(ns.Model.Build(quest, "esMX").kind ~= "story", "reused ID with changed lore never gets stale story")
quest.description = ""
equal(ns.Model.Build(quest, "esMX").kind,"story", "audited bilingual story is available before text loads")

local active, visible, selected, superTracked, watched = {[12]=true,[13]=true,[99]=true},true,12,13,{99}
local api = {
    isActive = function(id) return active[id] == true end,
    isLogVisible = function() return visible end,
    selected = function() return selected end,
    superTracked = function() return superTracked end,
    watched = function() return watched end,
}
equal(ns.Model.Resolve(api), 12, "visible quest details override supertracking")
visible = false
equal(ns.Model.Resolve(api), 13, "hidden stale selection never overrides active navigation")
superTracked = 0
equal(ns.Model.Resolve(api), 99, "watch list fallback")
watched = { -1, 0, 13, 99 }
equal(ns.Model.Resolve(api), 13, "first valid watch in client order")
watched = {}
equal(ns.Model.Resolve(api), nil, "no automatic untracked quest chosen")
visible, selected = true, 888
equal(ns.Model.Resolve(api), nil, "completed and abandoned quests ignored")

local intro = ns.Origins.Build({race="NightElf",class="DRUID",raceName="Elfa de la noche",className="Druida",faction="Alliance"})
equal(intro.kind,"origins","race and class introduction is readable context")
check(not intro.body:find("\n",1,true),"intro is one integrated narrative rather than race and class sections")
check(intro.body:find("Elune",1,true),"night elf intro includes cultural context")
check(intro.body:find("equilibrio natural",1,true),"druid intro includes class context")
local undead = ns.Origins.Build({race="Undead",class="PALADIN",faction="Horde"})
check(undead.body:find("Como paladín",1,true) and undead.body:find("Luz",1,true),"Forsaken paladin opening combines starting racial and class context")
check(undead.key:find("Scourge",1,true),"Undead alias maps to actual client race token")
local skyA=ns.Origins.Build({race="Skyborne",class="MAGE",faction="Alliance"})
local skyH=ns.Origins.Build({race="Skyborne",class="SHAMAN",faction="Horde"})
check(skyA.body~=skyH.body,"Skyborne factions have distinct opening context")
check(skyA.body:find("Alta Orden",1,true),"Alliance Skyborne uses arcane tradition")
check(skyH.body:find("elementales",1,true),"Horde Skyborne uses elemental tradition")
equal(ns.Origins.Build({}).kind,"missing","unknown player data does not invent biography")
for _,race in ipairs({"Human","Dwarf","Gnome","NightElf","Orc","Tauren","Troll","Scourge","Skyborne"}) do
    local model=ns.Origins.Build({race=race,class="WARRIOR"})
    equal(model.kind,"origins","opening context supported for "..race)
end

local a=ns.Model.Build({id=12,title="A",description="La Milicia Popular quiere defender las tierras."},"esMX")
local b=ns.Model.Build({id=13,title="B",description="Los saqueadores Defias amenazan a la Milicia."},"esMX")
local c=ns.Model.Build({id=99,title="C",description=narrative},"esMX")
-- A third authored fixture exercises navigation; raw-source retention is tested below.
c.kind,c.source="story","Authored test fixture"
local history=ns.History.New()
check(not history:Move(-1),"empty history cannot move backwards")
check(not history:Move(1),"empty history cannot move forwards")
history:Update(ns.Model.Build({id=999888,loading=true},"esMX"))
equal(#history.entries,0,"loading pages are not archived")
history:Update(intro);history:Update(intro)
equal(#history.entries,1,"introduction is archived once across duplicate events")
history:Update(a);history:Update(a)
equal(#history.entries,2,"same quest updates do not flood history")
check(history:Move(-1),"back reaches race/class introduction")
equal(history:Current().key,intro.key,"introduction remains readable after accepting a quest")
history:Update(b)
equal(history:Current().key,intro.key,"live quest change never steals a historical page")
equal(#history.entries,2,"unseen live pages are not added while browsing")
check(history:State().newLive,"new live context is indicated")
check(history:Move(1),"forward restores next historical page")
equal(history:Current().id,12,"forward does not jump to an unseen live quest")
check(not history:Move(1),"forward disabled at last saved page")
history:GoLive()
equal(history:Current().id,13,"Actual returns to live quest")
equal(#history.entries,3,"Actual archives new page when shown")
check(not history:State().canForward,"no forward destination while live")
history:Update(c);history:Update(a)
equal(#history.entries,4,"revisiting a known quest does not append a new page")
equal(history:State().index,2,"revisiting opens the quest's original page")
check(history:State().canForward,"a live quest in the middle retains forward navigation")
history:Move(1)
equal(history:Current().id,13,"forward follows the unique first-seen page order")
local restored=ns.History.New(history.entries)
equal(#restored.entries,4,"persisted unique history is restored")
history.entries[1].body="changed after snapshot"
check(restored.entries[1].body~="changed after snapshot","history snapshots do not alias saved tables")
local bounded=ns.History.New()
for i=1,205 do
    bounded:Update({key="quest:"..(900000+i),id=900000+i,title="Misión",body="Relato "..i,kind="story",source="Texto"})
end
equal(#bounded.entries,200,"history is bounded across unique pages")
equal(bounded.entries[1].id,900006,"history keeps the latest 200 unique quests")
local migrated=ns.History.New({
 {key="quest:999001",id=999001,title="A",body="Anterior",source="",kind="story"},
 {key="quest:999002",id=999002,title="B",body="Otro",source="",kind="story"},
 {key="quest:999001",id=999001,title="A",body="Actualizado",source="",kind="story"},
})
equal(#migrated.entries,2,"old duplicate visits collapse during reload")
equal(migrated.entries[1].body,"Actualizado","migration retains latest content at the original position")
history:Update(c,true)
equal(history:Current().id,99,"explicit quest selection exits history browsing")
equal(#history.entries,4,"explicit selection reuses the existing page")
local invalid=ns.History.New({{key="bad",kind="story"},intro})
equal(#invalid.entries,1,"invalid saved entries do not break navigation")
local noRaw=ns.History.New({
 {key="quest:999001",id=999001,title="A",body="Old full original",source="",kind="description"},
 {key="quest:999002",id=999002,title="B",body="Old excerpt",source="",kind="extract"},
})
equal(#noRaw.entries,0,"raw descriptions and source excerpts are not retained in saved history")
noRaw:Update({key="quest:999001",id=999001,title="A",body="Live full original",source="",kind="description"})
equal(#noRaw.entries,0,"live raw descriptions never enter saved history")
noRaw:Update({key="quest:999003",id=999003,title="C",body="Authored summary",source="",kind="story",description="Private original",fullText="Private original"})
check(noRaw.entries[1].description==nil and noRaw.entries[1].fullText==nil,"history whitelist excludes original-text fields")

-- Runtime harness: execute the actual adapter, native window and event wiring
-- on a strict subset of the WoW UI API, with simulated asynchronous events.
local frames, timers, now, hooks, requests = {}, {}, 0, {}, {}
local logged = {
    [12] = { title = "La Milicia Popular", description = "La Milicia Popular quiere defender los campos." },
    [13] = { title = "La Milicia Popular II", description = "Los saqueadores Defias amenazan a la Milicia." },
    [99] = { title = "Una misión desconocida", description = narrative },
}
local tracked, logVisible, selectedID = 12, false, 13

local Methods = {}
function Methods:SetScript(name, fn) self.scripts[name] = fn end
function Methods:HookScript(name, fn)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; fn(...) end
end
function Methods:RegisterEvent(name) self.events[name] = true end
function Methods:Show() self.shown = true end
function Methods:Hide()
    local shown = self.shown
    self.shown = false
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Methods:IsShown() return self.shown ~= false end
function Methods:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
function Methods:SetPoint(...)
    self.point={...};self.points=self.points or {};self.points[self.point[1]]=self.point
end
function Methods:ClearAllPoints() self.point=nil;self.points={} end
function Methods:SetSize(w,h) self.width, self.height = w,h end
function Methods:SetWidth(w) self.width = w end
function Methods:SetHeight(h) self.height = h end
function Methods:GetWidth() return self.width or 380 end
function Methods:GetHeight() return self.height or 310 end
function Methods:GetCenter() return 960,540 end
function Methods:GetLeft() return 770 end
function Methods:GetTop() return 695 end
function Methods:SetParent(parent) self.parent=parent end
function Methods:GetParent() return self.parent end
function Methods:GetEffectiveScale() return self.scale or 1 end
function Methods:SetScale(value) self.scale=value end
function Methods:SetText(t) self.text = t end
function Methods:GetText() return self.text end
function Methods:GetStringWidth()
    local width=#((self.text or ""):gsub("[\128-\191]", ""))*(self.fontSize or 16)*0.5
    return self.width and self.width>0 and math.min(width,self.width) or width
end
function Methods:SetEnabled(enabled) self.enabled = enabled end
function Methods:SetAlpha(value) self.alpha=value end
function Methods:SetFont(font,size,flags) self.fontName,self.fontSize,self.fontFlags=font,size,flags end
function Methods:GetFont() return "Interface/Fonts/FRIZQT__.TTF", 14, "" end
function Methods:GetStringHeight()
    local size=self.fontSize or 16
    local columns=(self.wordWrap==false or self.width==0) and math.huge or math.max(1,math.floor((self.width or 336)/(size*0.5)))
    local lines=0
    for line in ((self.text or "").."\n"):gmatch("(.-)\n") do
        local characters=#(line:gsub("[\128-\191]", ""))
        lines=lines+math.max(1,math.ceil(characters/columns))
    end
    local height=lines*(size+4)+math.max(0,lines-1)*(self.spacing or 0)
    if self.fontString and self.height and self.height>0 then return math.min(height,self.height) end
    return height
end
function Methods:SetVerticalScroll(n) self.scroll = n end
function Methods:GetVerticalScroll() return self.scroll or 0 end
function Methods:GetVerticalScrollRange() return self.range or 600 end
function Methods:SetScrollChild(child) self.child = child end
function Methods:UpdateScrollChildRect()
    if self.dynamicRange then self.range=math.max(0,self.child:GetHeight()-(self.viewportHeight or 176)) end
end
for _, name in ipairs({"SetClampedToScreen", "SetFrameStrata", "SetMovable", "EnableMouse", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
    "SetTextColor", "SetColorTexture", "EnableMouseWheel", "SetJustifyH", "SetJustifyV",
    "SetWordWrap", "SetSpacing", "SetNormalTexture", "SetPushedTexture", "SetDisabledTexture",
    "SetHighlightTexture", "SetResizable", "SetAtlas", "SetTexCoord", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetShadowColor", "SetShadowOffset"}) do Methods[name] = function() end end
function Methods:SetTextColor(...) self.textColor={...} end
function Methods:SetJustifyH(value) self.justifyH=value end
function Methods:SetSpacing(value) self.spacing=value end
function Methods:SetWordWrap(value) self.wordWrap=value end
function Methods:SetBackdrop(value) self.backdrop=value end
function Methods:SetChecked(checked) self.checked=checked end
function Methods:SetValue(value)
    local changed=self.value~=value
    self.value=value
    if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
function Methods:SetResizeBounds(...) self.resizeBounds={...} end
function Methods:StartSizing(corner) self.sizingCorner=corner end
local function object(parent)
    local obj = setmetatable({scripts={},events={},parent=parent}, {__index=Methods})
    frames[#frames+1] = obj
    return obj
end
function CreateFrame(_,name,parent,template) local obj=object(parent);if name then _G[name]=obj end;if template=="UIPanelScrollFrameTemplate" then obj.ScrollBar=object(obj) end;if template=="OptionsSliderTemplate" then obj.Low=object(obj);obj.High=object(obj) end;return obj end
function Methods:CreateFontString(_,_,template) local font=object(self);font.fontString=true;font.fontTemplate=template;return font end
function Methods:CreateTexture() return object(self) end
UIParent = object()
UIParent:SetSize(1920,1080)
GameFontNormal = object()
GameTooltip = object()
function GameTooltip:SetOwner(owner) self.owner=owner end
UISpecialFrames, SlashCmdList = {}, {}
local categories={}
Settings={
 RegisterCanvasLayoutCategory=function(panel,name) return {panel=panel,name=name,GetID=function() return name end} end,
 RegisterCanvasLayoutSubcategory=function(parent,panel,name) return {parent=parent,panel=panel,name=name,GetID=function() return name end} end,
 OpenToCategory=function(id) Settings.lastOpened=id end,
 RegisterAddOnCategory=function(category) categories[#categories+1]=category end,
}
C_Timer = {After=function(delay,fn) timers[#timers+1]={time=now+delay,fn=fn} end}
local tickerCreations=0
C_Timer.NewTicker=function(interval, callback)
    tickerCreations=tickerCreations+1
    local ticker={cancelled=false}
    function ticker:Cancel() self.cancelled=true end
    local function fire()
        if ticker.cancelled then return end
        callback()
        if not ticker.cancelled then C_Timer.After(interval,fire) end
    end
    C_Timer.After(interval,fire)
    return ticker
end
local function tick(seconds)
    local finish = now + seconds
    local iterations = 0
    while true do
        table.sort(timers,function(a,b) return a.time < b.time end)
        if not timers[1] or timers[1].time > finish then break end
        local task = table.remove(timers,1);now=task.time;task.fn()
        iterations=iterations+1
        assert(iterations < 1000, "timer feedback loop")
    end
    now = finish
end
local function emit(event,...)
    for _,frame in ipairs(frames) do
        if frame.events[event] then frame.scripts.OnEvent(frame,event,...) end
    end
end
function GetLocale() return "esMX" end
function GetBuildInfo() return "1.60.1", "70938" end
function UnitRace() return "Elfa de la noche", "NightElf" end
function UnitClass() return "Druida", "DRUID" end
function UnitFactionGroup() return "Alliance", "Alianza" end
function GetQuestLogQuestText(index) return logged[index] and logged[index].description end
C_QuestLog = {
    GetLogIndexForQuestID = function(id) return logged[id] and id end,
    GetInfo = function(index) return logged[index] end,
    GetNumQuestLogEntries = function()
        local count=0;for _ in pairs(logged) do count=count+1 end
        return count+2,count
    end,
    GetSelectedQuest = function() return selectedID end,
    SetSelectedQuest = function(id) selectedID=id end,
    GetNumQuestWatches = function() return 1 end,
    GetQuestIDForQuestWatchIndex = function() return 99 end,
    RequestLoadQuestByID = function(id) requests[#requests+1]=id end,
}
C_SuperTrack = {GetSuperTrackedQuestID=function() return tracked end, SetSuperTrackedQuestID=function(id) tracked=id end}
QuestMapFrame = object()
QuestMapFrame.DetailsFrame = object(QuestMapFrame)
function QuestMapFrame_ShowQuestDetails(id)
    C_QuestLog.SetSelectedQuest(id)
    QuestMapFrame.DetailsFrame.questID=id
    QuestMapFrame.DetailsFrame:Show()
end
function QuestMapFrame_OpenToQuestDetails(id) QuestMapFrame_ShowQuestDetails(id) end
function QuestMapLogTitleButton_OnClick(button,mouseButton)
    if mouseButton=="LeftButton" then QuestMapFrame_ShowQuestDetails(button.questID) end
end
QuestMapFrame.DetailsFrame:Hide()
function hooksecurefunc(a,b,c)
    if type(a)=="table" then
        local original=a[b];a[b]=function(...) original(...);c(...) end
    else
        local original=_G[a];_G[a]=function(...) original(...);b(...) end
    end
    hooks[#hooks+1]=a
end

QuestLoreCharacterDB = nil
loadModule("QuestAPI.lua", ns)
loadModule("Polestar.lua", ns)
loadModule("RestedXP.lua", ns)
loadModule("Justify.lua", ns)
loadModule("FullText.lua", ns)
loadModule("Window.lua", ns)
loadModule("Tracker.lua", ns)
loadModule("Options.lua", ns)
loadModule("Core.lua", ns)
emit("PLAYER_LOGIN");tick(0.2)
equal(ns.Window.currentID,12,"login displays current navigation quest")
check(ns.Window.frame:IsShown(),"window opens on first installation")
equal(ns.Window.body.text,ns.Stories[12].text,"real frame displays narrative body")
check(ns.questSources[12] and ns.db.quests==nil,"quest source is session-only and absent from SavedVariables")
equal(#ns.db.history,1,"actual displayed summary persisted")
check(ns.Window.back==nil and ns.Window.forward==nil and ns.Window.status==nil and ns.Window.footer==nil,"main Lore has no history controls or pagination")

equal(ns.Window.body.fontSize,14,"initial body font is two steps smaller")
equal(ns.Window.title.fontSize,14,"quest title matches narrative size")
local historyBeforeFont=#ns.db.history
ns.Window.body:SetText(string.rep("Un relato suficientemente largo para necesitar desplazamiento. ",30))
ns.Window.scroll.dynamicRange=true;ns.Window.scroll.viewportHeight=ns.Window.frame:GetHeight()-ns.Window.HEADER_HEIGHT-ns.Window.CONTENT_TOP-ns.Window.FOOTER_HEIGHT
ns.Window:SetFontSize(16)
ns.Window.scroll:SetVerticalScroll(ns.Window.scroll:GetVerticalScrollRange()/2)
ns.Options.slider:SetValue(15)
equal(ns.db.fontSize,15,"A- immediately reduces and saves font size")
equal(ns.Window.body.fontSize,15,"A- updates the actual narrative font")
equal(ns.Window.title.fontSize,15,"title matches resized body")
local range=ns.Window.scroll:GetVerticalScrollRange()
check(range>0 and math.abs(ns.Window.scroll:GetVerticalScroll()/range-0.5)<0.001,"font reflow preserves proportional reading position")
ns.Options.slider:SetValue(16)
equal(ns.db.fontSize,16,"A+ increases size")
SlashCmdList.QUESTLORE("fuente 99")
equal(ns.db.fontSize,24,"font maximum enforced")
equal(ns.Options.slider.value,24,"slider follows maximum")
SlashCmdList.QUESTLORE("fuente 1")
equal(ns.db.fontSize,12,"font minimum enforced")
equal(ns.Options.slider.value,12,"slider follows minimum")
QuestLore_FontSize(-1)
equal(ns.db.fontSize,12,"keyboard action cannot go below minimum")
SlashCmdList.QUESTLORE("fuente 18")
equal(ns.db.fontSize,18,"explicit font size command")
equal(#ns.db.history,historyBeforeFont,"formatting never adds history entries")
ns.Window.scroll.dynamicRange=false;ns.Window.scroll.range=nil
for _,name in ipairs(UISpecialFrames) do check(name~="QuestLoreWindow","window never registers for Escape close") end
local specialCount=#UISpecialFrames
-- This is how the native Escape handler closes special frames.
for _,name in ipairs(UISpecialFrames) do if _G[name] then _G[name]:Hide() end end
check(ns.Window.frame:IsShown(),"Escape leaves QuestLore open")
QuestLore_Toggle();tick(0.2)
check(ns.Window.frame:IsShown(),"show binding never closes an already visible window")
SlashCmdList.QUESTLORE("");tick(0.2)
check(ns.Window.frame:IsShown(),"/lore only opens the window")

QuestMapFrame.DetailsFrame:Show();QuestMapFrame.DetailsFrame.questID=13
QuestMapLogTitleButton_OnClick({questID=13},"LeftButton");tick(0.2)
equal(ns.Window.currentID,13,"native selection hook updates displayed quest")
QuestMapFrame.DetailsFrame:Hide();tracked=99;emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(ns.Window.currentID,99,"closing details returns to actual tracked quest")
check(ns.Window.body.text:find("cultivos",1,true),"unknown quest has context")
QuestLore_Scroll(1);equal(ns.Window.scroll:GetVerticalScroll(),0,"short readable quest cannot scroll into blank space")
ns.Window:Render({key="scroll-test",id=99,title="Relato extenso",body=string.rep("Un relato largo debe poder leerse hasta su última línea. ",30),kind="story",source=""})
QuestLore_Scroll(1);check(ns.Window.scroll:GetVerticalScroll()>0,"bindable scroll works for real overflowing text")
tracked=12;emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(ns.Window.scroll:GetVerticalScroll(),0,"changing quest resets scrolling")

ns.SetVisible(false)
equal(ns.db.visible,false,"hidden state remains compatible")
tracked=13;emit("SUPER_TRACKING_CHANGED");tick(0.2)
check(not ns.Window.frame:IsShown(),"quest change never reopens dismissed window")
QuestLore_Toggle();tick(0.2)
equal(ns.Window.currentID,13,"reopening reads current quest")
ns.SetVisible(false)
equal(ns.db.visible,false,"hidden state is remembered")
QuestLore_Toggle();tick(0.2)
UIParent:Hide()
if ns.Window.frame.scripts.OnHide then ns.Window.frame.scripts.OnHide(ns.Window.frame) end
equal(ns.db.visible,true,"cinematic parent hide preserves visibility intent")
UIParent:Show()

logged[999500]={title="Cargando",description=""};tracked=999500
emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(#requests,1,"missing text requests load once")
equal(ns.Window.body.text,"Cargando el relato de la misión…","async loading state")
for i=1,30 do emit("QUEST_LOG_UPDATE") end
tick(4)
equal(#requests,1,"event bursts and retries never spam data requests")
check(ns.Window.body.text:find("Todavía",1,true),"bounded loading ends in useful missing state")
logged[999500].description="Un veneno amenaza los cultivos. Necesitamos investigar el agua para proteger al pueblo."
emit("QUEST_DATA_LOAD_RESULT",999500,true);tick(0.2)
check(ns.Window.body.text:find("veneno",1,true),"late data refreshes same quest")
local scroll = 42;ns.Window.scroll:SetVerticalScroll(scroll)
emit("QUEST_LOG_UPDATE");tick(0.2)
equal(ns.Window.scroll:GetVerticalScroll(),0,"short same-quest text resets obsolete scrolling")

logged[999501]={title="Solicitud vieja",description=""};tracked=999501
emit("SUPER_TRACKING_CHANGED");tick(0.2)
tracked=12;emit("SUPER_TRACKING_CHANGED");tick(0.2)
logged[999501].description="Esta misión pertenece a otro contexto."
emit("QUEST_DATA_LOAD_RESULT",999501,true);tick(4)
equal(ns.Window.currentID,12,"late old response cannot overwrite newer selection")
logged[12]=nil;emit("QUEST_REMOVED",12);tick(0.2)
equal(ns.questSources[12],nil,"abandoned or turned-in quest source pruned")
check(ns.Window.currentID~=12,"abandoned quest never remains active")
local found12=false
for _,entry in ipairs(ns.db.history) do if entry.id==12 then found12=true end end
check(found12,"removing quest preserves its previously read summary")

-- Archive reading is isolated from the always-live tracker.
tracked=999500;emit("SUPER_TRACKING_CHANGED");tick(0.2)
local latest=ns.Window.currentID
ns.Options:MoveHistory(-1)
local archiveKey=ns.Options.historyKey
check(archiveKey~=nil,"options can select an archived story")
check(ns.history.cursor==nil,"options do not set the main history cursor")
tracked=13;emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(ns.Window.currentID,13,"live quest updates while options archive is open")
equal(ns.Options.historyKey,archiveKey,"live updates preserve selected archive entry")
local archiveIndex=ns.history:Find(archiveKey)
equal(ns.Options.historyBody.text,ns.history.entries[archiveIndex].body,"archive displays the selected full narrative")
check(ns.Window.current==nil,"Current button is removed")
QuestLore_Current();tick(0.2)
equal(ns.Window.currentID,13,"legacy current binding follows live tracking")

-- A quest click must open its existing page even while the arrows are browsing.
local uniqueCount=#ns.db.history
local original13=ns.history:Find("quest:13")
QuestLore_Navigate(1)
QuestMapFrame.DetailsFrame:Show();QuestMapFrame.DetailsFrame.questID=13
QuestMapLogTitleButton_OnClick({questID=13},"LeftButton");tick(0.2)
equal(ns.Window.currentID,13,"clicking a quest opens it from historical browsing")
equal(ns.history:State().index,original13,"click focuses the original stored position")
check(not ns.history.cursor,"explicit quest selection resumes the selected live context")
for i=1,20 do
    local id=i%2==0 and 13 or 99
    QuestMapFrame.DetailsFrame.questID=id
    QuestMapLogTitleButton_OnClick({questID=id},"LeftButton");tick(0.2)
    equal(ns.Window.currentID,id,"repeated quest click displays selected summary")
end
equal(#ns.db.history,uniqueCount,"twenty repeated clicks never append duplicate pages")
QuestMapFrame.DetailsFrame.questID=13
C_SuperTrack.SetSuperTrackedQuestID(99);tick(0.2)
equal(ns.Window.currentID,99,"tracker click overrides stale visible journal details")
emit("QUEST_LOG_UPDATE");tick(0.2)
equal(ns.Window.currentID,99,"background refresh does not bounce to the old journal selection")
QuestMapFrame_ShowQuestDetails(13);tick(0.2)
equal(ns.Window.currentID,99,"journal repaint never overrides the last explicit tracker click")
QuestMapLogTitleButton_OnClick({questID=13},"LeftButton");tick(0.2)
equal(ns.Window.currentID,13,"explicit journal click takes focus back from tracker")
QuestLore_Navigate(1)
local beforeRepaint=ns.Window.currentKey
QuestMapFrame_ShowQuestDetails(13);tick(0.2)
equal(ns.Window.currentKey,beforeRepaint,"same-ID journal repaint preserves manual historical reading")
QuestMapLogTitleButton_OnClick({questID=13},"LeftButton");tick(0.2)
equal(ns.Window.currentID,13,"clicking that same quest explicitly reopens its stored page")
QuestMapFrame_OpenToQuestDetails(99);tick(0.2)
equal(ns.Window.currentID,99,"tracker open-details navigation uses the selected quest ID")
QuestMapFrame.DetailsFrame:Hide()
QuestLore_Navigate(1)
C_SuperTrack.SetSuperTrackedQuestID(99);tick(0.2)
equal(ns.Window.currentID,99,"tracker selection also leaves historical browsing")
check(not ns.history.cursor,"tracker selection resumes following the clicked quest")
equal(#ns.db.history,uniqueCount,"tracker click reuses existing stored summary")
C_SuperTrack.SetSuperTrackedQuestID(13);tick(0.2)

local beforeMinimized=#ns.db.history
logged[999777]={title="Nueva misión minimizada",description="Una caravana necesita ayuda para proteger a los viajeros de los ataques del camino."}
ns.Window:SetMinimized(true)
C_SuperTrack.SetSuperTrackedQuestID(999777);tick(0.2)
equal(ns.Window.currentID,999777,"minimized header follows an explicit quest selection")
QuestLore_Current()
equal(#ns.db.history,beforeMinimized,"Actual binding cannot archive unread minimized pages")
check(not ns.history:Find("quest:999777"),"minimized selection is deferred until displayed")
ns.Window:SetMinimized(false);tick(0.2)
equal(ns.Window.currentID,999777,"restore opens the quest selected while minimized")
equal(#ns.db.history,beforeMinimized,"restoring an unknown quest does not archive its original source text")
C_SuperTrack.SetSuperTrackedQuestID(13);tick(0.2)

tracked=0
local oldWatch=C_QuestLog.GetQuestIDForQuestWatchIndex
C_QuestLog.GetQuestIDForQuestWatchIndex=function() return nil end
emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(ns.Window.currentKey,"empty","untracked existing quests never trigger race/class intro")
local previousLog=logged;logged={}
emit("QUEST_LOG_UPDATE");tick(0.2)
equal(ns.Window.currentKey,"empty","empty log after adventuring never repeats opening lore")
check(ns.db.adventureStarted,"adventure progress is remembered")
check(ns.history.entries[#ns.history.entries].kind~="origins","transient empty log never archives a new origin")
logged=previousLog;tracked=13
C_QuestLog.GetQuestIDForQuestWatchIndex=oldWatch
emit("QUEST_ACCEPTED",13);tick(0.2)
equal(ns.Window.currentID,13,"accepting/tracking quest replaces introduction automatically")
QuestLore_Navigate(-1)
check(ns.Options.historyKey~=nil and not ns.history.cursor,"archive navigation stays in options")
QuestLore_Navigate(1)
equal(ns.Window.currentID,13,"forward arrow returns to live quest")

local beforeHidden=#ns.db.history
ns.SetVisible(false);tracked=99;emit("SUPER_TRACKING_CHANGED");tick(0.2)
equal(#ns.db.history,beforeHidden,"closed window never records unseen summaries")
ns.SetVisible(true);tick(0.2)
equal(ns.Window.currentID,99,"reopening reads current quest after hidden changes")

-- A fresh addon environment with the previous character's saved settings.
ns.SetVisible(false)
ns.db.position={x=200,y=80}
local reloaded = {}
for _,file in ipairs({"Text.lua","Locale.lua","Stories.lua","Stories_Undead.lua","Stories_ForeverTirisfal.lua","Narratives.lua","Origins_Stories.lua","Origins.lua","Model.lua","History.lua","QuestAPI.lua","Polestar.lua","RestedXP.lua","Justify.lua","FullText.lua","Window.lua","Tracker.lua","Options.lua","Core.lua"}) do
    loadModule(file,reloaded)
end
local reloadEvents=frames[#frames]
reloadEvents.scripts.OnEvent(reloadEvents,"PLAYER_LOGIN")
equal(reloaded.db.visible,false,"a reload preserves a deliberately closed window")
check(not reloaded.Window.frame:IsShown(),"a reload does not reopen closed window")
equal(reloaded.Window.frame.point[4],200,"saved horizontal position restored")
equal(reloaded.Window.frame.point[5],80,"saved vertical position restored")
equal(reloaded.db.build,"70938","cache tagged with actual client build")
equal(#reloaded.db.history,#ns.db.history,"reading history survives a reload")
equal(reloaded.Window.body.fontSize,18,"font size survives a reload")

-- First-ever login: don't mistake a not-yet-hydrated quest log for a new
-- character, and don't archive a loading message as the racial introduction.
QuestLoreCharacterDB=nil
logged={};tracked=0
local fresh={}
for _,file in ipairs({"Text.lua","Locale.lua","Stories.lua","Stories_Undead.lua","Stories_ForeverTirisfal.lua","Narratives.lua","Origins_Stories.lua","Origins.lua","Model.lua","History.lua","QuestAPI.lua","Polestar.lua","RestedXP.lua","Justify.lua","FullText.lua","Window.lua","Tracker.lua","Options.lua","Core.lua"}) do
    loadModule(file,fresh)
end
local freshEvents=frames[#frames]
freshEvents.scripts.OnEvent(freshEvents,"PLAYER_LOGIN");tick(0.2)
equal(fresh.Window.currentKey,"preparing","cold login waits until quest log is ready")
equal(#fresh.db.history,0,"cold loading message is not stored as lore")
freshEvents.scripts.OnEvent(freshEvents,"PLAYER_ENTERING_WORLD");tick(0.2)
equal(fresh.history:Current().kind,"origins","new empty-log character gets race/class lore")
equal(#fresh.db.history,1,"opening lore stored after it is actually shown")
local logCount=C_QuestLog.GetNumQuestLogEntries
local getInfo=C_QuestLog.GetInfo
C_QuestLog.GetNumQuestLogEntries=function() return 2 end
C_QuestLog.GetInfo=function(index)
    if index==1 then return {isHeader=true,title="Una zona"} end
    return {questID=90,title="Una misión"}
end
check(fresh.API.HasQuests(),"quest enumeration fallback ignores headers and counts real quests")
C_QuestLog.GetInfo=function() return {isHeader=true,title="Una zona"} end
check(not fresh.API.HasQuests(),"headers alone never count as quests")
C_QuestLog.GetNumQuestLogEntries=logCount;C_QuestLog.GetInfo=getInfo

check(not history:Move(0),"zero-step navigation cannot move out of history bounds")
check(not history:Move(nil),"invalid navigation cannot move out of history bounds")

-- All authored summaries are gated by their own anchors and contain no client
-- markup; fixtures for actual client texts are checked separately at build.
local stories = 0
for id,story in pairs(ns.Stories) do
    stories=stories+1
    check(#story.anchors>=1 or story.titles or story.byID,"story has validation anchors: "..id)
    check(ns.Text.WordCount(story.text)<=100,"story is brief: "..id)
    check(not story.text:find("%$"),"story contains no raw tokens: "..id)
end
equal(stories,303,"narrative content coverage")
local fixture=io.open(root.."/research/undead-fixtures.lua","r")
if fixture then
    fixture:close()
    local references=assert(loadfile(root.."/research/undead-fixtures.lua"))()
    for _,reference in ipairs(references) do
        local rendered=ns.Model.Build(reference,"esMX")
        equal(rendered.kind,"story","reference text selects authored summary for Horde quest "..reference.id)
        if reference.id==363 then
            check(rendered.body:find("voluntad",1,true),"Desvelo brutal explains regained free will")
            check(rendered.body:find("Sarvis",1,true),"Desvelo brutal explains reason for first meeting")
        end
    end
    equal(#references,171,"all additional Horde summaries exercised against reference descriptions")
end
print("PASS: "..count.." checks; 303 narrative summaries; Lua ".._VERSION)

local regionalCount=0
for id,story in pairs(ns.Stories) do
 if story.byID then
  regionalCount=regionalCount+1
  for _,locale in ipairs({"esMX","esES"}) do
   local model=ns.Model.Build({id=id,title="Nombre localizado variable",description=""},locale)
   assert(model.kind=="story" and model.body==story.text, "Regional quest falls back to extract: "..id)
  end
 end
end
assert(regionalCount==51, "Regional coverage incomplete")
ns.locale="esMX"
local migrated=ns.History.New({{key="quest:99153",id=99153,title="Relato anterior",body="Extracto anterior",source="Extracto",kind="extract"}})
assert(migrated.entries[1].kind=="story" and migrated.entries[1].body==ns.Stories[99153].text)
print("PASS: 51/51 regional quests remain narrative in esMX/esES, without description or stable title; old extracts migrate")

-- Updated presentation: one header title, uniform controls, conditional scroll,
-- and a collapsed state that never records unread narrative pages.
fresh.Window:Render({key="ui-short",title="Los autómatas",body="Defendés Camposanto de los siervos de la Plaga.",source="Etiqueta oculta",kind="story"})
assert(fresh.Window.title.text=="Los autómatas")
assert(fresh.Window.source==nil and fresh.Window.hint==nil)
assert(not fresh.Window.scroll.ScrollBar:IsShown(),"short text must hide the whole scroll control")
fresh.Window:Render({key="ui-long",title="Un título largo para consultar en la cabecera",body=string.rep("El bosque necesita tu ayuda ante una amenaza creciente. ",80),source="",kind="story"})
assert(fresh.Window.scroll.ScrollBar:IsShown(),"overflow must restore scrollbar")
assert(fresh.Window.fontDown==nil and fresh.Window.fontUp==nil and fresh.Window.close==nil,"header only has minimize")
assert(fresh.Window.minimize:GetWidth()==24 and fresh.Window.minimize:GetHeight()==24)
assert(fresh.Window.minimize.point[1]=="RIGHT" and fresh.Window.minimize.point[2]==fresh.Window.header and fresh.Window.minimize.point[4]==6)
local visits=#fresh.db.history
fresh.Window.minimize.scripts.OnClick()
assert(fresh.db.minimized and fresh.Window.frame:GetHeight()==fresh.Window:GetHeaderHeight())
assert(not fresh.Window.scroll:IsVisible() and fresh.Window.footer==nil)
assert(not fresh.Window.scroll.ScrollBar:IsShown())
assert(fresh.Window.frame.point[1]=="TOPLEFT" and fresh.Window.frame.point[5]==695,"minimize must preserve top edge")
logged[901]={title="Otra misión",description="Un peligro amenaza el bosque. Necesitamos investigar para proteger a sus habitantes."};tracked=901
freshEvents.scripts.OnEvent(freshEvents,"SUPER_TRACKING_CHANGED");tick(0.2)
assert(#fresh.db.history==visits,"minimized window must not record unseen summaries")
assert(fresh.Window.title.text=="Otra misión","minimized title follows active context")
fresh.Window.minimize.scripts.OnClick();tick(0.2)
assert(not fresh.db.minimized and fresh.Window.frame:GetHeight()==310)
assert(fresh.Window.footer==nil and fresh.Window.scroll:IsVisible())
assert(#fresh.db.history==visits+1,"restoring records the newly visible summary")
assert(fresh.db.fontDefaultsVersion==2 and fresh.db.fontSize==14)
print("PASS: clean header, aligned controls, short/long scrollbar, minimize/restore, fixed top edge and unread-history handling")

-- Resize via the actual grip handlers, then reload character-owned state.
local window=fresh.Window
assert(window.grip:IsVisible() and window.grip.alpha==0,"resize hit region starts with an invisible icon")
local over=false
MouseIsOver=function(frame) return over end
window.frame.scripts.OnEnter()
assert(window.grip.alpha==1 and window.minimize.alpha==1,"hovering the window reveals resize and minimize controls")
over=true;window.frame.scripts.OnLeave()
assert(window.grip.alpha==1,"moving to a child inside the window keeps icon visible")
over=false;window.scroll.scripts.OnLeave()
assert(window.grip.alpha==0 and window.minimize.alpha==0,"leaving the box hides both controls")
window.grip.scripts.OnEnter(window.grip)
assert(window.grip.alpha==1,"hovering the transparent corner reveals it")
window.grip.scripts.OnMouseDown(window.grip,"RightButton")
assert(not window.resizing)
window.grip.scripts.OnMouseDown(window.grip,"LeftButton")
assert(window.resizing and window.frame.sizingCorner=="BOTTOMRIGHT")
window.grip.scripts.OnLeave(window.grip)
assert(window.grip.alpha==1,"resize icon remains visible when dragging outside the box")
assert(window.frame.point[1]=="TOPLEFT")
window.frame:SetSize(520,440)
window.frame.scripts.OnSizeChanged(window.frame,520,440)
assert(window.body:GetWidth()==504 and window.expandedHeight==440)
assert(fresh.db.size.width==380 and fresh.db.size.height==310,"save on release")
window.grip.scripts.OnMouseUp()
assert(not window.resizing and fresh.db.size.width==520 and fresh.db.size.height==440)
assert(window.grip.alpha==0,"release outside hides resize icon")
window:SetMinimized(true)
assert(not window.grip:IsShown() and window.frame:GetHeight()==window:GetHeaderHeight())
assert(fresh.db.size.height==440,"collapse cannot overwrite expanded dimensions")
assert(window.minimize.alpha==0,"collapsed restore control starts hidden outside the box")
window.header.scripts.OnEnter(window.header)
assert(window.minimize.alpha==1 and not window.grip:IsShown(),"hovering collapsed header reveals restore, not resize")
window.header.scripts.OnLeave(window.header)
assert(window.minimize.alpha==0,"leaving collapsed header hides restore control")
window:SetMinimized(false)
assert(window.grip:IsShown() and window.frame:GetHeight()==440)
local paragraph=string.rep("El bosque necesita tu ayuda ante una amenaza creciente. ",12)
window:Render({key="resize",title="Tirisfal",body=paragraph})
window.frame:SetSize(320,180);window.frame.scripts.OnSizeChanged(window.frame,320,180)
assert(window.needsScroll and window.scroll.ScrollBar:IsShown(),"shrinking reflows and restores scroll")
window.frame:SetSize(760,600);window.frame.scripts.OnSizeChanged(window.frame,760,600)
assert(not window.needsScroll and not window.scroll.ScrollBar:IsShown(),"enlarging reflows and hides scroll")
-- Return to saved dimensions before simulating a reload while collapsed.
window.frame:SetSize(520,440);window.frame.scripts.OnSizeChanged(window.frame,520,440)
window:SetMinimized(true)
local function loginCharacter(db)
    QuestLoreCharacterDB=db
    local character={}
    for _,file in ipairs({"Text.lua","Locale.lua","Stories.lua","Stories_Undead.lua","Stories_ForeverTirisfal.lua","Narratives.lua","Origins_Stories.lua","Origins.lua","Model.lua","History.lua","QuestAPI.lua","Polestar.lua","RestedXP.lua","Justify.lua","FullText.lua","Window.lua","Tracker.lua","Options.lua","Core.lua"}) do
        loadModule(file,character)
    end
    local event=frames[#frames]
    character.testEvents=event
    event.scripts.OnEvent(event,"PLAYER_LOGIN")
    return character
end
local restored=loginCharacter(fresh.db)
assert(restored.Window.frame:GetWidth()==520 and restored.Window.frame:GetHeight()==restored.Window:GetHeaderHeight())
restored.Window:SetMinimized(false)
assert(restored.Window.frame:GetHeight()==440,"saved expanded height survives reload while minimized")
local other=loginCharacter(nil)
assert(other.Window.frame:GetWidth()==380 and other.Window.frame:GetHeight()==310,"another character keeps its own default size")
assert(fresh.db.size.width==520 and fresh.db.size.height==440)
UIParent:SetSize(400,300)
local clamped=loginCharacter({size={width=2000,height=1200}})
assert(clamped.Window.frame:GetWidth()==2000 and clamped.Window.frame:GetHeight()==280,"width has no addon ceiling while saved height fits screen")
assert(clamped.Window.frame.resizeBounds[1]==320 and clamped.Window.frame.resizeBounds[2]==80)
UIParent:SetSize(1920,1080)
print("PASS: corner resize, live text/scroll reflow, per-character dimensions, collapsed reload and screen bounds")

assert(categories[1].name=="QuestLore" and categories[1].panel==ns.Options.panel,"registered in native AddOns tab")
assert(ns.Options.slider.Low.text=="12" and ns.Options.slider.High.text=="24")
local optionHistory=#other.db.history
other.Options.slider:SetValue(21)
assert(other.db.fontSize==21 and other.Window.body.fontSize==21 and other.Window.title.fontSize==21)
assert(other.Options.preview.fontSize==21 and other.Options.value.text=="Tamaño del texto: 21")
other.Options.slider:SetValue(15.6)
assert(other.db.fontSize==16 and other.Options.slider.value==16,"slider rounds to whole steps without recursion")
assert(#other.db.history==optionHistory,"settings preview never writes history")
other.Options.reset.scripts.OnClick()
assert(other.db.fontSize==14 and other.Options.slider.value==14)
other.Options.slider:SetValue(20)
local fontRestored=loginCharacter(other.db)
assert(fontRestored.Options.slider.value==20 and fontRestored.Options.preview.fontSize==20,"font settings survive per-character reload")
assert(fresh.db.fontSize==14,"other character keeps its own text setting")
print("PASS: native AddOns category, live font slider/preview, rounding, reset, character persistence; sole minimize header control")

fontRestored.Window:SetMinimized(true)
fontRestored.Options.slider:SetValue(18)
assert(fontRestored.db.minimized and fontRestored.Window.frame:GetHeight()==fontRestored.Window:GetHeaderHeight(),"font option cannot expand minimized window")
fontRestored.SetVisible(false)
fontRestored.Options.slider:SetValue(19)
assert(not fontRestored.Window.frame:IsShown(),"font option cannot reopen hidden window")
print("PASS: changing text settings preserves minimized and hidden state")

-- Tracker-style presentation has no opaque panel or perimeter frame.
C_Texture={GetAtlasInfo=function(name)
    return {width=55,height=55,leftTexCoord=0.1,rightTexCoord=0.9,topTexCoord=0.2,bottomTexCoord=0.8}
end}
local native=loginCharacter(nil);tick(0.2)
assert(native.Window.frame.backdrop==nil,"transparent tracker has no backdrop")
assert(native.Window.headerLabel.text==native.Window.currentTitle and native.Window.wideLayout,"detached wide header shows the quest title")
assert(native.Window.body.textColor[1]==1 and native.Window.body.textColor[2]==1 and native.Window.body.textColor[3]==1,"summary uses white tracker text")
assert(native.Window.title.textColor[1]==1 and native.Window.title.textColor[2]>0.7 and native.Window.title.textColor[3]==0,"summary title uses quest yellow")
native.Window:SetMinimized(true)
assert(native.Window.frame:GetHeight()==native.Window:GetHeaderHeight() and not native.Window.scroll:IsShown(),"minimized tracker keeps only Lore header")
print("PASS: transparent tracker section, fixed Lore header, yellow quest title and white summary")

for _, locale in ipairs({"enUS","enGB","ruRU","koKR","zhCN"}) do
    equal(ns.Locale.Resolve(locale),"en","non-Spanish game locale defaults to English")
end
equal(ns.Locale.Resolve("esMX"),"es","Latin American Spanish auto language")
equal(ns.Locale.Resolve("esES"),"es","European Spanish auto language")
for language, stories in pairs(ns.OriginStories) do
    local total=0
    for key,body in pairs(stories) do
        total=total+1
        check(not body:find("\n",1,true),"integrated intro "..language..key)
    end
    equal(total,90,"every race/class and Skyborne faction variant has integrated lore")
end
native.db.language="auto";native.locale="frFR"
equal(native.Locale.Get(),"en","automatic mode keeps English until experimental French is explicitly selected")
native.Locale.Set("es")
equal(native.Locale.Get(),"es","explicit Spanish overrides client")
native.Locale.Set("en")
equal(native.Options.value.text,"Text size: 14","options translate immediately")
local priest=native.Origins.Build({race="Scourge",class="PRIEST",faction="Horde"})
check(priest.body:find("Light and Shadow",1,true),"unified Forsaken priest story in English")
native.Locale.Set("es")
local savedIntro=native.History.New({priest})
check(savedIntro.entries[1].body:find("Luz y las Sombras",1,true),"stored introduction follows selected language")
print("PASS: automatic language defaults, explicit override, translated options and 90 bilingual integrated origin variants")

for _, choice in ipairs(native.Options.languageChoices) do
    check(choice.checked == (choice.language==native.db.language),"only selected language is checked")
end
local languageHistory=native.History.New({{key="quest:363",id=363,title="Desvelo brutal",body="Texto anterior",kind="story",source=""}})
native.Locale.Set("en")
languageHistory.live=languageHistory.entries[1]
check(languageHistory:Current().body:find("free will",1,true),"stored quest narrative switches to English")
native.Locale.Set("es")
languageHistory:Relocalize()
check(languageHistory:Current().body:find("voluntad",1,true),"stored quest narrative switches back to Spanish")
UnitLevel=function() return 6 end
local experienced=loginCharacter(nil)
check(experienced.db.adventureStarted,"installing on an existing character never restarts opening lore")
UnitLevel=nil
print("PASS: historical narrative language conversion and existing-character opening guard")

local totalBilingual=0
for id,story in pairs(ns.Narratives) do
    totalBilingual=totalBilingual+1
    for _,lang in ipairs({"es","en"}) do
        local rendered=ns.Model.Build({id=id,title="Variable client title"},lang)
        equal(rendered.kind,"story","bilingual summary exists without client description: "..id..lang)
        equal(rendered.body,story[lang],"summary uses requested language: "..id..lang)
        check(ns.Text.WordCount(story[lang])<=100,"brief bilingual story: "..id..lang)
    end
end
check(totalBilingual>=327,"expanded bilingual story bank")
local stale=ns.Model.Build({id=12,title="Changed quest",description="El rey te envía a una isla nueva."},"es")
local guarded=ns.History.New()
guarded:Update(stale)
check(guarded:Current().kind~="story","history never promotes an ID with rejected source anchors")
native.locale="esMX"
local uncertain=native.Model.Build({id=777777,title="Una misión sin traducir",description="Hay un problema en el bosque."},"en")
check(uncertain.kind=="missing" and not uncertain.body:find("bosque",1,true),"untranslated text never leaks into another language")
print("PASS: "..totalBilingual.." bilingual narrative IDs, source-change guard and no mixed-language fallback")

check(ns.NarrativeCoverage.pending==0,"no unclassified catalog quest IDs remain")
check(ns.NarrativeCoverage.covered==ns.NarrativeCoverage.eligible,"every eligible catalog ID has both languages")
check(ns.NarrativeCoverage.catalog==ns.NarrativeCoverage.covered+ns.NarrativeCoverage.excluded,"narratives and documented exclusions account for the whole catalog")
local oldLocale=ns.locale
for _,client in ipairs({"enUS","esMX","esES","deDE","frFR","ptBR","koKR"}) do
    ns.locale=client
    for _,language in ipairs({"es","en"}) do
        local sample=ns.Model.Build({id=93036,title="Client-localized title",description="Client-localized description"},language)
        equal(sample.body,ns.Narratives[93036][language],"chosen narrative language is independent of client locale: "..client..language)
    end
end
ns.locale=oldLocale
print("PASS: exhaustive catalog coverage and bilingual narrative selection across seven client locales")

-- Exercise the public ForeverCore bridge without altering the native tracker
-- or shared attachment settings. This stub preserves the same base-method
-- contract as TrackerHost.Attach's Module mixin.
tick(5) -- Finish callbacks from the earlier simulated characters before exposing a new API.
local host=object(UIParent)
local bridgeModules, attaches, globalChanges={},0,0
local bridgeWidth, bridgeRoom=300,400
local bridgeQueued=false
local function bridgeLayout()
    bridgeQueued=false
    for _,module in ipairs(bridgeModules) do
        module:SetWidth(bridgeWidth)
        module:Update(bridgeRoom)
        module:ClearAllPoints()
        module:SetPoint("TOPLEFT",host,"TOPLEFT",0,0)
    end
end
function host:MarkDirty()
    if not bridgeQueued then bridgeQueued=true;C_Timer.After(0,bridgeLayout) end
end
ForeverTrackerHost={
    SetAttached=function() globalChanges=globalChanges+1 end,
    Attach=function(module)
        attaches=attaches+1
        module.parentContainer=host;module:SetParent(host)
        module.baseUpdate=module.Update
        module.baseGetContentsHeight=module.GetContentsHeight
        module.Update=function(self,available) self.baseUpdate(self,available) end
        module.GetContentsHeight=function(self) return self.baseGetContentsHeight(self) end
        bridgeModules[#bridgeModules+1]=module
        host:MarkDirty()
    end,
}
local combat=false
InCombatLockdown=function() return combat end
logged={[13]={title="La Milicia Popular II",description="Los saqueadores Defias amenazan a la Milicia."},[99]={title="Otro contexto",description=narrative}}
tracked=13;logVisible=false
local dock=loginCharacter({size={width=520,height=440},position={point="TOPLEFT",x=210,y=710},attachToTracker=true})
tick(0.3)
assert(dock.Tracker:IsAttached() and attaches==1,"saved attachment registers exactly one companion section")
assert(dock.Window.frame:GetParent()==dock.Tracker.proxy,"lore joins the shared column through its proxy")
assert(dock.Window.frame:GetWidth()==300 and not dock.Window.grip:IsShown(),"attached lore follows tracker width and disables separate resize")
assert(dock.db.size.width==520 and dock.db.size.height==440 and dock.db.position.x==210,"attachment never overwrites independent geometry")
assert(dock.Tracker.proxy:GetContentsHeight()==dock.Window.frame:GetHeight(),"host receives actual section height")
assert(dock.Options.attachment.checked and dock.Options.attachment.enabled,"options reflect saved attachment")
dock.Window.header.scripts.OnEnter(dock.Window.header)
assert(dock.Window.minimize.alpha==1 and not dock.Window.grip:IsShown(),"attached header reveals only minimize on hover")
dock.Window.header.scripts.OnLeave(dock.Window.header)
assert(dock.Window.minimize.alpha==1,"attached minimize stays visible outside the box")
bridgeWidth=340;host:MarkDirty();tick(0.2)
assert(dock.Window.frame:GetWidth()==340 and dock.Window.body:GetWidth()==324,"tracker width changes reflow the narrative")
dock.Window:SetMinimized(true);tick(0.2)
assert(dock.Tracker.proxy:GetContentsHeight()==dock.Window.HEADER_HEIGHT,"minimizing releases space below Lore header")
dock.Window:SetMinimized(false);tick(0.2)
local stored=#dock.db.history
host:Hide();tracked=99;dock.Refresh();tick(0.2)
assert(#dock.db.history==stored,"a hidden tracker never archives unread lore")
host:Show();dock.Refresh();tick(0.2)
assert(dock.Window.currentID==99 and #dock.db.history==stored,"showing an unknown quest does not archive its original source text")
combat=true
dock.Tracker:SetAttached(false)
assert(dock.Tracker:IsAttached() and dock.Tracker.pending and not dock.db.attachToTracker,"combat preserves layout while saving the requested detached mode")
combat=false
dock.Tracker.events.scripts.OnEvent(dock.Tracker.events,"PLAYER_REGEN_ENABLED");tick(0.2)
assert(not dock.Tracker:IsAttached() and dock.Window.frame:GetParent()==UIParent,"leaving combat applies detachment")
assert(dock.Window.frame:GetWidth()==520 and dock.Window.frame:GetHeight()==440 and dock.Window.frame.point[4]==210,"detaching restores saved free-window size and position")
assert(dock.Window.grip:IsShown() and dock.Tracker.proxy:GetContentsHeight()==0,"detached window resizes normally and releases column space")
dock.Tracker:SetAttached(true);tick(0.2)
assert(attaches==1,"reattaching reuses the registered section")
assert(globalChanges==0,"Lore never changes the shared host attachment preference")
bridgeRoom=30;host:MarkDirty();tick(0.2)
assert(dock.Tracker.proxy:GetContentsHeight()==0 and not dock.Window.frame:IsVisible(),"insufficient tracker space hides the section instead of overlapping title and footer")
bridgeRoom=400;host:MarkDirty();tick(0.2)
assert(dock.Window.frame:IsVisible(),"lore returns when the tracker has room")
-- A long quest list constrains Lore; collapsing it releases room after
-- sibling anchors settle. The probe queues a second host pass without polling.
local previousBody=dock.Window.body.text
local previousTitle=dock.Window.title.text
local stableKey=dock.Window.currentKey
dock.Window:Render({key=stableKey,id=dock.Window.currentID,title="Paciencia",body=string.rep("Los informes necesitan llegar a su destino. ",9),kind="story",source=""})
bridgeRoom=140;host:MarkDirty();tick(0.2)
assert(dock.Window.needsScroll and dock.Window.scroll.ScrollBar:IsShown(),"crowded tracker can still scroll a genuinely clipped story")
local natural=dock.Window.naturalContentHeight
assert(dock.Window:GetDesiredAttachedHeight()==dock.Window.HEADER_HEIGHT+dock.Window.CONTENT_TOP+natural+dock.Window.FOOTER_HEIGHT,"attached desired size uses full-width text instead of scrollbar-wrapped content")
local probe=dock.Tracker.spaceProbe
assert(probe and probe:IsShown(),"attached section observes space changes through an addon-owned probe")
bridgeRoom=500
probe.scripts.OnSizeChanged(probe,300,500)
probe.scripts.OnSizeChanged(probe,300,500)
assert(dock.Tracker.reflowQueued,"sibling movement queues one deferred reflow")
tick(0.2)
assert(not dock.Window.needsScroll and not dock.Window.scroll.ScrollBar:IsShown(),"collapsing sibling quests restores full narrative and hides scrollbar")
assert(dock.Window.body:GetWidth()==bridgeWidth-16,"released scrollbar gutter returns to the narrative")
assert(dock.Window.frame:GetHeight()==dock.Window:GetDesiredAttachedHeight(),"unconstrained section grows exactly to full narrative height")
assert(dock.Window.scroll:GetVerticalScroll()==0,"reclaiming space clears obsolete scrolling")
-- Model client FontStrings whose measured height is bounded by an old
-- explicit height. Short-to-long and narrow-to-wide transitions must unbound
-- both regions before measuring, instead of treating ellipsized text as fitted.
dock.Window.title:SetHeight(12)
dock.Window.body:SetHeight(20)
dock.Window:Render({key=stableKey,id=dock.Window.currentID,title=string.rep("Una nueva Peste ",5),body=string.rep("Johaan necesita muestras para investigar una nueva fórmula. ",10),kind="story",source=""})
bridgeRoom=900;host:MarkDirty();tick(0.2)
assert(dock.Window.body.height==0,"narrative remains naturally sized rather than fixed to an old clipped height")
assert(dock.Window.naturalContentHeight>100 and dock.Window.title:GetStringHeight()>12,"old title and body bounds never hide overflow from measurement")
assert(not dock.Window.needsScroll and dock.Window.frame:GetHeight()==dock.Window:GetDesiredAttachedHeight(),"ample tracker space expands to the complete long story")
bridgeRoom=140;host:MarkDirty();tick(0.2)
assert(dock.Window.needsScroll and dock.Window.scroll.ScrollBar:IsShown(),"real space limits scroll the complete text rather than ellipsizing it")
assert(dock.Window.content:GetHeight()>140 and dock.Window.body:GetStringHeight()>20,"scroll child retains the entire narrative beyond the viewport")
bridgeRoom=900;probe.scripts.OnSizeChanged(probe,300,900);tick(0.2)
assert(not dock.Window.needsScroll and dock.Window.body:GetWidth()==bridgeWidth-16,"restored space reveals the full text at full width")
local tallHeight=dock.Window.frame:GetHeight()
for i=1,5 do host:MarkDirty();tick(0.2) end
assert(dock.Window.frame:GetHeight()==tallHeight and not dock.Window.needsScroll,"repeated host passes converge without scroll-width feedback")
combat=true
bridgeRoom=140
probe.scripts.OnSizeChanged(probe,300,140);tick(0.2)
assert(dock.Tracker.pending and dock.Window.frame:GetHeight()==tallHeight,"space changes during combat leave the shared layout untouched")
combat=false
dock.Tracker.events.scripts.OnEvent(dock.Tracker.events,"PLAYER_REGEN_ENABLED");tick(0.2)
assert(dock.Window.needsScroll,"combat-deferred space restriction applies after combat")
bridgeRoom=500;probe.scripts.OnSizeChanged(probe,300,500);tick(0.2)
assert(not dock.Window.needsScroll,"released space removes scrolling again after combat")
dock.Window:Render({key=stableKey,id=dock.Window.currentID,title=previousTitle,body=previousBody,kind="story",source=""})
dock.Tracker:SetAttached(false);tick(0.2)
assert(not dock.Tracker.spaceProbe:IsShown(),"detached window stops observing shared-column space")
local lateAPI=ForeverTrackerHost
ForeverTrackerHost=nil
local late=loginCharacter({attachToTracker=true});tick(0.2)
assert(not late.Tracker:IsAttached() and not late.Options.attachment.enabled and late.Window.frame:GetParent()==UIParent,"missing ForeverCore keeps Lore independent and disables unavailable option")
ForeverTrackerHost=lateAPI
late.Tracker.events.scripts.OnEvent(late.Tracker.events,"ADDON_LOADED","ForeverCore");tick(0.2)
assert(late.Tracker:IsAttached() and late.Options.attachment.enabled,"late ForeverCore loading activates saved attachment without polling")
print("PASS: ForeverCore shared-column attachment, width reflow, visibility, combat deferral, late API and independent geometry restoration")

local defaultAttached=loginCharacter(nil);tick(0.2)
assert(defaultAttached.db.attachToTracker==true and defaultAttached.Tracker:IsAttached(),"attachment defaults to enabled")
local detachedPreference=loginCharacter({attachToTracker=false});tick(0.2)
assert(not detachedPreference.Tracker:IsAttached() and not detachedPreference.Options.attachment.checked,"explicit detached preference survives login")
GameTooltip:Hide()
detachedPreference.Window.header.scripts.OnEnter(detachedPreference.Window.header)
assert(not GameTooltip:IsShown(),"Lore header hover does not display a title tooltip")
detachedPreference.Window.header.scripts.OnLeave(detachedPreference.Window.header)
assert(detachedPreference.Window.back==nil and detachedPreference.Window.forward==nil and detachedPreference.Window.status==nil and detachedPreference.Window.footer==nil,"all pagination removed from main Lore")
local opts=detachedPreference.Options
assert(opts.historyPanel and opts.historyRows and opts.historyButton,"history is available in AddOns options")
opts:OpenHistory()
assert(Settings.lastOpened==opts.historyCategory:GetID(),"history button opens native AddOns subcategory")
if #detachedPreference.history.entries>0 then
    opts.historyRows[1].scripts.OnClick()
    assert(opts.historyBody.text==detachedPreference.history.entries[1].body,"archive row selects full saved story")
    local live=detachedPreference.Window.currentKey
    opts:MoveHistory(1)
    assert(detachedPreference.Window.currentKey==live,"archive selection never replaces main quest")
end
assert(detachedPreference.Window.FOOTER_HEIGHT==(detachedPreference.Window.fullTextButton:IsShown() and 30 or 8),"main window reserves only the eligible full-text action, with no pagination")
print("PASS: default attachment respects saved detachment; pagination absent; options archive is independent of live quest")

-- Archive capacity, independent selection, and safe native settings opening.
local archive=detachedPreference.history
local oldEntries=archive.entries
archive.entries={}
for i=1,200 do archive.entries[i]={key="archive:"..i,title="Story "..i,body="Narrative "..i,source="",kind="story"} end
opts:SyncHistory()
assert(#opts.historyRows==200 and opts.historyListContent:GetHeight()==6800,"all 200 entries remain accessible in scrollable archive")
opts.historyRows[1].scripts.OnClick()
assert(opts.historyKey=="archive:1" and opts.historyBody.text=="Narrative 1","first archive row has its own selection callback")
opts.historyRows[200].scripts.OnClick()
assert(opts.historyKey=="archive:200" and opts.historyBody.text=="Narrative 200","last archive row has its own selection callback")
local liveKey=detachedPreference.Window.currentKey
opts.historyList.scripts.OnMouseWheel(nil,-1)
assert(opts.historyList:GetVerticalScroll()>0,"archive titles can scroll")
assert(detachedPreference.Window.currentKey==liveKey,"archive scrolling does not alter active narrative")
archive.entries={};opts:SyncHistory()
assert(opts.historyKey==nil and not opts.historyRows[1]:IsShown(),"empty archive clears selection and hides recycled rows")
archive.entries=oldEntries
local originalCore, originalCombat=ForeverCore, InCombatLockdown
local opened
ForeverCore={OpenSettingsPanel=function(id) opened=id;return true end}
InCombatLockdown=function() return false end
opts:OpenHistory()
assert(opened==opts.historyCategory:GetID(),"Forever settings uses the secure ForeverCore opener")
opened=nil;InCombatLockdown=function() return true end
opts:OpenHistory()
assert(opened==nil,"archive opener does not request protected settings in combat")
ForeverCore,InCombatLockdown=originalCore,originalCombat
print("PASS: 200-entry scrollable archive, independent row callbacks, empty state, secure settings opening and combat guard")

local beforeLanguageTracked=tracked
tracked=13;QuestMapFrame.DetailsFrame:Hide()
local translated=loginCharacter({language="es",attachToTracker=false});tick(0.2)
translated.Options:OpenHistory()
local entriesBeforeLanguage=#translated.history.entries
translated.db.visible=false
translated.Locale.Set("en")
local selectedArchive=translated.history:Find(translated.Options.historyKey)
assert(translated.Options.historyBody.text==translated.history.entries[selectedArchive].body,"archive language refreshes immediately even with live window hidden")
assert(#translated.history.entries==entriesBeforeLanguage,"language changes never duplicate archive entries")
print("PASS: hidden live window does not delay archive language changes")
tracked=beforeLanguageTracked


-- Polestar's real dot-style message bus and navigation-target contract.
local previousPolestar=Polestar
local polestarTarget={quest=13,kind="kill",stepIndex=1,goalIndex=1,map=1,x=20,y=30}
local listeners,subscriptionCount,removalCount={},0,0
local fakePolestar={Nav={GetTarget=function() return polestarTarget end}}
function fakePolestar.On(message,callback)
    assert(message=="WAYPOINT_CHANGED")
    local handle={callback=callback,live=true}
    listeners[#listeners+1]=handle;subscriptionCount=subscriptionCount+1
    return handle
end
function fakePolestar.Off(handle) handle.live=false;removalCount=removalCount+1 end
local function announcePolestar(target)
    polestarTarget=target
    for _,handle in ipairs(listeners) do if handle.live then handle.callback(target) end end
    tick(0.2)
end
logged[13]={title="La Milicia Popular II",description="Los saqueadores Defias amenazan a la Milicia."}
logged[99]={title="Una misión desconocida",description=narrative}
tracked=99;QuestMapFrame.DetailsFrame:Hide()
Polestar=fakePolestar
local following=loginCharacter({attachToTracker=false});tick(0.2)
assert(following.db.followPolestar and following.Options.polestar.checked,"Polestar following defaults on per character")
assert(following.Window.currentID==13,"initial Polestar target overrides unrelated native tracking")
assert(subscriptionCount==1,"one subscription on initial load")
following.PolestarBridge:Sync();following.PolestarBridge:Sync();tick(0.2)
assert(subscriptionCount==1,"repeated addon sync never duplicates subscriptions")
announcePolestar({quest="99",kind="turnin",stepIndex=2,goalIndex=1})
assert(following.Window.currentID==99,"accepted Polestar turn-in supports numeric string IDs")
announcePolestar({quest=13,kind="kill",stepIndex=3,goalIndex=1,area=50,search=true})
assert(following.Window.currentID==13,"area/search targets follow their accepted quest directly")
following.SelectContext(99,"tracked");tick(0.2)
assert(following.Window.currentID==13,"Polestar retains priority over automatic or manual selection of another quest")
announcePolestar({quest=13,kind="kill",stepIndex=3,goalIndex=1,label="temporary travel leg",x=40,y=50})
assert(following.Window.currentID==13,"same goal or changed travel label continues following Polestar")
announcePolestar({quest=13,kind="kill",stepIndex=3,goalIndex=2})
assert(following.Window.currentID==13,"a new guide goal resumes direct following")
for _,target in ipairs({{quest=13,kind="manual"},{quest=13,kind="accept"},{quest=999999,kind="kill"},{quest=0,kind="kill"},{quest=-1,kind="kill"},{quest=13.5,kind="kill"},{quest="bad",kind="kill"},{quest=math.huge,kind="kill"},{kind="flightmaster",label="travel"}}) do
    announcePolestar(target)
    assert(following.Window.currentID==99,"manual, future, malformed or travel-only targets fall back to native tracking")
end
announcePolestar(nil)
assert(following.Window.currentID==99,"cleared Polestar target falls back")
announcePolestar({quest=13,kind="kill",stepIndex=4})
assert(following.Window.currentID==13)
logged[13]=nil;following.Refresh()
assert(following.Window.currentID==99,"removing Polestar quest stops rendering its active story")
logged[13]={title="La Milicia Popular II",description="Los saqueadores Defias amenazan a la Milicia."}
following.Refresh()
assert(following.Window.currentID==13,"acceptance/log updates can make a target valid without a new waypoint event")
local countBeforeDisable=subscriptionCount
following.Options.polestar.scripts.OnClick();tick(0.2)
assert(not following.db.followPolestar and not following.Options.polestar.checked and removalCount==1,"options toggle unsubscribes and persists disabled choice")
assert(following.Window.currentID==99,"disabling immediately returns to native selection")
announcePolestar({quest=13,kind="turnin",stepIndex=5})
assert(following.Window.currentID==99,"disabled bridge ignores target changes")
following.Options.polestar.scripts.OnClick();tick(0.2)
assert(subscriptionCount==countBeforeDisable+1 and following.Window.currentID==13,"reenabling subscribes once and reads current target immediately")
-- Reproduce accepting a new quest while the guide still points elsewhere.
polestarTarget={quest=13,kind="kill",stepIndex=6,goalIndex=1}
following.SelectContext(99,"selected")
following.testEvents.scripts.OnEvent(following.testEvents,"QUEST_ACCEPTED",99)
tick(0.2)
assert(following.Window.currentID==13,"accepting a different quest never takes focus from Polestar")
following.testEvents.scripts.OnEvent(following.testEvents,"QUEST_TURNED_IN",99)
tick(0.2)
assert(following.Window.currentID==13,"turning in another quest preserves the guide's active quest")
-- No message and no quest event: the safety ticker must discover the new target.
polestarTarget={quest=99,kind="kill",stepIndex=7,goalIndex=1}
tick(1.2)
assert(following.Window.currentID==99,"one-second polling recovers a silently changed target")
local checks=0
local originalRefresh=following.Refresh
following.Refresh=function() checks=checks+1;return originalRefresh() end
tick(2.2) -- settle lastQuest after the transition
checks=0;tick(3.2)
assert(checks==0,"unchanged Polestar targets do not repaint the window every second")
following.Refresh=originalRefresh
local tickerBefore=following.PolestarBridge.ticker
local createdBefore=tickerCreations
following.PolestarBridge:Sync();following.PolestarBridge:Sync()
assert(following.PolestarBridge.ticker==tickerBefore and tickerCreations==createdBefore,"sync never duplicates the safety ticker")
following.PolestarBridge:SetEnabled(false)
assert(tickerBefore.cancelled and not following.PolestarBridge.ticker,"disabling cancels periodic checks")
polestarTarget={quest=13,kind="turnin",stepIndex=8}
following.PolestarBridge:SetEnabled(true);tick(0.2)
assert(following.Window.currentID==13,"reenabling resumes following immediately")
following.Locale.Set("en")
assert(following.Options.polestar.label.text=="Follow Polestar's active quest","Polestar option is localized")
-- A missing or incompatible addon must leave the preference available.
following.PolestarBridge:SetEnabled(false)
Polestar=nil
local absent=loginCharacter({attachToTracker=false});tick(0.2)
assert(absent.db.followPolestar and absent.Window.currentID==99,"missing optional addon preserves intent and normal behavior")
assert(absent.Options.polestarStatus.text:find("Polestar",1,true))
Polestar=fakePolestar
absent.testEvents.scripts.OnEvent(absent.testEvents,"ADDON_LOADED","Polestar");tick(0.2)
assert(absent.Window.currentID==13,"late Polestar load applies the current target")
absent.PolestarBridge:SetEnabled(false)
local disabled=loginCharacter({attachToTracker=false,followPolestar=false});tick(0.2)
assert(not disabled.db.followPolestar and disabled.Window.currentID==99 and not disabled.PolestarBridge.handle,"saved disabled preference survives login")
local savedGetter=fakePolestar.Nav.GetTarget
fakePolestar.Nav.GetTarget=function() error("API unavailable") end
disabled.PolestarBridge:SetEnabled(true);tick(0.2)
assert(disabled.Window.currentID==99,"getter errors use fallback instead of breaking refresh")
fakePolestar.Nav.GetTarget=savedGetter
fakePolestar.Nav=nil
disabled.Refresh()
assert(disabled.Window.currentID==99,"changed API never leaves a stale Polestar quest selected")
fakePolestar.Nav={GetTarget=savedGetter}
disabled.PolestarBridge:SetEnabled(false)
-- A broken Off implementation must not reactivate a stale closure on re-enable.
local oldOff=fakePolestar.Off
fakePolestar.Off=function() error("unsubscribe unavailable") end
disabled.PolestarBridge:SetEnabled(true);tick(0.2)
local staleCallback=listeners[#listeners].callback
disabled.PolestarBridge:SetEnabled(false)
disabled.PolestarBridge:SetEnabled(true);tick(0.2)
local reads=0
fakePolestar.Nav.GetTarget=function() reads=reads+1;return polestarTarget end
staleCallback({quest=99,kind="kill"})
assert(reads==0,"invalidated callback stays inert even when unsubscription failed")
fakePolestar.Nav.GetTarget=savedGetter
fakePolestar.Off=oldOff
disabled.PolestarBridge:SetEnabled(false)
local oldOn=fakePolestar.On
fakePolestar.On=function() error("subscribe unavailable") end
disabled.PolestarBridge:SetEnabled(true);tick(0.2)
assert(disabled.Window.currentID==99 and not disabled.PolestarBridge.owner,"subscription errors preserve native fallback")
fakePolestar.On=oldOn
disabled.PolestarBridge:SetEnabled(false)
Polestar=previousPolestar
print("PASS: direct Polestar targets, per-character toggle, one subscription/ticker, late load, strict priority, missed events, acceptance guards, removal, native fallback and API failures")

assert(loadfile(root.."/tests/layout.lua"))()({
    login=loginCharacter, tick=tick, object=object,
    setQuest=function() tracked=13;QuestMapFrame.DetailsFrame:Hide() end,
})

assert(loadfile(root.."/tests/horizontal.lua"))()({login=loginCharacter,tick=tick,object=object})

assert(loadfile(root.."/tests/fulltext.lua"))()({login=loginCharacter,tick=tick,object=object})

assert(loadfile(root.."/tests/restedxp.lua"))()({login=loginCharacter,tick=tick,setNative=function() tracked=99;logged[12]={title="La Milicia Popular",description="La Milicia Popular quiere defender los campos."};logged[13]={title="La Milicia Popular II",description="Los saqueadores Defias amenazan a la Milicia."};QuestMapFrame.DetailsFrame:Hide() end})
