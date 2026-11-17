-- Run with the integration suite's normal simulated client environment.
return function(env)
    local ns = env.login({attachToTracker=false, followPolestar=false,
        quests={[12]={description="LEGACY_FULL_DIALOGUE"}}, questCache={raw="LEGACY_FULL_DIALOGUE"}})
    env.tick(0.2)
    ns.Refresh = function() end
    local active = {[12]=true,[13]=true}
    ns.API.isActive = function(id) return active[id] == true end
    local reads = 0
    local dialogue = "ORIGINAL_FULL_DIALOGUE " .. string.rep("A complete original paragraph. ", 100)
    ns.API.ReadOriginal = function(id)
        reads = reads + 1
        if not active[id] then return nil end
        return {id=id, title="Original client title", description=dialogue,
            objectives="Original client objectives", locale="esMX"}
    end
    ns.API.Read = function() error("full text must not use the summary source cache") end
    local window = ns.Window
    window:Render({id=12,key="quest:12",title="Summary title",body="A short narrative.",kind="story"})
    env.tick(0.1)
    assert(window.fullTextButton:IsShown(), "active quest exposes the original-text action")
    assert(window.fullTextButton.label.justifyH=="LEFT" and window.fullTextButton.label.point[1]=="LEFT", "full-text action label aligns with the left text margin")
    assert(window.FOOTER_HEIGHT==30, "footer action participates in summary and attached height")
    assert(reads==0, "rendering summaries does not fetch full dialogue")
    assert(ns.db.quests==nil and ns.db.questCache==nil, "legacy saved original text is removed")
    assert(ns.FullText:Open(12), "opens the current active quest")
    local full = ns.FullText
    assert(full.subtitle==nil and full.close:GetText()==nil, "reader has no subtitle or bottom back button")
    assert(full.close.point[1]=="TOPRIGHT" and full.frame.resizeBounds[1]==320, "reader exposes corner resizing and top-right close")
    full.grip.scripts.OnMouseDown(full.grip,"LeftButton")
    assert(full.frame.sizingCorner=="BOTTOMRIGHT", "reader corner starts native resizing")
    full.frame:SetSize(700,400)
    full.frame.scripts.OnSizeChanged(full.frame)
    full.grip.scripts.OnMouseUp(full.grip)
    assert(ns.db.fullTextWindow.width==700 and ns.db.fullTextWindow.height==400, "reader resize saves per-character dimensions")
    full.frame.scripts.OnDragStop(full.frame)
    assert(ns.db.fullTextWindow.x==full.frame:GetLeft() and ns.db.fullTextWindow.y==full.frame:GetTop(), "reader move saves position")
    full.scroll:SetSize(400,100)
    full:Layout()
    assert(full.body:GetText():find(dialogue,1,true), "full original dialogue is not extracted or shortened")
    assert(full.body:GetText():find("Original client objectives",1,true), "client objectives are included")
    assert(full.range>0 and full.scroll.ScrollBar:IsShown(), "long original text scrolls")
    window:SetFontSize(24)
    assert(full.body.fontSize==24, "open original reader follows text-size options immediately")
    full.scroll.scripts.OnMouseWheel(full.scroll,-100000)
    assert(full.scroll:GetVerticalScroll()==full.range, "scrolling reaches the original final line")
    assert(window.body:GetText()=="A short narrative.", "original reader never replaces the summary model")
    local function noOriginal(value)
        if type(value)=="table" then for _,v in pairs(value) do noOriginal(v) end
        elseif type(value)=="string" then assert(not value:find("ORIGINAL_FULL_DIALOGUE",1,true), "full dialogue never enters SavedVariables") end
    end
    noOriginal(ns.db)
    window:SetMinimized(true)
    assert(not window.fullTextButton:IsShown(), "minimized summary contains only its header")
    assert(not full.frame:IsShown() and full.body:GetText()=="", "minimizing Lore closes and clears its original reader")
    window:SetMinimized(false)
    assert(window.fullTextButton:IsShown(), "restoring exposes the eligible action")
    full.close.scripts.OnClick(full.close)
    assert(full.id==nil and full.body:GetText()=="" and not full.frame:IsShown(), "closing clears original UI text and identity")
    dialogue="A short original."
    assert(full:Open(12))
    full.scroll:SetSize(400,500);full:Layout()
    assert(full.range==0 and not full.scroll.ScrollBar:IsShown(), "fitting text has no scrollbar")
    full.frame.scripts.OnHide(full.frame)
    assert(not full.frame:IsShown() and full.id==nil and full.body:GetText()=="", "ancestor hiding cannot restore an empty original reader")
    assert(full:Open(12))
    window:Render({id=13,key="quest:13",title="Next quest",body="Another summary.",kind="story"})
    assert(full.id==nil and full.body:GetText()=="", "changing active summary clears the previous original")
    assert(not full:Open(12), "a different still-active quest cannot open from an old context")
    assert(full:Open(13))
    ns.questSources[13]={description="SESSION_ONLY_ORIGINAL"}
    window.frame:Hide()
    active[13]=false
    ns.testEvents.scripts.OnEvent(ns.testEvents,"QUEST_LOG_UPDATE")
    assert(ns.questSources[13]==nil, "inactive source cache prunes even with summary hidden")
    assert(full.id==nil and full.body:GetText()=="", "quest removal invalidates open original reader")
    assert(not window.fullTextButton:IsShown(), "inactive quest loses the action")
    window:Render({key="origin",title="Your place in Azeroth",body="An introduction.",kind="origin"})
    assert(not window.fullTextButton:IsShown() and window.FOOTER_HEIGHT==8, "origins have no full quest text or footer gap")
    local restored = env.login({fullTextWindow={width=700,height=400,x=100,y=800}})
    restored.FullText:Create()
    assert(restored.FullText.frame:GetWidth()==700 and restored.FullText.frame:GetHeight()==400, "reader dimensions restore after character reload")
    local point=restored.FullText.frame.point
    assert(point[1]=="TOPLEFT" and point[4]==100 and point[5]==800, "reader position restores after character reload")
    local other=env.login({})
    other.FullText:Create()
    assert(other.FullText.frame:GetWidth()==520 and other.FullText.frame:GetHeight()==580 and other.FullText.frame.point[1]=="CENTER", "another character keeps independent reader defaults")
    local invalid=env.login({fullTextWindow={width=math.huge,height=0/0,x=-99999,y=99999}})
    invalid.FullText:Create()
    assert(invalid.FullText.frame:GetWidth()==520 and invalid.FullText.frame:GetHeight()==580 and invalid.FullText.frame.point[4]==0 and invalid.FullText.frame.point[5]==1080, "invalid dimensions and offscreen positions are repaired")
    print("PASS: active-only original reader, complete scroll, live context changes, ephemeral text and hidden-window cache pruning")
end
