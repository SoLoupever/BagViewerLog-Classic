local addonName, ns = ...

-- Pierre de foyer : l'objet renvoyé par C_Container.PlayerHasHearthstone quand
-- le client la propose, sinon l'itemID de la pierre de foyer classique.

local HEARTHSTONE_ID = 6948
local PlayerHasHearthstone = C_Container.PlayerHasHearthstone

local hearthID   -- itemID, false si aucune, nil = à relire

local function Get()
    if hearthID == nil then
        if type(PlayerHasHearthstone) == "function" then
            hearthID = PlayerHasHearthstone() or false
        else
            hearthID = HEARTHSTONE_ID
        end
    end
    return hearthID
end

ns.On("INVENTORY_SCANNED", function() hearthID = nil end)

ns.RegisterCategory({
    id = "hearthstone", labelKey = "CAT_HEARTHSTONE", order = 8, priority = 7,
    match = function(item) return item.id ~= nil and item.id == Get() end,
})
