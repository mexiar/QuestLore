return function(env)
    local ns=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false,showUpdateNotices=false})
    env.tick(0.2)
    local o=ns.Options
    local expected="https://x.com/alejandrosena"
    local highlights,blurred=0,0
    o.contactLink.HighlightText=function() highlights=highlights+1 end
    o.contactLink.ClearFocus=function() blurred=blurred+1 end
    o.contactLink.scripts.OnEditFocusGained(o.contactLink)
    assert(highlights==1,"clicking the profile field selects its full URL")
    o.contactLink:SetText("accidental edit");o.contactLink.scripts.OnTextChanged(o.contactLink,true)
    assert(o.contactLink:GetText()==expected and highlights==2,"profile URL cannot be accidentally changed")
    o.contactLink.scripts.OnEscapePressed(o.contactLink);o.contactLink.scripts.OnEnterPressed(o.contactLink)
    assert(blurred==2,"Enter and Escape release keyboard focus")
    local cf="https://www.curseforge.com/wow/addons/questlore/files"
    o.updatesLink:SetText("accidental edit");o.updatesLink.scripts.OnTextChanged(o.updatesLink,true)
    assert(o.updatesLink:GetText()==cf and o.contactLink:GetText()==expected,"copyable links retain independent destinations")
    local body=ns.Window.body:GetText()
    for _,language in ipairs({"es","en","fr","de","pt","pl","ru"}) do
        ns.Locale.SetUI(language)
        assert(o.contactHeading:GetText()==ns.L("Errores y novedades"),"localized contact heading")
        assert(o.contactDescription:GetText()==ns.L("Reporta errores y sigue las novedades de QuestLore en X: @alejandrosena. Selecciona y copia el enlace para abrirlo en tu navegador."),"localized reporting/copy instructions")
        assert(o.contactDescription:GetText():find("@alejandrosena",1,true),"handle remains visible in every language")
        assert(o.contactLink:GetText()==expected,"profile URL remains unchanged")
        assert(ns.Window.body:GetText()==body,"contact localization leaves current narrative unchanged")
        o.panel:SetWidth(320);o:Layout()
        assert(o.contactLink:GetWidth()>0 and o.content:GetHeight()>-o.contactLink.point[#o.contactLink.point],"contact field is inside the scrollable content at narrow widths")
    end
    print("PASS: seven-language bug/news contact, exact X profile, selectable immutable independent links, focus release and narrow layout")
end
