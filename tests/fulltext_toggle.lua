return function(env)
    local ns=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    ns.QueueRefresh=function() end
    ns.API.isActive=function(id) return id==12 end
    ns.API.ReadOriginal=function(id) return id==12 and {id=id,title="Original",description="Complete original quest text."} or nil end
    local w,o=ns.Window,ns.Options
    local model={id=12,key="quest:12",title="Quest title",body="A short narrative.",kind="story",language="en"}
    w:Render(model)
    ns.history.entries={ns.Model.Build({id=12,title="Quest title"},"en")};ns.db.history=ns.history.entries
    o.historyPanel:Show();o:SyncHistory(true)
    local height=o.historyRows[1].height
    assert(ns.db.showFullTextButton==true and o.fullTextToggle.checked and w.fullTextButton:IsShown(),"new and existing profiles show the action by default")
    assert(o.historyRows[1].read:IsShown(),"default also shows the history action")
    o.fullTextToggle.scripts.OnClick()
    assert(ns.db.showFullTextButton==false and not w.fullTextButton:IsShown() and w.FOOTER_HEIGHT==8,"hiding removes the action and reserved footer space immediately")
    assert(not o.historyRows[1].read:IsShown() and o.historyRows[1].height<height,"history hides the action and reclaims its space")
    w:SetMinimized(true);w:SetMinimized(false);w:SetFontSize(24);w:RefreshFullText()
    assert(not w.fullTextButton:IsShown() and w.FOOTER_HEIGHT==8,"minimize, font changes and quest refresh do not restore a hidden action")
    for _,lang in ipairs({"es","en","fr","de","pt"}) do
        ns.Locale.SetUI(lang)
        assert(o.fullTextToggle.label:GetText()==ns.L("Mostrar botón de texto completo",lang),"option is translated in each interface")
        assert(not w.fullTextButton:IsShown(),"language changes preserve the preference")
    end
    w:Render({id=12,key="quest:12",title="Preview",body="Original preview…",kind="preview",language="en"})
    assert(w.previewButton:IsShown() and not w.fullTextButton:IsShown(),"literal fallback previews remain clickable independently of the button")
    w.previewButton.scripts.OnClick()
    assert(ns.FullText.frame:IsShown(),"hiding the action does not disable the original-text reader")
    ns.FullText:Close()
    local restored=env.login(ns.db)
    assert(restored.db.showFullTextButton==false and not restored.Options.fullTextToggle.checked,"explicit false survives per-character reload")
    restored.API.isActive=function(id) return id==12 end
    restored.Window:Render(model)
    assert(not restored.Window.fullTextButton:IsShown(),"saved preference is applied on render")
    restored.Options.fullTextToggle.scripts.OnClick()
    assert(restored.db.showFullTextButton and restored.Window.fullTextButton:IsShown() and restored.Window.FOOTER_HEIGHT>8,"enabling restores the action and layout")
    print("PASS: full-text button default, live/history visibility, reclaimed layout, reload persistence, five languages and independent fallback preview")
end
