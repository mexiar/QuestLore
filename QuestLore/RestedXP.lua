local _, ns = ...
local Bridge = {}
ns.RestedXPBridge = Bridge

local messages = {"RXP_GUIDE_LOADED", "RXP_STEP_COMPLETE", "RXP_OBJECTIVE_COMPLETE", "RXP_TARGET_LIST_UPDATE"}
local questTags = {complete=true, turnin=true, collect=true, questgoto=true, questwaypoint=true}
local function library(name)
    if not LibStub then return end
    return ns.API.Call(function() return LibStub(name, true) end)
end
local function available()
    -- RXPGuides' global is only its import facade. The live engine is AceAddon.
    local ace = library("AceAddon-3.0")
    if type(ace) ~= "table" or type(ace.GetAddon) ~= "function" then return end
    local addon = ns.API.Call(ace.GetAddon, ace, "RXPGuides", true)
    if type(addon) == "table" and type(addon.GetGuideProgress) == "function" then return addon end
end
local function field(object, key)
    if type(object) == "table" then return ns.API.Call(function() return object[key] end) end
end
local function validID(id)
    id = tonumber(id)
    if id and id > 0 and id <= 2147483647 and id == math.floor(id) then return id end
end
local function activeStep(addon, step)
    local guide = field(addon, "currentGuide")
    local steps = field(guide, "steps")
    local index = validID(field(step, "index"))
    return index and field(steps, index) == step and field(step, "active") == true
        and not field(step, "completed")
end
local function elementQuest(addon, element, seen, depth)
    if type(element) ~= "table" or depth > 8 or seen[element] then return end
    seen[element] = true
    if field(element, "completed") or field(element, "skip") or field(element, "hidden") then return end
    local step = field(element, "step")
    if not activeStep(addon, step) then return end
    local tag = field(element, "tag")
    -- Never turn an acceptance recommendation or a condition into a live quest.
    if tag == "accept" then return end
    if questTags[tag] then
        local id = validID(field(element, "questId"))
        if id and ns.API.isActive(id) then return id end
    end
    return elementQuest(addon, field(element, "source"), seen, depth+1)
        or elementQuest(addon, field(element, "parent"), seen, depth+1)
end
local function readTarget(addon)
    local profile = field(field(addon, "settings"), "profile")
    if field(profile, "showEnabled") == false then return end
    local arrow = field(addon, "arrowFrame")
    local shown = type(field(arrow, "IsShown")) == "function" and ns.API.Call(arrow.IsShown, arrow)
    if shown and not field(profile, "disableArrow") and not field(addon, "hideArrow") then
        local id = elementQuest(addon, field(arrow, "element"), {}, 0)
        if id then return id end
    end
    local guide = field(addon, "currentGuide")
    local progress = validID(ns.API.Call(addon.GetGuideProgress))
    local step = progress and field(field(guide, "steps"), progress)
    if not activeStep(addon, step) then return end
    local elements = field(step, "elements")
    if type(elements) ~= "table" or #elements > 500 then return end
    local unique
    -- No arbitrary choice among multiple guide objectives or sticky steps.
    for index = 1, #elements do
        local id = elementQuest(addon, elements[index], {}, 0)
        if id then
            if unique and unique ~= id then return end
            unique = id
        end
    end
    return unique
end
function Bridge:IsAvailable() return available() ~= nil end
function Bridge:QuestID()
    if not ns.db.followRestedXP or not self.owner or self.owner ~= available() then return end
    return ns.API.Call(readTarget, self.owner)
end
function Bridge:Poll(force)
    if not ns.db.followRestedXP then return end
    if self.owner ~= available() then self:Sync(); return end
    if not force and (not ns.db.visible or not ns.Window.frame:IsVisible()) then return end
    local quest = self:QuestID()
    if quest ~= self.lastQuest then
        self.lastQuest = quest
        ns.ClearSelectionContext()
        ns.QueueRefresh()
    end
end
function Bridge:Disconnect()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
    local listener = self.listener
    self.owner, self.listener, self.lastQuest, self.token = nil, nil, nil, nil
    if listener then ns.API.Call(listener.UnregisterAllMessages, listener) end
end
function Bridge:Sync()
    local owner = ns.db.followRestedXP and available() or nil
    if owner ~= self.owner then self:Disconnect() end
    if owner and not self.owner then
        self.owner, self.token = owner, {}
        local token = self.token
        -- Use our own AceEvent listener, never replace RXP's registrations.
        local ace = library("AceEvent-3.0")
        if type(ace) == "table" and type(ace.Embed) == "function" then
            local listener = {}
            ns.API.Call(ace.Embed, ace, listener)
            if type(listener.RegisterMessage) == "function" then
                self.listener = listener
                for _, message in ipairs(messages) do
                    ns.API.Call(listener.RegisterMessage, listener, message, function()
                        if self.owner == owner and self.token == token and ns.db.followRestedXP then self:Poll(true) end
                    end)
                end
            end
        end
        if C_Timer.NewTicker then
            self.ticker = C_Timer.NewTicker(1, function()
                if self.owner == owner and self.token == token then self:Poll() end
            end)
        end
    end
    if owner then self:Poll(true) end
    if ns.Options then ns.Options:Sync() end
    ns.QueueRefresh()
end
function Bridge:SetEnabled(value)
    ns.db.followRestedXP = value == true
    self:Sync()
end
