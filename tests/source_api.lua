local root = ... or "."
local active, info, description, objectives = true, {questID=42,title="Titre du client"}, "<Un geste.>\n"..string.rep("Texte original. ",300), "Objectifs du client"
local secondIndex, secret
local globals = {
    C_QuestLog = {
        GetLogIndexForQuestID=function() if secondIndex then return secondIndex() end;return active and 3 or 0 end,
        GetInfo=function() return info end,
        GetTitleForQuestID=function() return "fallback" end,
    },
    GetQuestLogQuestText=function(index) assert(index==3);return description,objectives end,
    GetLocale=function() return "frFR" end,
    issecretvalue=function(value) return secret~=nil and value==secret end,
}
local env=setmetatable(globals,{__index=_G})
local ns={};local chunk=assert(loadfile(root.."/QuestLore/QuestAPI.lua"));setfenv(chunk,env);chunk("QuestLore",ns)
local raw=assert(ns.API.ReadOriginal(42))
assert(raw.description==description and #raw.description>3000,"full original text must not be truncated or cleaned")
assert(raw.objectives==objectives and raw.locale=="frFR" and raw.title==info.title,"full text uses client prose and locale")
secret=42;assert(ns.API.ReadOriginal(42)==nil,"secret quest identity is not compared or exposed");secret=nil
assert(ns.API.ReadOriginal(nil)==nil and ns.API.ReadOriginal(-42)==nil)
active=false;assert(ns.API.ReadOriginal(42)==nil,"past quest unavailable")
active=true;info={questID=99,title="Other quest"};assert(ns.API.ReadOriginal(42)==nil,"reused log index rejected")
info={questID=42,title="Titre du client"}
local n=0;secondIndex=function() n=n+1;return n==1 and 3 or 4 end
assert(ns.API.ReadOriginal(42)==nil,"log identity must survive the read")
secondIndex=nil;description="  ";raw=assert(ns.API.ReadOriginal(42));assert(raw.objectives==objectives,"objective-only active quests remain readable")
local savedObjectives=objectives;objectives=" ";assert(ns.API.ReadOriginal(42)==nil,"empty original text is not invented");objectives=savedObjectives
description="Original";secret=description;assert(ns.API.ReadOriginal(42)==nil,"secret original text is not read")
secret=objectives;assert(ns.API.ReadOriginal(42)==nil,"secret secondary return is not exposed")
print("PASS: active-only full original quest API, complete body, client locale, stale indices and secret guards")
