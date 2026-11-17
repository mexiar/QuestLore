-- Run independently with Lua 5.1: lua tests/localization.lua <repository root>
local root = (arg and arg[1]) or "."
local count = 0
local function check(value, message)
    count=count+1
    assert(value, "Localization: "..message)
end
local function equal(actual, expected, message)
    check(actual==expected, message.." ("..tostring(actual).." ~= "..tostring(expected)..")")
end
local ns = { db={language="auto"}, locale="esMX" }
local function load(name) assert(loadfile(root.."/QuestLore/"..name))("QuestLore",ns) end
load("Locale.lua"); load("Text.lua"); load("Model.lua"); load("Origins.lua")
for _,pair in ipairs({{"esMX","es"},{"esES","es"},{"enUS","en"},{"enGB","en"},{"frFR","fr"},{"deDE","de"},{"ptBR","pt"},{"ptPT","pt"},{"koKR","en"},{"zhTW","en"},{"ruRU","en"}}) do
    equal(ns.Locale.Resolve(pair[1]),pair[2],"locale mapping "..pair[1])
    ns.locale=pair[1]; equal(ns.Locale.Get(),pair[2]=="es" and "es" or "en","automatic base language "..pair[1])
end
for _,lang in ipairs({"es","en","fr","de","pt"}) do
    ns.Locale.Set(lang); equal(ns.Locale.Get(),lang,"manual preference "..lang)
end
ns.Locale.Set("invalid"); equal(ns.Locale.Get(),"pt","invalid setting ignored")
ns.Locale.Set("auto"); ns.locale="esES"
equal(ns.Locale.Get(),"es","Spain client uses explicitly labeled Latin America base")
equal(ns.L("Español (Latinoamérica)","en"),"Español (Latinoamérica)","Spanish variant label")
equal(ns.L("Cerrar","fr"),"Fermer","French UI")
equal(ns.L("Cerrar","de"),"Schließen","German UI")
equal(ns.L("Cerrar","pt"),"Fechar","Brazilian Portuguese UI")
equal(ns.L("unregistered string","fr"),"unregistered string","unknown key fallback")
-- Check every UI entry has a nonempty value in each supported dictionary.
local dictionaries
for index=1,20 do
    local name,value=debug.getupvalue(ns.L,index)
    if not name then break end
    if name=="translations" then dictionaries=value end
end
check(type(dictionaries)=="table","UI dictionaries inspectable")
for key in pairs(dictionaries.es) do
    for _,lang in ipairs({"en","fr","de","pt"}) do
        check(type(dictionaries[lang][key])=="string" and dictionaries[lang][key]~="","UI key exists for "..lang..": "..key)
    end
end
for _,key in ipairs({"Leer texto completo","Volver al resumen","Texto original del juego","Cerrar","El texto completo solo está disponible para misiones activas."}) do
    for _,lang in ipairs({"en","fr","de","pt"}) do check(ns.L(key,lang)~=key,"viewer UI localized: "..lang) end
end
ns.Stories={}
ns.Narratives={[101]={en="Arugal needs help in Silverpine Forest.",es="Arugal necesita ayuda en el Bosque de Argénteos.",titleEN="Arugal's Request",titleES="La petición de Arugal"}}
ns.NarrativeTranslations={fr={[101]="Arugal a besoin d’aide dans Silverpine Forest."},de={},pt={}}
local quest={id=101,title="Titre du client",description="Texte du client"}
local translated=ns.Model.Build(quest,"frFR")
equal(translated.language,"fr","French narrative used")
equal(translated.title,"Arugal's Request","translated narrative keeps English quest name")
equal(translated.body,ns.NarrativeTranslations.fr[101],"translation body used")
check(translated.body:find("Silverpine Forest",1,true),"English proper name preserved")
local fallback=ns.Model.Build(quest,"deDE")
equal(fallback.language,"en","missing translation marked English")
equal(fallback.body,ns.Narratives[101].en,"missing translation uses English narrative")
check(fallback.translationFallback,"missing translation carries fallback flag")
equal(fallback.title,ns.Narratives[101].titleEN,"fallback has English title")
ns.locale="frFR"
equal(ns.Model.Build({id=102,description="Une quête inconnue."},"deDE").kind,"missing","foreign-language client text never masquerades as translated narrative")
equal(ns.locale,"frFR","summary choice leaves raw client locale unchanged")
ns.OriginStories={en={["Human:MAGE"]="A human mage finds a place in Stormwind."},es={["Human:MAGE"]="Un mago humano encuentra su lugar en Ventormenta."}}
ns.OriginTranslations={fr={["Human:MAGE"]="Un mage humain trouve sa place à Stormwind."}}
ns.db.language="fr"
local origin=ns.Origins.Build({race="Human",class="MAGE"})
equal(origin.language,"fr","translated origin language")
equal(origin.body,ns.OriginTranslations.fr["Human:MAGE"],"translated origin used")
ns.db.language="de"
origin=ns.Origins.Build({race="Human",class="MAGE"})
equal(origin.language,"en","missing origin translation marked English")
check(origin.translationFallback,"origin fallback marked")
equal(origin.body,ns.OriginStories.en["Human:MAGE"],"origin fallback is actual English text")
equal(ns.Origins.Build({}).kind,"missing","unknown profile safe with translated preference")
print("Localization checks passed: "..count)
