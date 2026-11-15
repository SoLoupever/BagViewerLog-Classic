local addonName, ns = ...

-- Vente groupée : clic droit sur une catégorie du sac, marchand ouvert.
-- Vend au plus MAX_SELL emplacements, dans l'ordre d'affichage.
-- Écoute CATEGORY_CONTEXT (liste d'entrées) ; ne connaît aucun widget.

local MAX_SELL = 5
local GetInfo = C_Container.GetContainerItemInfo
local Use = C_Container.UseContainerItem

ns.Vendor = {}

-- Marchand ouvert = MerchantFrame affiché (pas d'événement à écouter).
function ns.Vendor.IsOpen()
    return MerchantFrame ~= nil and MerchantFrame:IsShown()
end

-- Renvoie le nombre d'emplacements vendus.
function ns.Vendor.Sell(list)
    local sold = 0
    for i = 1, #list do
        if sold >= MAX_SELL then break end
        local e = list[i]
        local info = GetInfo(e.bag, e.slot)
        -- Emplacement relu en direct : le snapshot peut avoir un léger retard.
        if info and info.itemID == e.id and not info.hasNoValue and not info.isLocked then
            Use(e.bag, e.slot)
            sold = sold + 1
        end
    end
    return sold
end

ns.On("CATEGORY_CONTEXT", function(def, list)
    if not ns.Vendor.IsOpen() then return end
    if ns.Vendor.Sell(list) == 0 then
        UIErrorsFrame:AddMessage(ns.L("VENDOR_NOTHING"), 1, 0.1, 0.1)
    end
end)

ns.On("CATEGORY_CONTEXT_TIP", function(tip, def)
    if ns.Vendor.IsOpen() then
        tip:AddLine(ns.L("VENDOR_SELL_TIP"):format(MAX_SELL), 1, 1, 1, true)
    end
end)
