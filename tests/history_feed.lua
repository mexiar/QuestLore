return function(env)
    local ns=env.login({language="es",uiLanguage="es",attachToTracker=false,followPolestar=false,followRestedXP=false})
    env.tick(0.2)
    ns.QueueRefresh=function() end
    local active={[806]=true,[823]=true}
    local reads=0
    ns.API.isActive=function(id) return active[id]==true end
    ns.API.ReadOriginal=function(id)
        reads=reads+1
        return active[id] and {id=id,title="Original "..id,description="Texto original "..id,objectives="Objetivos "..id} or nil
    end
    ns.history.entries={ns.Model.Build({id=823,title="Informa a Orgnil"},"es"),ns.Model.Build({id=806,title="Oscuras tormentas"},"es"),ns.Model.Build({id=1801,title="Libro del conciliábulo"},"es")}
    ns.db.history=ns.history.entries
    ns.Window:Render(ns.history.entries[2])
    local key=ns.Window.currentKey
    local opts=ns.Options
    opts.historyPanel:Show();opts.historyPanel:SetWidth(620);opts:SyncHistory(true)
    assert(#opts.historyRows==3 and opts.historyRows[1].entry.id==1801 and opts.historyRows[3].entry.id==823,"newest-to-oldest feed")
    assert(reads==0,"building the feed never fetches original texts")
    assert(opts.historyList==nil and opts.historyDetail==nil,"old two-column button/detail browser removed")
    local lastBottom=0
    for i,row in ipairs(opts.historyRows) do
        assert(row.scripts.OnClick==nil and row.title:GetText()==row.entry.title and row.body:GetText()==row.entry.body,"each non-button row contains its own title and summary")
        assert(row.y>=lastBottom,"full entries never overlap")
        assert(row.line:IsShown()==(i<3),"only separators between entries")
        lastBottom=row.y+row.height
    end
    assert(opts.historyContent:GetHeight()>=lastBottom,"last story is reachable")
    local removed=opts.historyByKey["quest:1801"]
    assert(removed.read:IsShown() and not removed.read.enabled,"historical inactive quest retains a disabled original-text action")
    removed.read.scripts.OnClick();assert(reads==0,"disabled unavailable original cannot be fetched")
    local older=opts.historyByKey["quest:823"]
    assert(older.read.enabled,"any still-active historical quest can be read")
    older.read.scripts.OnClick()
    assert(ns.FullText.id==823 and ns.FullText.context=="history" and ns.FullText.body:GetText():find("Texto original 823",1,true),"archive opens original independently of current lore quest")
    assert(ns.Window.currentKey==key,"original reader does not change selected quest")
    ns.Window:RefreshFullText();assert(ns.FullText.id==823,"live refresh does not close an archive reader for another active quest")
    active[823]=false;ns.FullText:Refresh();assert(ns.FullText.id==nil and ns.FullText.body:GetText()=="","removed quest clears original reader")
    for _,width in ipairs({320,700}) do
        for _,size in ipairs({12,24}) do
            ns.db.fontSize=size;opts.historyPanel:SetWidth(width);opts:SyncHistory(true)
            local row=opts.historyByKey["quest:806"]
            opts.historyScroll:SetVerticalScroll(math.min(row.y,opts.historyRange));opts:UpdateHistoryVisible()
            local entities,words={},{}
            for i=1,row.rich.used do
                local word=row.rich.words[i];words[#words+1]=word:GetText()
                if word.entityID then
                    assert(word.entityButton.underline==nil,"archive links use yellow without underlines")
                    entities[word.entityID]=true
                    word.entityButton.scripts.OnClick()
                    assert(ns.Encyclopedia.currentID==word.entityID and ns.Window.currentKey==key,"archive name opens reference without changing live lore")
                end
                assert(-word.point[5]+word:GetStringHeight()<row.height,"linked archive paragraph and action stay within row")
            end
            assert(entities["npc:3142"] and entities["organization:burning-blade"] and entities["place:durotar"],"all known archive entities linked")
            assert(table.concat(words):gsub("%s+","")==row.entry.body:gsub("%s+",""),"archive linking preserves complete narrative")
        end
    end
    local row=opts.historyByKey["quest:806"]
    opts.historyScroll:SetVerticalScroll(0);opts:UpdateHistoryVisible()
    local mainOffset=ns.Window.scroll:GetVerticalScroll()
    for i=1,row.rich.used do
        local word=row.rich.words[i]
        if word.entityID then word.entityButton.scripts.OnMouseWheel(nil,-1);break end
    end
    assert(opts.historyScroll:GetVerticalScroll()>0 and ns.Window.scroll:GetVerticalScroll()==mainOffset,"wheel over history links scrolls history only")
    ns.history.entries={ns.history.entries[1]};opts:SyncHistory(true)
    for i=2,#opts.historyRows do assert(not opts.historyRows[i]:IsShown(),"recycled feed rows are hidden") end
    assert(#ns.db.history==3 and ns.db.history[1].description==nil,"feed never stores original quest dialogue")
    print("PASS: descending continuous history, complete non-button rows, independent active originals, separators, linked references, text reflow and pane-specific scrolling")
end
