-- Bounded widget retention and behavior in the deterministic Lua UI mock.
-- Timings measure this harness, not rendering time or memory in a real client.
return function(env)
    local ns=env.login({language="en",uiLanguage="en",fontSize=14,attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    ns.QueueRefresh=function() end
    assert(ns.History.LIMIT==200,"performance work preserves the per-character history cap")
    local ids={}
    for id in pairs(ns.Narratives) do ids[#ids+1]=id end
    table.sort(ids)
    local entries={}
    for _,id in ipairs(ids) do
        local model=ns.Model.Build({id=id,title=ns.Narratives[id].titleEN},"en")
        if model.kind=="story" and #ns.Encyclopedia.FindSpans(model.body,"en",id)>0 then
            entries[#entries+1]=model
            if #entries==200 then break end
        end
    end
    assert(#entries==200,"benchmark uses 200 real authored stories with linked proper names")
    ns.history.entries=entries;ns.db.history=entries
    local opts=ns.Options
    opts.historyPanel:SetSize(620,600)
    opts.historyScroll:SetHeight(400)
    local reads,lookups,spanCalls=0,0,0
    ns.API.ReadOriginal=function() reads=reads+1;error("archive must not fetch full quest dialogue") end
    ns.API.isActive=function() lookups=lookups+1;return false end
    local findSpans=ns.Encyclopedia.FindSpans
    ns.Encyclopedia.FindSpans=function(text,language,id,...)
        if type(id)=="number" then spanCalls=spanCalls+1 end
        return findSpans(text,language,id,...)
    end
    opts:SyncHistory()
    assert(opts.historyDirty and #opts.historyRows==0 and #opts.historyRichPool==0,"hidden unopened history remains unbuilt")
    assert(lookups==0 and spanCalls==0,"hidden history does no quest or encyclopedia scanning")
    local coldStart=os.clock()
    opts.historyPanel:Show();opts:SyncHistory()
    local coldMilliseconds=(os.clock()-coldStart)*1000
    assert(#opts.historyRows==200 and opts.historyRows[1].entry.id==entries[200].id,"continuous newest-first 200-story feed")
    assert(opts.historyMeasureRich and #opts.historyMeasureRich.words==0,"one shared measure-only renderer creates no word widgets")
    local liveKey=ns.Window.currentKey
    local maxVisible=0
    local function inspect(checkClicks)
        local top=opts.historyScroll:GetVerticalScroll()
        local bottom=top+opts.historyScroll:GetHeight()
        local visible=0
        for _,row in ipairs(opts.historyRows) do
            local expected=row:IsShown() and row.spans and #row.spans>0 and row.y+row.height>=top and row.y<=bottom
            if expected then
                visible=visible+1
                assert(row.rich and row.richSlot.row==row,"visible linked row borrows a renderer")
                assert(row.richSlot.host:GetParent()==row and row.rich.parent==row.richSlot.host,"pooled regions inherit the current row parent")
                local text={}
                local clicked=false
                for i=1,row.rich.used do
                    local word=row.rich.words[i];text[#text+1]=word:GetText()
                    if word.entityID then
                        assert(word.entityButton:IsShown(),"visible entity has an active hit target")
                        if checkClicks and not clicked then
                            word.entityButton.scripts.OnClick()
                            assert(ns.Encyclopedia.currentID==word.entityID,"recycled links open the current entity, never an old alias")
                            clicked=true
                        end
                    end
                end
                assert(table.concat(text):gsub("%s+","")==row.entry.body:gsub("%s+",""),"reused renderer preserves the complete narrative")
            else assert(not row.rich and not row.richSlot,"offscreen rows retain no private rich renderer") end
        end
        maxVisible=math.max(maxVisible,visible)
        assert(#opts.historyRichPool<=maxVisible,"pool size never exceeds maximum simultaneous visibility")
        assert(ns.Window.currentKey==liveKey,"archive links preserve the live quest")
    end
    local function scrollAll()
        for index,row in ipairs(opts.historyRows) do
            opts.historyScroll:SetVerticalScroll(math.min(row.y,opts.historyRange));opts:UpdateHistoryVisible()
            inspect(index==1 or index%50==0)
        end
    end
    local scrollStart=os.clock();scrollAll()
    local scrollMilliseconds=(os.clock()-scrollStart)*1000
    local function counts()
        local words,hits=0,0
        for _,slot in ipairs(opts.historyRichPool) do
            words=words+#slot.rich.words
            for _,word in ipairs(slot.rich.words) do if word.entityButton then hits=hits+1 end end
        end
        return #opts.historyRichPool,words,hits
    end
    local pool,words,hits=counts()
    assert(pool<20 and pool<200,"renderers are bounded by the viewport, not all archived stories")
    local measured=spanCalls
    opts.historyPanel:Hide()
    for _,slot in ipairs(opts.historyRichPool) do
        assert(not slot.row and not slot.host:IsShown(),"closing the archive releases every renderer")
        for _,word in ipairs(slot.rich.words) do
            assert(not word:IsShown() and not word.entityID,"hidden pooled words have no stale entity identity")
            assert(not word.entityButton or not word.entityButton:IsShown(),"hidden pooled hit targets cannot intercept input")
        end
    end
    local hiddenLookups=lookups
    ns.db.fontSize=20;opts:SyncHistory()
    assert(opts.historyDirty and spanCalls==measured and lookups==hiddenLookups,"hidden rebuilt history skips expensive work after font changes")
    ns.db.fontSize=14
    local reopenStart=os.clock()
    opts.historyPanel:Show();opts.historyScroll:SetVerticalScroll(0);opts:SyncHistory()
    local reopenMilliseconds=(os.clock()-reopenStart)*1000
    assert(spanCalls==measured,"warm reopen reuses per-row span and height caches")
    scrollAll()
    local pool2,words2,hits2=counts()
    assert(pool2==pool and words2==words and hits2==hits,"second full scroll and reopen allocate no additional pooled regions")
    ns.db.fontSize=24;opts.historyPanel:SetWidth(320);opts:SyncHistory()
    assert(spanCalls==measured,"font and width changes reuse entity matching")
    inspect()
    ns.db.showFullTextButton=false;opts:SyncHistory()
    for _,row in ipairs(opts.historyRows) do assert(not row.read:IsShown(),"full-text preference still applies to the whole archive") end
    assert(reads==0,"opening and scrolling never retrieves original quest texts")
    print(string.format("PASS: history pool, 200 real stories; %d renderers / %d words / %d hit targets retained; mock cold %.2f ms, first scroll %.2f ms, warm reopen %.2f ms; no client-performance claim",pool,words,hits,coldMilliseconds,scrollMilliseconds,reopenMilliseconds))
end
