return function(root)
    local function entry(aliases,scope)
        return {title=aliases[1],body="Independent entity article.",kind="Lugar",aliases=aliases,questIDs=scope,
            en={title=aliases[1],body="English entity article.",aliases=aliases}}
    end
    local ns={EncyclopediaData={
        ["one"]=entry({"Shared Name","Shared","Orgnil","Elune","Durotar","Bronze","Orgrimmar"}),
        ["two"]=entry({"Shared Name"}),
        ["scoped"]=entry({"Blue Order"},{[123]=true}),
        ["other-order"]=entry({"Blue Order","Red Order"}),
        ["light"]=entry({"the Light"}),
        ["chapel"]=entry({"Light's Hope","Light’s Hope"}),
        ["thrall-legacy"]=entry({"Thralls Legacy"}),
        ["thralla-guard"]=entry({"Thralla Guard"}),
    }}
    for _,name in ipairs({"Thrall","Gryan","Owen","Sayge","Flint","Flinta","Darin"}) do
        local data=entry({name});data.kind="Personaje";ns.EncyclopediaData[name]=data
    end
    ns.EncyclopediaData["other-darin"]=entry({"Darin"});ns.EncyclopediaData["other-darin"].kind="Personaje"
    ns.EncyclopediaData.garek=entry({"Garek"},{[793]=true});ns.EncyclopediaData.garek.kind="Personaje"
    ns.EncyclopediaData.bandarion=entry({"Garek Bandarion"});ns.EncyclopediaData.bandarion.kind="Personaje"
    ns.EncyclopediaData.roran=entry({"Roran"});ns.EncyclopediaData.roran.kind="Personaje"
    ns.EncyclopediaData["roran-shield"]=entry({"Roran Shield"});ns.EncyclopediaData["roran-shield"].kind="Personaje"
    ns.EncyclopediaData.nathanos=entry({"Nathanos"},{[200]=true});ns.EncyclopediaData.nathanos.kind="Personaje"
    ns.Narratives={
        [123]={en="Gryan, Owen, Thrall, Sayge, Flint and Darin wait in Durotar."},
        [124]={en="Gryanleigh waits in Durotar."},
        [125]={en="Roran Shield waits in Durotar."},
        [6185]={en="Nathanos remains a mystery."},
        [96896]={en="Garek Bandarion guards the keep."},
    }
    ns.EncyclopediaData.legion=entry({"Burning Legion","Legion"})
    ns.EncyclopediaData.legion.aliasQuestIDs={Legion={[123]=true}}
    ns.EncyclopediaData.legion.en.aliasQuestIDs={Legion={[123]=true}}
    for _,data in pairs(ns.EncyclopediaData) do
        for _,language in ipairs({"fr","de","pt","pl","ru"}) do data[language]={title=data.en.title,body="Translated independent article."} end
    end
    assert(loadfile(root.."/QuestLore/Encyclopedia.lua"))("QuestLore",ns)
    local find=ns.Encyclopedia.FindSpans
    assert(#find("Shared Name","en")==0,"ambiguous longer alias cannot fall back to a shorter different definition")
    assert(#find("Shared","en")==1,"unambiguous exact alias remains clickable")
    assert(#find("Elune'ara Elune’ara Bronzehide Durotarñ áDurotar","en")==0,"internal apostrophes and accented suffixes do not create partial-name links")
    for _,text in ipairs({"Elune's temple","Elune’s temple","'Orgnil'","‘Orgnil’","«Orgnil»","¡Orgnil!","¿Orgnil?","Orgnil—Durotar","Orgnil…"}) do
        local spans=find(text,"en")
        assert(#spans>0,"quote, punctuation or possessive boundary: "..text)
        assert(spans[1].language=="en" and text:sub(spans[1].first,spans[1].last)~="","byte offsets preserve original text")
    end
    local chapel=find("the Light’s Hope","en")
    assert(#chapel==1 and chapel[1].id=="chapel","longest overlapping entity wins even when it starts after a shorter phrase")
    assert(#find("Blue Order","en")==0 and #find("Blue Order","en",123)==1,"scoped alias needs its reviewed quest context")
    assert(#find("Blue Order","en",nil,{scoped=true})==1,"article can explicitly reference a scoped entity")
    assert(#find("Blue Order","en",456)==0,"a shared alias never falls back to an unscoped, unreviewed owner")
    assert(#find("Blue Order","en",nil,{["other-order"]=true})==1,"explicit article references resolve a shared alias")
    assert(#find("Burning Legion","en",456)==1,"alias scope does not restrict the unambiguous full name")
    assert(#find("Legion","en",456)==0 and #find("Legion","en",123)==1,"short form uses its own reviewed quest scope")
    assert(#find("Legion","en",nil,{legion=true})==1,"explicit article context permits its scoped short form")
    for _,language in ipairs({"fr","de","pt","pl","ru"}) do
        assert(#find("Shared Name",language)==0,"translated language preserves ambiguous-name suppression")
        assert(#find("Legion",language,456)==0 and #find("Legion",language,123)==1,"translated language inherits English per-alias scope")
        local span=find("Durotar",language)[1]
        assert(span and span.id=="one" and span.language==language,"shared English name index retains the requested language")
    end
    assert(#find("d'Elune l’Orgnil qu’Elune","fr")==3,"French elisions keep preserved proper names clickable")
    assert(#find("Jin'Elune Elune'ara","fr")==0,"French elisions do not broaden internal name fragments")
    local genitives=find("Orgrimmars Hafen und Thralls Rat","de")
    assert(#genitives==2 and genitives[1].id=="one" and genitives[2].id=="Thrall","German bare genitive s preserves canonical proper-name links")
    assert(("Orgrimmars Hafen"):sub(genitives[1].first,genitives[1].last)=="Orgrimmar","German genitive suffix remains outside the canonical name span")
    for _,language in ipairs({"es","en","fr","pt","pl"}) do
        assert(#find("Orgrimmars Thralls",language)==0,"bare genitive s never broadens other languages")
    end
    assert(#find("Orgrimmarswache Thrallss Thrallsñ Jin'Thralls Thrall'ara Thralls'ara","de")==0,"German genitives reject longer suffixes, UTF-8 words and internal apostrophe fragments")
    assert(#find("Thralls—Orgrimmars…","de")==2,"German terminal genitive s recognizes UTF-8 punctuation boundaries")
    assert(#find("Legions","de",456)==0 and #find("Legions","de",123)==1,"German genitive form still requires the reviewed identity scope")
    local longer=find("Thralls Legacy","de")
    assert(#longer==1 and longer[1].id=="thrall-legacy","longest-name ownership wins over a German genitive-shaped prefix")
    local polish=find("Gryanowi pomaga Owenem, Owena zna Thralla.","pl",123)
    assert(#polish==4 and polish[1].id=="Gryan" and polish[2].id=="Owen" and polish[3].id=="Owen" and polish[4].id=="Thrall","Polish case endings preserve undeformed character-name identities")
    assert(("Gryanowi"):sub(polish[1].first,polish[1].last)=="Gryan","Polish matching does not rewrite the displayed name")
    assert(#find("Sayge’a Sayge'a","pl",123)==2,"Polish apostrophe case endings are supported conservatively")
    assert(#find("Gryanowi","pl")==0 and #find("Gryanowi","pl",124)==0,"Polish inflection requires reviewed context or a literal source-name mention")
    assert(#find("Gryanowi","pl",nil,{Gryan=true})==1,"an explicit encyclopedia reference authorizes its character case form")
    assert(#find("Gareka Bandariona","pl",96896)==0,"Polish inflection cannot confuse Bandarion with scoped Badlands Garek")
    assert(#find("Rorana Shielda","pl",125)==0,"Polish source authorization uses longest resolved entity ownership rather than a short-name word inside another person's full name")
    assert(#find("Nathanosa","pl",6185)==0 and #find("Nathanosa","pl",200)==1,"Polish case forms cannot bypass spoiler-related identity restrictions")
    assert(#find("Darina Flinta","pl",123)==0,"ambiguous owners and exact-name/case-form collisions stay plain")
    assert(#find("Durotara Gryanowicz Gryanowia Thrallañ Jin'Thralla Thralla'ara","pl",123)==0,"Polish inflection rejects places, internal names, longer suffixes and UTF-8 fragments")
    local polishLong=find("Thralla Guard","pl",123)
    assert(#polishLong==1 and polishLong[1].id=="thralla-guard","a longer canonical name wins over a Polish case-shaped prefix")
    for _,language in ipairs({"es","en","fr","de","pt"}) do
        assert(#find("Gryanowi Owena Thralla Sayge’a",language,123)==0,"Polish case recognition does not broaden other languages")
    end
    assert(#find("Shared","it")==0,"unsupported language never borrows an English name index")
    print("PASS: encyclopedia matcher ambiguity, scoped identities, UTF-8 punctuation, internal apostrophes and English possessives")
end
