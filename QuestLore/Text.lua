local _, ns = ...
local Text = {}
ns.Text = Text

-- Lua 5.1's string.lower is not Unicode aware. Fold only for matching;
-- always display the original accented text.
local folds = {
    ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u",
    ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u",
    ["ü"] = "u", ["Ü"] = "u", ["ñ"] = "n", ["Ñ"] = "n",
}

function Text.Fold(value)
    value = type(value) == "string" and value or ""
    for from, to in pairs(folds) do value = value:gsub(from, to) end
    return value:lower()
end

function Text.Clean(value)
    if type(value) ~= "string" then return "" end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("|H.-|h(.-)|h", "%1")
    value = value:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    value = value:gsub("%$[Bb]", "\n\n")
    value = value:gsub("%$[Gg]([^:;]*):([^;]*);", "%1")
    local language = ns.Locale and ns.Locale.Get()
    local adventurer = language=="en" and "adventurer" or language=="zh" and "冒险者" or "aventurero"
    local traveler = language=="en" and "traveler" or language=="zh" and "旅行者" or "viajero"
    value = value:gsub("%$[Nn]", adventurer):gsub("%$[Cc]", adventurer)
    value = value:gsub("%$[Rr]", traveler)
    value = value:gsub("%$[%w]+[^%s]*", "") -- unresolved client tokens
    -- Quest text uses angle brackets for narrative actions, not HTML. Keep
    -- their meaning; some item-started quests consist entirely of an action.
    value = value:gsub("<([^>]*)>", "%1")
    value = value:gsub("\r\n", "\n"):gsub("\r", "\n")
    value = value:gsub("[ \t]+", " "):gsub(" *\n *", "\n")
    value = value:gsub("\n\n\n+", "\n\n")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Text.WordCount(value)
    local n = 0
    for _ in value:gmatch("%S+") do n = n + 1 end
    return n
end

local function hasAny(text, patterns)
    for _, pattern in ipairs(patterns) do
        if text:find(pattern, 1, true) then return true end
    end
    return false
end

local motives = {
    "porque", "por eso", "para que", "necesit", "debemos", "debe ",
    "ayud", "proteger", "defender", "investig", "averiguar", "temo", "teme",
    "sospech", "amenaz", "peligro", "corrup", "envenen", "enferm", "plaga",
    "destrui", "perdid", "desaparec", "atac", "rob", "expuls", "sufr",
    "prision", "atrap", "muri", "muert", "aliment", "hambre", "recurso",
    "abandon", "guardian", "consecuenc", "impedir", "descubri", "busca",
    "because", "need", "threat", "protect", "danger", "poison", "corrupt",
}
local errands = {
    "ve a ", "viaja ", "dirigete", "recoge ", "reune ", "llevame ",
    "traeme ", "entregale ", "vuelve ", "mata a ", "acaba con ",
    "bring ", "collect ", "return to ", "kill ", "go to ",
}

function Text.Sentences(value)
    local result = {}
    -- Keep punctuation and original order, never cut a sentence mid-word.
    value = Text.Clean(value):gsub("%.%.%.?", "…")
    for paragraph in value:gmatch("[^\n]+") do
        local start = 1
        for index in paragraph:gmatch("()[%.%!%?]") do
            local sentence = paragraph:sub(start, index):gsub("^%s+", "")
            if sentence ~= "" then result[#result + 1] = sentence end
            start = index + 1
        end
        local tail = paragraph:sub(start):gsub("^%s+", ""):gsub("%s+$", "")
        if tail ~= "" then result[#result + 1] = tail end
    end
    return result
end

-- An extractive fallback, deliberately not an invented narrative or AI call.
-- Prefer the problem/motivation over directions, rewards and kill counts.
function Text.Extract(description)
    local sentences, ranked, seen = Text.Sentences(description), {}, {}
    for index, sentence in ipairs(sentences) do
        local folded, words = Text.Fold(sentence), Text.WordCount(sentence)
        if words >= 5 and not seen[folded] then
            seen[folded] = true
            local score = index == 1 and 2 or 0
            if hasAny(folded, motives) then score = score + 5 end
            if hasAny(folded, errands) then score = score - 4 end
            if folded:find("%d") then score = score - 3 end
            if hasAny(folded, {"recompensa", "pagare", "oro", "reward", "silver"}) then
                score = score - 3
            end
            if words > 65 then score = score - 3 end
            ranked[#ranked + 1] = { index = index, text = sentence, words = words, score = score }
        end
    end
    table.sort(ranked, function(a, b)
        if a.score == b.score then return a.index < b.index end
        return a.score > b.score
    end)
    local chosen, words = {}, 0
    for _, item in ipairs(ranked) do
        if #chosen == 3 then break end
        if item.score >= 0 and (words + item.words <= 100 or #chosen == 0) then
            chosen[#chosen + 1] = item
            words = words + item.words
        end
    end
    if #chosen == 0 then
        -- A purely mechanical quest has no extra story to infer.
        return Text.Clean(description), "description"
    end
    table.sort(chosen, function(a, b) return a.index < b.index end)
    local result = {}
    for _, item in ipairs(chosen) do result[#result + 1] = item.text end
    return table.concat(result, " "), "extract"
end
