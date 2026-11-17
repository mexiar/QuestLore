-- Runtime coverage gates; these are not a substitute for linguistic review.
local root = (arg and arg[1]) or "."
local ns = {db={language="en"},locale="enUS"}
local function load(name) assert(loadfile(root.."/QuestLore/"..name))("QuestLore",ns) end
load("Text.lua");load("Locale.lua");load("Stories.lua")
load("Narratives.lua");load("Origins_Stories.lua")
for _,lang in ipairs({"fr","de","pt"}) do load("Narratives_"..lang..".lua") end
load("Origins.lua");load("Model.lua");load("History.lua")
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
assert(count(ns.Narratives)==5259)
for _,lang in ipairs({"fr","de","pt"}) do
    local bank=assert(ns.NarrativeTranslations[lang],"missing language "..lang)
    local origins=assert(ns.OriginTranslations[lang],"missing introductions "..lang)
    assert(count(bank)==5259 and count(origins)==90,"translation coverage "..lang)
    ns.db.language=lang
    for id,original in pairs(ns.Narratives) do
        local text=assert(bank[id],"missing quest "..id..lang)
        assert(type(text)=="string" and text:find("%S"),"nonempty translated text")
        assert(text~=original.en,"English fallback is not a completed translation: "..id..lang)
        assert(not text:find("ZXQ") and not text:find("<unk>") and not text:find("__P%d"),"unresolved marker "..id..lang)
        local model=ns.Model.Build({id=id,title="Client title"},lang)
        assert(model.body==text and model.language==lang and not model.translationFallback,"selected bank "..id..lang)
        assert(model.title=="Client title","translated bank preserves client title "..id..lang)
    end
    for key,original in pairs(ns.OriginStories.en) do
        local text=assert(origins[key],"missing introduction "..key..lang)
        assert(type(text)=="string" and text:find("%S") and text~=original,"translated introduction "..key..lang)
        assert(not text:find("ZXQ") and not text:find("<unk>"),"unresolved introduction marker")
    end
    local history=ns.History.New({{key="quest:363",id=363,title="Old",body="Old",kind="story",source=""}})
    assert(history.entries[1].body==bank[363] and history.entries[1].description==nil,"translated summary archive")
    local localizedHistory=ns.History.New({{key="quest:363",id=363,title="Old English title",gameTitle="Titre localisé",body="Old",kind="story",source=""}})
    assert(localizedHistory.entries[1].title=="Titre localisé" and localizedHistory.entries[1].body==bank[363],"archive preserves localized game title while translating narrative")
    local intro=ns.Origins.Build({race="Scourge",class="PRIEST",faction="Horde"})
    assert(intro.language==lang and intro.body==origins["Scourge:PRIEST"],"translated origin selection")
end
print("PASS: 15,777 translated quest summaries and 270 introductions; exhaustive selection, no empty/English fallback/sentinel, localized client titles and summary-only history")
