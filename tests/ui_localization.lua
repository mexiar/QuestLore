-- Behavioral coverage for native-language UI independently of narrative banks.
return function(env)
    local originalGetLocale=GetLocale
    for _, pair in ipairs({{"esMX","es"},{"esES","es"},{"enUS","en"},{"enGB","en"},
        {"frFR","fr"},{"deDE","de"},{"ptBR","pt"},{"ptPT","pt"},{"plPL","pl"},{"ruRU","ru"},{"koKR","en"}}) do
        GetLocale=function() return pair[1] end
        local ns=env.login({language="auto",attachToTracker=false,followPolestar=false,followRestedXP=false})
        assert(ns.Locale.GetUI()==pair[2],"native UI detection "..pair[1])
        assert(ns.Locale.Get()==(pair[2]=="es" and "es" or "en"),"automatic narrative policy preserved")
        assert(ns.db.uiLanguage=="auto","automatic interface choice persisted")
        assert(ns.Options.value:GetText()==ns.L("Tamaño del texto: ",pair[2])..ns.db.fontSize,"options localized at login")
    end
    GetLocale=originalGetLocale
    local ns=env.login({language="en",uiLanguage="auto",attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    ns.QueueRefresh=function() end
    ns.API.isActive=function(id) return id==12 end
    ns.API.ReadOriginal=function(id)
        return {id=id,title="Título del cliente",description="Texto original en español.",objectives="Objetivos originales."}
    end
    local model=ns.Model.Build({id=12,title="Título del cliente"},"en")
    ns.Window.frame:SetSize(320,500)
    ns.Window:Render(model)
    local originalBody=model.body
    local originalSize=ns.db.fontSize
    -- Simulate native button font strings, including wrapping at narrow widths.
    for _,button in ipairs({ns.Options.reset,ns.Options.historyButton}) do
        local font=button:CreateFontString(nil,"OVERLAY","GameFontNormal")
        button.GetFontString=function(self) font:SetText(self:GetText());return font end
    end
    local savedHistory=ns.History.New({model})
    local historyCount=#ns.history.entries
    local header={es="Lore",en="Lore",fr="Histoire",de="Hintergrund",pt="História",pl="Lore",ru="История"}
    local show={es="Mostrar el relato",en="Show story",fr="Afficher le récit",de="Geschichte anzeigen",pt="Mostrar história",pl="Pokaż opowieść",ru="Показать историю"}
    for _, language in ipairs({"es","en","fr","de","pt","pl","ru"}) do
        for _, choice in ipairs(ns.Options.uiLanguageChoices) do
            if choice.language==language then choice.scripts.OnClick(choice) end
        end
        assert(ns.Locale.GetUI()==language and ns.db.uiLanguage==language,"interface choice applied")
        assert(ns.db.language=="en" and ns.Locale.Get()=="en","interface change preserves summary choice")
        assert(ns.Window.headerLabel:GetText()==header[language],"tracker header localized")
        assert(ns.Window.body:GetText()==originalBody,"interface switch preserves English narrative")
        assert(savedHistory.entries[1].body==originalBody and #ns.history.entries==historyCount,"interface switch preserves archive")
        assert(ns.db.fontSize==originalSize,"interface change preserves font preference")
        assert(BINDING_HEADER_QUESTLORE=="QuestLore" and BINDING_NAME_QUESTLORE_TOGGLE==show[language],"bindings localized")
        assert(BINDING_NAME_QUESTLORE_HISTORY==ns.L("Abrir el historial"),"history binding localized")
        assert(ns.Options.historyCategory.name=="QuestLore · "..ns.L("Historial"),"registered archive category renamed")
        assert(ns.Model.Build(nil,"en").title==ns.L("Selecciona una misión"),"empty-state UI independent of summary")
        assert(ns.Model.Build({id=999999,loading=true},"en").body==ns.L("Cargando el relato de la misión…"),"loading UI independent of summary")
        assert(ns.Window.fullTextButton:GetText()==ns.L("Leer texto completo"),"full-text action localized")
        ns.FullText:Open(12)
        assert(ns.FullText.title:GetText()=="Título del cliente" and ns.FullText.body:GetText():find("Texto original en español.",1,true),"original reader remains client-language text")
        ns.FullText.close.scripts.OnEnter(ns.FullText.close)
        assert(GameTooltip:GetText()==ns.L("Cerrar"),"reader close tooltip localized")
        ns.FullText.grip.scripts.OnEnter(ns.FullText.grip)
        assert(GameTooltip:GetText()==ns.L("Arrastra para cambiar el tamaño"),"reader resize tooltip localized")
        ns.FullText:Close()
        ns.Window.minimize.scripts.OnEnter(ns.Window.minimize)
        assert(GameTooltip:GetText()==ns.L("Minimizar ventana"),"minimize tooltip localized")
        for _, width in ipairs({320,600}) do
            ns.Options.panel:SetWidth(width);ns.Options:Layout()
            for _, group in ipairs({ns.Options.uiLanguageChoices,ns.Options.languageChoices}) do
                for i=1,#group-1 do
                    assert(-group[i+1].point[3]>=-group[i].point[3]+group[i].label:GetStringHeight()+4,"wrapped language labels do not overlap")
                end
            end
            assert(ns.Options.content:GetHeight()>-ns.Options.historyButton.point[3],"options scroller reaches last action")
            assert(ns.Options.reset:GetHeight()>=ns.Options.reset:GetFontString():GetStringHeight()+12,"translated reset button fits its label")
        end
        for _, choice in ipairs(ns.Options.uiLanguageChoices) do assert(choice.checked==(choice.language==language),"only UI selection checked") end
    end
    ns.Locale.SetUI("de")
    ns.Window.frame:SetSize(200,500);ns.Window:Layout()
    assert(ns.Window.FOOTER_HEIGHT>30 and ns.Window.FOOTER_HEIGHT>=ns.Window.fullTextButton.label:GetStringHeight()+8,"wrapped full-text action reserves its entire footer")
    ns.Locale.SetUI("pt")
    local oldUI=ns.db.uiLanguage
    ns.Locale.SetUI("invalid")
    assert(ns.db.uiLanguage==oldUI,"invalid UI preference ignored")
    local reloaded=env.login(ns.db)
    assert(reloaded.Locale.GetUI()=="pt" and reloaded.Locale.Get()=="en","per-character independent languages survive login")
    local migrated=env.login({language="de",attachToTracker=false,followPolestar=false,followRestedXP=false})
    assert(migrated.db.uiLanguage=="de","previous explicit interface preference preserved on upgrade")
    local repaired=env.login({uiLanguage="invalid",language="auto",attachToTracker=false,followPolestar=false,followRestedXP=false})
    assert(repaired.db.uiLanguage=="auto","invalid persisted UI preference repaired")
    print("PASS: native UI detection, independent saved language choices, all six interfaces, key bindings, live archive categories, original-language reader and wrapped options")
end
