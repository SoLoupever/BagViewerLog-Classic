local addonName, ns = ...

-- Catégories de base, par classe (Enum.ItemClass) et sous-classe d'objet.
-- order : affichage. priority : résolution (bas = d'abord) ; les règles précises
-- passent avant leur classe. Un parent sans match n'est qu'un conteneur.

local IC = Enum.ItemClass

-- Sous-classes : valeurs de repli si l'enum n'est pas exposé par le client.
local CONSUMABLE_POTION   = Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Potion    or 1
local CONSUMABLE_FOOD     = Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Fooddrink or 5
local MISC_COMPANION_PET  = Enum.ItemMiscellaneousSubclass and Enum.ItemMiscellaneousSubclass.CompanionPet or 2

-- Classes absentes de ce client ignorées (nil).
local function ByClass(...)
    local set = {}
    for i = 1, select("#", ...) do
        local id = select(i, ...)
        if id then set[id] = true end
    end
    return function(item) return set[item.classID] == true end
end

local function BySubClass(classID, subClassID)
    return function(item)
        return item.classID == classID and item.subClassID == subClassID
    end
end

-- ── Sans sous-catégorie ───────────────────────────────────────────
ns.RegisterCategory({
    id = "potion", labelKey = "CAT_POTION", order = 10, priority = 35,
    match = BySubClass(IC.Consumable, CONSUMABLE_POTION),
})

ns.RegisterCategory({
    id = "food", labelKey = "CAT_FOOD", order = 11, priority = 30,
    match = BySubClass(IC.Consumable, CONSUMABLE_FOOD),
})

ns.RegisterCategory({
    id = "consumable", labelKey = "CAT_CONSUMABLE", order = 12, priority = 70,
    match = ByClass(IC.Consumable),
})

ns.RegisterCategory({
    id = "quest", labelKey = "CAT_QUEST", order = 13, priority = 20,
    match = ByClass(IC.Questitem),
})

ns.RegisterCategory({
    id = "ammo", labelKey = "CAT_AMMO", order = 14, priority = 45,
    match = ByClass(IC.Projectile, IC.Quiver),
})

ns.RegisterCategory({
    id = "gem", labelKey = "CAT_GEM", order = 50, priority = 85,
    match = ByClass(IC.Gem),
})

ns.RegisterCategory({
    id = "container", labelKey = "CAT_CONTAINER", order = 52, priority = 100,
    match = ByClass(IC.Container),
})

ns.RegisterCategory({
    id = "key", labelKey = "CAT_KEY", order = 53, priority = 101,
    match = ByClass(IC.Key),
})

ns.RegisterCategory({
    id = "misc", labelKey = "CAT_MISC", order = 54, priority = 110,
    match = ByClass(IC.Miscellaneous, IC.WoWToken, IC.Glyph),
})

local isBattlepet = ByClass(IC.Battlepet)
local isPetItem   = BySubClass(IC.Miscellaneous, MISC_COMPANION_PET)

ns.RegisterCategory({
    id = "pet", labelKey = "CAT_PET", order = 55, priority = 40,
    match = function(item) return isBattlepet(item) or isPetItem(item) end,
})

ns.RegisterCategory({
    id = "junk", labelKey = "CAT_JUNK", order = 58, priority = 10,
    match = function(item) return item.quality == Enum.ItemQuality.Poor end,
})

-- Repli.
ns.RegisterCategory({
    id = "other", labelKey = "CAT_OTHER", order = 57, priority = 999,
})

-- ── Équipement ────────────────────────────────────────────────────
ns.RegisterCategory({ id = "equipment", labelKey = "CAT_EQUIPMENT", order = 20 })

ns.RegisterCategory({
    id = "weapon", labelKey = "CAT_WEAPON", order = 22, priority = 60, parent = "equipment",
    match = ByClass(IC.Weapon),
})

ns.RegisterCategory({
    id = "armor", labelKey = "CAT_ARMOR", order = 23, priority = 61, parent = "equipment",
    match = ByClass(IC.Armor),
})

-- ── Artisanat ─────────────────────────────────────────────────────
ns.RegisterCategory({ id = "tradegoods", labelKey = "CAT_TRADEGOODS", order = 30 })

ns.RegisterCategory({
    id = "reagent", labelKey = "CAT_REAGENT", order = 31, priority = 80, parent = "tradegoods",
    match = ByClass(IC.Tradegoods, IC.Reagent),
})

ns.RegisterCategory({
    id = "recipe", labelKey = "CAT_RECIPE", order = 33, priority = 90, parent = "tradegoods",
    match = ByClass(IC.Recipe),
})
