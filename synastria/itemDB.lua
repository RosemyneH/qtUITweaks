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