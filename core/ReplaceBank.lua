local addonName, ns = ...

-- Remplace l'affichage de la banque Blizzard. Le BankFrame doit rester "affiché"
-- (son OnHide ferme l'interaction avec le banquier) : on le rend invisible et
-- minuscule. Le bouton « cadre Blizzard » le rend visible (achat d'emplacements,
-- sacs de banque) ; « retour » revient à notre vue.

local bf = _G.BankFrame
if not bf then return end

local native = false   -- cadre Blizzard demandé

local function Conceal()
    bf:SetAlpha(0)
    bf:SetScale(0.001)
end

local function Reveal()
    bf:SetAlpha(1)
    bf:SetScale(1)
end

bf:HookScript("OnShow", function()
    if native then return end
    Conceal()
    ns.UI.Bank.Show()
end)

bf:HookScript("OnHide", function()
    native = false
    Reveal()
    ns.UI.Bank.Hide()
end)

ns.UI.GuildReturn.Attach(bf, function()
    native = false
    Conceal()
    ns.UI.Bank.Show()
end)

ns.On("BANK_BLIZZARD_REQUESTED", function()
    native = true
    Reveal()
    ns.UI.Bank.Hide(true)
end)
