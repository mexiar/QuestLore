local _, ns = ...
local API = {}
ns.API = API
local log = C_QuestLog or {}
local super = C_SuperTrack or {}

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    -- Never compare or persist a secret value from the modern client.
    if issecretvalue and (issecretvalue(a) or issecretvalue(b)) then return nil end
    return a, b
end
API.Call = call

local function id(value)
    if type(value) == "number" and value > 0 then return value end
    return nil
end

function API.isActive(questID)
    if not id(questID) then return false end
    local index = call(log.GetLogIndexForQuestID, questID)
    return type(index) == "number" and index > 0
end

function API.isLogVisible()
    local details = QuestMapFrame and QuestMapFrame.DetailsFrame
    return details and details:IsVisible() or false
end

function API.selected()
    local details = QuestMapFrame and QuestMapFrame.DetailsFrame
    return id(details and details.questID) or id(call(log.GetSelectedQuest))
end

function API.superTracked()
    return id(call(super.GetSuperTrackedQuestID))
end

function API.watched()
    local result = {}
    local count = call(log.GetNumQuestWatches) or 0
    for index = 1, math.min(count, 200) do
        local questID = id(call(log.GetQuestIDForQuestWatchIndex, index))
        if questID then result[#result + 1] = questID end
    end
    return result
end

function API.Read(questID)
    local original = API.ReadOriginal(questID, true)
    if original then
        return {id=questID,title=original.title,description=original.description,
            objectives=original.objectives,sourceLocale=original.locale}
    end
end

-- Full quest prose is read from the current log only, in the client's locale.
-- Never serve it from the narrative archive or an earlier quest's source cache.
function API.ReadOriginal(questID, allowEmpty)
    if not id(questID) then return nil end
    local index = call(log.GetLogIndexForQuestID, questID)
    if type(index) ~= "number" or index <= 0 then return nil end
    local info = call(log.GetInfo, index)
    local rawTitle
    if type(info) == "table" then
        local logID = info.questID
        if issecretvalue and issecretvalue(logID) then return nil end
        if logID and logID ~= questID then return nil end
        rawTitle = info.title
    else
        rawTitle = call(log.GetTitleForQuestID, questID)
    end
    local description, objectives = call(GetQuestLogQuestText, index)
    -- Preserve the original client wording; guard every display field without
    -- applying the summary cleaner or replacing narrative stage directions.
    local function plain(value)
        if issecretvalue and issecretvalue(value) then return nil end
        return type(value) == "string" and value or nil
    end
    local title = plain(rawTitle)
    if not title or title == "" then title = plain(call(log.GetTitleForQuestID, questID)) end
    description, objectives = plain(description), plain(objectives)
    description = description or ""
    if not allowEmpty and description:match("^%s*$") and (not objectives or objectives:match("^%s*$")) then return nil end
    if call(log.GetLogIndexForQuestID, questID) ~= index then return nil end
    return { id=questID, title=title or "", description=description,
             objectives=objectives or "", locale=(GetLocale and GetLocale()) or ns.locale }
end

function API.Request(questID)
    call(log.RequestLoadQuestByID, questID)
end

function API.HasQuests()
    local rows, count = call(log.GetNumQuestLogEntries)
    if type(count) == "number" then return count > 0 end
    if type(rows) ~= "number" then return nil end
    for index = 1, math.min(rows, 500) do
        local info = call(log.GetInfo, index)
        if type(info) == "table" and not info.isHeader and id(info.questID) then return true end
    end
    return false
end

function API.Profile()
    local raceName, race = call(UnitRace, "player")
    local className, class = call(UnitClass, "player")
    local faction = call(UnitFactionGroup, "player")
    return { raceName = raceName, race = race, className = className, class = class, faction = faction, level = call(UnitLevel, "player") }
end
