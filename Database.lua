local addonName, PR = ...

PR.DB = {}

function PR.DB:Initialize()
    ProfessionsReminderDB = ProfessionsReminderDB or {}
    ProfessionsReminderDB.characters = ProfessionsReminderDB.characters or {}
    ProfessionsReminderDB.options = ProfessionsReminderDB.options or {
        enabled = true,
    }
    
    -- Migrate old key format to new format
    local newKey = self:GetCharacterKey()
    local oldKeyFormats = {}
    
    -- Check for old key formats with spaces
    for key in pairs(ProfessionsReminderDB.characters) do
        if key ~= newKey and key:find(" - ") then
            table.insert(oldKeyFormats, key)
        end
    end
    
    -- Migrate old keys to new format
    for _, oldKey in ipairs(oldKeyFormats) do
        if not ProfessionsReminderDB.characters[newKey] then
            ProfessionsReminderDB.characters[newKey] = ProfessionsReminderDB.characters[oldKey]
        end
        ProfessionsReminderDB.characters[oldKey] = nil
    end
end

function PR.DB:GetCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Unknown"
    return name .. "-" .. realm
end

function PR.DB:GetCharacterData()
    self:Initialize()
    local key = self:GetCharacterKey()
    
    if not ProfessionsReminderDB.characters[key] then
        ProfessionsReminderDB.characters[key] = {
            name = UnitName("player") or "Unknown",
            realm = GetRealmName() or "Unknown",
            class = select(2, UnitClass("player")),
            professions = {},
            shards = 0,
            abundance = 0,
            vitality = 0,
            lastUpdated = GetTime(),
        }
    end
    
    return ProfessionsReminderDB.characters[key]
end

function PR.DB:SetCharacterData(data)
    self:Initialize()
    local key = self:GetCharacterKey()
    data.lastUpdated = GetTime()
    ProfessionsReminderDB.characters[key] = data
end

function PR.DB:GetAllCharacters()
    self:Initialize()
    return ProfessionsReminderDB.characters
end

function PR.DB:GetOption(key)
    self:Initialize()
    return ProfessionsReminderDB.options[key]
end

function PR.DB:SetOption(key, value)
    self:Initialize()
    ProfessionsReminderDB.options[key] = value
end

function PR.DB:ResetDatabase()
    ProfessionsReminderDB = {
        characters = {},
        options = {
            enabled = true,
        }
    }
end