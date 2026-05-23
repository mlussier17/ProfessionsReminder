local addonName, PR = ...

PR.UI = {}

local frameWidth = 1200
local scrollFrameWidth = frameWidth - 40

-- Create main frame
local f = CreateFrame("Frame", "ProfessionsReminderFrame", UIParent, "BasicFrameTemplate")
PR.UI.MainFrame = f
f:SetSize(frameWidth, 520)
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
contentFrame:SetSize(scrollFrameWidth, 100)
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

local columnDefinitions = {
    {id = "name", label = "Character", width = 110},
    {id = "realm", label = "Realm", width = 90},
    {id = "shards", label = "Weekly Shards", width = 90},
    {id = "remaining", label = "Shards Owned", width = 90},
    {id = "abundance", label = "Unalloyed Abun", width = 90},
    {id = "vitality", label = "Fused Vit", width = 60},
    {id = "prof1_name", label = "Profession", width = 120},
    {id = "prof1_moxie", label = "Moxie", width = 50},
    {id = "prof1_treasures", label = "Treasures", width = 70},
    {id = "prof1_tool", label = "Tool", width = 50},
    {id = "prof1_acc", label = "Accessories", width = 50},
    {id = "prof1_treatise", label = "Treatise", width = 70},
    {id = "prof1_concentration", label = "Concentration", width = 90},
    {id = "prof1_dm", label = "Darkmoon", width = 50},
}

local function GetVisibleColumns()
    local visible = PR.DB:GetOption("visibleColumns")
    if type(visible) ~= "table" then
        visible = {}
    end
    local changed = false
    for _, col in ipairs(columnDefinitions) do
        if visible[col.id] == nil then
            visible[col.id] = true
            changed = true
        end
    end
    if changed then
        PR.DB:SetOption("visibleColumns", visible)
    end
    return visible
end

local function GetEffectiveVisibleColumns()
    local visible = GetVisibleColumns()
    if type(PR.IsDarkmoonFaireActive) == "function" and not PR.IsDarkmoonFaireActive() then
        -- visible["prof1_dm"] = false
    end
    return visible
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
    local tool = profData.toolEquipped and "T" or "-"
    local accCount = profData.accessories or 0
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

    local function getProfessionSortValue(charData, index, field)
        local profName = getProfNameAtIndex(charData, index)
        local profData = charData.professions and profName and charData.professions[profName]
        local profInfo = PR.Constants.GetProfession(profName)

        if field == "name" then
            return charData.name
        elseif field == "shards" then
            return charData.shards or 0
        elseif field == "remaining" then
            return charData.shardsOwned or 0
        elseif field == "abundance" then
            return charData.abundance or 0
        elseif field == "vitality" then
            return charData.vitality or 0
        elseif field == "prof1_name" then
            return profName
        elseif field == "prof1_moxie" then
            return profData and profData.moxie or 0
        elseif field == "prof1_treasures" then
            return profData and profData.treasures or 0
        elseif field == "prof1_tool" then
            return profData and (profData.toolEquipped and 1 or 0) or 0
        elseif field == "prof1_acc" then
            return profData and profData.accessories or 0
        elseif field == "prof1_dm" then
            local dmQuest = profInfo and profInfo.darkmoon
            return (dmQuest and C_QuestLog.IsQuestFlaggedCompleted(dmQuest.questId)) and 1 or 0
        elseif field == "prof1_treatise" then
            return profData and profData.treatise or 0
        elseif field == "prof1_concentration" then
            if profData and profData.concentration then
                return PR.EstimateConcentration(profData.concentration, charData.lastUpdated)
            end
            return 0
        elseif field == "prof1" then
            return profName
        elseif field == "prof2" then
            return getProfNameAtIndex(charData, 2)
        end
        return nil
    end

    table.sort(rows, function(a, b)
        local aValue = getProfessionSortValue(a.data, 1, sortField)
        local bValue = getProfessionSortValue(b.data, 1, sortField)

        if aValue ~= bValue then
            if sortAsc then
                return compareValues(aValue, bValue)
            else
                return compareValues(bValue, aValue)
            end
        end
        return compareValues(a.data.name, b.data.name)
    end)

    local visibleColumns = GetEffectiveVisibleColumns()
    local headerRow = CreateFrame("Frame", nil, contentFrame)
    local headerWidth = 0
    for _, col in ipairs(columnDefinitions) do
        if visibleColumns[col.id] then
            headerWidth = headerWidth + col.width + 5
        end
    end
    headerWidth = math.max(1, headerWidth - 5)
    headerRow:SetSize(headerWidth + 20, 20)
    headerRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    local bg = headerRow:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.2, 0.8)

    local xOffset = 10
    for _, col in ipairs(columnDefinitions) do
        if visibleColumns[col.id] then
            local btn = CreateFrame("Button", nil, headerRow)
            btn:SetSize(col.width, 20)
            btn:SetPoint("TOPLEFT", headerRow, "TOPLEFT", xOffset, 0)
            btn:SetScript("OnClick", function()
                SetSortState(col.id)
            end)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            txt:SetText(col.label)
            if col.id == "name" or col.id == "realm" or col.id == "prof1_name" then
                txt:SetJustifyH("LEFT")
                txt:SetPoint("LEFT", btn, "LEFT", 6, 0)
            else
                txt:SetJustifyH("CENTER")
                txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
            end
            table.insert(contentFrame.rows, btn)
            xOffset = xOffset + col.width + 5
        end
    end
    table.insert(contentFrame.rows, headerRow)
    yOffset = yOffset - 22

    local charIndex = 0
    for _, rowInfo in ipairs(rows) do
        charIndex = charIndex + 1
        local charData = rowInfo.data
        
        local profNames = {}
        for profName in pairs(charData.professions or {}) do
            table.insert(profNames, profName)
        end
        table.sort(profNames)

        for profIndex = 1, 2 do
            local profName = profNames[profIndex]
            local charRow = CreateFrame("Frame", nil, contentFrame)
            charRow:SetSize(scrollFrameWidth, 18)
            charRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)

            local bg = charRow:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            if (charIndex % 2) == 0 then
                bg:SetColorTexture(0.08, 0.08, 0.12, 0.2)
            else
                bg:SetColorTexture(0.12, 0.12, 0.16, 0.7)
            end

            local xPos = 10
            local profData = charData.professions and charData.professions[profName]
            local profInfo = profName and PR.Constants.GetProfession(profName)
            local specialtyColor = profInfo and profInfo.color

            local function addCell(text, width, justify)
                local cell = CreateText(charRow, text, nil, nil, width)
                cell:SetPoint("LEFT", charRow, "LEFT", xPos, -2)
                cell:SetJustifyH(justify or "CENTER")
                xPos = xPos + width + 5
            end

            for _, col in ipairs(columnDefinitions) do
                if visibleColumns[col.id] then
                    if col.id == "name" then
                        if profIndex == 1 then
                            local charLabel = charData.name or "Unknown"
                            local classColor = RAID_CLASS_COLORS[charData.class] or {r = 1, g = 1, b = 1}
                            local nameText = CreateText(charRow, charLabel, nil, true, col.width)
                            nameText:SetPoint("LEFT", charRow, "LEFT", xPos, -2)
                            nameText:SetJustifyH("LEFT")
                            nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
                        end
                        xPos = xPos + col.width + 5
                    elseif col.id == "realm" then
                        if profIndex == 1 then
                            addCell(charData.realm or "Unknown", col.width, "LEFT")
                        else
                            xPos = xPos + col.width + 5
                        end
                    elseif col.id == "shards" then
                        if profIndex == 1 then
                            local shardCount = charData.shards or 0
                            local shardColor = shardCount >= (PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX or 8) and "|cff00ff00" or "|c82828200"
                            addCell(shardColor .. tostring(shardCount) .. "/" ..(PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX) .. "|r", col.width)
                        else
                            xPos = xPos + col.width + 5
                        end
                    elseif col.id == "remaining" then
                        if profIndex == 1 then
                            local owned = charData.shardsOwned or 0
                            local ownedColor = owned > 0 and "|cff00ff00" or "|c82828200"
                            addCell(ownedColor .. tostring(owned) .. "/" ..(PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX) .. "|r", col.width)
                        else
                            xPos = xPos + col.width + 5
                        end
                    elseif col.id == "abundance" then
                        if profIndex == 1 then
                            local abundanceColor = (charData.abundance or 0) >= 800 and "|cff00ff00" or "|c82828200"
                            addCell(abundanceColor .. tostring(charData.abundance or 0) .. "|r", col.width)
                        else
                            xPos = xPos + col.width + 5
                        end
                    elseif col.id == "vitality" then
                        if profIndex == 1 then
                            local vitalityColor = (charData.vitality or 0) >= 20 and "|cff00ff00" or "|c82828200"
                            addCell(vitalityColor .. tostring(charData.vitality or 0) .. "|r", col.width)
                        else
                            xPos = xPos + col.width + 5
                        end
                    elseif col.id == "prof1_name" then
                        local label = profName or "-"
                        local profText = CreateText(charRow, label, nil, nil, col.width)
                        profText:SetPoint("TOPLEFT", charRow, "TOPLEFT", xPos, -2)
                        profText:SetJustifyH("LEFT")
                        if profName and specialtyColor then
                            profText:SetTextColor(specialtyColor[1], specialtyColor[2], specialtyColor[3])
                        end
                        xPos = xPos + col.width + 5
                    elseif col.id == "prof1_moxie" then
                        local moxieColor = (profData and profData.moxie or 0) >= 600 and "|cff00ff00" or "|c82828200"
                        addCell(moxieColor .. tostring(profData and profData.moxie or 0) .. "|r", col.width)
                    elseif col.id == "prof1_treasures" then
                        local treasuresColor = (profData and profData.treasures or 0) >= 2 and "|cff00ff00" or "|c82828200"
                        addCell(treasuresColor .. tostring(profData and profData.treasures or 0) .. "/" .. (PR.Constants.TREASURES_MAX) .. "|r", col.width)
                    elseif col.id == "prof1_tool" then
                        local toolEquipped = profData and profData.toolEquipped
                        local toolColor = toolEquipped and "|cff00ff00" or "|c82828200"
                        addCell(toolColor .. (toolEquipped and "Yes" or "No") .. "|r", col.width)
                    elseif col.id == "prof1_acc" then
                        local accCount = profData and profData.accessories or 0
                        local accColor = accCount >= 2 and "|cff00ff00" or "|c82828200"
                        addCell(accColor .. tostring(accCount) .. "|r", col.width)cal
                    elseif col.id == "prof1_dm" then
                        local dmQuest = profInfo and profInfo.darkmoon
                        if PR.IsDarkmoonFaireActive() then
                            local dmColor = (dmQuest and C_QuestLog.IsQuestFlaggedCompleted(dmQuest.questId)) and "|cff00ff00" or "|c82828200"
                            addCell(dmColor .. (dmQuest and C_QuestLog.IsQuestFlaggedCompleted(dmQuest.questId) and "Done" or "Open") .. "|r", col.width)
                        else
                            addCell("|c82828200Closed|r", col.width)
                        end
                    elseif col.id == "prof1_treatise" then
                        local treatiseColor = (profData and profData.treatise or 0) >= 1 and "|cff00ff00" or "|c82828200"
                        addCell(treatiseColor .. tostring(profData and profData.treatise or 0) .. "/" .. (PR.Constants.TREATISE_MAX) .. "|r", col.width)
                    elseif col.id == "prof1_concentration" then
                        local concentrationValue = profData and profData.concentration or 0
                        if profData and profData.concentration then
                            concentrationValue = PR.EstimateConcentration(profData.concentration, charData.lastUpdated)
                        end
                        local concentrationColor = (concentrationValue and concentrationValue > 900) and "|cff00ff00" or "|c82828200"
                        addCell(concentrationColor .. tostring(concentrationValue) .. "|r", col.width)
                    end
                end
            end

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