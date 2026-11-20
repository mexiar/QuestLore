-- Contract fixtures from RestedXP/RXPGuides: AceAddon engine, AceEvent bus,
-- arrowFrame.element parent/source links, currentGuide.steps, dot-style progress.
return function(env)
    local oldLib, oldFacade, oldPolestar = LibStub, RXPGuides, Polestar
    env.setNative()
    local step = {index=1,active=true}
    local goal = {tag="complete",questId=13,step=step}
    step.elements={goal}
    local arrow={element={tag="goto",step=step,parent=goal},IsShown=function() return true end}
    local progress=1
    local engine={arrowFrame=arrow,currentGuide={steps={step}},
        settings={profile={showEnabled=true}},GetGuideProgress=function() return progress end}
    local lookups=0
    local ace={GetAddon=function(self,name,silent) lookups=lookups+1;assert(name=="RXPGuides" and silent);return engine end}
    local listeners,registrations={},0
    local bus={Embed=function(self,listener)
        listener.messages={};listeners[#listeners+1]=listener
        function listener:RegisterMessage(message,callback) self.messages[message]=callback;registrations=registrations+1 end
        function listener:UnregisterAllMessages() self.messages={} end
    end}
    LibStub=function(name,silent) assert(silent);if name=="AceAddon-3.0" then return ace elseif name=="AceEvent-3.0" then return bus end end
    RXPGuides={RegisterGuide=function() error("must never import or inspect guide text") end}
    local function message(name)
        for _,listener in ipairs(listeners) do
            local callback=listener.messages[name]
            if callback then callback(name,{questId=999999}) end
        end
        env.tick(0.2)
    end
    local c=env.login({attachToTracker=false,followPolestar=false})
    local active={[12]=true,[13]=true,[99]=true}
    c.API.isActive=function(id) return active[id]==true end
    env.tick(0.2)
    assert(c.db.followRestedXP and c.Options.restedXP.checked and c.Window.currentID==13,"RXP supplies a target when no quest has native focus")
    local nativeFocus=c.API.superTracked
    local focus=99
    c.API.superTracked=function() return focus end
    c.SelectContext(99,"tracked");env.tick(0.2)
    assert(c.Window.currentID==99,"focused quest overrides RestedXP")
    goal.questId=12;message("RXP_TARGET_LIST_UPDATE")
    assert(c.Window.currentID==99,"RestedXP target changes cannot clear native focus")
    focus=nil;c.QueueRefresh();env.tick(0.2)
    assert(c.Window.currentID==12,"clearing focus restores RestedXP fallback")
    goal.questId=13;message("RXP_TARGET_LIST_UPDATE")
    c.API.superTracked=nativeFocus
    assert(registrations==4 and c.RestedXPBridge.listener~=engine,"independent AceEvent subscriber preserves RXP handlers")
    local timer=c.RestedXPBridge.ticker
    c.RestedXPBridge:Sync();c.RestedXPBridge:Sync();env.tick(0.2)
    assert(c.RestedXPBridge.ticker==timer and registrations==4,"one ticker and one registration set")
    arrow.element={tag="questgoto",questId="12",step=step}
    message("RXP_TARGET_LIST_UPDATE")
    assert(c.Window.currentID==12,"explicit arrow quest beats another quest in the step")
    arrow.element={tag="goto",step=step,source=goal}
    env.tick(1.2)
    assert(c.Window.currentID==13,"safety poll notices silent arrow target changes")
    local originalRefresh=c.Refresh;local redraws=0
    c.Refresh=function() redraws=redraws+1;originalRefresh() end
    env.tick(2.2);assert(redraws==0,"unchanged RXP state does not redraw")
    arrow.element=nil
    step.elements={goal,{tag="collect",questId=13,step=step}}
    message("RXP_STEP_COMPLETE")
    assert(c.Window.currentID==13,"repeated references to one accepted quest are unambiguous")
    step.elements={goal,{tag="turnin",questId=12,step=step}}
    message("RXP_OBJECTIVE_COMPLETE")
    assert(c.Window.currentID==99,"ambiguous multi-quest step uses normal selection")
    step.elements={{tag="accept",questId=13,step=step}}
    message("RXP_STEP_COMPLETE")
    assert(c.Window.currentID==99,"accept recommendations are not active guide targets")
    step.elements={goal};arrow.element={tag="questwaypoint",questId=999999,step=step}
    assert(c.RestedXPBridge:QuestID()==13,"unaccepted arrow quest is rejected; unique accepted step remains valid")
    active[13]=false;message("RXP_OBJECTIVE_COMPLETE")
    assert(c.Window.currentID==99,"removed quests cannot remain the RXP target")
    active[13]=true
    goal.completed=true;message("RXP_STEP_COMPLETE")
    assert(c.Window.currentID==99,"completed guide elements are ignored")
    goal.completed=nil;goal.skip=true;message("RXP_STEP_COMPLETE")
    assert(c.Window.currentID==99,"skipped elements are ignored")
    goal.skip=nil;arrow.element={tag="goto",step=step};arrow.element.parent=arrow.element
    message("RXP_TARGET_LIST_UPDATE");assert(c.Window.currentID==13,"cyclic parents terminate safely; unique step fallback works")
    local newStep={index=1,active=true};newStep.elements={{tag="turnin",questId=12,step=newStep}}
    engine.currentGuide={steps={newStep}};arrow.element=goal
    message("RXP_GUIDE_LOADED")
    assert(c.Window.currentID==12,"old guide arrow is rejected by step identity")
    step=newStep;goal=newStep.elements[1]
    engine.settings.profile.showEnabled=false;message("RXP_TARGET_LIST_UPDATE")
    assert(c.Window.currentID==99,"disabled guide falls back")
    engine.settings.profile.showEnabled=true
    local oldProgress=engine.GetGuideProgress
    engine.GetGuideProgress=function() error("API changed") end;arrow.element=nil
    message("RXP_STEP_COMPLETE");assert(c.Window.currentID==99,"getter failure falls back safely")
    engine.GetGuideProgress=oldProgress;arrow.element={tag="goto",step=step,parent=goal}
    message("RXP_STEP_COMPLETE");assert(c.Window.currentID==12)
    local stale=c.RestedXPBridge.listener.messages.RXP_STEP_COMPLETE
    c.Options.restedXP.scripts.OnClick();env.tick(0.2)
    assert(not c.db.followRestedXP and timer.cancelled and not c.RestedXPBridge.ticker and c.Window.currentID==99,"toggle cancels ticker, disconnects messages and restores native selection")
    c.Options.restedXP.scripts.OnClick();env.tick(0.2)
    local beforeStale=lookups
    stale();assert(lookups==beforeStale,"stale callback never reads the new connection")
    env.tick(0.2);assert(c.Window.currentID==12,"stale callback cannot reactivate an old connection")
    c.testEvents.scripts.OnEvent(c.testEvents,"QUEST_ACCEPTED",1,99);env.tick(0.2)
    assert(c.Window.currentID==12,"accepting another quest does not replace the guide target")
    Polestar={Nav={GetTarget=function() return {quest=13,kind="kill"} end},On=function() return {} end,Off=function() end}
    c.PolestarBridge:SetEnabled(true);env.tick(0.2)
    assert(c.Window.currentID==13,"Polestar has documented priority if both guide bridges are enabled")
    c.PolestarBridge:SetEnabled(false);env.tick(0.2);assert(c.Window.currentID==12)
    c.RestedXPBridge:SetEnabled(false)
    local disabled=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false});env.tick(0.2)
    assert(not disabled.RestedXPBridge.owner and disabled.Window.currentID==99,"disabled per-character setting survives reload")
    local oldEngine=engine;engine=nil
    disabled.RestedXPBridge:SetEnabled(true);env.tick(0.2)
    assert(not disabled.RestedXPBridge.ticker and disabled.Window.currentID==99,"missing addon does not create a ticker")
    engine=oldEngine
    disabled.testEvents.scripts.OnEvent(disabled.testEvents,"ADDON_LOADED","RXPGuides");env.tick(0.2)
    assert(disabled.Window.currentID==12,"late loading connects to current guide")
    disabled.RestedXPBridge:SetEnabled(false)
    LibStub,RXPGuides,Polestar=oldLib,oldFacade,oldPolestar
    print("PASS: RestedXP live-engine discovery, isolated messages, arrow parent/source, unique-step fallback, ambiguity, stale guides, cycles, accepted-only targets, late load, toggle, API errors, stable polls and Polestar priority")
end
