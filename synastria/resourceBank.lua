--[[
================================================================================
 Project:       qtUITweaks
 File:          resourceBank.lua
 License:       MIT

 Description:
   Enhances the Resource Bank addon UI by adding item icons to bank entries
   and enabling mouse wheel scrolling. Provides visual item identification
   and improved tooltips for better user experience.

 Usage:
   Load this file as part of qtUITweaks addon. The enhancements will
   automatically apply when the RBankFrame is opened.

 Notes:
   - Icons are positioned to the left of each bank entry
   - Tooltips show full item information on hover
================================================================================
]]
local ICON_SIZE = 18
local maxButtons = 100

local function StyleButton(btn)
    if btn.ItemId then
        local iconTexture = select(10, GetItemInfo(btn.ItemId))

        if iconTexture then
            -- Check if our custom icon texture exists on this button yet.
            if not btn.myIcon then
                -- If it's the first time, create it.
                btn.myIcon = btn:CreateTexture(nil, "ARTWORK")
                btn.myIcon:SetSize(ICON_SIZE, ICON_SIZE)
                btn.myIcon:SetPoint("LEFT", btn, "LEFT", 4, 0)
            end

            btn.myIcon:SetTexture(iconTexture)
            btn.myIcon:Show()
        elseif btn.myIcon then
            btn.myIcon:Hide()
        end

        -- Only hook tooltip once
        if not btn._tooltipHooked then
            btn:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local _, itemLink = GetItemInfo(self.ItemId)
                if itemLink then
                    GameTooltip:SetHyperlink(itemLink)
                else
                    GameTooltip:AddLine(self.ItemName or "Unknown Item", 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            btn._tooltipHooked = true
        end
    elseif btn.myIcon then
        -- Hide icon if no ItemId
        btn.myIcon:Hide()
    end
end

---
-- Main setup frame: Hooks everything together.
---
local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(self)
    local bankFrame = _G["RBankFrame"]
    if not bankFrame then return end

    -- Hook every potential item line's OnShow event.
    for i = 1, maxButtons do
        local btn = _G["RBankFrame-ILine-" .. i]
        if btn and not btn._styleHooked then
            btn:HookScript("OnShow", StyleButton)
            btn._styleHooked = true
        end
    end

    -- Function to refresh all visible buttons
    local function RefreshAllButtons()
        for i = 1, maxButtons do
            local btn = _G["RBankFrame-ILine-" .. i]
            if btn and btn:IsShown() then
                StyleButton(btn)
            end
        end
    end

    bankFrame:HookScript("OnShow", RefreshAllButtons)

    local searchBox = _G["RBankFrame-Search"]
    if searchBox and not searchBox._searchHooked then
        searchBox:HookScript("OnTextChanged", RefreshAllButtons)
        searchBox._searchHooked = true
    end

    local filterButton = _G["RBankFrame-FilterButton"] or _G["RBankFrameFilterButton"]
    if filterButton and not filterButton._filterHooked then
        filterButton:HookScript("OnClick", RefreshAllButtons)
        filterButton._filterHooked = true
    end

    local scrollBar = _G["RBankFrame-Slider1"] or _G["RBankFrame-Scrollable1ScrollBar"]
    if scrollBar and not scrollBar._scrollHooked then
        scrollBar:HookScript("OnValueChanged", RefreshAllButtons)
        scrollBar._scrollHooked = true
    end

    local parent = _G["RBankFrame-Scrollable1"]
    if parent and not parent._wheelOverlay then
        local overlay = CreateFrame("Frame", nil, parent)
        overlay:SetAllPoints(true)
        overlay:EnableMouseWheel(true)

        overlay:SetScript("OnMouseWheel", function(_, delta)
            if not scrollBar then return end

            local current = scrollBar:GetValue()
            local step = 20

            if delta > 0 then
                scrollBar:SetValue(current - step)
            else
                scrollBar:SetValue(current + step)
            end
        end)
        parent._wheelOverlay = overlay
    end

    self:SetScript("OnUpdate", nil)
end)
