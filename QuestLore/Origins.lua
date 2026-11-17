local _, ns = ...
local Origins = {}
ns.Origins = Origins
function Origins.Build(profile)
    profile = profile or {}
    local race = profile.race == "Undead" and "Scourge" or profile.race
    local culture = race
    if race == "Skyborne" then culture = race .. ":" .. (profile.faction == "Horde" and "Horde" or "Alliance") end
    local language = ns.Locale.Get()
    local requestedLanguage = language
    local key = culture and (culture .. ":" .. (profile.class or ""))
    local bank = ns.OriginStories and ns.OriginStories[language]
    if language ~= "es" and language ~= "en" then
        bank = ns.OriginTranslations and ns.OriginTranslations[language]
    end
    local body = key and bank and bank[key]
    local fallback = false
    if not body and key and language ~= "es" and language ~= "en" then
        body = ns.OriginStories and ns.OriginStories.en and ns.OriginStories.en[key]
        if body then language, fallback = "en", true end
    end
    if not body then
        return {key="origins:unknown",kind="missing",title=ns.L("Tu lugar en Azeroth"),source="",
            body=ns.L("Todavía no se pudo leer tu raza y tu clase. El contexto aparecerá cuando tu personaje termine de cargar.")}
    end
    return {key="origins:"..race..":"..profile.class..":"..(profile.faction or ""),
        title=ns.L("Tu lugar en Azeroth"),body=body,source="",kind="origins",language=language,requestedLanguage=requestedLanguage,translationFallback=fallback}
end
