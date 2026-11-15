local addonName, ns = ...

-- Remplace le sac Blizzard sans toucher à ses fonctions : Blizzard ouvre ses
-- cadres, on les masque aussitôt et on affiche le nôtre.
-- Ouvrir : "ContainerFrame.OpenBag" (UI moderne) ou OnShow des ContainerFrame
-- (UI Classic). Basculer : post-hooks des Toggle*. Fermer : post-hooks des Close*.

local Frame = ns.UI.Frame

-- true pendant l'image où l'ouverture vient d'avoir lieu (Toggle* imbriqués).
local justOpened = false

local function ClearOpened() justOpened = false end

local function HideBlizzardFrame(f)
    if not f or not f.Hide then return end
    f:SetAlpha(0)
    -- Différé : on ne masque pas un cadre au milieu de son propre OnShow.
    C_Timer.After(0, function()
        f:Hide()
        f:SetAlpha(1)
    end)
end

local function OpenOurs()
    if Frame.IsShown() then return end
    justOpened = true
    C_Timer.After(0, ClearOpened)
    Frame.Show()
end

if ns.Env.modernBags then
    EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function(_, blizzFrame)
        HideBlizzardFrame(blizzFrame)
        OpenOurs()
    end, ns)
else
    local LAST_BAG = NUM_BAG_SLOTS
    local function OnBlizzShow(f)
        local id = f:GetID()
        if id < 0 then return end          -- porte-clés : laissé à Blizzard
        HideBlizzardFrame(f)
        if id <= LAST_BAG then OpenOurs() end   -- sacs de banque : cadre banque
    end
    local i = 1
    while _G["ContainerFrame" .. i] do
        _G["ContainerFrame" .. i]:HookScript("OnShow", OnBlizzShow)
        i = i + 1
    end
end

-- Blizzard ne voit jamais de sac ouvert : un Toggle rouvre donc toujours côté
-- Blizzard. Si notre cadre était déjà ouvert, c'est une demande de fermeture.
local function AfterToggle()
    if not justOpened then Frame.Hide() end
end

hooksecurefunc("ToggleAllBags", AfterToggle)
hooksecurefunc("ToggleBackpack", AfterToggle)
hooksecurefunc("ToggleBag", AfterToggle)

hooksecurefunc("CloseAllBags", function() Frame.Hide() end)
hooksecurefunc("CloseBackpack", function() Frame.Hide() end)
