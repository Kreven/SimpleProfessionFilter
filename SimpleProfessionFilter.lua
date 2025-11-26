local addonName, SPF = ...
_G[addonName] = SPF

SPF.Frame = CreateFrame("Frame")
SPF.Frame:RegisterEvent("ADDON_LOADED")
SPF.Frame:RegisterEvent("TRADE_SKILL_SHOW")
SPF.Frame:RegisterEvent("TRADE_SKILL_UPDATE")
SPF.Frame:RegisterEvent("CRAFT_SHOW")
SPF.Frame:RegisterEvent("CRAFT_UPDATE")

SPF.filterText = ""
SPF.showSkillUp = false
SPF.showHaveMats = false

SPF.skillUpText = "Skill up"
SPF.haveMatsText = "Have mats"
SPF.searchPlaceholder = "Search..."

local function StripColor(text)
    if not text then return "" end
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local isLeatrixLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded("Leatrix_Plus")) or IsAddOnLoaded("Leatrix_Plus")
local enhanceProfessions =  isLeatrixLoaded and _G.LeaPlusDB and _G.LeaPlusDB["EnhanceProfessions"] == "On"

function SPF.Frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_TradeSkillUI" then
            SPF:InitTradeSkillUI()
        elseif arg1 == "Blizzard_CraftUI" then
            SPF:InitCraftUI()
        end
    elseif event == "TRADE_SKILL_SHOW" then
        SPF.filterText = ""
        if SPF.SearchBox then SPF.SearchBox:SetText("") end
        SPF:AdjustTradeSkillLayout()
    elseif event == "CRAFT_SHOW" then
        SPF.filterText = ""
        if SPF.CraftSearchBox then SPF.CraftSearchBox:SetText("") end
    end
end
SPF.Frame:SetScript("OnEvent", SPF.Frame.OnEvent)

-- ============================================================================
-- TradeSkillFrame Support
-- ============================================================================

function SPF:AdjustTradeSkillLayout()
    if enhanceProfessions then return end

    -- 1. Hide Title
    if TradeSkillFrameTitleText then
        TradeSkillFrameTitleText:Hide()
    end

    -- 2. Move RankFrame UP (to Title area)
    if TradeSkillRankFrame then
        TradeSkillRankFrame:ClearAllPoints()
        TradeSkillRankFrame:SetPoint("TOP", TradeSkillFrame, "TOP", 5, -16)
        TradeSkillRankFrame:SetWidth(254)
        TradeSkillRankFrame:SetHeight(16)

        if TradeSkillRankFrameBorder then
            TradeSkillRankFrameBorder:Hide()
        end
        
        local rankName = _G["TradeSkillRankFrameSkillName"]
        local rankRank = _G["TradeSkillRankFrameSkillRank"]
        
        if rankName and rankRank then
            rankName:ClearAllPoints()
            rankName:SetPoint("RIGHT", TradeSkillRankFrame, "CENTER", -5, -0.5)
            rankName:SetJustifyH("RIGHT")
            
            rankRank:ClearAllPoints()
            rankRank:SetPoint("LEFT", TradeSkillRankFrame, "CENTER", 5, -0.5)
            rankRank:SetJustifyH("LEFT")
        end
    end

    -- 3. Move My Controls UP (to Skill progress area)
    local myControlsY = -35.5
    if SPF.SearchBox then
        SPF.SearchBox:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 75, myControlsY)
    end
    -- Checkboxes follow SearchBox automatically due to relative anchoring
end

function SPF:InitTradeSkillUI()
    if SPF.TradeSkillInitialized then return end
    SPF.TradeSkillInitialized = true
    if enhanceProfessions then SPF.haveMatsText = "Have materials" end

    local parent = TradeSkillFrame

    local point, relativeTo, relativePoint, xOfs, yOfs = TradeSkillRankFrame:GetPoint()
    TradeSkillRankFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - 2)
    TradeSkillRankFrame:SetWidth(280)
    TradeSkillRankFrame:SetHeight(15)

    TradeSkillRankFrameBorder:SetWidth(290)
    TradeSkillRankFrameBorder:SetHeight(38)
    
    
    -- Search Box
    local searchBox = CreateFrame("EditBox", "SPF_TradeSkillSearchBox", parent, "BackdropTemplate") 
    searchBox:SetSize(130, 18)
    searchBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 71, -55)
    -- Raise above TradeSkillRankFrame to avoid border shadow overlap
    searchBox:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    searchBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchBox:SetBackdropColor(0, 0, 0, 0.5)
    searchBox:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(6, 18, 0, 0)

    local fontName, _, fontFlags = ChatFontNormal:GetFont()
    searchBox:SetFont(fontName, 11, fontFlags)

    -- Placeholder Text (FontString overlay)
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetText(SPF.searchPlaceholder)
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    
    -- Clear Button
    local clearButton = CreateFrame("Button", nil, searchBox)
    clearButton:SetSize(14, 14)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearButton:Hide()
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    clearButton:SetScript("OnEnter", function(self)
        self:GetNormalTexture():SetVertexColor(1, 0.2, 0.2)
    end)
    clearButton:SetScript("OnLeave", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1)
    end)
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        SPF.filterText = text:lower()
        
        if text ~= "" then
            placeholder:Hide()
            clearButton:Show()
            ExpandTradeSkillSubClass(0) 
        else
            placeholder:Show()
            clearButton:Hide()
        end
        
        TradeSkillFrame_Update()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self) 
        if self:GetText() ~= "" then
            self:SetText("")
        end
        self:ClearFocus() 
    end)
    searchBox:SetScript("OnEnterPressed", function(self) 
        self:ClearFocus() 
    end)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        placeholder:Hide()
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            placeholder:Show()
        end
    end)

    SPF.SearchBox = searchBox

    -- Skill Up Checkbox
    local skillUp = CreateFrame("CheckButton", "SPF_TradeSkillSkillUpCheck", parent, "UICheckButtonTemplate")
    skillUp:SetSize(21, 21)
    skillUp:SetPoint("LEFT", searchBox, "RIGHT", 7, 0)
    skillUp:SetHitRectInsets(0, -35, 0, 0) -- Extend clickable area to include text
    skillUp:SetFrameLevel(parent:GetFrameLevel() + 10) -- Raise above RankFrame
    
    local skillUpText = _G[skillUp:GetName().."Text"]
    skillUpText:SetText(SPF.skillUpText)
    skillUpText:SetFontObject(GameFontNormalSmall)
    
    skillUp:SetScript("OnClick", function(self)
        SPF.showSkillUp = self:GetChecked()
        if SPF.showSkillUp then ExpandTradeSkillSubClass(0) end
        TradeSkillFrame_Update()
    end)

    -- Have Mats Checkbox
    local haveMats = CreateFrame("CheckButton", "SPF_TradeSkillHaveMatsCheck", parent, "UICheckButtonTemplate")
    haveMats:SetSize(21, 21)
    haveMats:SetPoint("LEFT", skillUp, "RIGHT", 38, 0)
    -- Extend clickable area - more for "Have materials" than "Have mats"
    local haveMatsInset = enhanceProfessions and -75 or -50
    haveMats:SetHitRectInsets(0, haveMatsInset, 0, 0)
    haveMats:SetFrameLevel(parent:GetFrameLevel() + 10) -- Raise above RankFrame
    
    local haveMatsText = _G[haveMats:GetName().."Text"]
    haveMatsText:SetText(SPF.haveMatsText)
    haveMatsText:SetFontObject(GameFontNormalSmall)
    
    haveMats:SetScript("OnClick", function(self)
        SPF.showHaveMats = self:GetChecked()
        if SPF.showHaveMats then ExpandTradeSkillSubClass(0) end
        TradeSkillFrame_Update()
    end)

    -- Clear focus when clicking outside search box
    parent:HookScript("OnMouseDown", function(self, button)
        if searchBox:HasFocus() then
            searchBox:ClearFocus()
        end
    end)

    -- Hook Update
    hooksecurefunc("TradeSkillFrame_Update", SPF.TradeSkillFrame_Update)
end

function SPF.TradeSkillFrame_Update()
    -- Enforce layout adjustment on every update to prevent default UI from resetting it
    SPF:AdjustTradeSkillLayout()

    local numTradeSkills = GetNumTradeSkills()
    local filteredIndices = {}
    local currentHeaderIndex = nil
    local keepHeader = false

    -- If no filters are active, show everything (but still use our rendering logic)
    if SPF.filterText == "" and not SPF.showSkillUp and not SPF.showHaveMats then
        for i = 1, numTradeSkills do
            table.insert(filteredIndices, i)
        end
    else
        for i = 1, numTradeSkills do
            local name, type, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(i)
            
            if type == "header" then
                currentHeaderIndex = i
                keepHeader = false
            else
                local match = true
                
                -- Correct difficulty based on skill ups
                if (numSkillUps or 0) == 0 then type = "trivial" end

                -- Search
                if SPF.filterText ~= "" then
                    local nameMatch = name and string.find(StripColor(name):lower(), SPF.filterText, 1, true)
                    local reagentMatch = false
                    
                    -- Check reagents if name doesn't match
                    if not nameMatch then
                        local numReagents = GetTradeSkillNumReagents(i)
                        for j = 1, numReagents do
                            local reagentName = GetTradeSkillReagentInfo(i, j)
                            if reagentName and string.find(StripColor(reagentName):lower(), SPF.filterText, 1, true) then
                                reagentMatch = true
                                break
                            end
                        end
                    end
                    
                    if not nameMatch and not reagentMatch then
                        match = false
                    end
                end

                -- Skill Up
                if SPF.showSkillUp then
                    if type == "trivial" then
                        match = false
                    end
                end

                -- Have Mats
                if SPF.showHaveMats then
                    if numAvailable == 0 then
                        match = false
                    end
                end

                if match then
                    if currentHeaderIndex and not keepHeader then
                        table.insert(filteredIndices, currentHeaderIndex)
                        keepHeader = true
                    end
                    table.insert(filteredIndices, i)
                end
            end
        end
    end

    -- Update ScrollFrame
    FauxScrollFrame_Update(TradeSkillListScrollFrame, #filteredIndices, TRADE_SKILLS_DISPLAYED, TRADE_SKILL_HEIGHT, nil, nil, nil, TradeSkillHighlightFrame, 293, 316)

    -- Check if selected recipe is in filtered results
    local selectedIndex = GetTradeSkillSelectionIndex()
    local selectedInFiltered = false
    if selectedIndex then
        for _, idx in ipairs(filteredIndices) do
            if idx == selectedIndex then
                selectedInFiltered = true
                break
            end
        end
    end
    
    -- Hide highlight if selected recipe is filtered out
    if selectedIndex and not selectedInFiltered then
        TradeSkillHighlightFrame:Hide()
    end

    -- Update Buttons
    local scrollOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame)
    for i = 1, TRADE_SKILLS_DISPLAYED do
        local skillIndex = filteredIndices[i + scrollOffset]
        local skillButton = _G["TradeSkillSkill"..i]
        
        if skillIndex then
            local name, type, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(skillIndex)
            skillButton:SetID(skillIndex)
            skillButton:Show()

            -- Visuals
            local skillButtonText = _G["TradeSkillSkill"..i.."Text"]
            local skillButtonCount = _G["TradeSkillSkill"..i.."Count"]
            
            -- Fix for incorrect difficulty colors (e.g. Green when it should be Grey)
            -- If numSkillUps is explicitly 0 or nil, treat as trivial
            if (numSkillUps or 0) == 0 and type ~= "header" then
                type = "trivial"
            end

            if ( type == "header" ) then
                skillButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                skillButton.r = 1.0; skillButton.g = 1.0; skillButton.b = 1.0;
                skillButtonText:SetTextColor(1.0, 1.0, 1.0)
                if ( isExpanded ) then
                    skillButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                end
                _G["TradeSkillSkill"..i.."Highlight"]:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            else
                skillButton:SetNormalTexture("")
                _G["TradeSkillSkill"..i.."Highlight"]:SetTexture("")
                
                local color = TradeSkillTypeColor and TradeSkillTypeColor[type]
                if not color then
                    -- Fallback colors if global table is missing or type is unknown
                    if type == "optimal" then color = {r=1.0, g=0.5, b=0.25}
                    elseif type == "medium" then color = {r=1.0, g=1.0, b=0.0}
                    elseif type == "easy" then color = {r=0.25, g=0.75, b=0.25}
                    elseif type == "trivial" then color = {r=0.5, g=0.5, b=0.5}
                    else color = {r=1.0, g=1.0, b=1.0} end
                end
                
                skillButtonText:SetTextColor(color.r, color.g, color.b)
            end
            
            -- Indent
            if ( type == "header" ) then
                skillButton:GetNormalTexture():SetPoint("LEFT", skillButton, "LEFT", 0, 0)
                skillButtonText:SetPoint("LEFT", skillButton, "LEFT", 18, 0)
            else
                skillButtonText:SetPoint("LEFT", skillButton, "LEFT", 23, 0)
            end

            local displayName = StripColor(name)
            if numAvailable > 0 then
                displayName = displayName.." ["..numAvailable.."]"
            end
            skillButtonText:SetText(displayName)
            
            if skillButtonCount then
                skillButtonCount:SetText("")
            end
            
            -- Selection Highlight
            if ( selectedIndex == skillIndex ) then
                TradeSkillHighlightFrame:SetPoint("TOPLEFT", "TradeSkillSkill"..i, "TOPLEFT", 0, 0)
                TradeSkillHighlightFrame:Show()
                skillButtonText:SetVertexColor(1.0, 1.0, 1.0)
                if skillButtonCount then
                    skillButtonCount:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        else
            skillButton:Hide()
        end
    end
end

-- ============================================================================
-- CraftFrame Support (Enchanting)
-- ============================================================================

function SPF:InitCraftUI()
    if SPF.CraftInitialized then return end
    SPF.CraftInitialized = true
    SPF.haveMatsText = "Have materials"

    local parent = CraftFrame

    -- Adjust CraftRankFrame position (similar to TradeSkillRankFrame)
    if CraftRankFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = CraftRankFrame:GetPoint()
        CraftRankFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - 2)
        CraftRankFrame:SetWidth(enhanceProfessions and 280 or 270)
        CraftRankFrame:SetHeight(16)

        CraftRankFrameBorder:SetWidth(enhanceProfessions and 290 or 280)
        CraftRankFrameBorder:SetHeight(38)
    end

    -- Search Box
    local searchBox = CreateFrame("EditBox", "SPF_CraftSearchBox", parent, "BackdropTemplate")
    local searchBoxX = enhanceProfessions and 71 or 18
    local searchBoxY = enhanceProfessions and -55 or -73
    searchBox:SetFrameLevel(parent:GetFrameLevel() + 10)
    searchBox:SetSize(160, 18)
    searchBox:SetPoint("TOPLEFT", parent, "TOPLEFT", searchBoxX, searchBoxY)
    
    searchBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchBox:SetBackdropColor(0, 0, 0, 0.5)
    searchBox:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(6, 0, 0, 0)

    local fontName, _, fontFlags = ChatFontNormal:GetFont()
    searchBox:SetFont(fontName, 11, fontFlags)
    
    -- Placeholder Text (FontString overlay)
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetText("Search...")
    placeholder:SetTextColor(0.5, 0.5, 0.5)
    
    -- Clear Button
    local clearButton = CreateFrame("Button", nil, searchBox)
    clearButton:SetSize(14, 14)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -4, 0)
    clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearButton:Hide()
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    clearButton:SetScript("OnEnter", function(self)
        self:GetNormalTexture():SetVertexColor(1, 0.2, 0.2)
    end)
    clearButton:SetScript("OnLeave", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1)
    end)
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        SPF.filterText = text:lower()
        
        if text ~= "" then
            placeholder:Hide()
            clearButton:Show()
            ExpandCraftSkillLine(0)
        else
            placeholder:Show()
            clearButton:Hide()
        end
        
        CraftFrame_Update()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self) 
        if self:GetText() ~= "" then
            self:SetText("")
        end
        self:ClearFocus() 
    end)
    searchBox:SetScript("OnEnterPressed", function(self) 
        self:ClearFocus() 
    end)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        placeholder:Hide()
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            placeholder:Show()
        end
    end)

    SPF.CraftSearchBox = searchBox

    -- Skill Up Checkbox
    local skillUp = CreateFrame("CheckButton", "SPF_CraftSkillUpCheck", parent, "UICheckButtonTemplate")
    skillUp:SetSize(21, 21)
    skillUp:SetPoint("LEFT", searchBox, "RIGHT", 7, 0)
    skillUp:SetHitRectInsets(0, -35, 0, 0) -- Extend clickable area to include text
    
    local skillUpText = _G[skillUp:GetName().."Text"]
    skillUpText:SetText("Skill up")
    skillUpText:SetFontObject(GameFontNormalSmall)
    
    skillUp:SetScript("OnClick", function(self)
        SPF.showSkillUp = self:GetChecked()
        if SPF.showSkillUp then ExpandCraftSkillLine(0) end
        CraftFrame_Update()
    end)

    -- Have Mats Checkbox
    local haveMats = CreateFrame("CheckButton", "SPF_CraftHaveMatsCheck", parent, "UICheckButtonTemplate")
    haveMats:SetSize(21, 21)
    haveMats:SetPoint("LEFT", skillUp, "RIGHT", 38, 0)
    -- Extend clickable area - more for "Have materials" than "Have mats"
    local haveMatsInset = enhanceProfessions and -75 or -50
    haveMats:SetHitRectInsets(0, haveMatsInset, 0, 0)
    
    local haveMatsText = _G[haveMats:GetName().."Text"]
    haveMatsText:SetText(SPF.haveMatsText)
    haveMatsText:SetFontObject(GameFontNormalSmall)
    
    haveMats:SetScript("OnClick", function(self)
        SPF.showHaveMats = self:GetChecked()
        if SPF.showHaveMats then ExpandCraftSkillLine(0) end
        CraftFrame_Update()
    end)

    -- Clear focus when clicking outside search box
    parent:HookScript("OnMouseDown", function(self, button)
        if searchBox:HasFocus() then
            searchBox:ClearFocus()
        end
    end)

    -- Hook Update
    hooksecurefunc("CraftFrame_Update", SPF.CraftFrame_Update)
end

function SPF.CraftFrame_Update()
    local numCrafts = GetNumCrafts()
    local filteredIndices = {}
    local currentHeaderIndex = nil
    local keepHeader = false

    if SPF.filterText == "" and not SPF.showSkillUp and not SPF.showHaveMats then
        for i = 1, numCrafts do
            table.insert(filteredIndices, i)
        end
    else
        for i = 1, numCrafts do
            local name, rank, type, numAvailable, isExpanded = GetCraftInfo(i)
            
            if type == "header" then
                currentHeaderIndex = i
                keepHeader = false
            else
                local match = true

                if SPF.filterText ~= "" then
                    local nameMatch = name and string.find(StripColor(name):lower(), SPF.filterText, 1, true)
                    local reagentMatch = false
                    
                    -- Check reagents if name doesn't match
                    if not nameMatch then
                        local numReagents = GetCraftNumReagents(i)
                        for j = 1, numReagents do
                            local reagentName = GetCraftReagentInfo(i, j)
                            if reagentName and string.find(StripColor(reagentName):lower(), SPF.filterText, 1, true) then
                                reagentMatch = true
                                break
                            end
                        end
                    end
                    
                    if not nameMatch and not reagentMatch then
                        match = false
                    end
                end

                if SPF.showSkillUp then
                    -- For CraftFrame, trivial = grey = no skill up
                    if type == "trivial" then
                        match = false
                    end
                end

                if SPF.showHaveMats then
                    if numAvailable == 0 then
                        match = false
                    end
                end

                if match then
                    if currentHeaderIndex and not keepHeader then
                        table.insert(filteredIndices, currentHeaderIndex)
                        keepHeader = true
                    end
                    table.insert(filteredIndices, i)
                end
            end
        end
    end

    FauxScrollFrame_Update(CraftListScrollFrame, #filteredIndices, CRAFTS_DISPLAYED, CRAFT_SKILL_HEIGHT, nil, nil, nil, CraftHighlightFrame, 293, 316)

    -- Check if selected craft is in filtered results
    local selectedIndex = GetCraftSelectionIndex()
    local selectedInFiltered = false
    if selectedIndex then
        for _, idx in ipairs(filteredIndices) do
            if idx == selectedIndex then
                selectedInFiltered = true
                break
            end
        end
    end
    
    -- Hide highlight if selected craft is filtered out
    if selectedIndex and not selectedInFiltered then
        CraftHighlightFrame:Hide()
    end

    local scrollOffset = FauxScrollFrame_GetOffset(CraftListScrollFrame)
    for i = 1, CRAFTS_DISPLAYED do
        local craftIndex = filteredIndices[i + scrollOffset]
        local craftButton = _G["Craft"..i]
        
        if craftIndex then
            local name, rank, type, numAvailable, isExpanded = GetCraftInfo(craftIndex)
            craftButton:SetID(craftIndex)
            craftButton:Show()

            local craftButtonText = _G["Craft"..i.."Text"]
            local craftButtonCost = _G["Craft"..i.."Cost"]
            local craftButtonCount = _G["Craft"..i.."Count"]

            if ( type == "header" ) then
                craftButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                craftButtonText:SetTextColor(1.0, 1.0, 1.0)
                if ( isExpanded ) then
                    craftButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                end
                _G["Craft"..i.."Highlight"]:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
            else
                craftButton:SetNormalTexture("")
                _G["Craft"..i.."Highlight"]:SetTexture("")
                
                local color = TradeSkillTypeColor and TradeSkillTypeColor[type]
                if not color then
                    if type == "optimal" then color = {r=1.0, g=0.5, b=0.25}
                    elseif type == "medium" then color = {r=1.0, g=1.0, b=0.0}
                    elseif type == "easy" then color = {r=0.25, g=0.75, b=0.25}
                    elseif type == "trivial" then color = {r=0.5, g=0.5, b=0.5}
                    else color = {r=1.0, g=1.0, b=1.0} end
                end
                
                craftButtonText:SetTextColor(color.r, color.g, color.b)
            end
            
            if ( type == "header" ) then
                craftButton:GetNormalTexture():SetPoint("LEFT", craftButton, "LEFT", 0, 0)
                craftButtonText:SetPoint("LEFT", craftButton, "LEFT", 25, 0)
            else
                craftButtonText:SetPoint("LEFT", craftButton, "LEFT", 40, 0)
            end

            local displayName = StripColor(name)
            if numAvailable > 0 then
                displayName = displayName.." ["..numAvailable.."]"
            end
            craftButtonText:SetText(displayName)
            
            if craftButtonCount then
                craftButtonCount:SetText("")
            end
            
            -- Simplified selection highlight logic
            if ( selectedIndex == craftIndex ) then
                CraftHighlightFrame:SetPoint("TOPLEFT", "Craft"..i, "TOPLEFT", 0, 0)
                CraftHighlightFrame:Show()
                craftButtonText:SetVertexColor(1.0, 1.0, 1.0)
                if craftButtonCount then
                    craftButtonCount:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        else
            craftButton:Hide()
        end
    end
end
