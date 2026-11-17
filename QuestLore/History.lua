local _, ns = ...
local History = {}
History.__index = History
History.LIMIT = 200
ns.History = History

local fields = { "key", "id", "title", "body", "source", "kind", "language", "requestedLanguage", "translationFallback", "gameTitle", "guardRejected" }
-- Archive authored summaries only. A client description/excerpt can be shown
-- live, but must never become a saved full-text archive of past quests.
local kinds = { story = true, origins = true }
local function snapshot(model)
    local result = {}
    for _, field in ipairs(fields) do result[field] = model[field] end
    if model.kind == "origins" then
        local race, class, faction = model.key:match("^origins:([^:]+):([^:]+):?(.*)$")
        if race and class then return ns.Origins.Build({race=race,class=class,faction=faction}) end
    end
    local bilingual = ns.Narratives and ns.Narratives[model.id]
    if bilingual and not model.guardRejected then
        return ns.Model.Build({id=model.id,title=model.gameTitle or model.title},ns.Locale.Get())
    end
    local regional = ns.Stories[model.id]
    if regional and (regional.byID or model.kind == "story") then
        result.body, result.kind = regional.text, "story"
        result.source = "Resumen narrativo · sin adelantar la historia"
        result.language = "es"
    end
    return result
end
local function isReadable(model)
    return type(model) == "table" and kinds[model.kind] == true
        and type(model.key) == "string" and type(model.title) == "string"
        and type(model.body) == "string" and model.body ~= ""
        and type(model.source) == "string"
end

function History.New(saved)
    local entries, positions = {}, {}
    if type(saved) == "table" then
        for _, model in ipairs(saved) do
            -- Old installations may have stored a raw extract. Upgrade it only
            -- when a current authored summary replaces that original text.
            local legacy = type(model) == "table" and (model.kind == "extract" or model.kind == "description")
                and model.id and ns.Narratives and ns.Narratives[model.id]
            if isReadable(model) or legacy then
                local copy = snapshot(model)
                if isReadable(copy) then
                    local index = positions[copy.key]
                    if index then
                        entries[index] = copy
                    else
                        entries[#entries + 1] = copy
                        positions[copy.key] = #entries
                    end
                end
            end
        end
    end
    while #entries > History.LIMIT do table.remove(entries, 1) end
    return setmetatable({ entries = entries }, History)
end

function History:Find(key)
    for index, entry in ipairs(self.entries) do
        if entry.key == key then return index end
    end
end

function History:Record(model)
    if not isReadable(model) then return end
    local copy = snapshot(model)
    if not isReadable(copy) then return end
    local index = self:Find(copy.key)
    if index then
        self.entries[index] = copy
        return index
    end
    self.entries[#self.entries + 1] = copy
    if #self.entries > History.LIMIT then
        table.remove(self.entries, 1)
        if self.cursor then self.cursor = math.max(1, self.cursor - 1) end
    end
    return #self.entries
end

function History:Update(model, followSelection)
    self.live = model
    -- An explicit quest click focuses its existing page. Background progress
    -- updates preserve a page the player is reading with the history arrows.
    if followSelection then self.cursor = nil end
    if not self.cursor then self:Record(model) end
    return self:Current()
end

function History:Current()
    local model = self.cursor and self.entries[self.cursor] or self.live
    if model and model.language and model.language ~= ns.Locale.Get() then
        if model.id then
            if model.guardRejected then
                return {key=model.key,id=model.id,title=model.title,kind="missing",source="",
                    body=ns.L("Este relato todavía no tiene una traducción al idioma elegido.")}
            end
            return ns.Model.Build({id=model.id,title=model.gameTitle or model.title},ns.Locale.Get())
        end
    end
    return model
end

function History:LiveIndex()
    if not isReadable(self.live) then return end
    local index = self:Find(self.live.key)
    local saved = index and self.entries[index]
    if saved and saved.body == self.live.body and saved.source == self.live.source then return index end
end

function History:IsAtLiveEnd()
    return self:LiveIndex() == #self.entries and #self.entries > 0
end

function History:State()
    local total = #self.entries
    local liveIndex = self:LiveIndex()
    local index = self.cursor or liveIndex
    return {
        index = index or 0, total = total, browsing = self.cursor ~= nil,
        canBack = index and index > 1 or (not index and total > 0),
        canForward = index ~= nil and index < total,
        newLive = self.cursor ~= nil and liveIndex == nil,
    }
end

function History:Move(direction)
    if type(direction) ~= "number" or direction == 0 then return false end
    local state = self:State()
    if direction < 0 and not state.canBack then return false end
    if direction > 0 and not state.canForward then return false end
    local index = self.cursor or self:LiveIndex() or (#self.entries + 1)
    index = index + (direction < 0 and -1 or 1)
    if index == self:LiveIndex() then self.cursor = nil else self.cursor = index end
    return true
end

function History:GoLive()
    self.cursor = nil
    if self.live then self:Record(self.live) end
    return self.live
end

function History:Relocalize()
    for i, entry in ipairs(self.entries) do self.entries[i] = snapshot(entry) end
    if self.live and (self.live.kind == "origins" or self.live.id) then self.live = snapshot(self.live) end
end
