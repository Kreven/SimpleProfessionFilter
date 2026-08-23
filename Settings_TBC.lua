local addonName, SPF = ...

-- Default settings
local DEFAULTS = {
    insertWithoutFocus = true,
    insertWithoutFocusAlt = true,
}

-- Initialize saved variables and create settings panel
EventUtil.ContinueOnAddOnLoaded(addonName, function()
    SimpleProfessionFilterDB_TBC = SimpleProfessionFilterDB_TBC or {}
    
    -- Apply defaults for missing values
    for k, v in pairs(DEFAULTS) do
        if SimpleProfessionFilterDB_TBC[k] == nil then
            SimpleProfessionFilterDB_TBC[k] = v
        end
    end
    
    -- Create options panel using Settings API
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
    
    -- Function to create a checkbox with title and sub-text
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
        cb.HoverBackground = nil
        cb:SetChecked(SimpleProfessionFilterDB_TBC[dbKey])
        cb:SetScript("OnClick", function(self)
            SimpleProfessionFilterDB_TBC[dbKey] = self:GetChecked()
        end)
        return cb
    end
    
    -- Setting: Insert without focus
    CreateCheckbox(
        "Shift+Click insert without focus",
        "Automatically insert item name into the search box even if it's not focused",
        "insertWithoutFocus"
    )
    
    -- Setting: Insert without focus (Alt)
    CreateCheckbox(
        "Shift+Alt+Click insert without focus",
        "Automatically insert item name using Shift+Alt+Click, ignoring the above setting",
        "insertWithoutFocusAlt"
    )
    
    optionsFrame:Layout()
end)

-- Slash command to open settings
SLASH_SIMPLEPROFESSIONFILTER1 = "/spf"
SlashCmdList["SIMPLEPROFESSIONFILTER"] = function()
    Settings.OpenToCategory("SimpleProfessionFilter")
end
