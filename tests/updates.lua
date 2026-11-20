return function(env)
    local function load(name,ns) assert(loadfile(env.root.."/QuestLore/"..name))("QuestLore",ns) end
    local fixture={db={},Locale={GetUI=function() return "en" end},L=function(key) return key end}
    load("ReleaseNotes.lua",fixture);load("Updates.lua",fixture)
    local u=fixture.Updates
    local version=u:Version()
    assert(type(version)=="string" and u.Compare(version,version)==0,"installed notes declare a valid release version")
    for _,pair in ipairs({{"0.18.0-alpha1","0.18.0-alpha2"},{"0.18.0-alpha9","0.18.0-beta1"},{"0.18.0-beta9","0.18.0-rc1"},{"0.18.0-rc9","0.18.0"},{"0.18.9","0.19.0"},{"0.99.9","1.0.0"}}) do
        assert(u.Compare(pair[1],pair[2])==-1 and u.Compare(pair[2],pair[1])==1,"version ordering includes prerelease stages and numeric components")
    end
    for _,bad in ipairs({"latest","0.18","v0.18.0","0.18.0-beta","0.18.0-preview1","0.18.0-beta1 junk","100001.0.0",string.rep("1",49)}) do
        assert(u.Compare(version,bad)==nil and u.Compare(bad,version)==nil,"malformed versions cannot create a false upgrade")
    end
    assert(#fixture.ReleaseNotes.history==5,"bundle contains exactly the last five releases")
    assert(fixture.ReleaseNotes.history[1].version==version,"installed version leads the archive")
    for _,language in ipairs({"es","en","fr","de","pt","pl","ru"}) do
        local archive=u:Changelog(language)
        for i,entry in ipairs(fixture.ReleaseNotes.history) do
            assert(entry.notes[language],"every archived release is localized")
            assert(archive:find(entry.notes[language],1,true),"all five releases appear in the changelog")
            if i>1 then assert(u.Compare(fixture.ReleaseNotes.history[i-1].version,entry.version)>0,"archive is newest first") end
        end
    end
    u:Initialise(false)
    assert(fixture.db.showUpdateNotices==true and not u:Notice() and fixture.db.lastSeenUpdateVersion==version,"new install stores installed version without an initial notice")
    fixture.db={}
    u:Initialise(true)
    assert(u:Notice().version==version and u:Notice().kind=="installed","first legacy migration surfaces the installed release once")
    u:Initialise(true)
    assert(u:Notice() and fixture.db.unreadUpdateVersion==version,"unread release persists through reinitialization")
    u:Dismiss();u:Initialise(true)
    assert(not u:Notice() and fixture.db.lastSeenUpdateVersion==version,"acknowledged migration never resurrects on reload")
    fixture.ReleaseNotes.version="0.18.1"
    u:Initialise(true)
    assert(u:Notice() and u:Notice().version=="0.18.1","a later installed release creates one new notice")
    fixture.ReleaseNotes.version="0.17.4"
    u:Initialise(true)
    assert(not u:Notice() and fixture.db.unreadUpdateVersion==nil,"downgrade clears rather than advertises an older installed version")
    fixture.ReleaseNotes.version=version
    u:Initialise(true)
    assert(not u:Notice(),"reinstalling a previously acknowledged version after a downgrade does not repeat its notice")
    fixture.db.acknowledgedUpdateVersions="malformed";u:Initialise(true)
    assert(type(fixture.db.acknowledgedUpdateVersions)=="table" and not u:Notice(),"legacy acknowledgement safely repairs malformed version history")

    -- Exercise actual Core's migration boundary: arbitrary settings are not a legacy install.
    local first=env.login(nil);env.tick(0.2)
    assert(first.Updates and not first.Updates:Notice() and first.db.showUpdateNotices,"fresh Core fixture loads updates without showing a banner")
    local settingsOnly=env.login({fontSize=17,attachToTracker=false});env.tick(0.2)
    assert(not settingsOnly.Updates:Notice(),"settings-only tables are not mistaken for an established installation")
    local ns=env.login({locale="esMX",build="70959",language="es",uiLanguage="en",attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    assert(ns.Updates:Notice() and ns.db.lastUpdateVersion==version,"legacy locale/build marker migrates to current installed version")
    local saved=ns.db
    ns=env.login(saved);env.tick(0.2)
    assert(ns.Updates:Notice(),"a real character reload retains the unread installed release")
    ns.QueueRefresh=function() end
    local w,o=ns.Window,ns.Options
    ns.API.isActive=function(id) return id==12 end
    ns.API.ReadOriginal=function(id) return id==12 and {id=id,title="Original",description="Complete original quest text."} or nil end
    w:Render({id=12,key="quest:12",title="Quest title",body="A short narrative that must remain unchanged.",kind="story",language="en"})
    local currentID,currentKey,body,historyCount=w.currentID,w.currentKey,w.body:GetText(),#ns.history.entries
    local historyKey=ns.history:Current() and ns.history:Current().key
    assert(w.updateNoticeButton:IsShown() and w.updateNoticeClose:IsShown(),"unread installed release appears in the actual footer")
    local closePoint,gripPoint=w.updateNoticeClose.point,w.grip.point
    local closeRight=w.frame:GetWidth()+closePoint[#closePoint-1]
    local gripLeft=w.frame:GetWidth()+gripPoint[#gripPoint-1]-w.grip:GetWidth()
    local noticeRight=8+w.updateNoticeButton:GetWidth()
    assert(closeRight<=gripLeft-4,"notice close hitbox stays clear of the active resize grip")
    assert(noticeRight<=closeRight-w.updateNoticeClose:GetWidth()-4,"notice text does not overlap its close hitbox")
    local withBoth=w.FOOTER_HEIGHT
    assert(w.fullTextButton:IsShown() and w.fullTextButton.point[#w.fullTextButton.point]>w.updateNoticeButton.point[#w.updateNoticeButton.point],"full-text and update actions occupy separate stacked footer rows")
    w:SetShowFullTextButton(false)
    assert(w.updateNoticeButton:IsShown() and not w.fullTextButton:IsShown() and w.FOOTER_HEIGHT<withBoth,"full-text toggle reclaims only its own row")
    w.frame:SetSize(220,300);w.frame.scripts.OnSizeChanged(w.frame,220,300)
    w:SetFontSize(24)
    assert(w.updateNoticeButton.label:GetWidth()==160 and w.updateNoticeButton:GetHeight()>18,"narrow footer wraps complete notice text at a large font")
    assert(w.FOOTER_HEIGHT>=w.updateNoticeButton:GetHeight()+12,"wrapped notice height is reserved below the narrative")
    w:SetMinimized(true)
    assert(not w.updateNoticeButton:IsShown() and not w.updateNoticeClose:IsShown() and ns.Updates:Notice(),"minimizing hides the footer without acknowledging it")
    assert(w.frame:GetHeight()==w:GetHeaderHeight(),"notice cannot expand the minimized window")
    w:SetMinimized(false)
    assert(w.updateNoticeButton:IsShown(),"restoring reveals the still-unread notice")
    w:SetShowFullTextButton(true)
    assert(w.fullTextButton:IsShown(),"full-text action can be restored beside a pending notice")

    local oldCombat,oldCore=InCombatLockdown,ForeverCore
    local opened,opens=nil,0
    ForeverCore={OpenSettingsPanel=function(id) opened=id;opens=opens+1;return true end}
    InCombatLockdown=function() return true end
    assert(ns.Updates:Open()==false and opens==0 and ns.Updates:Notice(),"combat suppresses protected settings opening and retains unread state")
    InCombatLockdown=function() return false end
    ns.Updates:SetNoticesEnabled(false)
    assert(not ns.Updates:Notice() and not w.updateNoticeButton:IsShown() and not o.updateNotices.checked,"disabling notifications hides the footer and syncs options")
    for _,language in ipairs({"es","en","fr","de","pt","pl","ru"}) do
        ns.Locale.SetUI(language)
        assert(ns.Updates:Notes()==ns.ReleaseNotes.notes[language],"release notes follow the interface language: "..language)
        assert(o.updatesBody:GetText()==ns.Updates:Changelog(language),"settings panel uses the installed local notes: "..language)
        assert(o.updateNotices.label:GetText()==ns.L("Mostrar avisos de actualización",language),"notice preference is localized: "..language)
        assert(ns.db.language=="es","reading notes never changes story language")
        assert(not w.updateNoticeButton:IsShown(),"UI language changes preserve disabled notifications")
    end
    assert(ns.Updates:Notes("unsupported")==ns.ReleaseNotes.notes.en,"unknown note language falls back to bundled English")
    assert(ns.Updates:Open() and opened==o.updatesCategory:GetID(),"notes remain accessible from settings while notifications are disabled")
    assert(ns.db.lastSeenUpdateVersion==version and ns.db.unreadUpdateVersion==nil,"successful opening acknowledges the installed release")
    ns.Updates:SetNoticesEnabled(true)
    assert(not ns.Updates:Notice() and not w.updateNoticeButton:IsShown(),"reenabling notifications cannot resurrect a read release")
    assert(w.currentID==currentID and w.currentKey==currentKey and w.body:GetText()==body,"notes and layout leave the active quest narrative unchanged")
    assert(#ns.history.entries==historyCount and (ns.history:Current() and ns.history:Current().key)==historyKey,"updates never add, reorder or navigate quest history")
    assert(o.updatesLink:GetText()=="https://www.curseforge.com/wow/addons/questlore/files","full changelog link is available to copy")
    local acknowledged=env.login(ns.db);env.tick(0.2)
    assert(not acknowledged.Updates:Notice(),"read acknowledgement persists across actual reload")

    local pending=env.login({locale="enUS",build="70959",lastUpdateVersion="0.17.4",attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    assert(pending.Updates:Notice(),"existing earlier release gets a notice")
    assert(pending.Window.updateNoticeButton:GetText()==pending.L("Actualizado - Ver novedades"),"banner contains only the short localized copy")
    pending.Window.updateNoticeClose.scripts.OnClick()
    assert(not pending.Updates:Notice() and pending.db.lastSeenUpdateVersion==version and not pending.Window.updateNoticeButton:IsShown(),"close acknowledges this release and immediately reclaims the notice")
    pending=env.login(pending.db);env.tick(0.2)
    assert(not pending.Updates:Notice(),"closing a banner stays acknowledged after reload")
    InCombatLockdown,ForeverCore=oldCombat,oldCore
    print("PASS: installed-only updates, version comparison, fresh/legacy migration, unread reload, acknowledgement, downgrade/reinstall, seven UI languages and five-release archive, settings/combat guards and wrapped independent footer")
end
