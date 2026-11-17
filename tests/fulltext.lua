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
    assert(window.FOOTER_HEIGHT==30, "footer action participates in summary and attached height")
    assert(reads==0, "rendering summaries does not fetch full dialogue")
    assert(ns.db.quests==nil and ns.db.questCache==nil, "legacy saved original text is removed")
    assert(ns.FullText:Open(12), "opens the current active quest")
    local full = ns.FullText
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
    full:Close()
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
    print("PASS: active-only original reader, complete scroll, live context changes, ephemeral text and hidden-window cache pruning")
end
