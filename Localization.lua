local addonName, SPF = ...

local currentLocale = GetLocale()

local LOCALIZED_CATEGORIES = {
    enUS = {
        All = "All Slots", Other = "Other",
        Boots = "Boots", Bracer = "Bracer", Chest = "Chest", Cloak = "Cloak",
        Gloves = "Gloves", Shield = "Shield", Weapon = "Weapon", TwoHWeapon = "2H Weapon", Wand = "Wand",
        Rod = "Rod", Oil = "Oil"
    },
    deDE = {
        All = "Alle Plätze", Other = "Andere",
        Boots = "Stiefel", Bracer = "Armschiene", Chest = "Brust", Cloak = "Umhang",
        Gloves = "Handschuhe", Shield = "Schild", Weapon = "Waffe", TwoHWeapon = "2H-Waffe", Wand = "Zauberstab",
        Rod = "Runenverzierte", Oil = "Öl"
    },
    frFR = {
        All = "Tous les emplacements", Other = "Autres",
        Boots = "Bottes", Bracer = "Bracelets", Chest = "Plastron", Cloak = "Cape",
        Gloves = "Gants", Shield = "Bouclier", Weapon = "Arme", TwoHWeapon = "Arme 2M", Wand = "Baguette",
        Rod = "Bâtonnet", Oil = "Huile"
    },
    esES = {
        All = "Todos los espacios", Other = "Otros",
        Boots = "Botas", Bracer = "Brazal", Chest = "Pechera", Cloak = "Capa",
        Gloves = "Guantes", Shield = "Escudo", Weapon = "Arma", TwoHWeapon = "Arma 2M", Wand = "Varita",
        Rod = "Vara", Oil = "Aceite"
    },
    esMX = {
        All = "Todos los espacios", Other = "Otros",
        Boots = "Botas", Bracer = "Brazal", Chest = "Pechera", Cloak = "Capa",
        Gloves = "Guantes", Shield = "Escudo", Weapon = "Arma", TwoHWeapon = "Arma 2M", Wand = "Varita",
        Rod = "Vara", Oil = "Aceite"
    },
    ptBR = {
        All = "Todos os slots", Other = "Outros",
        Boots = "Botas", Bracer = "Braçadeiras", Chest = "Torso", Cloak = "Manto",
        Gloves = "Luvas", Shield = "Escudo", Weapon = "Arma", TwoHWeapon = "Arma 2M", Wand = "Varinha",
        Rod = "Bastão", Oil = "Óleo"
    },
    koKR = {
        All = "모든 슬롯", Other = "기타",
        Boots = "장화", Bracer = "손목", Chest = "가슴", Cloak = "망토",
        Gloves = "장갑", Shield = "방패", Weapon = "한손 무기", TwoHWeapon = "양손 무기", Wand = "마술봉",
        Rod = "마법막대", Oil = "오일"
    },
    zhTW = {
        All = "所有插槽", Other = "其他",
        Boots = "靴子", Bracer = "護腕", Chest = "胸甲", Cloak = "披風",
        Gloves = "手套", Shield = "盾牌", Weapon = "單手武器", TwoHWeapon = "雙手武器", Wand = "魔法杖",
        Rod = "符文", Oil = "之油"
    },
    zhCN = {
        All = "所有插槽", Other = "其他",
        Boots = "靴子", Bracer = "护腕", Chest = "胸甲", Cloak = "披风",
        Gloves = "手套", Shield = "盾牌", Weapon = "单手武器", TwoHWeapon = "双手武器", Wand = "魔杖",
        Rod = "符文", Oil = "之油"
    }
}

-- Category synonyms for languages with multiple keywords per slot
local CATEGORY_SYNONYMS = {
    frFR = {
        Bracer = { "bracelets", "brassards" },
    },
    esES = {
        Bracer = { "brazal", "brazales" },
    },
    esMX = {
        Bracer = { "brazal", "brazales" },
    },
}

-- Fallback to English if locale not in table
SPF.L = LOCALIZED_CATEGORIES[currentLocale] or LOCALIZED_CATEGORIES.enUS
SPF.CategorySynonyms = CATEGORY_SYNONYMS[currentLocale] or {}
