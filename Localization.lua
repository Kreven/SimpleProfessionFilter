local addonName, SPF = ...

local currentLocale = GetLocale()

local LOCALIZED_CATEGORIES = {
    enUS = {
        All = "All Slots", Other = "Other",
        Boots = "Boots", Bracer = "Bracer", Chest = "Chest", Cloak = "Cloak",
        Gloves = "Gloves", Shield = "Shield", Weapon = "Weapon", Wand = "Wand",
        Rod = "Rod", Oil = "Oil"
    },
    deDE = {
        All = "Alle Plätze", Other = "Andere",
        Boots = "Stiefel", Bracer = "Armschiene", Chest = "Brust", Cloak = "Umhang",
        Gloves = "Handschuhe", Shield = "Schild", Weapon = "Waffe", Wand = "Zauberstab",
        Rod = "Runenverzierte", Oil = "Öl"
    },
    frFR = {
        All = "Tous les emplacements", Other = "Autres",
        Boots = "bottes", Bracer = "bracelets", Chest = "plastron", Cloak = "cape",
        Gloves = "gants", Shield = "bouclier", Weapon = "arme", Wand = "baguette",
        Rod = "bâtonnet", Oil = "huile"
    },
    esES = {
        All = "Todos los espacios", Other = "Otros",
        Boots = "botas", Bracer = "brazal", Chest = "pechera", Cloak = "capa",
        Gloves = "guantes", Shield = "escudo", Weapon = "arma", Wand = "varita",
        Rod = "vara", Oil = "aceite"
    },
    esMX = {
        All = "Todos los espacios", Other = "Otros",
        Boots = "botas", Bracer = "brazal", Chest = "pechera", Cloak = "capa",
        Gloves = "guantes", Shield = "escudo", Weapon = "arma", Wand = "varita",
        Rod = "vara", Oil = "aceite"
    },
    ptBR = {
        All = "Todos os slots", Other = "Outros",
        Boots = "Botas", Bracer = "Braçadeiras", Chest = "Torso", Cloak = "Manto",
        Gloves = "Luvas", Shield = "Escudo", Weapon = "Arma", Wand = "Varinha",
        Rod = "Bastão", Oil = "Óleo"
    },
    koKR = {
        All = "모든 슬롯", Other = "기타",
        Boots = "장화", Bracer = "손목", Chest = "가슴", Cloak = "망토",
        Gloves = "장갑", Shield = "방패", Weapon = "무기", Wand = "마술봉",
        Rod = "마법막대", Oil = "오일"
    },
    zhTW = {
        All = "所有插槽", Other = "其他",
        Boots = "靴子", Bracer = "護腕", Chest = "胸甲", Cloak = "披風",
        Gloves = "手套", Shield = "盾牌", Weapon = "武器", Wand = "魔法杖",
        Rod = "符文", Oil = "之油"
    }
}

-- Fallback to English if locale not in table
SPF.L = LOCALIZED_CATEGORIES[currentLocale] or LOCALIZED_CATEGORIES.enUS
