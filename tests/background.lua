return function(env)
    local ns=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    local w,o=ns.Window,ns.Options
    assert(ns.db.backgroundEnabled==false and w.background.color[4]==0,"existing transparent default preserved")
    assert(not o.backgroundSlider.enabled,"transparency slider disabled until background enabled")
    local textColor=w.body.textColor
    local historyCount=#ns.history.entries
    local body=w.body:GetText()
    o.backgroundToggle.scripts.OnClick()
    assert(ns.db.backgroundEnabled and w.background.color[4]==0.5 and o.backgroundSlider.enabled,"checkbox enables half-transparent black background")
    o.backgroundSlider:SetValue(0)
    assert(w.background.color[4]==1,"zero transparency is opaque")
    o.backgroundSlider:SetValue(100)
    assert(w.background.color[4]==0,"full transparency leaves world visible")
    o.backgroundSlider:SetValue(35)
    assert(w.background.color[4]==0.65,"live slider updates background only")
    assert(w.body.textColor==textColor and w.body:GetText()==body and #ns.history.entries==historyCount,"opacity does not fade or alter the story")
    w:SetMinimized(true)
    assert(w.background.points.TOPLEFT[2]==w.frame and w.background.points.BOTTOMRIGHT[2]==w.frame,"background follows collapsed frame geometry")
    w:SetMinimized(false)
    o.backgroundToggle.scripts.OnClick()
    assert(w.background.color[4]==0 and ns.db.backgroundTransparency==35,"disabling preserves preferred transparency")
    o.backgroundToggle.scripts.OnClick()
    local restored=env.login(ns.db)
    assert(restored.db.backgroundEnabled and restored.db.backgroundTransparency==35 and restored.Window.background.color[4]==0.65,"settings survive character reload")
    restored.Window.attachedLayout=true
    restored.Window:SetBackground(true,70)
    assert(math.abs(restored.Window.background.color[4]-0.3)<0.00001,"attached layout supports the same background")
    restored.Window:SetBackground(true,-20);assert(restored.db.backgroundTransparency==0)
    restored.Window:SetBackground(true,200);assert(restored.db.backgroundTransparency==100)
    restored.Window:SetBackground(true,0/0);assert(restored.db.backgroundTransparency==50)
    for _,lang in ipairs({"es","en","fr","de","pt"}) do
        restored.Locale.SetUI(lang)
        assert(restored.Options.backgroundToggle.label:GetText()==restored.L("Mostrar fondo",lang))
        assert(restored.Options.backgroundValue:GetText()==restored.L("Transparencia del fondo: ",lang).."50%")
    end
    print("PASS: optional background, live transparency endpoints, unchanged text, collapsed/attached geometry, per-character persistence and five-language controls")
end
