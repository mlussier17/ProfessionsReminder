local addonName, PR = ...

PR.UI = {}

-- Create main frame
local f = CreateFrame("Frame", "ProfessionsReminderFrame", UIParent, "BasicFrameTemplate")
PR.UI.MainFrame = f
f:SetSize(1100, 520)
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
contentFrame:SetSize(1080, 100)
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

local function GetSortState()
    local field = PR.DB:GetOption("sortField") or "name"
    local asc = PR.DB:GetOption("sortAsc")
    if asc == nil then asc = true end
    return field, asc
end

local function SetSortState(field)
    local currentField, asc = GetSortState()
    if currentField == field then
        asc = not asc
    else
        asc = true
    end
    PR.DB:SetOption("sortField", field)
    PR.DB:SetOption("sortAsc", asc)
    if PR.UI.RefreshDisplay then
        PR.UI:RefreshDisplay()
    end
end

local function FormatProfessionCell(profName, profData)
    if not profName or not profData then
        return "-"
    end
    local moxie = profData.moxie or 0
    local treasures = profData.treasures or 0
    local tool = PR.IsEpicToolEquipped(profName) and "T" or "-"
    local accCount = #PR.GetEpicAccessoriesEquipped(profName)
    return string.format("%s %d/%d %s/%d", profName, moxie, treasures, tool, accCount)
end

-- Display all characters
function PR.UI:RefreshDisplay()
    -- Clear existing rows
    for i, row in ipairs(contentFrame.rows or {}) do
        row:Hide()
        row:ClearAllPoints()
    end
    contentFrame.rows = {}

    local sortField, sortAsc = GetSortState()
    local characters = PR.DB:GetAllCharacters()
    local currentKey = PR.DB:GetCharacterKey()
    local rows = {}
    for charKey, charData in pairs(characters) do
        table.insert(rows, { key = charKey, data = charData })
    end
    local yOffset = 0

    local function compareValues(a, b)
        if a == b then return false end
        if a == nil then return false end
        if b == nil then return true end
        if type(a) == "string" then
            return string.lower(a) < string.lower(b)
        end
        return a < b
    end

    local function getProfNameAtIndex(charData, index)
        local profNames = {}
        for profName in pairs(charData.professions or {}) do
            table.insert(profNames, profName)
        end
        table.sort(profNames)
        return profNames[index]
    end

    table.sort(rows, function(a, b)
        if a.key == currentKey then return true end
        if b.key == currentKey then return false end

        local aValue, bValue
        if sortField == "name" then
            aValue = a.data.name
            bValue = b.data.name
        elseif sortField == "shards" then
            aValue = a.data.shards or 0
            bValue = b.data.shards or 0
        elseif sortField == "remaining" then
            aValue = PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX - (a.data.shards or 0)
            bValue = PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX - (b.data.shards or 0)
        elseif sortField == "abundance" then
            aValue = a.data.abundance or 0
            bValue = b.data.abundance or 0
        elseif sortField == "vitality" then
            aValue = a.data.vitality or 0
            bValue = b.data.vitality or 0
        elseif sortField == "prof1" then
            aValue = getProfNameAtIndex(a.data, 1)
            bValue = getProfNameAtIndex(b.data, 1)
        elseif sortField == "prof2" then
            aValue = getProfNameAtIndex(a.data, 2)
            bValue = getProfNameAtIndex(b.data, 2)
        end

        if aValue ~= bValue then
            if sortAsc then
                return compareValues(aValue, bValue)
            else
                return compareValues(bValue, aValue)
            end
        end
        return compareValues(a.data.name, b.data.name)
    end)

    local headerRow = CreateFrame("Frame", nil, contentFrame)
    headerRow:SetSize(680, 20)
    headerRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    local bg = headerRow:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.2, 0.8)

    local columns = {
        {id = "name", label = "Character", width = 110},
        {id = "realm", label = "Realm", width = 90},
        {id = "shards", label = "Shards", width = 60},
        {id = "remaining", label = "Remain", width = 60},
        {id = "abundance", label = "Abun", width = 60},
        {id = "vitality", label = "Vit", width = 60},
        {id = "prof1_name", label = "Profession", width = 120},
        {id = "prof1_moxie", label = "Moxie", width = 50},
        {id = "prof1_treasures", label = "Treasures", width = 70},
        {id = "prof1_tool", label = "Tool", width = 50},
        {id = "prof1_acc", label = "Acc", width = 50},
        {id = "prof1_dm", label = "DM", width = 50},
        {id = "prof1_treatise", label = "Treatise", width = 70},
        -- {id = "prof2_name", label = "Prof 2", width = 80},
        -- {id = "prof2_moxie", label = "Moxie", width = 50},
        -- {id = "prof2_treasures", label = "Treas", width = 50},
        -- {id = "prof2_tool", label = "Tool", width = 50},
        -- {id = "prof2_acc", label = "Acc", width = 50},
        -- {id = "prof2_dm", label = "DM", width = 50},
    }

    local xOffset = 10
    for _, col in ipairs(columns) do
        local btn = CreateFrame("Button", nil, headerRow)
        btn:SetSize(col.width, 20)
        btn:SetPoint("TOPLEFT", headerRow, "TOPLEFT", xOffset, 0)
        btn:SetScript("OnClick", function()
            SetSortState(col.id)
        end)
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
        txt:SetText(col.label)
        table.insert(contentFrame.rows, btn)
        xOffset = xOffset + col.width + 5
    end
    table.insert(contentFrame.rows, headerRow)
    yOffset = yOffset - 22

    for _, rowInfo in ipairs(rows) do
        local charData = rowInfo.data
        
        local profNames = {}
        for profName in pairs(charData.professions or {}) do
            table.insert(profNames, profName)
        end
        table.sort(profNames)

        for profIndex = 1, 2 do
            local profName = profNames[profIndex]
            local charRow = CreateFrame("Frame", nil, contentFrame)
            charRow:SetSize(1080, 18)
            charRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)

            local bg = charRow:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.08, 0.08, 0.12, 0.5)

            -- Only show character info on first profession row
            if profIndex == 1 then
                local charLabel = charData.name or "Unknown"
                local classColor = RAID_CLASS_COLORS[charData.class] or {r=1, g=1, b=1}
                local nameText = CreateText(charRow, charLabel, nil, true, 110)
                nameText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 10, -2)
                nameText:SetJustifyH("LEFT")
                nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

                local realmText = CreateText(charRow, charData.realm or "Unknown", nil, nil, 90)
                realmText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 125, -2)
                realmText:SetJustifyH("LEFT")

                local shardCount = charData.shards or 0
                local shardRemaining = math.max(0, PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX - shardCount)
                local shardColor = "|c82828200"
                if (shardCount or 0) >= 8 then
                    shardColor = "|cff00ff00"
                end
                local shardsText = CreateText(charRow, shardColor .. tostring(shardCount) .. "|r", nil, nil, 60)
                shardsText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 220, -2)
                shardsText:SetJustifyH("CENTER")

                local shardRemainingColor = "|cff00ff00"
                if (shardRemaining or 0) < 1 then
                    shardRemainingColor = "|c82828200"
                end
                local remainText = CreateText(charRow, shardRemainingColor .. tostring(shardRemaining) .. "|r", nil, nil, 60)
                remainText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 285, -2)
                remainText:SetJustifyH("CENTER")

                local abundanceColor = "|c82828200"
                if (charData.abundance or 0) >= 800 then
                    abundanceColor = "|cff00ff00"
                end
                local abundanceText = CreateText(charRow, abundanceColor .. tostring(charData.abundance or 0) .. "|r", nil, nil, 60)
                abundanceText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 350, -2)
                abundanceText:SetJustifyH("CENTER")

                local vitalityColor = "|c82828200"
                if (charData.vitality or 0) >= 20 then
                    vitalityColor = "|cff00ff00"
                end
                local vitalityText = CreateText(charRow, vitalityColor .. tostring(charData.vitality or 0) .. "|r", nil, nil, 60)
                vitalityText:SetPoint("TOPLEFT", charRow, "TOPLEFT", 415, -2)
                vitalityText:SetJustifyH("CENTER")
            end

            -- Profession columns
            local xPos = 500
            local profData = charData.professions and charData.professions[profName]
            
            -- Profession name
            local profText = CreateText(charRow, profName or "-", nil, nil, 80)
            profText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            profText:SetJustifyH("LEFT")
            if profName then
                local profInfo = PR.Constants.GetProfession(profName)
                if profInfo and profInfo.color then
                    profText:SetTextColor(profInfo.color[1], profInfo.color[2], profInfo.color[3])
                end
            end
            xPos = xPos + 85
            
            -- Moxie
            local moxieColor = "|c82828200"
            if (profData.moxie or 0) >= 600 then
                moxieColor = "|cff00ff00"
            end
            local moxieText = CreateText(charRow, moxieColor .. (profData and tostring(profData.moxie or 0) or "-") .. "|r", nil, nil, 50)
            moxieText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            moxieText:SetJustifyH("CENTER")
            xPos = xPos + 55
            
            -- Treasures
            local treasuresColor = "|c82828200"
            if (profData.treasures or 0) >= 2 then
                treasuresColor = "|cff00ff00"
            end
            local treasuresText = CreateText(charRow, treasuresColor .. (profData and tostring(profData.treasures or 0) or "-") .. "|r", nil, nil, 50)
            treasuresText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            treasuresText:SetJustifyH("CENTER")
            xPos = xPos + 55
            
            -- Epic Tool
            local toolEquipped = profName and PR.IsEpicToolEquipped(profName)
            local toolColor = "|c82828200"
            if toolEquipped then
                toolColor = "|cff00ff00"
            end
            local toolText = CreateText(charRow, toolColor .. (toolEquipped and "Yes" or "No") .. "|r", nil, nil, 50)
            toolText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            toolText:SetJustifyH("CENTER")
            xPos = xPos + 55
            
            -- Epic Accessories
            local accCount = profName and #PR.GetEpicAccessoriesEquipped(profName) or 0
            local accColor = "|c82828200"
            if accCount >= 2 then
                accColor = "|cff00ff00"
            end
            local accText = CreateText(charRow, accColor .. tostring(accCount) .. "|r", nil, nil, 50)
            accText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            accText:SetJustifyH("CENTER")
            xPos = xPos + 55
            
            -- Darkmoon Faire (quest completion status)
            local dmQuest = profName and PR.Constants.GetProfession(profName) and PR.Constants.GetProfession(profName).darkmoon
            local dmCompleted = dmQuest and C_QuestLog.IsQuestFlaggedCompleted(dmQuest.questId) and "Done" or "Open"
            local dmText = CreateText(charRow, dmCompleted, nil, nil, 50)
            dmText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            dmText:SetJustifyH("CENTER")
            xPos = xPos + 55

            -- Treatise (quest completion status)
            local treatiseColor = "|c82828200"
            if (profData.treatise or 0) >= 1 then
                treatiseColor = "|cff00ff00"
            end
            local treatiseText = CreateText(charRow, treatiseColor .. (profData and tostring(profData.treatise or 0) or "-") .. "|r", nil, nil, 50)
            treatiseText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
            treatiseText:SetJustifyH("CENTER")

            table.insert(contentFrame.rows, charRow)


            yOffset = yOffset - 20
        end
    end

    contentFrame:SetHeight(-yOffset)
    scrollFrame:UpdateScrollChildRect()
end

-- Show main frame and refresh
f:SetScript("OnShow", function(self)
    PR.UI:RefreshDisplay()
end)