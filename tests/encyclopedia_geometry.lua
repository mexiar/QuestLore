-- Per-character geometry, using the same UIParent coordinate convention as the
-- original-quest reader. No story or article text joins SavedVariables.
return function(env)
    local screenWidth,screenHeight,parentScale=UIParent:GetWidth(),UIParent:GetHeight(),UIParent:GetEffectiveScale()
    UIParent:SetSize(1920,1080);UIParent:SetScale(1)
    local function login(saved)
        local ns=env.login({attachToTracker=false,followPolestar=false,followRestedXP=false,encyclopediaWindow=saved})
        assert(ns.Encyclopedia:Open("npc:3142","en"))
        return ns,ns.Encyclopedia
    end
    local function sameGeometry(a,b)
        return a.width==b.width and a.height==b.height and a.x==b.x and a.y==b.y
    end
    local first,e=login()
    assert(e.frame:GetWidth()==680 and e.frame:GetHeight()==460 and e.frame.point[1]=="CENTER","new character uses centered encyclopedia defaults")
    assert(first.db.encyclopediaWindow==nil,"creating a reader does not overwrite a character's preferences")
    local left,top=145,850
    e.frame.GetLeft=function() return left end;e.frame.GetTop=function() return top end
    e.frame:ClearAllPoints();e.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)
    e.frame.scripts.OnDragStart(e.frame)
    e.frame.scripts.OnDragStop(e.frame)
    assert(first.db.encyclopediaWindow.x==145 and first.db.encyclopediaWindow.y==850,"drag stop saves character position")
    e.grip.scripts.OnMouseDown(e.grip,"LeftButton")
    assert(e.frame.sizingCorner=="BOTTOMRIGHT","encyclopedia uses native corner resizing")
    e.frame:SetSize(740,430);e.frame.scripts.OnSizeChanged(e.frame)
    e.grip.scripts.OnMouseUp(e.grip)
    assert(first.db.encyclopediaWindow.width==740 and first.db.encyclopediaWindow.height==430,"resize release saves character dimensions")
    local anchor=e.frame.point
    assert(e:Open("place:durotar","pl"));first.Locale.SetUI("fr")
    assert(e.frame.point==anchor and e.frame:GetWidth()==740 and e.frame:GetHeight()==430,"article and interface language changes never reapply defaults")
    e.frame:SetSize(760,440);left,top=160,900;e.frame:Hide()
    assert(sameGeometry(first.db.encyclopediaWindow,{width=760,height=440,x=160,y=900}),"hiding saves the final geometry even without a resize-release event")
    local saved={};for k,v in pairs(first.db.encyclopediaWindow) do saved[k]=v end
    local restored,r=login(saved)
    assert(r.frame:GetWidth()==760 and r.frame:GetHeight()==440,"dimensions survive a character reload or addon update")
    assert(r.frame.point[1]=="TOPLEFT" and r.frame.point[4]==160 and r.frame.point[5]==900,"position survives reload in UIParent coordinates")
    local other,o=login()
    assert(o.frame:GetWidth()==680 and o.frame:GetHeight()==460 and o.frame.point[1]=="CENTER","another character has independent defaults")
    o.frame:SetSize(500,300);o.grip.scripts.OnMouseUp(o.grip)
    assert(restored.db.encyclopediaWindow.width==760 and first.db.encyclopediaWindow.width==760,"saving another character never mutates prior geometry")
    assert(other.db.encyclopediaWindow~=restored.db.encyclopediaWindow,"geometry records are not shared between characters")
    local _,invalid=login({width=math.huge,height=0/0,x=-99999,y=99999})
    assert(invalid.frame:GetWidth()==680 and invalid.frame:GetHeight()==460,"infinite and NaN dimensions use valid defaults")
    assert(invalid.frame.point[4]==0 and invalid.frame.point[5]==1080,"finite offscreen coordinates clamp to the screen")
    local _,badPosition=login({width="900",height=false,x=0/0,y=500})
    assert(badPosition.frame:GetWidth()==680 and badPosition.frame:GetHeight()==460 and badPosition.frame.point[1]=="CENTER","malformed fields and NaN position do not break creation")
    local _,small=login({width=-20,height=0,x=math.huge,y=-math.huge})
    assert(small.frame:GetWidth()==320 and small.frame:GetHeight()==240 and small.frame.point[1]=="CENTER","small dimensions clamp and infinite positions recenter")
    local _,huge=login({width=99999,height=99999,x=99999,y=-99999})
    assert(huge.frame:GetWidth()==1896 and huge.frame:GetHeight()==1040 and huge.frame.point[4]==24 and huge.frame.point[5]==1040,"oversized saved geometry remains entirely on screen")
    local _,badRecord=login("invalid")
    assert(badRecord.frame.point[1]=="CENTER" and badRecord.frame:GetWidth()==680,"malformed geometry record has independent safe defaults")
    UIParent:SetSize(400,300)
    local _,compact=login({width=740,height=430,x=99999,y=99999})
    assert(compact.frame:GetWidth()==376 and compact.frame:GetHeight()==260 and compact.frame.point[4]==24 and compact.frame.point[5]==300,"resolution changes clamp restored dimensions and position together")
    UIParent:SetSize(200,180)
    local _,tiny=login({width=1,height=1,x=-1,y=-1})
    assert(tiny.frame:GetWidth()==176 and tiny.frame:GetHeight()==140 and tiny.frame.point[4]==0 and tiny.frame.point[5]==140,"a screen smaller than normal minimums still receives positive usable bounds")
    UIParent:SetSize(1920,1080);UIParent:SetScale(0.75)
    local scaled,s=login()
    s.frame.GetEffectiveScale=function() return 0.75 end
    s.frame.GetLeft=function() return 100 end;s.frame.GetTop=function() return 800 end
    s.frame:SetSize(700,400);s:SaveGeometry()
    assert(sameGeometry(scaled.db.encyclopediaWindow,{width=700,height=400,x=100,y=800}),"inherited UI scale does not multiply saved coordinates or dimensions")
    s.frame.GetEffectiveScale=function() return 0.5 end
    s.frame.GetLeft=function() return 90 end;s.frame.GetTop=function() return 900 end
    s.frame:SetSize(900,600);s:SaveGeometry()
    assert(sameGeometry(scaled.db.encyclopediaWindow,{width=600,height=400,x=60,y=600}),"an independently scaled frame saves normalized UIParent geometry")
    local last=scaled.db.encyclopediaWindow
    s.frame.GetLeft=function() return 0/0 end;s:SaveGeometry()
    assert(scaled.db.encyclopediaWindow==last,"unavailable or invalid native geometry never overwrites a good save")
    local nativeWidth=s.frame.GetWidth
    s.frame.GetLeft=function() return 90 end;s.frame.GetWidth=function() return math.huge end;s:SaveGeometry()
    assert(scaled.db.encyclopediaWindow==last,"invalid native size never enters saved preferences")
    s.frame.GetWidth=nativeWidth
    UIParent:SetSize(screenWidth,screenHeight);UIParent:SetScale(parentScale)
    print("PASS: encyclopedia geometry drag/resize/hide persistence, reload and article reuse, character isolation, malformed/NaN/offscreen bounds and UI-scale normalization")
end
