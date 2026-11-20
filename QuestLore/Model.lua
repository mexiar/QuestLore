local _, ns = ...
local Model = {}
ns.Model = Model

-- API-independent selection policy, shared by the addon and regression tests.
function Model.Resolve(api)
    local function valid(id) return api.isActive(id) and id or nil end
    if api.isLogVisible() then
        local selected = valid(api.selected())
        if selected then return selected, "selected" end
    end
    local tracked = valid(api.superTracked())
    if tracked then return tracked, "tracked" end
    for _, id in ipairs(api.watched()) do
        local watched = valid(id)
        if watched then return watched, "watched" end
    end
    return nil, "none"
end

function Model.Build(quest, locale)
    local language = ns.Locale.Resolve(locale or ns.Locale.Get())
    local function translated(key) return ns.L(key, language) end
    if not quest then
        return {
            title = ns.L("Selecciona una misión"),
            body = ns.L("Abre el diario y selecciona una misión, o sigue una para leer por qué estás haciéndola."),
            source = "", kind = "empty", key = "empty",
        }
    end
    local description = ns.Text.Clean(quest.description)
    local result = { id = quest.id, key = "quest:" .. quest.id, title = ns.Text.Clean(quest.title), gameTitle = ns.Text.Clean(quest.title), language = language, requestedLanguage = language }
    if result.title == "" then result.title = ns.L("Misión ") .. quest.id end
    local bilingual = ns.Narratives and ns.Narratives[quest.id]
    local legacy = ns.Stories[quest.id]
    local validLegacy = true
    if legacy and not legacy.byID and description~="" and ns.Locale.Resolve(ns.locale or "esMX")=="es" then
        for _, anchor in ipairs(legacy.anchors) do
            if not ns.Text.Fold(description):find(ns.Text.Fold(anchor),1,true) then validLegacy=false; break end
        end
        if legacy.titles then
            validLegacy=false
            for _, title in ipairs(legacy.titles) do
                if ns.Text.Fold(result.title)==ns.Text.Fold(title) then validLegacy=true; break end
            end
        end
    end
    result.guardRejected = not validLegacy
    if language ~= "es" and language ~= "en" and validLegacy then
        local bank = ns.NarrativeTranslations and ns.NarrativeTranslations[language]
        local body = bank and bank[quest.id]
        if body and body ~= "" then
            result.body, result.kind = body, "story"
            result.source = translated("Resumen narrativo · sin adelantar la historia")
            if result.gameTitle == "" then result.title = bilingual and bilingual.titleEN or (ns.L("Misión ", "en") .. quest.id) end
            return result
        end
        -- A missing translated body uses English; the client title stays localized.
        if bilingual and bilingual.en then
            result.body, result.kind, result.language = bilingual.en, "story", "en"
            if result.gameTitle == "" then result.title = bilingual.titleEN or (ns.L("Misión ", "en") .. quest.id) end
            result.source = ns.L("Resumen narrativo · sin adelantar la historia", "en")
            result.translationFallback = true
            return result
        end
    end
    if bilingual and bilingual[language] and validLegacy then
        result.body, result.kind, result.language = bilingual[language], "story", language
        result.source = translated("Resumen narrativo · sin adelantar la historia")
        local title = language=="es" and bilingual.titleES or bilingual.titleEN
        if result.gameTitle == "" and title and title~="" then result.title=title end
        return result
    end
    local regional = ns.Stories[quest.id]
    if regional and regional.byID and language == "es" then
        result.body, result.kind = regional.text, "story"
        result.source = translated("Resumen narrativo · sin adelantar la historia")
        return result
    end
    local original = type(quest.description)=="string" and quest.description or ""
    if type(quest.objectives)=="string" and quest.objectives~="" then
        original = original .. (original~="" and "\n\n" or "") .. quest.objectives
    end
    local preview = ns.Text.Preview(original)
    if preview == "" then
        result.kind = quest.loading and "loading" or "missing"
        result.body = quest.loading and ns.L("Cargando el relato de la misión…")
            or ns.L("Todavía no hay relato disponible para esta misión. Prueba a abrir sus detalles en el diario.")
        result.source = ""
        return result
    end
    local story = ns.Stories[quest.id]
    if story and language == "es" then
        local matches, folded = true, ns.Text.Fold(description)
        -- Guard against ID reuse or changes to a Forever quest's story.
        for _, anchor in ipairs(story.anchors) do
            if not folded:find(ns.Text.Fold(anchor), 1, true) then matches = false; break end
        end
        if story.titles then
            matches = false
            for _, title in ipairs(story.titles) do
                if ns.Text.Fold(result.title) == ns.Text.Fold(title) then matches = true; break end
            end
        end
        if matches then
            result.body, result.kind = story.text, "story"
            result.source = translated("Resumen narrativo · sin adelantar la historia")
            return result
        end
    end
    result.sourceLocale = quest.sourceLocale or ns.locale or "enUS"
    result.language = ns.Locale.Resolve(result.sourceLocale)
    result.body, result.kind = preview, "preview"
    result.source = ns.L("Descripción de la misión", result.language)
    return result
end
