local addonName, SPF = ...
_G[addonName] = SPF

-- Localize Lua functions for performance
local string_find = string.find
local string_lower = string.lower
local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs
local unpack = unpack
local GetTime = GetTime

-- ============================================================================
-- Constants & Configuration
-- ============================================================================

local CONSTANTS = {
    -- UI Positions
    TRADESKILL_SEARCH_X = 71,
    TRADESKILL_SEARCH_Y = -55,
    TRADESKILL_SEARCH_WIDTH = 130,
    CRAFT_SEARCH_X_NORMAL = 107,
    CRAFT_SEARCH_X_LEATRIX = 71,
    CRAFT_SEARCH_Y_NORMAL = -73,
    CRAFT_SEARCH_Y_LEATRIX = -55,
    CRAFT_SEARCH_WIDTH = 100,
    CRAFT_SEARCH_WIDTH_LEATRIX = 130,
    SEARCH_HEIGHT = 18,
    
    -- DropDown
    CRAFT_DROPDOWN_X_NORMAL = 0,
    CRAFT_DROPDOWN_X_LEATRIX = 505,
    CRAFT_DROPDOWN_Y_NORMAL = -67,
    CRAFT_DROPDOWN_Y_LEATRIX = -40,
    CRAFT_DROPDOWN_WIDTH = 70,
    CRAFT_DROPDOWN_WIDTH_LEATRIX = 135,
    
    -- Checkbox
    CHECKBOX_SIZE = 21,
    CHECKBOX_SPACING = 38,
    CHECKBOX_OFFSET = 7,
    CHECKBOX_HIT_INSET_NORMAL = -50,
    CHECKBOX_HIT_INSET_LEATRIX = -75,
    
    -- RankFrame
    RANKFRAME_WIDTH_NORMAL = 280,
    RANKFRAME_WIDTH_LEATRIX = 280,
    RANKFRAME_HEIGHT = 15,
    RANKFRAME_OFFSET_Y = -2,
    
    -- CraftRankFrame
    CRAFT_RANKFRAME_WIDTH_NORMAL = 270,
    CRAFT_RANKFRAME_WIDTH_LEATRIX = 280,
    CRAFT_RANKFRAME_HEIGHT = 16,
    CRAFT_RANKFRAME_BORDER_WIDTH_NORMAL = 280,
    CRAFT_RANKFRAME_BORDER_WIDTH_LEATRIX = 290,
    CRAFT_RANKFRAME_BORDER_HEIGHT = 38,
    
    -- ScrollFrame
    SCROLL_HIGHLIGHT_WIDTH = 293,
    SCROLL_HIGHLIGHT_HEIGHT = 316,
    
    -- Layout
    LAYOUT_CONTROLS_Y = -35.5,
    LAYOUT_RANK_TOP_Y = -16,
    LAYOUT_RANK_WIDTH = 254,
    LAYOUT_RANK_HEIGHT = 16,
    
    -- Colors
    COLOR_PLACEHOLDER = {0.5, 0.5, 0.5},
    COLOR_CLEAR_HOVER = {1, 0.2, 0.2},
    COLOR_CLEAR_NORMAL = {1, 1, 1},
    
    -- Textures
    TEXTURE_CLEAR_BUTTON = "Interface\\FriendsFrame\\ClearBroadcastIcon",
    TEXTURE_PLUS_BUTTON = "Interface\\Buttons\\UI-PlusButton-Up",
    TEXTURE_MINUS_BUTTON = "Interface\\Buttons\\UI-MinusButton-Up",
    TEXTURE_PLUS_HIGHLIGHT = "Interface\\Buttons\\UI-PlusButton-Hilight",
    
    -- Backdrop
    BACKDROP_BG = "Interface\\ChatFrame\\ChatFrameBackground",
    BACKDROP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border",
    BACKDROP_TILE_SIZE = 16,
    BACKDROP_EDGE_SIZE = 12,
    BACKDROP_INSETS = { left = 3, right = 3, top = 3, bottom = 3 },
    BACKDROP_COLOR = {0, 0, 0, 0.5},
    BACKDROP_BORDER_COLOR = {0.6, 0.6, 0.6, 1},
}

-- Difficulty color fallbacks
local DIFFICULTY_COLORS = {
    optimal = {r=1.0, g=0.5, b=0.25},
    medium = {r=1.0, g=1.0, b=0.0},
    easy = {r=0.25, g=0.75, b=0.25},
    trivial = {r=0.5, g=0.5, b=0.5},
    default = {r=1.0, g=1.0, b=1.0}
}


-- ============================================================================
-- State Management (Separate states for TradeSkill and Craft)
-- ============================================================================

SPF.TradeSkillState = {
    filterText = "",
    showSkillUp = false,
    showHaveMats = false
}

SPF.CraftState = {
    filterText = "",
    filterCategory = "All",
    showSkillUp = false,
    showHaveMats = false
}

-- Enchanting Localization
local L = SPF.L


-- Craft Categories (Internal Keys)
local CRAFT_CATEGORIES = {
    "All",
    "Boots",
    "Bracer",
    "Chest",
    "Cloak",
    "Gloves",
    "Shield",
    "Weapon",
    "Wand",
    "Rod",
    "Oil",
    "Other"
}

SPF.skillUpText = "Skill up"
SPF.tradeSkillHaveMatsText = "Have mats"  -- For TradeSkill (normal professions)
SPF.craftHaveMatsText = "Have mats"   -- For Craft (Enchanting)
SPF.searchPlaceholder = "Search..."

-- ============================================================================
-- Utility Functions
-- ============================================================================

local stripColorCache = setmetatable({}, { __mode = "kv" })
local function StripColor(text)
    if not text then return "" end
    if stripColorCache[text] then return stripColorCache[text] end
    
    local stripped = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    stripColorCache[text] = stripped
    return stripped
end

function SPF:TryInsertLink(text)
    if not text then return false end
    
    local targetEditBox = SPF.FocusedEditBox
    
    -- If no box is focused, find which profession window is open
    if not targetEditBox and SimpleProfessionFilterDB.insertWithoutFocus then
        if TradeSkillFrame and TradeSkillFrame:IsShown() and SPF.SearchBox then
            targetEditBox = SPF.SearchBox
        elseif CraftFrame and CraftFrame:IsShown() and SPF.CraftSearchBox then
            targetEditBox = SPF.CraftSearchBox
        end
    end
    
    -- Fallback for grace period focus
    if not targetEditBox and SPF.LastFocusedEditBox and SPF.LastFocusTime then
         if (GetTime() - SPF.LastFocusTime) < 0.5 then
             targetEditBox = SPF.LastFocusedEditBox
         end
    end
    
    if targetEditBox then
        targetEditBox:SetText(text)
        return true
    end
    
    return false
end

local isLeatrixLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded("Leatrix_Plus")) or IsAddOnLoaded("Leatrix_Plus")
local enhanceProfessions = isLeatrixLoaded and _G.LeaPlusDB and _G.LeaPlusDB["EnhanceProfessions"] == "On"

-- ============================================================================
-- Event Handler
-- ============================================================================

SPF.Frame = CreateFrame("Frame")
SPF.Frame:RegisterEvent("ADDON_LOADED")
SPF.Frame:RegisterEvent("TRADE_SKILL_SHOW")
SPF.Frame:RegisterEvent("TRADE_SKILL_UPDATE")
SPF.Frame:RegisterEvent("CRAFT_SHOW")
SPF.Frame:RegisterEvent("CRAFT_UPDATE")


function SPF.Frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_TradeSkillUI" then
            SPF:InitTradeSkillUI()
        elseif arg1 == "Blizzard_CraftUI" then
            SPF:InitCraftUI()
        end
    elseif event == "TRADE_SKILL_SHOW" then
        if not SimpleProfessionFilterDB.rememberFilters then
            SPF.TradeSkillState.filterText = ""
            SPF.TradeSkillState.showSkillUp = false
            SPF.TradeSkillState.showHaveMats = false
        end
        
        -- Sync UI
        if SPF.SearchBox then 
            SPF.SearchBox:SetText(SPF.TradeSkillState.filterText or "") 
        end
        if SPF.TradeSkillSkillUpCheck then
            SPF.TradeSkillSkillUpCheck:SetChecked(SPF.TradeSkillState.showSkillUp)
        end
        if SPF.TradeSkillHaveMatsCheck then
            SPF.TradeSkillHaveMatsCheck:SetChecked(SPF.TradeSkillState.showHaveMats)
        end
        
        stripColorCache = {}
        SPF:AdjustTradeSkillLayout()
    elseif event == "CRAFT_SHOW" then
        if not SimpleProfessionFilterDB.rememberFilters then
            SPF.CraftState.filterText = ""
            SPF.CraftState.showSkillUp = false
            SPF.CraftState.showHaveMats = false
            SPF.CraftState.filterCategory = "All"
        end
        
        -- Sync UI
        if SPF.CraftSearchBox then 
            SPF.CraftSearchBox:SetText(SPF.CraftState.filterText or "") 
        end
        if SPF.CraftSkillUpCheck then
            SPF.CraftSkillUpCheck:SetChecked(SPF.CraftState.showSkillUp)
        end
        if SPF.CraftHaveMatsCheck then
            SPF.CraftHaveMatsCheck:SetChecked(SPF.CraftState.showHaveMats)
        end
        if SPF.CraftDropDown then
            local cat = SPF.CraftState.filterCategory or "All"
            UIDropDownMenu_SetText(SPF.CraftDropDown, L[cat] or cat)
        end
        
        stripColorCache = {}
    end
end
SPF.Frame:SetScript("OnEvent", SPF.Frame.OnEvent)

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Create a search box with clear button and placeholder
local function CreateSearchBox(parent, name, x, y, width, height, state, updateCallback, expandCallback)
    if not parent then return nil end
    
    local searchBox = CreateFrame("EditBox", name, parent, "BackdropTemplate")
    searchBox:SetSize(width, height)
    searchBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    searchBox:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    searchBox:SetBackdrop({
        bgFile = CONSTANTS.BACKDROP_BG,
        edgeFile = CONSTANTS.BACKDROP_EDGE,
        tile = true,
        tileSize = CONSTANTS.BACKDROP_TILE_SIZE,
        edgeSize = CONSTANTS.BACKDROP_EDGE_SIZE,
        insets = CONSTANTS.BACKDROP_INSETS
    })
    searchBox:SetBackdropColor(unpack(CONSTANTS.BACKDROP_COLOR))
    searchBox:SetBackdropBorderColor(unpack(CONSTANTS.BACKDROP_BORDER_COLOR))
    
    searchBox:SetAutoFocus(false)
    searchBox:SetTextInsets(6, 18, 0, 0)
    
    local fontName, _, fontFlags = ChatFontNormal:GetFont()
    searchBox:SetFont(fontName, 11, fontFlags)
    
    -- Placeholder
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetText(SPF.searchPlaceholder)
    placeholder:SetTextColor(unpack(CONSTANTS.COLOR_PLACEHOLDER))
    
    -- Clear Button
    local clearButton = CreateFrame("Button", nil, searchBox)
    clearButton:SetSize(14, 14)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    clearButton:SetNormalTexture(CONSTANTS.TEXTURE_CLEAR_BUTTON)
    clearButton:Hide()
    
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    clearButton:SetScript("OnEnter", function(self)
        self:GetNormalTexture():SetVertexColor(unpack(CONSTANTS.COLOR_CLEAR_HOVER))
    end)
    clearButton:SetScript("OnLeave", function(self)
        self:GetNormalTexture():SetVertexColor(unpack(CONSTANTS.COLOR_CLEAR_NORMAL))
    end)
    
    -- Event Handlers
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        state.filterText = text:lower()
        
        if text ~= "" then
            placeholder:Hide()
            clearButton:Show()
            -- Expand only on user input, not programmatic changes
            if userInput and expandCallback then 
                expandCallback(0) 
            end
        else
            placeholder:Show()
            clearButton:Hide()
        end
        
        if updateCallback then updateCallback() end
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
        SPF.FocusedEditBox = self
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            placeholder:Show()
        end
        SPF.FocusedEditBox = nil
        SPF.LastFocusedEditBox = self
        SPF.LastFocusTime = GetTime()
    end)
    
    return searchBox
end

-- Create a checkbox with label
local function CreateCheckbox(parent, name, labelText, anchorTo, xOffset, yOffset, hitInset, state, stateKey, updateCallback, expandCallback)
    if not parent then return nil end
    
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetSize(CONSTANTS.CHECKBOX_SIZE, CONSTANTS.CHECKBOX_SIZE)
    checkbox:SetPoint("LEFT", anchorTo, "RIGHT", xOffset, yOffset)
    checkbox:SetHitRectInsets(0, hitInset, 0, 0)
    checkbox:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    local text = _G[checkbox:GetName().."Text"]
    text:SetText(labelText)
    text:SetFontObject(GameFontNormalSmall)
    
    checkbox:SetScript("OnClick", function(self)
        state[stateKey] = self:GetChecked()
        if state[stateKey] and expandCallback then expandCallback(0) end
        if updateCallback then updateCallback() end
    end)
    
    return checkbox
end

-- Get difficulty color with fallback
local function GetDifficultyColor(type)
    local color = TradeSkillTypeColor and TradeSkillTypeColor[type]
    if not color then
        color = DIFFICULTY_COLORS[type] or DIFFICULTY_COLORS.default
    end
    return color
end

-- Filtering logic (unified for both TradeSkill and Craft)
local function ApplyFilters(numItems, getInfoFunc, getNumReagentsFunc, getReagentInfoFunc, state)
    if not getInfoFunc then return {} end
    
    local filteredIndices = {}
    
    -- Quick path: if no filters, just return all indices
    local noCategoryFilter = (not state.filterCategory or state.filterCategory == "All")
    if state.filterText == "" and not state.showSkillUp and not state.showHaveMats and noCategoryFilter then
        for i = 1, numItems do
            filteredIndices[i] = i
        end
        return filteredIndices
    end
    
    -- Apply filters
    local currentHeaderIndex = nil
    local keepHeader = false
    
    for i = 1, numItems do
        local name, type, numAvailable, isExpanded, altVerb, numSkillUps
        
        -- Different APIs have different return order
        if getNumReagentsFunc == GetTradeSkillNumReagents then
            -- TradeSkill: name, type, numAvailable, isExpanded, altVerb, numSkillUps
            name, type, numAvailable, isExpanded, altVerb, numSkillUps = getInfoFunc(i)
            -- Fix difficulty based on skill ups
            if (numSkillUps or 0) == 0 and type ~= "header" then
                type = "trivial"
            end
        else
            -- Craft: name, rank, type, numAvailable, isExpanded
            local rank
            name, rank, type, numAvailable, isExpanded = getInfoFunc(i)
        end
        
        if type == "header" then
            currentHeaderIndex = i
            keepHeader = false
        else
            local match = true
            
            -- Pre-calculate stripped lower case name for filters
            local strippedNameL
            if state.filterText ~= "" or (state.filterCategory and state.filterCategory ~= "All") then
                strippedNameL = string_lower(StripColor(name))
            end

            -- Search filter
            if state.filterText ~= "" then
                local nameMatch = name and string_find(strippedNameL, state.filterText, 1, true)
                
                if not nameMatch and getNumReagentsFunc and getReagentInfoFunc then
                    local numReagents = getNumReagentsFunc(i)
                    for j = 1, numReagents do
                        local reagentName = getReagentInfoFunc(i, j)
                        if reagentName and string_find(string_lower(StripColor(reagentName)), state.filterText, 1, true) then
                            nameMatch = true
                            break
                        end
                    end
                end
                
                if not nameMatch then
                    match = false
                end
            end
            
            -- Category filter (Craft only)
            if match and state.filterCategory and state.filterCategory ~= "All" then
                local catKey = state.filterCategory
                
                if catKey == "Other" then
                    -- Check against all localized slot categories (exclude All and Other)
                    local found = false
                    for key, localizedName in pairs(L) do
                        if key ~= "All" and key ~= "Other" then
                            if string_find(strippedNameL, string_lower(localizedName), 1, true) then
                                found = true
                                break
                            end
                        end
                    end
                    if found then match = false end
                else
                    local localizedMatch = L[catKey]
                    if localizedMatch then
                        if not string_find(strippedNameL, string_lower(localizedMatch), 1, true) then
                            match = false
                        end
                    else
                        match = false -- Should not happen if keys match
                    end
                end
            end
            
            -- Skill up filter
            if match and state.showSkillUp and type == "trivial" then
                match = false
            end
            
            -- Have materials filter
            if match and state.showHaveMats and numAvailable == 0 then
                match = false
            end
            
            if match then
                if currentHeaderIndex and not keepHeader then
                    table_insert(filteredIndices, currentHeaderIndex)
                    keepHeader = true
                end
                table_insert(filteredIndices, i)
            end
        end
    end
    
    return filteredIndices
end

-- Check if selected index is in filtered results (O(1) hash lookup)
local function IsSelectedInFiltered(selectedIndex, filteredIndices)
    if not selectedIndex then return false end
    
    local filteredSet = {}
    for _, idx in ipairs(filteredIndices) do
        filteredSet[idx] = true
    end
    
    return filteredSet[selectedIndex] == true
end


-- ============================================================================
-- TradeSkillFrame Support
-- ============================================================================

function SPF:AdjustTradeSkillLayout()
    if enhanceProfessions then return end

    -- Hide Title
    if TradeSkillFrameTitleText then
        TradeSkillFrameTitleText:Hide()
    end

    -- Move RankFrame UP (to Title area)
    if TradeSkillRankFrame then
        TradeSkillRankFrame:ClearAllPoints()
        TradeSkillRankFrame:SetPoint("TOP", TradeSkillFrame, "TOP", 5, CONSTANTS.LAYOUT_RANK_TOP_Y)
        TradeSkillRankFrame:SetWidth(CONSTANTS.LAYOUT_RANK_WIDTH)
        TradeSkillRankFrame:SetHeight(CONSTANTS.LAYOUT_RANK_HEIGHT)

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

    -- Move Controls UP
    if SPF.SearchBox then
        SPF.SearchBox:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 75, CONSTANTS.LAYOUT_CONTROLS_Y)
    end
end

function SPF:InitTradeSkillUI()
    if SPF.TradeSkillInitialized then return end
    SPF.TradeSkillInitialized = true
    
    -- API Validation
    if not TradeSkillFrame or not GetNumTradeSkills then return end
    
    -- Set text based on Leatrix Plus setting
    local haveMatsText = SPF.tradeSkillHaveMatsText
    if enhanceProfessions then 
        haveMatsText = "Have materials" 
    end

    local parent = TradeSkillFrame

    -- Adjust RankFrame
    if TradeSkillRankFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = TradeSkillRankFrame:GetPoint()
        TradeSkillRankFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + CONSTANTS.RANKFRAME_OFFSET_Y)
        TradeSkillRankFrame:SetWidth(CONSTANTS.RANKFRAME_WIDTH_NORMAL)
        TradeSkillRankFrame:SetHeight(CONSTANTS.RANKFRAME_HEIGHT)

        if TradeSkillRankFrameBorder then
            TradeSkillRankFrameBorder:SetWidth(290)
            TradeSkillRankFrameBorder:SetHeight(38)
        end
    end

    -- Wrapper function for update callback
    local function UpdateTradeSkill()
        if TradeSkillFrame_Update then
            TradeSkillFrame_Update()
        end
    end

    -- Search Box
    SPF.SearchBox = CreateSearchBox(
        parent,
        "SPF_TradeSkillSearchBox",
        CONSTANTS.TRADESKILL_SEARCH_X,
        CONSTANTS.TRADESKILL_SEARCH_Y,
        CONSTANTS.TRADESKILL_SEARCH_WIDTH,
        CONSTANTS.SEARCH_HEIGHT,
        SPF.TradeSkillState,
        UpdateTradeSkill,
        ExpandTradeSkillSubClass
    )

    -- Skill Up Checkbox
    local skillUp = CreateCheckbox(
        parent,
        "SPF_TradeSkillSkillUpCheck",
        SPF.skillUpText,
        SPF.SearchBox,
        CONSTANTS.CHECKBOX_OFFSET,
        0,
        -35,
        SPF.TradeSkillState,
        "showSkillUp",
        UpdateTradeSkill,
        ExpandTradeSkillSubClass
    )
    SPF.TradeSkillSkillUpCheck = skillUp

    -- Have Mats Checkbox
    local haveMatsInset = enhanceProfessions and CONSTANTS.CHECKBOX_HIT_INSET_LEATRIX or CONSTANTS.CHECKBOX_HIT_INSET_NORMAL
    local haveMats = CreateCheckbox(
        parent,
        "SPF_TradeSkillHaveMatsCheck",
        haveMatsText,
        skillUp,
        CONSTANTS.CHECKBOX_SPACING,
        0,
        haveMatsInset,
        SPF.TradeSkillState,
        "showHaveMats",
        UpdateTradeSkill,
        ExpandTradeSkillSubClass
    )
    SPF.TradeSkillHaveMatsCheck = haveMats

    -- Clear focus when clicking outside search box
    if SPF.SearchBox then
        parent:HookScript("OnMouseDown", function(self, button)
            if SPF.SearchBox:HasFocus() then
                SPF.SearchBox:ClearFocus()
            end
        end)
    end

    -- Hook Update
    hooksecurefunc("TradeSkillFrame_Update", SPF.TradeSkillFrame_Update)
end



function SPF.TradeSkillFrame_Update()
    -- API Validation
    if not GetNumTradeSkills or not TradeSkillListScrollFrame then return end
    
    -- Enforce layout adjustment
    SPF:AdjustTradeSkillLayout()

    local numTradeSkills = GetNumTradeSkills()
    
    -- Apply filters using unified logic
    local filteredIndices = ApplyFilters(
        numTradeSkills,
        GetTradeSkillInfo,
        GetTradeSkillNumReagents,
        GetTradeSkillReagentInfo,
        SPF.TradeSkillState
    )

    -- Update ScrollFrame
    FauxScrollFrame_Update(
        TradeSkillListScrollFrame,
        #filteredIndices,
        TRADE_SKILLS_DISPLAYED,
        TRADE_SKILL_HEIGHT,
        nil, nil, nil,
        TradeSkillHighlightFrame,
        CONSTANTS.SCROLL_HIGHLIGHT_WIDTH,
        CONSTANTS.SCROLL_HIGHLIGHT_HEIGHT
    )

    -- Check if selected recipe is in filtered results (O(1) hash lookup)
    local selectedIndex = GetTradeSkillSelectionIndex and GetTradeSkillSelectionIndex()
    local selectedInFiltered = IsSelectedInFiltered(selectedIndex, filteredIndices)
    
    -- Hide highlight if selected recipe is filtered out
    if selectedIndex and not selectedInFiltered and TradeSkillHighlightFrame then
        TradeSkillHighlightFrame:Hide()
    end

    -- Update Buttons
    local scrollOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame)
    for i = 1, TRADE_SKILLS_DISPLAYED do
        local skillIndex = filteredIndices[i + scrollOffset]
        local skillButton = _G["TradeSkillSkill"..i]
        
        if not skillButton then break end
        
        if skillIndex then
            local name, type, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(skillIndex)
            skillButton:SetID(skillIndex)
            skillButton:Show()

            local skillButtonText = _G["TradeSkillSkill"..i.."Text"]
            local skillButtonCount = _G["TradeSkillSkill"..i.."Count"]
            
            -- Fix difficulty colors
            if (numSkillUps or 0) == 0 and type ~= "header" then
                type = "trivial"
            end

            if type == "header" then
                skillButton:SetNormalTexture(CONSTANTS.TEXTURE_PLUS_BUTTON)
                skillButton.r = 1.0
                skillButton.g = 1.0
                skillButton.b = 1.0
                if skillButtonText then
                    skillButtonText:SetTextColor(1.0, 1.0, 1.0)
                end
                if isExpanded then
                    skillButton:SetNormalTexture(CONSTANTS.TEXTURE_MINUS_BUTTON)
                end
                local highlight = _G["TradeSkillSkill"..i.."Highlight"]
                if highlight then
                    highlight:SetTexture(CONSTANTS.TEXTURE_PLUS_HIGHLIGHT)
                end
            else
                skillButton:SetNormalTexture("")
                local highlight = _G["TradeSkillSkill"..i.."Highlight"]
                if highlight then
                    highlight:SetTexture("")
                end
                
                local color = GetDifficultyColor(type)
                if skillButtonText then
                    skillButtonText:SetTextColor(color.r, color.g, color.b)
                end
            end

            -- Indent
            if type == "header" then
                local texture = skillButton:GetNormalTexture()
                if texture then
                    texture:SetPoint("LEFT", skillButton, "LEFT", 0, 0)
                end
                if skillButtonText then
                    skillButtonText:SetPoint("LEFT", skillButton, "LEFT", 18, 0)
                end
            else
                if skillButtonText then
                    skillButtonText:SetPoint("LEFT", skillButton, "LEFT", 23, 0)
                end
            end

            -- Set text and indent based on type
            local displayName = StripColor(name)
            if numAvailable > 0 then
                displayName = displayName.." ["..numAvailable.."]"
            end
            
            if skillButtonText then
                skillButtonText:SetText(displayName)
            end
            
            if skillButtonCount then
                skillButtonCount:SetText("")
            end
            
            -- Selection Highlight
            if selectedIndex == skillIndex and TradeSkillHighlightFrame then
                TradeSkillHighlightFrame:SetPoint("TOPLEFT", "TradeSkillSkill"..i, "TOPLEFT", 0, 0)
                TradeSkillHighlightFrame:Show()
                if skillButtonText then
                    skillButtonText:SetVertexColor(1.0, 1.0, 1.0)
                end
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
    
    -- API Validation
    if not CraftFrame or not GetNumCrafts then return end
    
    local haveMatsText = SPF.craftHaveMatsText
    if enhanceProfessions then 
        haveMatsText = "Have materials" 
    end

    local parent = CraftFrame

    -- Adjust CraftRankFrame
    if CraftRankFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = CraftRankFrame:GetPoint()
        CraftRankFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + CONSTANTS.RANKFRAME_OFFSET_Y)
        CraftRankFrame:SetWidth(enhanceProfessions and CONSTANTS.CRAFT_RANKFRAME_WIDTH_LEATRIX or CONSTANTS.CRAFT_RANKFRAME_WIDTH_NORMAL)
        CraftRankFrame:SetHeight(CONSTANTS.CRAFT_RANKFRAME_HEIGHT)

        if CraftRankFrameBorder then
            CraftRankFrameBorder:SetWidth(enhanceProfessions and CONSTANTS.CRAFT_RANKFRAME_BORDER_WIDTH_LEATRIX or CONSTANTS.CRAFT_RANKFRAME_BORDER_WIDTH_NORMAL)
            CraftRankFrameBorder:SetHeight(CONSTANTS.CRAFT_RANKFRAME_BORDER_HEIGHT)
        end
    end

    -- Wrapper function for update callback
    local function UpdateCraft()
        if CraftFrame_Update then
            CraftFrame_Update()
        end
    end

    -- Search Box
    local searchX = enhanceProfessions and CONSTANTS.CRAFT_SEARCH_X_LEATRIX or CONSTANTS.CRAFT_SEARCH_X_NORMAL
    local searchY = enhanceProfessions and CONSTANTS.CRAFT_SEARCH_Y_LEATRIX or CONSTANTS.CRAFT_SEARCH_Y_NORMAL
    local searchWidth = enhanceProfessions and CONSTANTS.CRAFT_SEARCH_WIDTH_LEATRIX or CONSTANTS.CRAFT_SEARCH_WIDTH
    
    SPF.CraftSearchBox = CreateSearchBox(
        parent,
        "SPF_CraftSearchBox",
        searchX,
        searchY,
        searchWidth,
        CONSTANTS.SEARCH_HEIGHT,
        SPF.CraftState,
        UpdateCraft,
        ExpandCraftSkillLine
    )

    -- Skill Up Checkbox
    local skillUp = CreateCheckbox(
        parent,
        "SPF_CraftSkillUpCheck",
        "Skill up",
        SPF.CraftSearchBox,
        CONSTANTS.CHECKBOX_OFFSET,
        0,
        -35,
        SPF.CraftState,
        "showSkillUp",
        UpdateCraft,
        ExpandCraftSkillLine
    )
    SPF.CraftSkillUpCheck = skillUp

    -- Have Mats Checkbox
    local haveMatsInset = enhanceProfessions and CONSTANTS.CHECKBOX_HIT_INSET_LEATRIX or CONSTANTS.CHECKBOX_HIT_INSET_NORMAL
    local haveMats = CreateCheckbox(
        parent,
        "SPF_CraftHaveMatsCheck",
        haveMatsText,
        skillUp,
        CONSTANTS.CHECKBOX_SPACING,
        0,
        haveMatsInset,
        SPF.CraftState,
        "showHaveMats",
        UpdateCraft,
        ExpandCraftSkillLine
    )
    SPF.CraftHaveMatsCheck = haveMats

    -- Clear focus when clicking outside search box
    if SPF.CraftSearchBox then
        parent:HookScript("OnMouseDown", function(self, button)
            if SPF.CraftSearchBox:HasFocus() then
                SPF.CraftSearchBox:ClearFocus()
            end
        end)
    end

    -- Hook Update
    hooksecurefunc("CraftFrame_Update", SPF.CraftFrame_Update)
    
    -- Explicitly hook Reagent buttons for Shift+Click
    for i = 1, 8 do
        local reagentBtn = _G["CraftReagent"..i]
        if reagentBtn then
            reagentBtn:HookScript("OnClick", function(self)
                if IsModifiedClick("CHATLINK") and SPF.CraftSearchBox then
                    local link = GetCraftReagentItemLink(GetCraftSelectionIndex(), self:GetID())
                    if link then
                        local name = GetItemInfo(link) or link:match("%[([^%]]+)%]")
                        if name then
                            SPF:TryInsertLink(name)
                        end
                    end
                end
            end)
        end
    end
    
    -- Init DropDown
    SPF:InitCraftDropDown(parent)
end




-- Custom Dropdown implementation
function SPF:CreateCraftOptionsMenu()
    local frame = CreateFrame("Frame", "SPF_CraftOptionsMenu", UIParent, "BackdropTemplate")
    frame:SetSize(155, #CRAFT_CATEGORIES * 16 + 30)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    -- Fullscreen closer button (to close when clicking outside)
    local closer = CreateFrame("Button", nil, UIParent)
    closer:SetFrameStrata("DIALOG")
    closer:SetFrameLevel(frame:GetFrameLevel() - 1)
    closer:SetAllPoints(UIParent)
    closer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    closer:SetScript("OnClick", function()
        frame:Hide()
        closer:Hide()
    end)
    closer:Hide()
    frame.closer = closer

    frame.buttons = {}
    
    local function Button_OnClick(self)
        SPF.CraftState.filterCategory = self.value
        local label = L[self.value] or self.value
        UIDropDownMenu_SetText(SPF.CraftDropDown, label)
        frame:Hide()
        closer:Hide()
        
        -- Update Check marks
        for _, btn in ipairs(frame.buttons) do
            if btn.check then
                if btn.value == self.value then
                    btn.check:Show()
                else
                    btn.check:Hide()
                end
            end
        end
        
        if CraftFrame_Update then
            CraftFrame_Update()
        end
    end

    for i, category in ipairs(CRAFT_CATEGORIES) do
        local btn = CreateFrame("Button", nil, frame)
        btn:SetHeight(16)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -15 - (i-1)*16)
        btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -15 - (i-1)*16)
        
        btn.value = category
        
        -- Text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", btn, "LEFT", 18, 0)
        
        text:SetText(L[category] or category)
        text:SetJustifyH("LEFT")
        btn.text = text
        
        -- Check
        local check = btn:CreateTexture(nil, "ARTWORK")
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetSize(16, 16)
        check:SetPoint("LEFT", btn, "LEFT", 0, 0)
        check:Hide()
        if category == "All" then check:Show() end
        btn.check = check
        
        -- Highlight
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hl:SetBlendMode("ADD")
        
        btn:SetScript("OnClick", Button_OnClick)
        
        table.insert(frame.buttons, btn)
    end
    
    return frame
end

function SPF:ToggleCraftMenu()
    if not SPF.CraftOptionsMenu then
        SPF.CraftOptionsMenu = SPF:CreateCraftOptionsMenu()
    end
    
    local menu = SPF.CraftOptionsMenu
    if menu:IsShown() then
        menu:Hide()
        menu.closer:Hide()
    else
        -- Anchor to the Main Dropdown
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", SPF.CraftDropDown, "BOTTOMLEFT", 15, 6)
        menu:Show()
        menu.closer:Show()
        
        -- Update state (checks)
        local current = SPF.CraftState.filterCategory or "All"
        for _, btn in ipairs(menu.buttons) do
            if btn.check then
                 if btn.value == current then
                     btn.check:Show()
                 else
                     btn.check:Hide()
                 end
            end
        end
    end
end

function SPF:InitCraftDropDown(parent)
    local dropDown = CreateFrame("Frame", "SPF_CraftDropDown", parent, "UIDropDownMenuTemplate")
    SPF.CraftDropDown = dropDown
    
    local x = enhanceProfessions and CONSTANTS.CRAFT_DROPDOWN_X_LEATRIX or CONSTANTS.CRAFT_DROPDOWN_X_NORMAL
    local y = enhanceProfessions and CONSTANTS.CRAFT_DROPDOWN_Y_LEATRIX or CONSTANTS.CRAFT_DROPDOWN_Y_NORMAL
    local width = enhanceProfessions and CONSTANTS.CRAFT_DROPDOWN_WIDTH_LEATRIX or CONSTANTS.CRAFT_DROPDOWN_WIDTH
    
    dropDown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dropDown, width)
    
    local initialLabel = L["All"] or "All Slots"
    local currentCat = SPF.CraftState.filterCategory
    if currentCat and currentCat ~= "All" then
        initialLabel = L[currentCat] or currentCat
    end
    
    UIDropDownMenu_SetText(dropDown, initialLabel)
    -- Hijack the Button click to show our custom frame
    local button = _G[dropDown:GetName().."Button"]
    if button then
        button:SetScript("OnClick", function()
            SPF:ToggleCraftMenu()
            PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
        end)
        
        -- Also make the text area clickable
        local textButton = CreateFrame("Button", nil, dropDown)
        textButton:SetPoint("TOPLEFT", dropDown, "TOPLEFT")
        textButton:SetPoint("BOTTOMLEFT", dropDown, "BOTTOMLEFT")
        textButton:SetPoint("RIGHT", button, "LEFT")
        textButton:SetScript("OnClick", function()
            SPF:ToggleCraftMenu()
            PlaySound(856)
        end)
    end
    

end


function SPF.CraftFrame_Update()
    -- API Validation
    if not GetNumCrafts or not CraftListScrollFrame then return end
    
    local numCrafts = GetNumCrafts()
    
    -- Apply filters using unified logic
    local filteredIndices = ApplyFilters(
        numCrafts,
        GetCraftInfo,
        GetCraftNumReagents,
        GetCraftReagentInfo,
        SPF.CraftState
    )

    -- Update ScrollFrame
    FauxScrollFrame_Update(
        CraftListScrollFrame,
        #filteredIndices,
        CRAFTS_DISPLAYED,
        CRAFT_SKILL_HEIGHT,
        nil, nil, nil,
        CraftHighlightFrame,
        CONSTANTS.SCROLL_HIGHLIGHT_WIDTH,
        CONSTANTS.SCROLL_HIGHLIGHT_HEIGHT
    )

    -- Check if selected craft is in filtered results (O(1) hash lookup)
    local selectedIndex = GetCraftSelectionIndex and GetCraftSelectionIndex()
    local selectedInFiltered = IsSelectedInFiltered(selectedIndex, filteredIndices)
    
    -- Hide highlight if selected craft is filtered out
    if selectedIndex and not selectedInFiltered and CraftHighlightFrame then
        CraftHighlightFrame:Hide()
    end

    -- Update Buttons
    local scrollOffset = FauxScrollFrame_GetOffset(CraftListScrollFrame)
    for i = 1, CRAFTS_DISPLAYED do
        local craftIndex = filteredIndices[i + scrollOffset]
        local craftButton = _G["Craft"..i]
        
        if not craftButton then break end
        
        if craftIndex then
            local name, rank, type, numAvailable, isExpanded = GetCraftInfo(craftIndex)
            craftButton:SetID(craftIndex)
            craftButton:Show()

            local craftButtonText = _G["Craft"..i.."Text"]
            local craftButtonCost = _G["Craft"..i.."Cost"]
            local craftButtonCount = _G["Craft"..i.."Count"]

            if type == "header" then
                craftButton:SetNormalTexture(CONSTANTS.TEXTURE_PLUS_BUTTON)
                craftButton.r = 1.0
                craftButton.g = 1.0
                craftButton.b = 1.0
                if craftButtonText then
                    craftButtonText:SetTextColor(1.0, 1.0, 1.0)
                end
                if isExpanded then
                    craftButton:SetNormalTexture(CONSTANTS.TEXTURE_MINUS_BUTTON)
                end
                local highlight = _G["Craft"..i.."Highlight"]
                if highlight then
                    highlight:SetTexture(CONSTANTS.TEXTURE_PLUS_HIGHLIGHT)
                end
            else
                craftButton:SetNormalTexture("")
                local highlight = _G["Craft"..i.."Highlight"]
                if highlight then
                    highlight:SetTexture("")
                end
                
                local color = GetDifficultyColor(type)
                if craftButtonText then
                    craftButtonText:SetTextColor(color.r, color.g, color.b)
                end
            end

            -- Indent
            if type == "header" then
                local texture = craftButton:GetNormalTexture()
                if texture then
                    texture:SetPoint("LEFT", craftButton, "LEFT", 0, 0)
                end
                if craftButtonText then
                    craftButtonText:SetPoint("LEFT", craftButton, "LEFT", 25, 0)
                end
            else
                if craftButtonText then
                    craftButtonText:SetPoint("LEFT", craftButton, "LEFT", 40, 0)
                end
            end

            -- Set text and indent
            local displayName = StripColor(name)
            if numAvailable > 0 then
                displayName = displayName.." ["..numAvailable.."]"
            end
            
            if craftButtonText then
                craftButtonText:SetText(displayName)
            end
            
            if craftButtonCount then
                craftButtonCount:SetText("")
            end
            
            -- Selection highlight
            if selectedIndex == craftIndex and CraftHighlightFrame then
                CraftHighlightFrame:SetPoint("TOPLEFT", "Craft"..i, "TOPLEFT", 0, 0)
                CraftHighlightFrame:Show()
                if craftButtonText then
                    craftButtonText:SetVertexColor(1.0, 1.0, 1.0)
                end
                if craftButtonCount then
                    craftButtonCount:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        else
            craftButton:Hide()
        end
    end
end

-- ============================================================================
-- Shift+Click Item Insertion Hook
-- ============================================================================

local orig_HandleModifiedItemClick = HandleModifiedItemClick
function HandleModifiedItemClick(link)
    if not link then return end
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

-- Hook ChatEdit_InsertLink as fallback (CraftFrame reagents sometimes call this directly)
local orig_ChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text)
    if not text then return false end
    
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


