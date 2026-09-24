local addonName, SPF = ...
local settingsCategory

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
    settingsCategory = category
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
    
    -- Support link
    local supportFrame = CreateFrame("Frame", nil, optionsFrame)
    supportFrame:SetSize(450, 48)
    supportFrame.layoutIndex = GetLayoutIndex()
    supportFrame.topPadding = 16
    
    local supportLabel = supportFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    supportLabel:SetPoint("TOPLEFT", 0, 0)
    supportLabel:SetTextColor(0.6, 0.6, 0.6)
    supportLabel:SetText("|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t If you find this addon helpful, consider buying me a cup of tea on Donatello :)")
    
    local supportBox = CreateFrame("EditBox", nil, supportFrame, "InputBoxTemplate")
    supportBox:SetSize(220, 20)
    supportBox:SetPoint("TOPLEFT", supportLabel, "BOTTOMLEFT", 6, -6)
    supportBox:SetAutoFocus(false)
    supportBox:SetFontObject(GameFontHighlightSmall)
    supportBox:SetText("https://donatello.to/Krev")
    supportBox:SetCursorPosition(0)
    
    supportBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    supportBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetText("https://donatello.to/Krev")
    end)
    supportBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    supportBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText("https://donatello.to/Krev")
            self:HighlightText()
        end
    end)
    supportBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click and press Ctrl+C to copy the link", 1, 1, 1)
        GameTooltip:Show()
    end)
    supportBox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    optionsFrame:Layout()
end)

-- Slash command to open settings
SLASH_SIMPLEPROFESSIONFILTER1 = "/spf"
SlashCmdList["SIMPLEPROFESSIONFILTER"] = function()
    if settingsCategory then
        Settings.OpenToCategory(settingsCategory:GetID())
    end
end
