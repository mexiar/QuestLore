-- Serialize as SavedVariables do; use independent tables for each reload.
return function(env)
    local function literal(value)
        local kind=type(value)
        if kind=="string" then return string.format("%q",value) end
        if kind=="number" or kind=="boolean" then return tostring(value) end
        assert(kind=="table","only serializable SavedVariables values")
        local pieces={}
        for key,item in pairs(value) do pieces[#pieces+1]="["..literal(key).."]="..literal(item) end
        return "{"..table.concat(pieces,",").."}"
    end
    local function roundtrip(value) return assert(loadstring("return "..literal(value)))() end
    local function equal(a,b)
        if type(a)~="table" or type(b)~="table" then return a==b end
        for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    local fields={"language","uiLanguage","fontSize","fontDefaultsVersion","backgroundEnabled","backgroundTransparency","attachToTracker","followPolestar","followRestedXP","showFullTextButton","showUpdateNotices","visible","minimized","size","position","fullTextWindow","encyclopediaWindow","futurePreference"}
    local cases=0
    for _,enabled in ipairs({false,true}) do
        for _,transparency in ipairs({0,37,100}) do
            local profile={locale="esMX",build="70959",lastUpdateVersion="0.18.0-beta10",lastSeenUpdateVersion="0.18.0-beta10",
                language="ru",uiLanguage="de",fontSize=22,fontDefaultsVersion=2,
                backgroundEnabled=enabled,backgroundTransparency=transparency,
                attachToTracker=enabled,followPolestar=not enabled,followRestedXP=enabled,
                showFullTextButton=not enabled,showUpdateNotices=enabled,visible=not enabled,minimized=enabled,
                size={width=640,height=420},position={point="TOPLEFT",x=120,y=900},
                fullTextWindow={width=700,height=400,x=100,y=850},encyclopediaWindow={width=660,height=440,x=150,y=900},
                futurePreference={disabled=false,zero=0},
                history={{key="preferences:sentinel",title="Prior story",body="A previously read narrative.",kind="story",source="",language="en"}}}
            local expected=roundtrip(profile)
            for iteration=1,3 do
                local ns=env.login(roundtrip(profile));env.tick(0.2)
                for _,field in ipairs(fields) do assert(equal(ns.db[field],expected[field]),"preference reset after saved reload/upgrade: "..field) end
                local alpha=enabled and 1-transparency/100 or 0
                assert(math.abs(ns.Window.background.color[4]-alpha)<0.00001,"actual background alpha restores correctly")
                assert(ns.Options.backgroundToggle.checked==enabled,"checkbox matches saved enabled state")
                assert(ns.Options.backgroundSlider.value==transparency,"slider restores zero, intermediate and full transparency")
                assert(ns.history:Find("preferences:sentinel"),"existing archive remains present")
                ns.FullText:Create();ns.Encyclopedia:Create()
                assert(ns.FullText.frame:GetWidth()==700 and ns.FullText.frame:GetHeight()==400,"reader geometry restored")
                assert(ns.Encyclopedia.frame:GetWidth()==660 and ns.Encyclopedia.frame:GetHeight()==440,"encyclopedia geometry restored")
                assert(ns.FullText.frame.point[4]==100 and ns.FullText.frame.point[5]==850,"reader anchor restored")
                assert(ns.Encyclopedia.frame.point[4]==150 and ns.Encyclopedia.frame.point[5]==900,"encyclopedia anchor restored")
                profile=ns.db
            end
            cases=cases+1
        end
    end
    print("PASS: "..cases.." independent profiles across 18 saved reload/upgrade roundtrips; opacity endpoints, all preferences, three-window geometry and history retained")
end
