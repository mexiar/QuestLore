return function(env)
    local ns=env.login({attachToTracker=false,language="en",followPolestar=false,followRestedXP=false})
    local e=ns.Encyclopedia
    local count,checks=0,0
    local ownership={}
    for language,entries in pairs(e.localized) do
        ownership[language]={}
        for _,entry in pairs(entries) do
            for _,alias in ipairs(entry.aliases) do
                ownership[language][alias]=ownership[language][alias] or {}
                local owners=ownership[language][alias];owners[#owners+1]=entry
            end
        end
    end
    for id,spanish in pairs(e.localized.es) do
        count=count+1
        local english=assert(e.localized.en[id],"every entity has an English article")
        assert(spanish.body~=english.body,"each bilingual article has its own localized text")
        for _,language in ipairs({"es","en","fr","de","pt","pl","ru"}) do
            local entry=assert(e.localized[language][id],"every canonical entity exists in all seven languages")
            assert(entry.title~="" and #entry.body>=24,"every article has substantive text")
            if language~="es" and language~="en" then
                assert(entry.title==english.title and entry.body~=english.body,"translated prose retains its English proper-name title")
                assert(entry.aliases==english.aliases and entry.aliasQuestIDs==english.aliasQuestIDs,"translated entries share English aliases and identity scopes")
                assert(entry.questIDs==english.questIDs,"translated entry inherits its entity context restriction")
            end
            for _,alias in ipairs(entry.aliases) do
                local scope=(entry.aliasQuestIDs and entry.aliasQuestIDs[alias]) or entry.questIDs
                local questID=scope and next(scope)
                local spans=e.FindSpans("("..alias.."),",language,questID)
                -- Ambiguous aliases deliberately remain plain text. They may not
                -- resolve to an arbitrary entity or partially link a shorter name.
                if #spans==1 and spans[1].first==2 and spans[1].last==#alias+1 then
                    local owners=0
                    for _,other in ipairs(ownership[language][alias]) do
                        local otherScope=(other.aliasQuestIDs and other.aliasQuestIDs[alias]) or other.questIDs
                        if not otherScope or otherScope[questID] then owners=owners+1 end
                    end
                    if owners==1 then assert(spans[1].id==id,"unambiguous alias keeps its canonical entity") end
                    assert(spans[1].language==language,"link carries narrative language")
                end
                checks=checks+1
            end
        end
    end
    assert(#e.FindSpans("Light","en")==0 and #e.FindSpans("Luz","es")==0,"display titles never bypass deliberately restricted aliases")
    for _,qid in ipairs({6184,6185}) do
        local story=assert(ns.Narratives[qid],"early investigation remains in the narrative catalog")
        for _,language in ipairs({"es","en"}) do
            for _,span in ipairs(e.FindSpans(story[language],language,qid)) do
                assert(span.id~="npc:nathanos-blightcaller","early investigation cannot reveal the missing ranger's identity through an article title")
            end
        end
    end
    for _,qid in ipairs({9178,9181}) do
        local place=false
        for _,span in ipairs(e.FindSpans(ns.Narratives[qid].es,"es",qid)) do
            if span.id=="place:lights-hope-chapel" then place=true end
            assert(span.id~="concept:holy-light","chapel shorthand must not open the Holy Light article")
        end
        assert(place,"Spanish chapel shorthand resolves to the place")
    end
    local english=e.localized.en["npc:3142"]
    local body=ns.Narratives[806].en
    local spans=e.FindSpans(body,"en",806)
    assert(#spans>=3,"English quest links are available")
    ns.Window:Render({id=806,key="quest:806",title="Dark Storms",body=body,language="en",kind="story"})
    local clicked=false
    for i=1,ns.Window.justified.used do
        local word=ns.Window.justified.words[i]
        if word.entityID=="npc:3142" then
            word.entityButton.scripts.OnClick()
            assert(e.language=="en" and e.body:GetText()==english.body,"English narrative opens English article")
            clicked=true;break
        end
    end
    assert(clicked,"English link has a clickable target")
    local key=ns.Window.currentKey
    local target
    for i=1,e.rich.used do
        local word=e.rich.words[i]
        if word.entityID then target=word.entityButton;break end
    end
    assert(target,"English article includes contextual reference links")
    target.scripts.OnClick()
    assert(e.language=="en" and e.body:GetText()==e.localized.en[e.currentID].body,"article cross-reference keeps English")
    assert(ns.Window.currentKey==key,"article navigation never changes focused quest")
    ns.Locale.SetUI("es")
    assert(e.language=="en","interface language does not overwrite chosen article language")
    e:Open("npc:3142","es")
    assert(e.body:GetText()==e.localized.es["npc:3142"].body,"explicit Spanish link opens Spanish article")
    for _,language in ipairs({"fr","de","pt","pl","ru"}) do
        assert(e:Open("npc:3142",language),"translated article opens in requested language")
        assert(e.language==language and e.body:GetText()==e.localized[language]["npc:3142"].body,"reader displays translated body")
        local translatedTarget
        for i=1,e.rich.used do
            if e.rich.words[i].entityID then translatedTarget=e.rich.words[i].entityButton;break end
        end
        assert(translatedTarget,"translated article retains contextual English proper-name links")
        translatedTarget.scripts.OnClick()
        assert(e.language==language and e.body:GetText()==e.localized[language][e.currentID].body,"translated article navigation preserves language")
        local spans=e.FindSpans("Orgnil protects Durotar.",language,806)
        assert(#spans==2 and spans[1].language==language,"English proper names link within translated narrative context")
        assert(#e.FindSpans("Gorn",language,999999)==0 and #e.FindSpans("Gorn",language,782)==1,"translation cannot broaden a scoped identity")
        assert(#e.FindSpans("Starsong",language,8713)==1 and #e.FindSpans("Starsong",language,999999)==0,"shared surname scope survives translation")
        ns.Window:Render({key="translated:test",id=806,title="Dark Storms",body="Orgnil protects Durotar.",language=language,kind="story"})
        local clickedTranslation=false
        for i=1,ns.Window.justified.used do
            local word=ns.Window.justified.words[i]
            if word.entityID=="npc:3142" then
                word.entityButton.scripts.OnClick();clickedTranslation=true
                assert(e.language==language,"translated quest click opens the same article language")
                break
            end
        end
        assert(clickedTranslation,"translated narrative exposes a canonical click target")
    end
    for _,case in ipairs({
        {12,"Gryanowi","npc:gryan-stoutmantle"},
        {787,"Thralla","person:thrall"},
        {7937,"Sayge'a","npc:sayge"},
        {361,"Thurmana","npc:thurman-agamand"},
        {9250,"Sargerasa","npc:sargeras"},
    }) do
        local spans=e.FindSpans(case[2],"pl",case[1])
        assert(#spans==1 and spans[1].id==case[3],"reviewed Polish contribution case form preserves its canonical identity")
    end
    for _,qid in ipairs({6184,6185}) do
        for _,span in ipairs(e.FindSpans("Nathanosa Blightcallera Flintowi","pl",qid)) do
            assert(span.id~="npc:nathanos-blightcaller","Polish inflections cannot expose the investigation's hidden identity")
        end
    end
    for _,span in ipairs(e.FindSpans("Gareka Bandariona","pl",96896)) do
        assert(span.id~="npc:garek-badlands","Polish inflections cannot merge the Bandarion hero with Badlands Garek")
    end
    assert(not e:Open("npc:3142","it"),"unsupported encyclopedia language cannot silently show another language")
    assert(#e.FindSpans(body,"it",806)==0,"unsupported language has no accidental fallback index")
    ns.Window:Render({key="origin:test",title="Your place in Azeroth",body="The Horde has a place for your people.",language="en",kind="origins"})
    assert(ns.Window.entitySpans and #ns.Window.entitySpans>0,"opening stories also link known entities")
    assert(not ns.Window.fullTextButton:IsShown(),"encyclopedia links do not expose original quest text for an introduction")
    assert(e.index==nil and e.notice==nil,"expanded encyclopedia does not reintroduce free browsing")
    print("PASS: seven-language encyclopedia; "..count.." canonical identities; "..checks.." localized alias checks; language-preserving narrative and article links")
end
