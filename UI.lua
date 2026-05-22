local addonName, PR = ...

PR.UI = {}

-- Create main frame
local f = CreateFrame("Frame", "ProfessionsReminderFrame", UIParent, "BasicFrameTemplate")
PR.UI.MainFrame = f
f:SetSize(800, 600)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:SetFrameStrata("HIGH")
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()

-- Create title
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -6)
title:SetText("Professions Reminder")

-- Create scroll frame
local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

-- Create content frame for scroll
local contentFrame = CreateFrame("Frame")
contentFrame:SetSize(850, 100)
scrollFrame:SetScrollChild(contentFrame)

-- Header row
local function CreateText(parent, text, size, bold, width)
    local txt = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetText(text)
    if bold then
        txt:SetFontObject(GameFontBold)
    end
    txt:SetWidth(width or 100)
    txt:SetWordWrap(false)
    return txt
end

-- Display all characters
function PR.UI:RefreshDisplay()
    -- Clear existing rows
    for i, row in ipairs(contentFrame.rows or {}) do
        row:Hide()
        row:ClearAllPoints()
    end
    contentFrame.rows = {}
    
    local characters = PR.DB:GetAllCharacters()
    local yOffset = 0
    
    for charKey, charData in pairs(characters) do
        -- Character header row
        local charRow = CreateFrame("Frame", nil, contentFrame)
        charRow:SetSize(850, 25)
        charRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
        
        local bg = charRow:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.2, 0.5)
        
        local charName = charData.name or "Unknown"
        local charRealm = charData.realm or "Unknown"
        local nameText = CreateText(charRow, charName .. " - " .. charRealm, 12, true, 200)
        nameText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 10, -5)
        nameText:SetJustifyH("LEFT")
        
        local classColor = RAID_CLASS_COLORS[charData.class] or {r=1, g=1, b=1}
        nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
        
        table.insert(contentFrame.rows, charRow)
        yOffset = yOffset - 30
        
        -- Currencies row
        local currRow = CreateFrame("Frame", nil, contentFrame)
        currRow:SetSize(850, 20)
        currRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
        
        -- Shards (green if at max 8, orange if partial, gray if none)
        local shardsColor = "|cffffffff"
        if (charData.shards or 0) >= 8 then
            shardsColor = "|cff00ff00"
        elseif (charData.shards or 0) > 0 then
            shardsColor = "|cffffa500"
        else
            shardsColor = "|cFFFFFF00"
        end
        local shardsText = CreateText(currRow, shardsColor .. "Shards: " .. (charData.shards or 0) .. "/8|r")
        shardsText:SetPoint("TOPLEFT", currRow, "TOPLEFT", 20, -2)
        
        local abundanceText = CreateText(currRow, "Abundance: " .. (charData.abundance or 0), nil, nil, 180)
        abundanceText:SetPoint("TOPLEFT", currRow, "TOPLEFT", 200, -2)
        abundanceText:SetJustifyH("LEFT")
        abundanceText:SetJustifyV("TOP")
        
        local vitalityColor = "|cffffffff"
        if (charData.vitality or 0) > 20 then
            vitalityColor = "|cff00ff00"
        elseif (charData.vitality or 0) > 0 then
            vitalityColor = "|cffffa500"
        else
            vitalityColor = "|cFFFFFF00"
        end
        local vitalityText = CreateText(currRow, vitalityColor .. "Vitality: " .. (charData.vitality or 0) .. "|r", nil, nil, 140)
        vitalityText:SetPoint("TOPLEFT", currRow, "TOPLEFT", 380, -2)
        vitalityText:SetJustifyH("LEFT")
        vitalityText:SetJustifyV("TOP")
        
        table.insert(contentFrame.rows, currRow)
        yOffset = yOffset - 25
        
        -- Professions
        if charData.professions and next(charData.professions) then
            for profName, profData in pairs(charData.professions) do
                local profRow = CreateFrame("Frame", nil, contentFrame)
                profRow:SetSize(850, 20)
                profRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
                
                local profText = CreateText(profRow, profName, nil, nil, 120)
                profText:SetPoint("TOPLEFT", profRow, "TOPLEFT", 30, -2)
                profText:SetJustifyH("LEFT")
                profText:SetJustifyV("TOP")
                local profColor = PR.Constants.PROFESSION_COLORS[profName] or {1, 1, 1}
                profText:SetTextColor(profColor[1], profColor[2], profColor[3])

                local moxieColor = "|cFFFFFF00"
                if (profData.moxie or 0) > 600 then
                    moxieColor = "|cff00ff00"
                end
                local moxieText = CreateText(profRow, moxieColor .. "Moxie: " .. (profData.moxie or 0) .. "|r", nil, nil, 120)
                moxieText:SetPoint("TOPLEFT", profRow, "TOPLEFT", 150, -2)
                moxieText:SetJustifyH("LEFT")
                moxieText:SetJustifyV("TOP")
                
                local treasuresColor = "|cFFFFFF00"
                if (profData.treasures or 0) >= 2 then
                    treasuresColor = "|cff00ff00"
                end
                local treasureText = CreateText(profRow, treasuresColor .. "Treasures: " .. (profData.treasures or 0) .. "/2|r", nil, nil, 120)
                treasureText:SetPoint("TOPLEFT", profRow, "TOPLEFT", 280, -2)

                local epicText = CreateText(profRow, "|cffA335EE Epic tool|r", nil, nil, 120)
                epicText:SetPoint("TOPLEFT", profRow, "TOPLEFT", 420, -2)
                epicText:SetJustifyH("LEFT")

                local equippedTool = PR.IsEpicToolEquipped(profName)
                local equippedAccessories = PR.GetEpicAccessoriesEquipped(profName) or {}
                local accCount = #equippedAccessories
                -- show count on the label if accessories present
                if accCount == 2 then
                    epicText:SetText("|cffA335EE Epic tool|r |cffA335EE(" .. accCount .. ")|r")
                else
                    epicText:SetText("|cffA335EE Epic tool|r |c82828200(" .. accCount .. ")|r")
                end

                epicText:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Epic tool", 1, 0.5, 1)
                    if equippedTool then
                        local toolInfo = PR.Constants.EPIC_TOOLS[profName]
                        local equippedName = toolInfo and toolInfo.name or "Unknown"
                        GameTooltip:AddLine("Tool: " .. equippedName, 1, 1, 1)
                    else
                        GameTooltip:AddLine("Tool: (none)", 0.8, 0.8, 0.8)
                    end

                    if accCount > 0 then
                        GameTooltip:AddLine("Accessories:", 1, 1, 1)
                        for _, name in ipairs(equippedAccessories) do
                            GameTooltip:AddLine("- " .. name, 1, 1, 1)
                        end
                    else
                        GameTooltip:AddLine("Accessories: (none)", 0.8, 0.8, 0.8)
                    end
                    GameTooltip:Show()
                end)
                epicText:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                table.insert(contentFrame.rows, profRow)
                yOffset = yOffset - 25
            end
        else
            local noProfsText = CreateText(contentFrame, "No professions tracked")
            noProfsText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 30, yOffset)
            yOffset = yOffset - 25
        end
        
        yOffset = yOffset - 10 -- Spacing between characters
    end
    
    -- Update scroll frame content size
    contentFrame:SetHeight(-yOffset)
    scrollFrame:UpdateScrollChildRect()
end

-- Show main frame and refresh
f:SetScript("OnShow", function(self)
    PR.UI:RefreshDisplay()
end)