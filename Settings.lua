local addonName, SPF = ...

-- Default settings
local DEFAULTS = {
    insertWithoutFocus = true,
    rememberFilters = false,
}

-- ============================================================================
-- Interface Options Settings
-- ============================================================================

function SPF:RegisterSettings()
    local optionsFrame = CreateFrame("Frame", nil, nil, "VerticalLayoutFrame")
    optionsFrame.spacing = 4
    
    local categoryName = "|TInterface/Addons/SimpleProfessionFilter/Art/Icon:20:20:0:-7|t Simple Profession Filter"
    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsFrame, categoryName)
    category.ID = "SimpleProfessionFilter"
    Settings.RegisterAddOnCategory(category)
    
    local layoutIndex = 0
    local function GetLayoutIndex()
        layoutIndex = layoutIndex + 1
        return layoutIndex
    end
    
    -- Header
    local Header = CreateFrame("Frame", nil, optionsFrame)
    Header:SetSize(150, 50)
    local headerIcon = Header:CreateTexture(nil, "ARTWORK")
    headerIcon:SetTexture("Interface/Addons/SimpleProfessionFilter/Art/Icon")
    headerIcon:SetSize(26, 26)
    headerIcon:SetPoint("TOPLEFT", 0, -10)
    
    local headerText = Header:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    headerText:SetPoint("LEFT", headerIcon, "RIGHT", 6, 0)
    headerText:SetText("Simple Profession Filter")
    
    local divider = Header:CreateTexture(nil, "ARTWORK")
    divider:SetAtlas("Options_HorizontalDivider", true)
    divider:SetPoint("BOTTOMLEFT", -50)
    Header.layoutIndex = GetLayoutIndex()
    Header.bottomPadding = 10

    -- Helper to create styled checkboxes
    local function CreateCheckbox(label, subText, dbKey)
        local cb = CreateFrame("CheckButton", nil, optionsFrame, "SettingsCheckBoxTemplate")
        cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        cb.text:SetText(label)
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 6)
        
        local st = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        st:SetText(subText)
        st:SetPoint("TOPLEFT", cb.text, "BOTTOMLEFT", 0, -2)
        st:SetTextColor(0.6, 0.6, 0.6)
        
        cb:SetSize(21, 20)
        cb.layoutIndex = GetLayoutIndex()
        cb.bottomPadding = 12
        cb:SetHitRectInsets(0, -cb.text:GetWidth(), 0, -10)
        cb:SetChecked(SimpleProfessionFilterDB[dbKey])
        cb:SetScript("OnClick", function(self)
            SimpleProfessionFilterDB[dbKey] = self:GetChecked()
        end)
        return cb
    end

    -- Setting: Insert without focus
    CreateCheckbox(
        "Shift+Click insert without focus",
        "Automatically insert item name into the search box even if it's not focused (frame must be open)",
        "insertWithoutFocus"
    )
    
    -- Setting: Remember active filters
    CreateCheckbox(
        "Remember active filters",
        "Keep your search text and checkbox selections when closing the window or across sessions",
        "rememberFilters"
    )

    optionsFrame:Layout()
end

-- Initialize saved variables and create settings panel
EventUtil.ContinueOnAddOnLoaded(addonName, function()
    SimpleProfessionFilterDB = SimpleProfessionFilterDB or {}
    for k, v in pairs(DEFAULTS) do
        if SimpleProfessionFilterDB[k] == nil then
            SimpleProfessionFilterDB[k] = v
        end
    end
    
    -- Initialize state from DB if remembering
    SimpleProfessionFilterDB.TradeSkillState = SimpleProfessionFilterDB.TradeSkillState or {}
    SimpleProfessionFilterDB.CraftState = SimpleProfessionFilterDB.CraftState or {}
    
    -- Merge current state with DB
    for k, v in pairs(SPF.TradeSkillState) do
        if SimpleProfessionFilterDB.TradeSkillState[k] == nil then
            SimpleProfessionFilterDB.TradeSkillState[k] = v
        end
    end
    for k, v in pairs(SPF.CraftState) do
        if SimpleProfessionFilterDB.CraftState[k] == nil then
            SimpleProfessionFilterDB.CraftState[k] = v
        end
    end
    
    -- Point local states to DB
    SPF.TradeSkillState = SimpleProfessionFilterDB.TradeSkillState
    SPF.CraftState = SimpleProfessionFilterDB.CraftState
    
    SPF:RegisterSettings()
end)

-- Slash command to open settings
_G["SLASH_SIMPLEPROFESSIONFILTER1"] = "/spf"
SlashCmdList["SIMPLEPROFESSIONFILTER"] = function()
    Settings.OpenToCategory("SimpleProfessionFilter")
end
