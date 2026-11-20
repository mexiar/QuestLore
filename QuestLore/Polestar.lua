local _, ns = ...
local Bridge = {}
ns.PolestarBridge = Bridge

local function available()
    local addon = _G.Polestar
    if type(addon) == "table" and type(addon.Nav) == "table"
        and type(addon.Nav.GetTarget) == "function"
        and type(addon.On) == "function" and type(addon.Off) == "function" then
        return addon
    end
end

local function field(target, key)
    local value = ns.API.Call(function() return target[key] end)
    if type(value) == "string" or type(value) == "number" then return value end
    return nil
end

local function targetState(addon)
    local target = ns.API.Call(addon.Nav.GetTarget)
    if type(target) ~= "table" then return "none" end
    local quest = tonumber(field(target, "quest"))
    if not quest or quest <= 0 or quest > 2147483647 or quest ~= math.floor(quest) then quest = nil end
    local kind = field(target, "kind")
    -- Identity follows the quest/guide goal, not temporary travel labels or
    -- moving spawn coordinates. This avoids unnecessary selection resets.
    local signature = table.concat({tostring(quest), tostring(kind),
        tostring(field(target, "stepIndex")), tostring(field(target, "goalIndex"))}, ":")
    if kind == "manual" or kind == "accept" then quest = nil end
    return signature, quest
end

function Bridge:IsAvailable()
    return available() ~= nil
end

function Bridge:ReadTarget()
    if not self.owner or self.owner ~= available() then return end
    local signature, quest = targetState(self.owner)
    if signature ~= self.signature then
        self.signature = signature
    end
    self.quest = quest
end

function Bridge:Disconnect()
    local owner, handle = self.owner, self.handle
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
    -- Invalidate first: a stale callback can never restore the old context.
    self.owner, self.handle, self.quest, self.signature, self.lastQuest, self.callbackToken = nil, nil, nil, nil, nil, nil
    if owner and handle then ns.API.Call(owner.Off, handle) end
end

function Bridge:Sync()
    local addon = ns.db.followPolestar and available() or nil
    if self.owner ~= addon then self:Disconnect() end
    if addon and not self.owner then
        self.owner = addon
        local token = {}
        self.callbackToken = token
        local handle = ns.API.Call(addon.On, "WAYPOINT_CHANGED", function()
            if self.owner ~= addon or self.callbackToken ~= token or not ns.db.followPolestar then return end
            -- Read the getter rather than trusting a possibly stale event payload.
            self:ReadTarget()
            ns.QueueRefresh()
        end)
        if handle then self.handle = handle else self:Disconnect() end
    end
    if self.owner and not self.ticker and C_Timer.NewTicker then
        local owner = self.owner
        local token = self.callbackToken
        self.ticker = C_Timer.NewTicker(1, function()
            if self.owner == owner and self.callbackToken == token then self:Poll() end
        end)
    end
    self:ReadTarget()
    if ns.Options then ns.Options:Sync() end
    ns.QueueRefresh()
end

function Bridge:SetEnabled(value)
    ns.db.followPolestar = value == true
    self:Sync()
end

function Bridge:QuestID()
    if not ns.db.followPolestar or not self.owner or self.owner ~= available() then return end
    self:ReadTarget()
    if ns.API.isActive(self.quest) then return self.quest end
end

-- Read-only local recovery for missed/late notifications. Never ask Polestar
-- to recalculate a route or change its waypoint, and avoid repainting steady state.
function Bridge:Poll()
    if not ns.db.followPolestar then return end
    if self.owner ~= available() then self:Sync(); return end
    if not ns.db.visible or not ns.Window.frame:IsVisible() then return end
    local signature = self.signature
    local quest = self:QuestID()
    if signature ~= self.signature or quest ~= self.lastQuest
        or (quest and not ns.FocusedQuestID() and ns.Window.currentID ~= quest) then
        self.lastQuest = quest
        ns.QueueRefresh()
    end
end
