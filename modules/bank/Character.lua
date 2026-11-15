local addonName, ns = ...

-- Type de banque : personnage. Deux modèles selon le client (comme le scanner
-- de ViewerLog_Items) : BANK_CONTAINER + sacs de banque, ou onglets
-- Enum.BagIndex.CharacterBankTab_N. Seuls les conteneurs avec emplacements comptent.

local candidates = {}
local function Add(bag)
    if bag then candidates[#candidates + 1] = { ID = bag } end
end

Add(BANK_CONTAINER)
for bag = (NUM_BAG_SLOTS or 0) + 1, (NUM_BAG_SLOTS or 0) + (NUM_BANKBAGSLOTS or 0) do
    Add(bag)
end
local bagIndex = Enum and Enum.BagIndex
if bagIndex then
    for i = 1, 9 do Add(bagIndex["CharacterBankTab_" .. i]) end
end

local tabs = {}

ns.Bank.RegisterType({
    id = "character", labelKey = "BANK_CHARACTER", order = 1,
    getTabs = function()
        wipe(tabs)
        for i = 1, #candidates do
            local tab = candidates[i]
            if (C_Container.GetContainerNumSlots(tab.ID) or 0) > 0 then
                tabs[#tabs + 1] = tab
            end
        end
        return tabs
    end,
    getData = function(tabID)
        local bank = ns.vl.GetBank and ns.vl.GetBank(UnitName("player"), GetRealmName())
        return bank and bank[tabID]
    end,
})
