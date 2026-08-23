local addonName, SPF = ...
_G[addonName] = SPF

-- ============================================================================
-- Configuration
-- ============================================================================

-- Detection for Leatrix Plus "Enhance Professions"
local function IsEnhanceProfessionsActive()
    local isLeatrixLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isLeatrixLoaded = C_AddOns.IsAddOnLoaded("Leatrix_Plus")
    elseif IsAddOnLoaded then
        isLeatrixLoaded = IsAddOnLoaded("Leatrix_Plus")
    end
    return isLeatrixLoaded and _G.LeaPlusDB and _G.LeaPlusDB["EnhanceProfessions"] == "On"
end

local LAYOUTS = {
    Default = {
        -- TradeSkill positions
        SEARCH_BOX_X = 76,
        SEARCH_BOX_Y = -40,
        HAVE_MATS_OFFSET_X = 0,
        HAVE_MATS_OFFSET_Y = 0,
        SKILLUP_OFFSET_X = 72,
        SKILLUP_OFFSET_Y = 0,
        RANK_FRAME_X = 70,
        RANK_FRAME_Y = -16,
        RANK_FRAME_WIDTH = 254,
        RANK_FRAME_HEIGHT = 16,

        -- CraftFrame positions
        CRAFT_SEARCH_BOX_X = 76,
        CRAFT_SEARCH_BOX_Y = -35,
        CRAFT_SEARCH_BOX_WIDTH = 270,
        CRAFT_HAVE_MATS_OFFSET_X = -290,
        CRAFT_HAVE_MATS_OFFSET_Y = -33,
        CRAFT_SKILLUP_OFFSET_X = 72,
        CRAFT_SKILLUP_OFFSET_Y = 0,
        CRAFT_RANK_FRAME_X = 70,
        CRAFT_RANK_FRAME_Y = -16,
        CRAFT_RANK_FRAME_WIDTH = 254,
        CRAFT_RANK_FRAME_HEIGHT = 16,
    },
    Leatrix = {
        -- TradeSkill positions
        SEARCH_BOX_X = 83,
        SEARCH_BOX_Y = -44,
        HAVE_MATS_OFFSET_X = 10,
        HAVE_MATS_OFFSET_Y = 0,
        SKILLUP_OFFSET_X = 80,
        SKILLUP_OFFSET_Y = 0,
        RANK_FRAME_X = 70,
        RANK_FRAME_Y = -16,
        RANK_FRAME_WIDTH = 584,
        RANK_FRAME_HEIGHT = 16,

        -- CraftFrame positions
        CRAFT_SEARCH_BOX_X = 78,
        CRAFT_SEARCH_BOX_Y = -42,
        CRAFT_SEARCH_BOX_WIDTH = 270,
        CRAFT_HAVE_MATS_OFFSET_X = 7,
        CRAFT_HAVE_MATS_OFFSET_Y = -2,
        CRAFT_SKILLUP_OFFSET_X = 76,
        CRAFT_SKILLUP_OFFSET_Y = 0,
        CRAFT_RANK_FRAME_X = 70,
        CRAFT_RANK_FRAME_Y = -16,
        CRAFT_RANK_FRAME_WIDTH = 584,
        CRAFT_RANK_FRAME_HEIGHT = 16,
    }
}

local function GetLayout()
    if IsEnhanceProfessionsActive() then
        return LAYOUTS.Leatrix
    else
        return LAYOUTS.Default
    end
end

-- UI Sizes
local CHECKBOX_SIZE = 20

-- Difficulty colors (matches TradeSkillTypeColor)
local DIFFICULTY_COLORS = {
    optimal = {1.0, 0.5, 0.25},  -- Orange
    medium = {1.0, 1.0, 0.0},    -- Yellow
    easy = {0.25, 0.75, 0.25},   -- Green
}

-- ============================================================================
-- State
-- ============================================================================

local showSkillUp = false

-- Original Blizzard API reference
local OriginalGetTradeSkillInfo = GetTradeSkillInfo
local OriginalGetCraftInfo = GetCraftInfo

-- ============================================================================
-- Core Filtering Logic
-- ============================================================================

-- Hook TradeSkillFrame_Update to hide trivial recipes after Blizzard renders them
local function HookTradeSkillFrameUpdate()
    hooksecurefunc("TradeSkillFrame_Update", function()
        if not showSkillUp then return end
        
        local numTradeSkills = GetNumTradeSkills()
        local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame)
        
        -- First pass: collect which items should be visible
        local visibleItems = {}
        local currentHeaderIndex = nil
        local headerHasVisibleChildren = {}
        
        for i = 1, numTradeSkills do
            local name, skillType, numAvailable, isExpanded, altVerb, numSkillUps = OriginalGetTradeSkillInfo(i)
            
            if skillType == "header" then
                currentHeaderIndex = i
                headerHasVisibleChildren[i] = false
                -- Temporarily add header, we'll remove it later if it has no children
                table.insert(visibleItems, {index = i, isHeader = true})
            elseif skillType and skillType ~= "trivial" and (not numSkillUps or numSkillUps > 0) then
                -- Non-trivial recipe
                table.insert(visibleItems, {index = i, isHeader = false})
                if currentHeaderIndex then
                    headerHasVisibleChildren[currentHeaderIndex] = true
                end
            end
        end
        
        -- Second pass: remove headers without visible children
        local filteredItems = {}
        for _, item in ipairs(visibleItems) do
            if item.isHeader then
                if headerHasVisibleChildren[item.index] then
                    table.insert(filteredItems, item)
                end
            else
                table.insert(filteredItems, item)
            end
        end
        
        -- Check if current selection is filtered out
        local currentSelection = GetTradeSkillSelectionIndex()
        local selectionIsVisible = false
        
        if currentSelection and currentSelection > 0 then
            for _, item in ipairs(filteredItems) do
                if item.index == currentSelection then
                    selectionIsVisible = true
                    break
                end
            end
        end
        
        -- If current selection is not visible, select first non-header recipe
        if not selectionIsVisible and #filteredItems > 0 then
            for _, item in ipairs(filteredItems) do
                if not item.isHeader then
                    if TradeSkillFrame_SetSelection then
                        TradeSkillFrame_SetSelection(item.index)
                    end
                    break
                end
            end
        end
        
        -- Third pass: display filtered items and hide the rest
        for i = 1, TRADE_SKILLS_DISPLAYED do
            local skillButton = _G["TradeSkillSkill"..i]
            if skillButton then
                local item = filteredItems[i + skillOffset]
                if item then
                    -- Show this button with the filtered item's data
                    local skillIndex = item.index
                    local name, skillType, numAvailable, isExpanded = OriginalGetTradeSkillInfo(skillIndex)
                    
                    skillButton:SetID(skillIndex)
                    skillButton:Show()
                    
                    -- Set button width
                    skillButton:SetWidth(293)
                    
                    -- Set color
                    local color = TradeSkillTypeColor[skillType]
                    if color then
                        skillButton:SetNormalFontObject(color.font)
                    end
                    
                    -- Handle headers vs recipes
                    if skillType == "header" then
                        skillButton:SetWidth(293)
                        skillButton:SetText(name)
                        if isExpanded then
                            skillButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                        else
                            skillButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                        end
                        _G["TradeSkillSkill"..i.."Highlight"]:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
                        skillButton:UnlockHighlight()
                    else
                        skillButton:SetWidth(293)
                        skillButton:ClearNormalTexture()
                        _G["TradeSkillSkill"..i.."Highlight"]:SetTexture("")
                        if numAvailable == 0 then
                            skillButton:SetText(" "..name)
                        else
                            skillButton:SetText(" "..name.." ["..numAvailable.."]")
                        end
                        
                        -- Handle highlight
                        if GetTradeSkillSelectionIndex() == skillIndex then
                            TradeSkillHighlightFrame:ClearAllPoints()
                            TradeSkillHighlightFrame:SetPoint("TOPLEFT", "TradeSkillSkill"..i, "TOPLEFT", 0, 0)
                            TradeSkillHighlightFrame:Show()
                            skillButton:LockHighlight()
                        else
                            skillButton:UnlockHighlight()
                        end
                    end
                else
                    -- Hide unused buttons
                    skillButton:Hide()
                end
            end
        end
        
        -- Update scroll bar
        FauxScrollFrame_Update(TradeSkillListScrollFrame, #filteredItems, TRADE_SKILLS_DISPLAYED, TRADE_SKILL_HEIGHT, nil, nil, nil, TradeSkillHighlightFrame, 293, 316)

        -- Color the highlight frame
        if TradeSkillHighlightFrame and TradeSkillHighlightFrame:IsShown() then
            local selectedIndex = GetTradeSkillSelectionIndex()
            if selectedIndex and selectedIndex > 0 then
                local name, difficulty = OriginalGetTradeSkillInfo(selectedIndex)
                if difficulty and difficulty ~= "header" then
                    local color = DIFFICULTY_COLORS[difficulty]
                    if color then
                        local texture = TradeSkillHighlightFrame:GetRegions()
                        if texture and texture.SetVertexColor then
                            texture:SetVertexColor(color[1], color[2], color[3])
                        end
                    end
                end
            end
        end
    end)
end

-- Hook CraftFrame_Update
local function HookCraftFrameUpdate()
    hooksecurefunc("CraftFrame_Update", function()
        if not showSkillUp and (not SPF_CraftSearchInputBox or SPF_CraftSearchInputBox:GetText() == "" or SPF_CraftSearchInputBox:GetText() == "Search") then return end
        
        local numCrafts = GetNumCrafts()
        local craftOffset = FauxScrollFrame_GetOffset(CraftListScrollFrame)
        local searchText = SPF_CraftSearchInputBox and SPF_CraftSearchInputBox:GetText():lower()
        if searchText == "search" then searchText = "" end
        
        -- First pass: collect which items should be visible
        local visibleItems = {}
        local currentHeaderIndex = nil
        local headerHasVisibleChildren = {}
        
        for i = 1, numCrafts do
            local name, subText, craftType, numAvail, isExpanded, points, reqLevel = OriginalGetCraftInfo(i)
            local matchesSearch = not searchText or searchText == "" or name:lower():find(searchText, 1, true)
            
            -- Reagent search
            if not matchesSearch and searchText and searchText ~= "" and craftType ~= "header" then
                for reagentIndex = 1, GetCraftNumReagents(i) do
                    local reagentName = GetCraftReagentInfo(i, reagentIndex)
                    if reagentName and reagentName:lower():find(searchText, 1, true) then
                        matchesSearch = true
                        break
                    end
                end
            end
            
            local isNotTrivial = craftType ~= "trivial"
            
            if craftType == "header" then
                currentHeaderIndex = i
                headerHasVisibleChildren[i] = false
                table.insert(visibleItems, {index = i, isHeader = true})
            elseif matchesSearch and (not showSkillUp or isNotTrivial) then
                table.insert(visibleItems, {index = i, isHeader = false})
                if currentHeaderIndex then
                    headerHasVisibleChildren[currentHeaderIndex] = true
                end
            end
        end
        
        -- Second pass: filter items to display
        local filteredItems = {}
        for _, item in ipairs(visibleItems) do
            if item.isHeader then
                if headerHasVisibleChildren[item.index] then
                    table.insert(filteredItems, item)
                end
            else
                table.insert(filteredItems, item)
            end
        end

        -- Check if current selection is filtered out
        local currentSelection = GetCraftSelectionIndex()
        local selectionIsVisible = false
        
        if currentSelection and currentSelection > 0 then
            for _, item in ipairs(filteredItems) do
                if item.index == currentSelection then
                    selectionIsVisible = true
                    break
                end
            end
        end
        
        -- If current selection is not visible, select first non-header craft
        if not selectionIsVisible and #filteredItems > 0 then
            for _, item in ipairs(filteredItems) do
                if not item.isHeader then
                    if CraftFrame_SetSelection then
                        CraftFrame_SetSelection(item.index)
                    elseif SelectCraft then
                        SelectCraft(item.index)
                    end
                    break
                end
            end
        end

        -- If no items visible, hide details
        if #filteredItems == 0 then
            CraftHighlightFrame:Hide()
        end

        -- Third pass: display
        for i = 1, CRAFTS_DISPLAYED do
            local craftButton = _G["Craft"..i]
            if craftButton then
                local item = filteredItems[i + craftOffset]
                if item then
                    local skillIndex = item.index
                    local name, subText, craftType, numAvail, isExpanded = OriginalGetCraftInfo(skillIndex)
                    craftButton:SetID(skillIndex)
                    craftButton:Show()
                    
                    -- Set button width
                    craftButton:SetWidth(293)
                    _G["Craft"..i.."Text"]:SetWidth(290)
                    
                    -- Set color
                    local color = CraftTypeColor[craftType]
                    if color then
                        craftButton:SetNormalFontObject(color.font)
                    end
                    
                    if craftType == "header" then
                        craftButton:SetWidth(293)
                        craftButton:SetText(name)
                        if isExpanded then
                            craftButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                        else
                            craftButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                        end
                        _G["Craft"..i.."Highlight"]:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
                        craftButton:UnlockHighlight()
                    else
                        craftButton:SetWidth(293)
                        craftButton:ClearNormalTexture()
                        _G["Craft"..i.."Highlight"]:SetTexture("")
                        if numAvail == 0 then
                            craftButton:SetText(" "..name)
                        else
                            craftButton:SetText(" "..name.." ["..numAvail.."]")
                        end
                        
                        -- Handle highlight
                        if GetCraftSelectionIndex() == skillIndex then
                            CraftHighlightFrame:ClearAllPoints()
                            CraftHighlightFrame:SetPoint("TOPLEFT", "Craft"..i, "TOPLEFT", 0, 0)
                            CraftHighlightFrame:Show()
                            craftButton:LockHighlight()
                        else
                            craftButton:UnlockHighlight()
                        end
                    end
                else
                    craftButton:Hide()
                end
            end
        end
        
        -- Update scroll bar
        FauxScrollFrame_Update(CraftListScrollFrame, #filteredItems, CRAFTS_DISPLAYED, CRAFT_SKILL_HEIGHT, nil, nil, nil, CraftHighlightFrame, 293, 316 )
    end)
end

-- ============================================================================
-- UI Creation
-- ============================================================================

local function CreateClearSearchButton()
    if not TradeSearchInputBox then return end
    
    local button = CreateFrame("Button", "SPF_ClearSearchButton", TradeSkillFrame)
    button:SetSize(16, 16)
    button:SetPoint("RIGHT", TradeSearchInputBox, "RIGHT", -2, 0)
    button:SetFrameLevel(TradeSearchInputBox:GetFrameLevel() + 2)
    
    -- X texture
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    highlight:SetAlpha(0.5)
    
    -- Initially hide
    button:Hide()
    
    -- Click handler
    button:SetScript("OnClick", function()
        TradeSearchInputBox:SetText("")
        TradeSearchInputBox:ClearFocus()
        
        -- Clear native filter
        if SetTradeSkillItemNameFilter then
            SetTradeSkillItemNameFilter("")
        end
        
        -- Update UI
        if TradeSkillFrame_Update then
            TradeSkillFrame_Update()
        end
    end)
    
    -- Show/hide based on text content
    TradeSearchInputBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text ~= "" and text ~= "Search" then
            button:Show()
        else
            button:Hide()
        end
    end)
    
    return button
end

local function CreateCraftClearSearchButton()
    if not SPF_CraftSearchInputBox then return end
    
    local button = CreateFrame("Button", "SPF_CraftClearSearchButton", CraftFrame)
    button:SetSize(16, 16)
    button:SetPoint("RIGHT", SPF_CraftSearchInputBox, "RIGHT", -2, 0)
    button:SetFrameLevel(SPF_CraftSearchInputBox:GetFrameLevel() + 2)
    
    -- X texture
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    highlight:SetAlpha(0.5)
    
    -- Initially hide
    button:Hide()
    
    -- Click handler
    button:SetScript("OnClick", function()
        SPF_CraftSearchInputBox:SetText("")
        SPF_CraftSearchInputBox:ClearFocus()
        
        -- Update UI
        if CraftFrame_Update then
            CraftFrame_Update()
        end
    end)
    
    -- Show/hide based on text content
    SPF_CraftSearchInputBox:HookScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text ~= "" and text ~= "Search" then
            button:Show()
        else
            button:Hide()
        end
    end)
    
    return button
end

local function CreateCraftSearchBox()
    local layout = GetLayout()
    local editBox = CreateFrame("EditBox", "SPF_CraftSearchInputBox", CraftFrame)
    editBox:SetSize(layout.CRAFT_SEARCH_BOX_WIDTH, 20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontSmall)
    
    -- Background textures to match Blizzard look
    local left = editBox:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\Common\\Common-Input-Border")
    left:SetSize(8, 20)
    left:SetPoint("TOPLEFT", -5, 0)
    left:SetTexCoord(0, 0.0625, 0, 0.625)
    
    local right = editBox:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Common\\Common-Input-Border")
    right:SetSize(8, 20)
    right:SetPoint("RIGHT", 0, 0)
    right:SetTexCoord(0.9375, 1.0, 0, 0.625)
    
    local middle = editBox:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture("Interface\\Common\\Common-Input-Border")
    middle:SetSize(0, 20)
    middle:SetPoint("LEFT", left, "RIGHT")
    middle:SetPoint("RIGHT", right, "LEFT")
    middle:SetTexCoord(0.0625, 0.9375, 0, 0.625)
    
    -- Black background for Leatrix
    if IsEnhanceProfessionsActive() then
        local bg = editBox:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetColorTexture(0, 0, 0, 1)
        bg:SetAllPoints()
    end
    
    -- Scripts
    editBox:SetScript("OnShow", function(self)
        if self:GetText() == "" then
            self:SetText("Search")
        end
    end)
    
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnTextChanged", function(self)
        if CraftFrame_Update then
            CraftFrame_Update()
        end
    end)
    
    editBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        if self:GetText() == "" then
            self:SetText("Search")
        end
    end)
    
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        if self:GetText() == "Search" then
            self:SetText("")
        end
    end)
    
    return editBox
end

local function PositionSearchBox()
    if not TradeSearchInputBox then return end
    
    local layout = GetLayout()
    TradeSearchInputBox:ClearAllPoints()
    TradeSearchInputBox:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", layout.SEARCH_BOX_X, layout.SEARCH_BOX_Y)
end

local function PositionHaveMatsCheckbox()
    if not TradeSkillFrameAvailableFilterCheckButton or not TradeSearchInputBox then return end
    
    local layout = GetLayout()
    TradeSkillFrameAvailableFilterCheckButton:ClearAllPoints()
    TradeSkillFrameAvailableFilterCheckButton:SetPoint("LEFT", TradeSearchInputBox, "RIGHT", layout.HAVE_MATS_OFFSET_X, layout.HAVE_MATS_OFFSET_Y)
end

local function AdjustRankFrame()
    if not TradeSkillRankFrame then return end
    
    local layout = GetLayout()
    -- Hide Title
    if TradeSkillFrameTitleText then
        TradeSkillFrameTitleText:Hide()
    end
    
    -- Position and size rank frame
    TradeSkillRankFrame:ClearAllPoints()
    TradeSkillRankFrame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", layout.RANK_FRAME_X, layout.RANK_FRAME_Y)
    TradeSkillRankFrame:SetWidth(layout.RANK_FRAME_WIDTH)
    TradeSkillRankFrame:SetHeight(layout.RANK_FRAME_HEIGHT)
    
    -- Hide border
    if TradeSkillRankFrameBorder then
        TradeSkillRankFrameBorder:Hide()
    end
    
    -- Center the text inside the bar
    local nameText = _G["TradeSkillRankFrameSkillName"]
    local rankText = _G["TradeSkillRankFrameSkillRank"]
    
    if nameText then
        nameText:ClearAllPoints()
        nameText:SetPoint("LEFT", TradeSkillRankFrame, "LEFT", 10, 0)
        nameText:SetJustifyH("LEFT")
    end
    
    if rankText then
        rankText:ClearAllPoints()
        rankText:SetPoint("RIGHT", TradeSkillRankFrame, "RIGHT", -10, 0)
        rankText:SetJustifyH("RIGHT")
        rankText:SetWidth(0) -- Let it auto-size
    end
end

local function CreateSkillUpCheckbox()
    if not TradeSkillFrameAvailableFilterCheckButton then return end
    
    local layout = GetLayout()
    local checkbox = CreateFrame("CheckButton", "SPF_TradeSkillSkillUpCheck", TradeSkillFrame, "UICheckButtonTemplate")
    checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    
    -- Position relative to Have Materials checkbox
    checkbox:SetPoint("LEFT", TradeSkillFrameAvailableFilterCheckButton, "RIGHT", layout.SKILLUP_OFFSET_X, layout.SKILLUP_OFFSET_Y)
    checkbox:SetFrameLevel(TradeSkillFrame:GetFrameLevel() + 10)
    
    -- Extend hit area
    checkbox:SetHitRectInsets(0, -30, 0, 0)
    
    local text = _G[checkbox:GetName().."Text"]
    text:SetText("Skill Up")
    text:SetFontObject(GameFontNormalSmall)
    
    checkbox:SetScript("OnClick", function(self)
        showSkillUp = self:GetChecked()
        
        -- Update the frame
        if TradeSkillFrame_Update then
            TradeSkillFrame_Update()
        end
    end)
    
    return checkbox
end

local function PositionCraftSearchBox()
    if not SPF_CraftSearchInputBox then return end
    
    local layout = GetLayout()
    SPF_CraftSearchInputBox:ClearAllPoints()
    SPF_CraftSearchInputBox:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", layout.CRAFT_SEARCH_BOX_X, layout.CRAFT_SEARCH_BOX_Y)
end

local function PositionCraftHaveMatsCheckbox()
    if not CraftFrameAvailableFilterCheckButton or not SPF_CraftSearchInputBox then return end
    
    local layout = GetLayout()
    CraftFrameAvailableFilterCheckButton:ClearAllPoints()
    CraftFrameAvailableFilterCheckButton:SetPoint("LEFT", SPF_CraftSearchInputBox, "RIGHT", layout.CRAFT_HAVE_MATS_OFFSET_X, layout.CRAFT_HAVE_MATS_OFFSET_Y)
end

local function AdjustCraftRankFrame()
    if not CraftRankFrame then return end
    
    local layout = GetLayout()
    -- Hide Title
    if CraftFrameTitleText then
        CraftFrameTitleText:Hide()
    end
    
    -- Position and size rank frame
    CraftRankFrame:ClearAllPoints()
    CraftRankFrame:SetPoint("TOPLEFT", CraftFrame, "TOPLEFT", layout.CRAFT_RANK_FRAME_X, layout.CRAFT_RANK_FRAME_Y)
    CraftRankFrame:SetWidth(layout.CRAFT_RANK_FRAME_WIDTH)
    CraftRankFrame:SetHeight(layout.CRAFT_RANK_FRAME_HEIGHT)
    
    -- Hide border
    if CraftRankFrameBorder then
        CraftRankFrameBorder:Hide()
    end
    
    -- Center the text inside the bar
    local nameText = _G["CraftRankFrameSkillName"]
    local rankText = _G["CraftRankFrameSkillRank"]
    
    if nameText then
        nameText:ClearAllPoints()
        nameText:SetPoint("LEFT", CraftRankFrame, "LEFT", 10, 0)
        nameText:SetJustifyH("LEFT")
    end
    
    if rankText then
        rankText:ClearAllPoints()
        rankText:SetPoint("RIGHT", CraftRankFrame, "RIGHT", -10, 0)
        rankText:SetJustifyH("RIGHT")
        rankText:SetWidth(0)
    end
end

local function CreateCraftSkillUpCheckbox()
    if not CraftFrameAvailableFilterCheckButton then return end
    
    local layout = GetLayout()
    local checkbox = CreateFrame("CheckButton", "SPF_CraftSkillUpCheck", CraftFrame, "UICheckButtonTemplate")
    checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    
    -- Position relative to Have Materials checkbox
    checkbox:SetPoint("LEFT", CraftFrameAvailableFilterCheckButton, "RIGHT", layout.CRAFT_SKILLUP_OFFSET_X, layout.CRAFT_SKILLUP_OFFSET_Y)
    checkbox:SetFrameLevel(CraftFrame:GetFrameLevel() + 10)
    
    -- Extend hit area
    checkbox:SetHitRectInsets(0, -30, 0, 0)
    
    local text = _G[checkbox:GetName().."Text"]
    text:SetText("Skill Up")
    text:SetFontObject(GameFontNormalSmall)
    
    checkbox:SetScript("OnClick", function(self)
        showSkillUp = self:GetChecked()
        
        -- Update the frame
        if CraftFrame_Update then
            CraftFrame_Update()
        end
    end)
    
    return checkbox
end

local function InitTradeSkillUI()
    if not TradeSkillFrame or not GetNumTradeSkills then return end
    
    -- Hook Blizzard UI update
    if not SPF.tradeSkillHooksInstalled then
        HookTradeSkillFrameUpdate()
        SPF.tradeSkillHooksInstalled = true
    end
    
    -- Position native UI elements
    PositionSearchBox()
    PositionHaveMatsCheckbox()
    AdjustRankFrame()
    
    -- Create custom UI
    SPF.SkillUpCheckbox = CreateSkillUpCheckbox()
    SPF.ClearSearchButton = CreateClearSearchButton()
end

local function InitCraftUI()
    if not CraftFrame or not GetNumCrafts then return end
    
    -- Hook Blizzard UI update
    if not SPF.craftHooksInstalled then
        HookCraftFrameUpdate()
        SPF.craftHooksInstalled = true
    end
    
    -- Create custom UI elements first so we can anchor to them
    SPF.CraftSearchBox = CreateCraftSearchBox()
    SPF.CraftClearSearchButton = CreateCraftClearSearchButton()
    SPF.CraftSkillUpCheckbox = CreateCraftSkillUpCheckbox()
    
    -- Position native and custom UI elements
    PositionCraftSearchBox()
    PositionCraftHaveMatsCheckbox()
    AdjustCraftRankFrame()
end

-- ============================================================================
-- Event Handling
-- ============================================================================

local function OnTradeSkillShow()
    -- Always reset filter when opening
    showSkillUp = false
    
    if SPF.SkillUpCheckbox then
        SPF.SkillUpCheckbox:SetChecked(showSkillUp)
    end
end

local function OnCraftShow()
    -- Always reset filter when opening
    showSkillUp = false
    
    if SPF.CraftSkillUpCheckbox then
        SPF.CraftSkillUpCheckbox:SetChecked(showSkillUp)
    end
    
    if SPF.CraftSearchBox then
        SPF.CraftSearchBox:SetText("Search")
    end
end

local function OnAddonLoaded(addonName)
    if addonName == "Blizzard_TradeSkillUI" then
        InitTradeSkillUI()
    elseif addonName == "Blizzard_CraftUI" then
        InitCraftUI()
    end
end

-- ============================================================================
-- Shift+Click Item Insertion Hook
-- ============================================================================

function SPF:TryInsertLink(text)
    if not text then return false end
    
    -- 1. If our search boxes have focus, ALWAYS insert!
    if TradeSearchInputBox and TradeSearchInputBox:HasFocus() then
        TradeSearchInputBox:SetText(text)
        if SetTradeSkillItemNameFilter then SetTradeSkillItemNameFilter(text) end
        if TradeSkillFrame_Update then TradeSkillFrame_Update() end
        return true
    elseif SPF_CraftSearchInputBox and SPF_CraftSearchInputBox:HasFocus() then
        SPF_CraftSearchInputBox:SetText(text)
        if CraftFrame_Update then CraftFrame_Update() end
        return true
    end
    
    local isShiftAltClick = IsAltKeyDown()

    -- 2. If ANY other edit box has keyboard focus, DO NOT hijack it.
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox and editBox:IsVisible() and editBox:HasFocus() then
            return false
        end
    end
    
    -- Check for other common edit boxes
    if BrowseName and BrowseName:HasFocus() then
        return false
    end
    
    -- 3. If NO box is focused, check for redirection to TradeSkill search box
    local shouldInsert = false
    if SimpleProfessionFilterDB_TBC then
        if isShiftAltClick then
            shouldInsert = SimpleProfessionFilterDB_TBC.insertWithoutFocusAlt
        else
            shouldInsert = SimpleProfessionFilterDB_TBC.insertWithoutFocus
        end
    end

    if shouldInsert then
        -- Insert into TradeSkillFrame search box if visible
        if TradeSkillFrame and TradeSkillFrame:IsShown() and TradeSearchInputBox then
            TradeSearchInputBox:SetText(text)
            TradeSearchInputBox:SetFocus()
            
            -- Trigger search update
            if SetTradeSkillItemNameFilter then
                SetTradeSkillItemNameFilter(text)
            end
            
            if TradeSkillFrame_Update then
                TradeSkillFrame_Update()
            end
            
            return true
        -- Insert into CraftFrame search box if visible
        elseif CraftFrame and CraftFrame:IsShown() and SPF_CraftSearchInputBox then
            SPF_CraftSearchInputBox:SetText(text)
            SPF_CraftSearchInputBox:SetFocus()
            
            if CraftFrame_Update then
                CraftFrame_Update()
            end
            
            return true
        end
    end
    
    return false
end

-- Hook HandleModifiedItemClick to intercept shift-clicks
local orig_HandleModifiedItemClick = HandleModifiedItemClick
function HandleModifiedItemClick(link)
    if not link then 
        if orig_HandleModifiedItemClick then
            return orig_HandleModifiedItemClick(link)
        end
        return
    end
    
    if IsModifiedClick("CHATLINK") then
        local name = GetItemInfo(link) or link:match("%[([^%]]+)%]")
        if name then
            if SPF:TryInsertLink(name) then
                return true
            end
        end
    end
    
    if orig_HandleModifiedItemClick then
        return orig_HandleModifiedItemClick(link)
    end
end

-- Hook ChatEdit_InsertLink as fallback
local orig_ChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text)
    if not text then 
        if orig_ChatEdit_InsertLink then
            return orig_ChatEdit_InsertLink(text)
        end
        return false
    end
    
    local name = GetItemInfo(text) or text:match("%[([^%]]+)%]")
    if name then
        if SPF:TryInsertLink(name) then
             return true
        end
    end
    
    if orig_ChatEdit_InsertLink then
        return orig_ChatEdit_InsertLink(text)
    end
    return false
end

-- ============================================================================
-- Event Frame
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("CRAFT_SHOW")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "TRADE_SKILL_SHOW" then
        OnTradeSkillShow()
    elseif event == "CRAFT_SHOW" then
        OnCraftShow()
    end
end)
