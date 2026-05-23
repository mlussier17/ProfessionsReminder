local addonName, PR = ...

-- Initialize namespace
PR.Constants = {}

-- Currency and Item IDs
PR.Constants.SHARD_OF_DUNDUN_ID = 3376
PR.Constants.SHARD_OF_DUNDUN_NAME = "Shard of Dundun"
PR.Constants.SHARD_OF_DUNDUN_WEEKLY_MAX = 8
PR.Constants.UNALLOYED_ABUNDANCE_ID = 3377
PR.Constants.FUSED_VITALITY_ID = 245345
PR.Constants.TREATISE_MAX = 1
PR.Constants.TREASURES_MAX = 2

-- Unified profession data
PR.Constants.PROFESSIONS = {
    ["Alchemy"] = {
        name = "Alchemy",
        moxieId = 3256,
        epicTool = { id = 259205, name = "Gilded Alchemist's Mixing Rod" },
        epicAccessories = {
            { id = 267052, name = "Thalassian Alchemy Coveralls" },
            { id = 244812, name = "Thalassian Alchemist's Mixcap" },
        },
        treasureMapQuests = {93528, 93529},
        color = {1, 0.5, 1},
        treatise = {questId = 95127, itemId = 245755},
        darkmoon = {questId = 29506},
        concentration = {currencyId = 3161},
    },
    ["Blacksmithing"] = {
        name = "Blacksmithing",
        moxieId = 3257,
        epicTool = { id = 246537, name = "Sunforged Blacksmith's Hammer" },
        epicAccessories = {
            { id = 244813, name = "Thalassian Ironbender's Regalia" },
            { id = 259230, name = "Sunforged Blacksmith's Tolbox" },
        },
        treasureMapQuests = {93530, 93531},
        color = {0.8, 0.8, 0.8},
        treatise = {questId = 95128, itemId = 245763},
        darkmoon = {questId = 29508},
        concentration = {currencyId = 3162},
    },
    ["Enchanting"] = {
        name = "Enchanting",
        moxieId = 3258,
        epicTool = { id = 244177, name = "Runed Dazzling Thorium Rod" },
        epicAccessories = {
            { id = 246527, name = "Attuned Thalassian Rune-Prism" },
            { id = 267056, name = "Thalassian Enchanter's Bonnet" },
        },
        treasureMapQuests = {93532, 93533},
        color = {0.63, 0.21, 0.94},
        treatise = {questId = 95129, itemId = 245759},
        darkmoon = {questId = 29510},
        concentration = {currencyId = 3163},
    },
    ["Engineering"] = {
        name = "Engineering",
        moxieId = 3259,
        epicTool = { id = 259183, name = "Turbo-Junker's Multitool v9" },
        epicAccessories = {
            { id = 244810, name = "Thalassian Scrapmaster's Gauntlets" },
            { id = 259171, name = "Head-Mounted Beam Bummer" },
        },
        treasureMapQuests = {93534, 93535},
        color = {0.9, 0.8, 0},
        treatise = {questId = 95138, itemId = 245809},
        darkmoon = {questId = 29511},
        concentration = {currencyId = 3164},
    },
    ["Herbalism"] = {
        name = "Herbalism",
        moxieId = 3260,
        epicTool = nil,
        epicAccessories = {},
        treasureMapQuests = {},
        color = {0.3, 0.9, 0.3},
        treatise = {},
        darkmoon = {questId = 29514},
        concentration = {currencyId = 0},
    },
    ["Inscription"] = {
        name = "Inscription",
        moxieId = 3261,
        epicTool = { id = 259209, name = "Gilded Sin'dorei Quill" },
        epicAccessories = {
            { id = 246525, name = "Thalassian Scribe's Crystalline Lens" },
            { id = 246524, name = "Flawless Text Scrutinizers" },
        },
        treasureMapQuests = {93536, 93537},
        color = {1, 0.8, 0},
        treatise = {questId = 95131, itemId = 245757},
        darkmoon = {questId = 29515},
        concentration = {currencyId = 3165},
    },
    ["Jewelcrafting"] = {
        name = "Jewelcrafting",
        moxieId = 3262,
        epicTool = { id = 259181, name = "Giga-Gem Grippers" },
        epicAccessories = {
            { id = 244814, name = "Thalassian Gemshaper's Grand Cover" },
            { id = 246526, name = "Mage-Eye Precision Loupes" },
        },
        treasureMapQuests = {93538, 93539},
        color = {0, 1, 1},
        treatise = {questId = 95133, itemId = 245760},
        darkmoon = {questId = 29516},
        concentration = {currencyId = 3166},
    },
    ["Leatherworking"] = {
        name = "Leatherworking",
        moxieId = 3263,
        epicTool = { id = 246536, name = "Sunforged Leatherworker's Knife" },
        epicAccessories = {
            { id = 259232, name = "Sunforged Leatherworker's Toolset" },
            { id = 244811, name = "Thalassian Hideshaper's Regalia" },
        },
        treasureMapQuests = {93540, 93541},
        color = {0.8, 0.6, 0.2},
        treatise = {questId = 95134, itemId = 245758},
        darkmoon = {questId = 29517},
        concentration = {currencyId = 3167},
    },
    ["Mining"] = {
        name = "Mining",
        moxieId = 3264,
        epicTool = nil,
        epicAccessories = {},
        treasureMapQuests = {},
        color = {0.6, 0.6, 0.6},
        treatise = {},
        darkmoon = {questId = 29518},
        concentration = {currencyId = 0},
    },
    ["Skinning"] = {
        name = "Skinning",
        moxieId = 3265,
        epicTool = nil,
        epicAccessories = {},
        treasureMapQuests = {},
        color = {0.8, 0.5, 0.3},
        treatise = {},
        darkmoon = {questId = 29519},
        concentration = {currencyId = 0},
    },
    ["Tailoring"] = {
        name = "Tailoring",
        moxieId = 3266,
        epicTool = { id = 259177, name = "Self-Sharpening Sin'dorei Snippers" },
        epicAccessories = {
            { id = 267062, name = "Thalassian Tailor's Threads" },
            { id = 259234, name = "Sunforged Needle Set" },
        },
        treasureMapQuests = {93542, 93543},
        color = {0.6, 0.3, 0.8},
        treatise = {questId = 95137, itemId = 245756},
        darkmoon = {questId = 29520},
        concentration = {currencyId = 3168},
    },
}

function PR.Constants.GetProfession(profName)
    if not profName then return nil end
    return PR.Constants.PROFESSIONS and PR.Constants.PROFESSIONS[profName]
end