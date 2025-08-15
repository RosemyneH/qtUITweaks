--[[
================================================================================
 Project:       qtUITweaks
 File:          itemDB.lua
 License:       MIT

 Description:
   Enhances the LootDB addon UI by adding item icons to database entries,
   enabling mouse wheel scrolling, and improving search functionality.
   Provides visual item identification with tooltips and shift-click linking.

 Usage:
   Load this file as part of qtUITweaks addon. The enhancements will
   automatically apply when the LootDBFrame is opened.

 Notes:
   - Icons are positioned to the left of each database entry
   - Tooltips show full item information on hover
   - ESC key clears search box focus
   - Uses GetItemInfoCustom for automatic caching
================================================================================
]]
local ICON_SIZE = 18
local maxButtons = 100

local function StyleButton(btn)
    if btn.ItemId then
        local iconTexture = select(10, GetItemInfoCustom(btn.ItemId))

        if iconTexture then
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

        -- Only hook tooltip and click events once
        if not btn._tooltipHooked then
            btn:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local _, itemLink = GetItemInfoCustom(self.ItemId)
                if itemLink then
                    GameTooltip:SetHyperlink(itemLink)
                else
                    GameTooltip:AddLine(self.ItemName or "Unknown Item", 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            
            btn:HookScript("OnLeave", function() 
                GameTooltip:Hide() 
            end)
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
    local lootFrame = _G["LootDBFrame"]
    if not lootFrame then return end

    -- Hook every potential item line's OnShow event.
    for i = 1, maxButtons do
        local btn = _G["LootDBFrame-ILine-" .. i]
        if btn and not btn._styleHooked then
            btn:HookScript("OnShow", StyleButton)
            btn._styleHooked = true
        end
    end

    -- Function to refresh all visible buttons
    local function RefreshAllButtons()
        for i = 1, maxButtons do
            local btn = _G["LootDBFrame-ILine-" .. i]
            if btn and btn:IsShown() then
                StyleButton(btn)
            end
        end
    end

    lootFrame:HookScript("OnShow", RefreshAllButtons)

    local searchBox = _G["LootDBFrame-Search"]
    if searchBox and not searchBox._searchHooked then
        searchBox:HookScript("OnTextChanged", RefreshAllButtons)
        
        -- Fix enter key override - allow normal typing when hovering
        searchBox:HookScript("OnEnter", function(self)
            self:EnableKeyboard(true)
        end)
        
        searchBox:HookScript("OnLeave", function(self)
            self:EnableKeyboard(false)
        end)
        
        searchBox:HookScript("OnKeyDown", function(self, key)
	    if key == "ESCAPE" then
		self._escPressed = true
		self:ClearFocus()
		self:EnableKeyboard(false)
	    end
	end)

	-- Prevent refocus after ESC
	searchBox:HookScript("OnEditFocusGained", function(self)
	    if self._escPressed then
		self._escPressed = false
		self:ClearFocus()
		return
	    end
	    self:EnableKeyboard(true)
	end)
        
        -- Disable keyboard when losing focus
        searchBox:HookScript("OnEditFocusLost", function(self)
            self:EnableKeyboard(false)
        end)
        
        searchBox:HookScript("OnKeyUp", function(self, key)
	    if key == "ESCAPE" then
		self:ClearFocus()
		self:EnableKeyboard(false)
	    end
	end)
        searchBox._searchHooked = true
    end

    local filterButton = _G["LootDBFrame-FilterButton"] or _G["LootDBFrameFilterButton"]
    if filterButton and not filterButton._filterHooked then
        filterButton:HookScript("OnClick", RefreshAllButtons)
        filterButton._filterHooked = true
    end

    local scrollBar = _G["LootDBFrame-Slider1"] or _G["LootDBFrame-Scrollable1ScrollBar"]
    if scrollBar and not scrollBar._scrollHooked then
        scrollBar:HookScript("OnValueChanged", RefreshAllButtons)
        scrollBar._scrollHooked = true
    end

    local parent = _G["LootDBFrame-Scrollable1"]
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