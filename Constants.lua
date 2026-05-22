local addonName, PR = ...

-- Initialize namespace
PR.Constants = {}

-- Currency and Item IDs
PR.Constants.SHARD_OF_DUNDUN_ID = 3376
PR.Constants.SHARD_OF_DUNDUN_NAME = "Shard of Dundun"
PR.Constants.UNALLOYED_ABUNDANCE_ID = 3377
PR.Constants.FUSED_VITALITY_ID = 245345

-- Profession Moxie Currency IDs
PR.Constants.MOXIE_IDS = {
    ["Alchemy"] = 3256,
    ["Blacksmithing"] = 3257,
    ["Enchanting"] = 3258,
    ["Engineering"] = 3259,
    ["Herbalism"] = 3260,
    ["Inscription"] = 3261,
    ["Jewelcrafting"] = 3262,
    ["Leatherworking"] = 3263,
    ["Mining"] = 3264,
    ["Skinning"] = 3265,
    ["Tailoring"] = 3266,
}

PR.Constants.EPIC_TOOLS = {
    ["Jewelcrafting"] = { id = 259181, name = "Giga-Gem Grippers" },
    ["Leatherworking"] = { id = 246536, name = "Sunforged Leatherworker's Knife" },
    ["Blacksmithing"] = { id = 246537, name = "Sunforged Blacksmith's Hammer" },
    ["Enchanting"] = { id = 244177, name = "Runed Dazzling Thorium Rod" },
    ["Inscription"] = { id = 259209, name = "Gilded Sin'dorei Quill" },
    ["Engineering"] = { id = 259183, name = "Turbo-Junker's Multitool v9" },
    ["Tailoring"] = { id = 259177, name = "Self-Sharpening Sin'dorei Snippers" },
    ["Alchemy"] = { id = 259205, name = "Gilded Alchemist's Mixing Rod" },
}

-- Epic accessories per profession
PR.Constants.EPIC_ACCESSORIES = {
    ["Jewelcrafting"] = {
        { id = 244814, name = "Thalassian Gemshaper's Grand Cover" },
        { id = 246526, name = "Mage-Eye Precision Loupes" },
    },
    ["Leatherworking"] = {
        { id = 259232, name = "Sunforged Leatherworker's Toolset" },
        { id = 244811, name = "Thalassian Hideshaper's Regalia" },
    },
    ["Blacksmithing"] = {
        { id = 244813, name = "Thalassian Ironbender's Regalia" },
        { id = 259230, name = "Sunforged Blacksmith's Tolbox" },
    },
    ["Enchanting"] = {
        { id = 246527, name = "Attuned Thalassian Rune-Prism" },
        { id = 267056, name = "Thalassian Enchanter's Bonnet" },
    },
    ["Inscription"] = {
        { id = 246525, name = "Thalassian Scribe's Crystalline Lens" },
        { id = 246524, name = "Flawless Text Scrutinizers" },
    },
    ["Engineering"] = {
        { id = 244810, name = "Thalassian Scrapmaster's Gauntlets" },
        { id = 259171, name = "Head-Mounted Beam Bummer" },
    },
    ["Tailoring"] = {
        { id = 267062, name = "Thalassian Tailor's Threads" },
        { id = 259234, name = "Sunforged Needle Set" },
    },
    ["Alchemy"] = {
        { id = 267052, name = "Thalassian Alchemy Coveralls" },
        { id = 267052, name = "Thalassian Alchemist's Mixcap" },
    },
}

-- Quest IDs for treasure map activities
PR.Constants.TREASURE_MAP_QUESTS = {
    ["Alchemy"] = {93528, 93529},
    ["Blacksmithing"] = {93530, 93531},
    ["Enchanting"] = {93532, 93533},
    ["Engineering"] = {93534, 93535},
    ["Herbalism"] = {},
    ["Inscription"] = {93536, 93537},
    ["Jewelcrafting"] = {93538, 93539},
    ["Leatherworking"] = {93540, 93541},
    ["Mining"] = {},
    ["Skinning"] = {},
    ["Tailoring"] = {93542, 93543},
}

-- UI Colors
PR.Constants.COLORS = {
    white = {1, 1, 1},
    gray = {0.7, 0.7, 0.7},
    yellow = {1, 1, 0},
    green = {0, 1, 0},
    red = {1, 0, 0},
    blue = {0, 0.5, 1},
}

-- Profession Colors (class-like styling)
PR.Constants.PROFESSION_COLORS = {
    ["Alchemy"] = {1, 0.5, 1},
    ["Blacksmithing"] = {0.8, 0.8, 0.8},
    ["Enchanting"] = {0.63, 0.21, 0.94},
    ["Engineering"] = {0.9, 0.8, 0},
    ["Herbalism"] = {0.3, 0.9, 0.3},
    ["Inscription"] = {1, 0.8, 0},
    ["Jewelcrafting"] = {0, 1, 1},
    ["Leatherworking"] = {0.8, 0.6, 0.2},
    ["Mining"] = {0.6, 0.6, 0.6},
    ["Skinning"] = {0.8, 0.5, 0.3},
    ["Tailoring"] = {0.6, 0.3, 0.8},
}