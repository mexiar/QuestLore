return function(env)
    local ns=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false,language="es"})
    env.tick(0.2)
    ns.QueueRefresh=function() end
    local e,w=ns.Encyclopedia,ns.Window
    local text=ns.Narratives[806].es
    local spans=e.FindSpans(text,"es",806)
    assert(#spans==3,"example identifies Orgnil, Filo Ardiente and Durotar")
    assert(spans[1].id=="npc:3142" and spans[2].id=="organization:burning-blade" and spans[3].id=="place:durotar")
    for _,span in ipairs(e.FindSpans(text,"en",806)) do assert(span.language=="en","aliases belong to their requested language") end
    assert(#e.FindSpans("Filo Ardiente","es",999999)==0,"unknown context cannot confuse the cult with a similarly named clan")
    assert(#e.FindSpans("Durotares áDurotar Durotarñ","es")==0,"UTF-8 word boundaries exclude substrings")
    local longest=e.FindSpans("Orgnil Escaralma y Orgnil","es")
    assert(#longest==2 and longest[1].last==#"Orgnil Escaralma","longest full name wins without duplicate links")
    assert(#e.FindSpans("(Durotar), Durotar.","es")==2,"punctuation and repeated names are recognized")
    local historyCount=#ns.history.entries
    local selection=ns.API.superTracked()
    local cases=0
    for size=12,24 do
        w:SetFontSize(size)
        for _,dims in ipairs({{280,500},{320,500},{1000,100}}) do
            w.frame:SetSize(dims[1],dims[2])
            w:Render({id=806,key="quest:806",title="Oscuras tormentas",body=text,language="es",kind="story"})
            local chars,seen={},{}
            for i=1,w.justified.used do
                local word=w.justified.words[i]
                chars[#chars+1]=word:GetText()
                if word.entityID then
                    seen[word.entityID]=true
                    assert(word.textColor[1]==1 and word.textColor[2]==0.82 and word.textColor[3]==0,"entity words use quest yellow")
                    assert(word.entityButton:IsShown(),"entity has a visible click target")
                    assert(word.entityButton.underline==nil,"entity links have no underline")
                    word.entityButton.scripts.OnClick()
                    assert(e.currentID==word.entityID and e.body:GetText()==e.entries[word.entityID].body,"click opens the canonical independent description")
                    assert(w.currentID==806 and w.body:GetText()==text and #ns.history.entries==historyCount,"encyclopedia never changes active quest or narrative history")
                    assert(ns.API.superTracked()==selection,"lookup does not select a different quest")
                end
                local bottom=-word.point[5]+word:GetStringHeight()
                assert(bottom<=w.content:GetHeight()+1,"every rendered line remains inside scroll content")
            end
            assert(seen["npc:3142"] and seen["organization:burning-blade"] and seen["place:durotar"],"all three links survive reflow")
            assert(table.concat(chars):gsub("%s+","")==text:gsub("%s+",""),"link styling preserves all original narrative characters")
            cases=cases+1
        end
    end
    e:Open("place:durotar");local same=e.body:GetText()
    w:Render({id=823,key="quest:823",title="Informa a Orgnil",body="Orgnil protege Durotar.",language="es",kind="story"})
    e:Open("place:durotar");assert(e.body:GetText()==same,"entry is shared across quests")
    assert(not e:Open("missing") and e.currentID=="place:durotar","unknown entity cannot replace the open record")
    e:Open("object:cabal-tome");assert(e.kind:GetText()==ns.L("Objeto"),"object category available independently")
    assert(e.index==nil and e.notice==nil,"encyclopedia has no free-browsing index or language subtitle")
    assert(#e.FindSpans("Libro del conciliábulo","es")==1,"object alias links to its canonical entry")
    e.close.scripts.OnClick();assert(not e.frame:IsShown(),"native close button closes only encyclopedia")
    assert(ns.Options.encyclopediaButton==nil and not e:Open(),"encyclopedia requires an explicitly clicked entry")
    e:Open("npc:3142")
    local linked={}
    for i=1,e.rich.used do
        local word=e.rich.words[i]
        if word.entityID then linked[word.entityID]=true end
    end
    assert(linked["organization:burning-blade"] and linked["place:durotar"],"article text has contextual reference links")
    local target
    for i=1,e.rich.used do if e.rich.words[i].entityID=="place:durotar" then target=e.rich.words[i].entityButton;break end end
    target.scripts.OnClick();assert(e.currentID=="place:durotar","article link opens its own reference")
    w:Render({key="none",title="Another story",body="A story without known entities.",kind="story",language="en"})
    for _,word in ipairs(w.justified.words) do if word.entityButton then assert(not word.entityButton:IsVisible(),"stale click targets removed when narrative changes") end end
    ns.Locale.SetUI("fr");assert(e.heading:GetText()=="Encyclopédie" and e.body:GetText()==e.entries[e.currentID].body,"interface language preserves the explicitly opened article language")
    local count=0;for _ in pairs(e.entries) do count=count+1 end;assert(count>=4,"expanded catalog retains all four original canonical entries")
    print("PASS: encyclopedia bilingual catalog; "..cases.." linked layouts; canonical entries, UTF-8 boundaries, repeated/full names, no quest/history changes and stale-hit cleanup")
end
