-- Focused regression coverage for the community Polish contribution and current UI.
local root, env = ...
root = root or (arg and arg[1]) or "."
local ns = {db={language="pl",uiLanguage="pl"},locale="plPL"}
local function load(name) assert(loadfile(root.."/QuestLore/"..name))("QuestLore",ns) end
for _,name in ipairs({"Locale.lua","Text.lua","Stories.lua","Narratives.lua","Narratives_pl.lua","Origins_Stories.lua","Origins.lua","Model.lua","History.lua"}) do load(name) end
assert(ns.Text.Fold("ŁÓDŹ ŚWIATŁO")=="lodz swiatlo","Polish case and diacritic folding")
assert(ns.Text.Clean("$N / $C / $R")=="podróżnik / podróżnik / wędrowiec","Polish character-token fallback")
assert(ns.TranslationCoverage.pl.quests==5259 and ns.TranslationCoverage.pl.origins==90,"community contribution counts")
assert(ns.TranslationCoverage.pl.contributor=="dawiss","community authorship retained")
local quest=ns.Model.Build({id=12,title="Lokalny tytuł questa"},"pl")
assert(quest.language=="pl" and quest.body==ns.NarrativeTranslations.pl[12] and not quest.translationFallback,"manual Polish narrative selection")
assert(quest.title=="Lokalny tytuł questa","client title retained")
assert(quest.body:find("Gryanowi",1,true),"contributor’s natural proper-name inflection retained")
local reviewed=ns.NarrativeTranslations.pl[7507]
assert(reviewed:find("z trudem odnalezione",1,true),"source-guarded discovery correction applied")
for key,body in pairs(ns.OriginTranslations.pl) do
    local culture,class=key:match("^(.*):([^:]+)$")
    local faction
    if culture:find(":",1,true) then culture,faction=culture:match("^([^:]+):(.+)$") end
    local intro=ns.Origins.Build({race=culture,class=class,faction=faction})
    assert(intro.body==body and intro.language=="pl" and not intro.translationFallback,"Polish introduction "..key)
end
assert(ns.L("Enciclopedia")=="Encyklopedia","Polish encyclopedia interface")
assert(ns.L("Mostrar fondo")=="Pokaż tło","Polish background option")
assert(ns.L("Mostrar botón de texto completo")=="Pokaż przycisk pełnego tekstu questa","Polish full-text toggle")
assert(ns.L("La misión seleccionada o en foco tiene prioridad. Polestar se usa cuando no hay una misión en foco."):find("ma pierwszeństwo",1,true),"current focus-priority instruction translated")
local missing=ns.Model.Build({id=999999,description="Oryginalny tekst klienta."},"pl")
assert(missing.kind=="preview" and missing.sourceLocale=="plPL" and missing.body:find("Oryginalny tekst klienta",1,true),"missing-summary fallback remains original client text")
if env then
    local character=env.login({language="pl",uiLanguage="pl",attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    local choices=0
    for _,group in ipairs({character.Options.languageChoices,character.Options.uiLanguageChoices}) do
        for _,button in ipairs(group) do
            if button.language=="pl" then choices=choices+1;assert(button.label:GetText()=="Polski","native Polish selector caption") end
        end
    end
    assert(choices==2,"both Polish selectors available")
    local model=character.Model.Build({id=12,title="Tytuł klienta"},"pl")
    character.Window:Render(model)
    assert(character.Window.fullTextButton:GetText()=="Czytaj pełny tekst questa","Polish full-text action")
    local history=character.History.New({model})
    assert(history.entries[1].body==character.NarrativeTranslations.pl[12],"Polish summary archive")
    local reloaded=env.login(character.db)
    assert(reloaded.Locale.Get()=="pl" and reloaded.Locale.GetUI()=="pl","Polish preferences persist per character")
end
print("PASS: Polish contribution, 90 integrated introductions, inflected names, current UI, client-text fallback and saved selectors")
