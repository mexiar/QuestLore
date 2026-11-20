local _, ns = ...
local Updates = {}
ns.Updates = Updates

-- Compare installed release tags only. This module makes no network requests,
-- sends no addon messages, registers no events and creates no timers.
local function versionParts(value)
    if type(value)~="string" or #value>48 then return end
    local major,minor,patch,suffix=value:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
    if not major then return end
    local rank,serial=4,0
    if suffix~="" then
        local stage,number=suffix:match("^%-(%a+)(%d+)$")
        rank=({alpha=1,beta=2,rc=3})[stage]
        serial=tonumber(number)
        if not rank or not serial then return end
    end
    local parts={tonumber(major),tonumber(minor),tonumber(patch),rank,serial}
    for _,number in ipairs(parts) do if number>100000 then return end end
    return parts
end

function Updates.Compare(left,right)
    local a,b=versionParts(left),versionParts(right)
    if not a or not b then return end
    for i=1,#a do
        if a[i]~=b[i] then return a[i]>b[i] and 1 or -1 end
    end
    return 0
end

function Updates:Version()
    return ns.ReleaseNotes and ns.ReleaseNotes.version
end

function Updates:Notes(language)
    local notes=ns.ReleaseNotes and ns.ReleaseNotes.notes or {}
    return notes[language or ns.Locale.GetUI()] or notes.en or ns.L("No hay notas disponibles para esta versión.")
end

-- Keep a small, newest-first archive bundled with the installed addon.
function Updates:Changelog(language)
    language=language or ns.Locale.GetUI()
    local entries=ns.ReleaseNotes and ns.ReleaseNotes.history or {}
    local sections={}
    for i=1,math.min(5,#entries) do
        local entry=entries[i]
        sections[#sections+1]=(entry.notes[language] or entry.notes.en or "")
    end
    return #sections>0 and table.concat(sections,"\n\n--------------------\n\n") or self:Notes(language)
end

function Updates:Refresh()
    if ns.Window and ns.Window.frame then ns.Window:Layout();ns.Window:QueueLayout() end
    if ns.Options and ns.Options.slider then ns.Options:Sync() end
end

function Updates:Initialise(migratingExistingCharacter)
    local db=ns.db
    local current=self:Version()
    if type(db.acknowledgedUpdateVersions)~="table" then db.acknowledgedUpdateVersions={} end
    if versionParts(db.lastSeenUpdateVersion) then db.acknowledgedUpdateVersions[db.lastSeenUpdateVersion]=true end
    if db.showUpdateNotices==nil then db.showUpdateNotices=true end
    if not versionParts(current) then return end
    local previous=db.lastUpdateVersion
    local difference=self.Compare(current,previous)
    if difference and difference>0 then
        db.unreadUpdateVersion=current
    elseif difference and difference<0 then
        db.unreadUpdateVersion=nil -- a downgrade is not a new release
    elseif not difference then
        if migratingExistingCharacter then db.unreadUpdateVersion=current
        else db.unreadUpdateVersion=nil;db.lastSeenUpdateVersion=current end
    elseif db.unreadUpdateVersion~=current then
        db.unreadUpdateVersion=nil
    end
    if db.acknowledgedUpdateVersions[current] then db.unreadUpdateVersion=nil end
    db.lastUpdateVersion=current
end

function Updates:Notice()
    local db=ns.db
    local current=self:Version()
    if not db or db.showUpdateNotices==false or not versionParts(current) then return end
    if db.unreadUpdateVersion==current and db.lastSeenUpdateVersion~=current
        and not (db.acknowledgedUpdateVersions and db.acknowledgedUpdateVersions[current]) then
        return {key=current,kind="installed",version=current,label=ns.L("Actualizado - Ver novedades")}
    end
end

function Updates:Dismiss()
    if not ns.db then return end
    if type(ns.db.acknowledgedUpdateVersions)~="table" then ns.db.acknowledgedUpdateVersions={} end
    local current=self:Version()
    if versionParts(current) then ns.db.acknowledgedUpdateVersions[current]=true end
    ns.db.lastSeenUpdateVersion=current
    ns.db.unreadUpdateVersion=nil
    self:Refresh()
end

function Updates:SetNoticesEnabled(enabled)
    ns.db.showUpdateNotices=enabled==true
    self:Refresh()
end

function Updates:Open()
    if InCombatLockdown and InCombatLockdown() then return false end
    if not (ns.Options and ns.Options.OpenUpdates) then return false end
    if ns.Options:OpenUpdates()==false then return false end
    self:Dismiss()
    return true
end
