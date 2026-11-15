local addonName, ns = ...

-- Pools de boutons d'objet. Un bouton = un (conteneur, emplacement), créé une fois
-- puis réutilisé. Le parent porte le bagID.
-- Type par défaut : ContainerFrameItemButtonTemplate (clic, glisser, infobulle,
-- utilisation natifs). Les conteneurs virtuels (bag >= ns.VBAG_BASE) se branchent
-- avec ns.UI.RegisterButtonKind({ matches(bag), create(parent, bag, slot) }) : leur
-- bouton gère lui-même clic et infobulle ; pas de SetHasItem ni de cooldown.
-- Une instance par cadre (sac, banque) : ns.UI.NewItemButtons().
-- Deux familles de client : UI moderne (ItemButton + méthodes de mixin) et UI
-- Classic (Button + fonctions globales) ; l'adaptateur A est choisi une fois.

local SetItemButtonQuality, SetItemButtonCount = SetItemButtonQuality, SetItemButtonCount
local SetItemButtonDesaturated = SetItemButtonDesaturated

local A = {}

if ns.Env.modernBags then
    A.frameType = "ItemButton"
    function A.texture(btn, icon) btn:SetItemButtonTexture(icon) end
    function A.clear(btn) ClearItemButtonOverlay(btn) end
    function A.has(btn, icon) btn:SetHasItem(icon) end
    function A.cooldown(btn, icon) btn:UpdateCooldown(icon) end
    function A.match(btn, ok) btn:SetMatchesSearch(ok) end
    function A.quality(btn, quality, link) SetItemButtonQuality(btn, quality, link) end
    function A.noCooldown(btn) btn:UpdateCooldown(nil) end
else
    local COMMON = Enum.ItemQuality.Common or 1
    A.frameType = "Button"
    A.template  = "ItemButtonTemplate"   -- fournit icône, compte, bordure, recherche
    function A.texture(btn, icon) SetItemButtonTexture(btn, icon) end
    function A.clear() end   -- pas d'overlay à nettoyer
    function A.has(btn, icon) btn.hasItem = icon and 1 or nil end
    function A.cooldown(btn)
        ContainerFrame_UpdateCooldown(btn:GetParent():GetID(), btn)
    end
    function A.noCooldown(btn)
        if btn.cd then btn.cd:Hide() end
        SetItemButtonTextureVertexColor(btn, 1, 1, 1)
    end
    function A.match(btn, ok) btn.searchOverlay:SetShown(not ok) end
    -- SetItemButtonQuality masque la bordure en Classic : on la colore nous-mêmes.
    function A.quality(btn, quality, link)
        SetItemButtonQuality(btn, quality, link)
        if quality and quality >= COMMON then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            btn.IconBorder:SetVertexColor(r, g, b)
            btn.IconBorder:Show()
        end
    end
end
ns.UI.ItemButtonAdapter = A

local count = 0

local CONTAINER = {
    container = true,
    create = function(parent, bag, slot)
        count = count + 1
        -- Nom requis en Classic : le cooldown Blizzard est retrouvé par _G[nom .. "Cooldown"].
        local btn = CreateFrame(A.frameType, "BagViewerLogItem" .. count, parent,
                                "ContainerFrameItemButtonTemplate")
        btn:SetID(slot)
        -- Pas de SetBagID : Blizzard lit le bagID du parent (écrire un champ = taint).
        -- Visibles par défaut dans le template ; Blizzard les masque lui-même.
        if btn.BattlepayItemTexture then btn.BattlepayItemTexture:Hide() end
        if btn.NewItemTexture then btn.NewItemTexture:Hide() end
        btn.cd = _G[btn:GetName() .. "Cooldown"]
        return btn
    end,
}

local kinds = {}

function ns.UI.RegisterButtonKind(def)
    kinds[#kinds + 1] = def
end

local function KindOf(bag)
    for i = 1, #kinds do
        if kinds[i].matches(bag) then return kinds[i] end
    end
    return CONTAINER
end

function ns.UI.NewItemButtons()
    local IB = {}

    local container
    local bagParents = {}   -- bagID -> frame (ID = bagID)
    local buttons    = {}   -- bagID -> { [slot] = button }
    local active, prev = {}, {}
    local nActive, nPrev = 0, 0
    local token = 0         -- rendu en cours
    local slotSize = 37
    local cdFrame = CreateFrame("Frame")
    local cdOn, cdQueued = false, false

    function IB.SetContainer(frame)
        container = frame
    end

    -- Taille des boutons (profil de dimensions) : existants et à venir.
    function IB.SetSlotSize(size)
        if size == slotSize then return end
        slotSize = size
        for _, perBag in pairs(buttons) do
            for _, btn in pairs(perBag) do btn:SetSize(size, size) end
        end
    end

    local function GetBagParent(bag)
        local p = bagParents[bag]
        if not p then
            p = CreateFrame("Frame", nil, container)
            p:SetAllPoints(container)
            p:SetID(bag)
            bagParents[bag] = p
        end
        return p
    end

    -- Cooldowns : écoutés seulement si des boutons sont affichés.
    local function SetCooldownEvent(on)
        if on == cdOn then return end
        cdOn = on
        if on then cdFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
        else cdFrame:UnregisterEvent("BAG_UPDATE_COOLDOWN") end
    end

    local function RefreshCooldowns()
        cdQueued = false
        for i = 1, nActive do
            local btn = active[i]
            local e = btn.entry
            if e and e.icon and btn.kind.container then A.cooldown(btn, e.icon) end
        end
    end

    cdFrame:SetScript("OnEvent", function()
        if cdQueued then return end
        cdQueued = true
        C_Timer.After(0.1, RefreshCooldowns)
    end)

    -- Un rendu = Begin, Acquire..., Finish : les boutons déjà affichés le restent.
    function IB.Begin()
        active, prev = prev, active
        nPrev, nActive = nActive, 0
        token = token + 1
    end

    function IB.Acquire(bag, slot)
        local perBag = buttons[bag]
        if not perBag then
            perBag = {}
            buttons[bag] = perBag
        end
        local btn = perBag[slot]
        if not btn then
            local kind = KindOf(bag)
            btn = kind.create(GetBagParent(bag), bag, slot)
            btn.kind = kind
            btn:SetSize(slotSize, slotSize)
            perBag[slot] = btn
        end
        if btn.token ~= token then
            btn.token = token
            if not btn:IsShown() then btn:Show() end
            nActive = nActive + 1
            active[nActive] = btn
        end
        return btn
    end

    function IB.Finish()
        for i = 1, nPrev do
            local btn = prev[i]
            if btn.token ~= token then
                btn:Hide()
                btn.entry, btn.mode = nil, nil
            end
            prev[i] = nil
        end
        nPrev = 0
        SetCooldownEvent(nActive > 0)
    end

    function IB.ReleaseAll()
        for i = nActive, 1, -1 do
            local btn = active[i]
            btn:Hide()
            btn.entry, btn.mode = nil, nil
            active[i] = nil
        end
        nActive = 0
        SetCooldownEvent(false)
    end

    -- entry = objet du snapshot (icon, count, link, quality) ou emplacement vide.
    -- L'apparence Blizzard n'est réécrite que si l'objet affiché a changé.
    function IB.Set(btn, entry)
        if not entry.id then return IB.SetEmpty(btn, entry) end
        btn.entry = entry
        local id, count, link, quality = entry.id, entry.count, entry.link, entry.quality
        local native, locked = btn.kind.container, entry.locked
        if btn.mode ~= "item" or btn.sId ~= id or btn.sCount ~= count
           or btn.sLink ~= link or btn.sQuality ~= quality or btn.sLocked ~= locked then
            btn.mode, btn.sId, btn.sCount, btn.sLink, btn.sQuality = "item", id, count, link, quality
            btn.sLocked = locked
            if btn.freeCount then btn.freeCount:Hide() end
            A.clear(btn)
            if native then A.has(btn, entry.icon) end
            A.texture(btn, entry.icon)
            A.quality(btn, quality, link)
            SetItemButtonCount(btn, count)
            if native then A.cooldown(btn, entry.icon)
            else SetItemButtonDesaturated(btn, locked) end
        end
        A.match(btn, ns.Search.Matches(entry))
        ns.UI.ApplyBadges(btn, entry)
    end

    -- Remise à blanc d'un bouton qui n'affiche plus d'objet.
    local function Blank(btn, mode)
        btn.mode, btn.sId, btn.sCount, btn.sLink, btn.sQuality = mode, nil, nil, nil, nil
        btn.sFree, btn.sLocked = nil, nil
        if btn.kind.container then
            A.has(btn, nil)
            A.noCooldown(btn)
        else
            SetItemButtonDesaturated(btn, false)
        end
        A.texture(btn, nil)
        SetItemButtonCount(btn, 0)
        ns.UI.HideBadges(btn)
    end

    -- Emplacement vide (vues par sac) : reste un vrai bouton, cible de dépôt.
    function IB.SetEmpty(btn, entry)
        btn.entry = entry
        if btn.mode ~= "empty" then
            if btn.freeCount then btn.freeCount:Hide() end
            Blank(btn, "empty")
            A.quality(btn, nil, nil)
        end
        A.match(btn, true)
    end

    -- Bouton d'un emplacement libre : sert de cible de dépôt, le nombre de libres
    -- est écrit dans l'icône.
    function IB.SetFree(btn, entry, numFree)
        btn.entry = entry
        local fresh = btn.mode ~= "free"
        if fresh then
            A.clear(btn)
            Blank(btn, "free")
        end
        A.match(btn, true)

        if fresh or btn.sFree ~= numFree then
            btn.sFree = numFree
            if not btn.freeCount then
                btn.freeCount = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                btn.freeCount:SetPoint("BOTTOMRIGHT", -5, 5)
            end
            btn.freeCount:SetText(numFree)
            btn.freeCount:Show()
        end
    end

    ns.On("SEARCH_CHANGED", function()
        for i = 1, nActive do
            local btn = active[i]
            if btn.entry then A.match(btn, ns.Search.Matches(btn.entry)) end
        end
    end)

    return IB
end

ns.UI.ItemButtons = ns.UI.NewItemButtons()
