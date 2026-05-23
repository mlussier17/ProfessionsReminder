local addonName, PR = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("CHAT_MSG_CURRENCY")

local function UpdateCharacterProfessions()
    local data = PR.DB:GetCharacterData()
    data.professions = {}
    
    -- Get professions
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    
    for _, profIndex in pairs({prof1, prof2}) do
        if profIndex then
            local profName, profIcon, profRank, profMaxRank = GetProfessionInfo(profIndex)
            if profName then
                data.professions[profName] = {
                    rank = profRank,
                    maxRank = profMaxRank,
                    moxie = 0,
                    treasures = 0,
                    treatise = 0,
                    toolEquipped = false,
                    accessories = 0,
                    concentration = 0,
                }
                
                -- Count completed treasure map quests (use helper)
                local questCount = 0
                local profConst = PR.Constants.GetProfession(profName)
                local treasureList = (profConst and profConst.treasureMapQuests) or nil
                if treasureList then
                    for _, questID in pairs(treasureList) do
                        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                            questCount = questCount + 1
                        end
                    end
                end
                data.professions[profName].treasures = questCount

                local treatiseCount = 0
                local treatiseQuestId = (profConst and profConst.treatise.questId) or nil
                if treatiseQuestId then
                    if C_QuestLog.IsQuestFlaggedCompleted(treatiseQuestId) then
                        treatiseCount = 1
                    end
                end
                data.professions[profName].treatise = treatiseCount
            end
        end
    end
    
    PR.DB:SetCharacterData(data)
end

PR.IsEpicToolEquipped = function(profName)
    local profConst = PR.Constants.GetProfession(profName)
    local tool = profConst and profConst.epicTool
    if not tool or not tool.id then return false end
    for _, slotID in ipairs({20, 23}) do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID and tonumber(itemID) == tool.id then
            return true
        end
    end
    return false
end

-- Returns a list of equipped epic accessory names for a profession
PR.GetEpicAccessoriesEquipped = function(profName)
    local profConst = PR.Constants.GetProfession(profName)
    local accessories = profConst and profConst.epicAccessories
    if not accessories or type(accessories) ~= "table" then return {} end

    local equipped = {}
    local accessoryIds = {}
    for _, acc in ipairs(accessories) do
        accessoryIds[tonumber(acc.id)] = acc.name
    end

    for _, slotID in ipairs({21, 22, 24, 25}) do
        local itemID = GetInventoryItemID("player", slotID)
        if itemID and accessoryIds[tonumber(itemID)] then
            table.insert(equipped, accessoryIds[tonumber(itemID)])
        end
    end
    return equipped
end

local function FindCurrencyInfoByName(targetName)
    if not targetName then
        return nil
    end

    if type(C_CurrencyInfo.GetCurrencyListSize) == "function" and type(C_CurrencyInfo.GetCurrencyListInfo) == "function" then
        local lowerTarget = string.lower(targetName)
        local exactMatch
        local partialMatch
        for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)
            if info and info.name then
                local lowerName = string.lower(info.name)
                if lowerName == lowerTarget then
                    exactMatch = info
                    break
                elseif not partialMatch and string.find(lowerName, lowerTarget, 1, true) then
                    partialMatch = info
                end
            end
        end
        return exactMatch or partialMatch
    end

    return nil
end

local function GetCurrencyInfoAny(currencyID, currencyName)
    local info = nil
    if type(C_CurrencyInfo.GetCurrencyInfo) == "function" then
        info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    end
    if (not info or info.quantity == nil) and type(GetCurrencyInfo) == "function" then
        info = GetCurrencyInfo(currencyID)
    end
    if (not info or info.quantity == nil) and type(C_CurrencyInfo.GetCurrencyInfoByID) == "function" then
        info = C_CurrencyInfo.GetCurrencyInfoByID(currencyID)
    end
    if (not info or info.quantity == nil) and currencyName then
        info = FindCurrencyInfoByName(currencyName)
    end
    return info
end

function PR.EstimateConcentration(amount, lastUpdated)
    amount = tonumber(amount) or 0
    lastUpdated = tonumber(lastUpdated) or time()
    local elapsed = time() - lastUpdated
    if elapsed < 0 then
        elapsed = 0
    end
    local gained = math.floor(elapsed / 360)
    return math.min(1000, amount + gained)
end

local function GetFirstSundayOfMonth(timeStamp)
    local t = date("*t", timeStamp or time())
    local year = t.year
    local month = t.month
    local firstDay = time({ year = year, month = month, day = 1, hour = 0 })
    local weekday = tonumber(date("%w", firstDay)) or 0
    local daysUntilSunday = (7 - weekday) % 7
    return firstDay + (daysUntilSunday * 86400)
end

function PR.IsDarkmoonFaireActive()
    local now = time()
    local firstSunday = GetFirstSundayOfMonth(now)
    local endTime = firstSunday + (7 * 86400)
    return now >= firstSunday and now < endTime
end

local function ParseNumber(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "string" then
        local num = tonumber(value)
        if num then
            return num
        end
        local digits = string.match(value, "(%d+)")
        if digits then
            return tonumber(digits)
        end
    end
    return nil
end

local function GetShardCount(shardInfo)
    -- Return how many shards the character has earned this week (capped at weekly max)
    if not shardInfo then
        return 0
    end

    local fields = {
        "quantityEarnedThisWeek",
        "currentQuantity",
        "currencyQuantity",
        "weeklyQuantity",
        "weeklyQuantityEarned",
        "amountEarnedThisWeek",
        "quantity",
        "current",
        "amount",
        "totalEarnedThisWeek",
        "earnedThisWeek",
        "weeklyEarned",
        "totalEarned",
    }

    local collected = nil
    for _, field in ipairs(fields) do
        if shardInfo[field] ~= nil then
            local parsed = ParseNumber(shardInfo[field])
            if parsed ~= nil then
                collected = parsed
                break
            end
        end
    end

    if collected == nil and shardInfo.quantity then
        local quantity = ParseNumber(shardInfo.quantity)
        local weeklyMax = ParseNumber(shardInfo.weeklyMax or shardInfo.maxWeeklyQuantity or shardInfo.maxQuantity)
        if quantity and weeklyMax then
            collected = weeklyMax - quantity
        end
    end

    collected = tonumber(collected) or 0
    return math.max(0, math.min(collected, PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX or 8))
end

local function GetShardOwnedCount(shardInfo)
    -- Return how many shards the character currently owns (in bags/currency)
    if not shardInfo then return 0 end
    local fields = { "currentQuantity", "currencyQuantity", "quantity", "current", "amount" }
    for _, field in ipairs(fields) do
        if shardInfo[field] ~= nil then
            local parsed = ParseNumber(shardInfo[field])
            if parsed ~= nil then
                return tonumber(parsed) or 0
            end
        end
    end
    if shardInfo.quantity then
        local q = ParseNumber(shardInfo.quantity)
        return tonumber(q) or 0
    end
    return 0
end

local function UpdateCurrencies()
    local data = PR.DB:GetCharacterData()
    
    -- Vibrant Shards: record both earned this week and currently owned
    local shardInfo = GetCurrencyInfoAny(PR.Constants.SHARD_OF_DUNDUN_ID, PR.Constants.SHARD_OF_DUNDUN_NAME)
    if shardInfo then
        data.shards = GetShardCount(shardInfo)
        data.shardsOwned = GetShardOwnedCount(shardInfo)
    else
        data.shards = data.shards or 0
        data.shardsOwned = data.shardsOwned or 0
    end
    
    -- Unalloyed Abundance
    local abundanceInfo = C_CurrencyInfo.GetCurrencyInfo(PR.Constants.UNALLOYED_ABUNDANCE_ID)
    if abundanceInfo then
        data.abundance = abundanceInfo.quantity or 0
    end
    
    -- Vitality
    data.vitality = C_Item.GetItemCount(PR.Constants.FUSED_VITALITY_ID) or 0
    
    -- Update moxie for each profession
    if data.professions then
        for profName, profData in pairs(data.professions) do
            local profConst = PR.Constants.GetProfession(profName)
            local moxieID = (profConst and profConst.moxieId) or nil
            if moxieID then
                local moxieInfo = C_CurrencyInfo.GetCurrencyInfo(moxieID)
                if moxieInfo then
                    profData.moxie = moxieInfo.quantity or 0
                end
            end

            if profConst then
                -- Epic tool state
                profData.toolEquipped = false
                local tool = profConst.epicTool
                if tool and tool.id then
                    for _, slotID in ipairs({20, 23}) do
                        local itemID = GetInventoryItemID("player", slotID)
                        if itemID and tonumber(itemID) == tool.id then
                            profData.toolEquipped = true
                            break
                        end
                    end
                end

                -- Epic accessory count
                profData.accessories = 0
                local accessories = profConst.epicAccessories
                if accessories and type(accessories) == "table" then
                    local accessoryIds = {}
                    for _, acc in ipairs(accessories) do
                        accessoryIds[tonumber(acc.id)] = true
                    end
                    for _, slotID in ipairs({21, 22, 24, 25}) do
                        local itemID = GetInventoryItemID("player", slotID)
                        if itemID and accessoryIds[tonumber(itemID)] then
                            profData.accessories = profData.accessories + 1
                        end
                    end
                end

                -- Profession concentration currency amount
                profData.concentration = 0
                local concentrationId = (profConst.concentration and profConst.concentration.currencyId) or nil
                if concentrationId and concentrationId > 0 then
                    local concInfo = GetCurrencyInfoAny(concentrationId)
                    profData.concentration = concInfo and concInfo.quantity or 0
                end
            else
                profData.toolEquipped = false
                profData.accessories = 0
                profData.concentration = 0
            end
        end
    end
    
    PR.DB:SetCharacterData(data)
end

frame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        PR.DB:Initialize()
        UpdateCharacterProfessions()
        UpdateCurrencies()
        print("|cff0070ddProfessions Reminder|r loaded. Type |cffFFD100/pr|r to open.")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local data = PR.DB:GetCharacterData()
        local _, classFilename = UnitClass("player")
        data.class = classFilename
        UpdateCharacterProfessions()
        UpdateCurrencies()
        
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        UpdateCurrencies()
        if PR.UI.RefreshDisplay then
            PR.UI:RefreshDisplay()
        end

    elseif event == "QUEST_TURNED_IN" or event == "QUEST_LOG_UPDATE" then
        UpdateCharacterProfessions()
        UpdateCurrencies()
        if PR.UI.RefreshDisplay then
            PR.UI:RefreshDisplay()
        end

    elseif event == "BAG_UPDATE_DELAYED" then
        -- Bag changes can affect item counts like Vitality; refresh currencies
        UpdateCurrencies()
        if PR.UI.RefreshDisplay then
            PR.UI:RefreshDisplay()
        end

    elseif event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_CURRENCY" then
        -- Loot or currency chat messages may signal a shard gain; refresh currencies and quests
        UpdateCurrencies()
        UpdateCharacterProfessions()
        if PR.UI.RefreshDisplay then
            PR.UI:RefreshDisplay()
        end
    end
end)

-- Slash command
SLASH_PROFESSIONSREMINDER1 = "/pr"
SlashCmdList["PROFESSIONSREMINDER"] = function(msg)
    msg = msg:lower()
    
    if msg == "reset" then
        PR.DB:ResetDatabase()
        print("|cff0070ddProfessions Reminder|r: Database reset.")
        if PR.UI.RefreshDisplay then
            PR.UI:RefreshDisplay()
        end
    elseif msg == "shardinfo" then
        local shardInfo = GetCurrencyInfoAny(PR.Constants.SHARD_OF_DUNDUN_ID, PR.Constants.SHARD_OF_DUNDUN_NAME)
        if shardInfo then
            print("|cff0070ddProfessions Reminder|r shard info:")
            for k, v in pairs(shardInfo) do
                print("  " .. tostring(k) .. ": " .. tostring(v))
            end
            print("|cff0070ddProfessions Reminder|r computed shards (this week): " .. tostring(GetShardCount(shardInfo)))
            print("|cff0070ddProfessions Reminder|r owned shards: " .. tostring(GetShardOwnedCount(shardInfo)))
        else
            print("|cff0070ddProfessions Reminder|r: Shard info not found.")
        end
    else
        if PR.UI.MainFrame then
            if PR.UI.MainFrame:IsShown() then
                PR.UI.MainFrame:Hide()
            else
                PR.UI.MainFrame:Show()
                if PR.UI.RefreshDisplay then
                    PR.UI:RefreshDisplay()
                end
            end
        end
    end
end