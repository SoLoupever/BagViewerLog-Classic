local addonName, ns = ...

-- Type de bouton des conteneurs de l'historique ViewerLog : lecture seule,
-- infobulle et clic modifié (lien, aperçu) uniquement.

local function OnEnter(self)
    local e = self.entry
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(e.link or ("item:" .. e.id))
    GameTooltip:Show()
end

local function OnClick(self)
    local e = self.entry
    if e and e.link then HandleModifiedItemClick(e.link) end
end

ns.UI.RegisterButtonKind({
    matches = function(bag) return bag >= ns.HBAG_BASE end,
    create = function(parent)
        local A = ns.UI.ItemButtonAdapter
        local btn = CreateFrame(A.frameType, nil, parent, A.template)
        btn:RegisterForClicks("LeftButtonUp")
        btn:SetScript("OnClick", OnClick)
        btn:SetScript("OnEnter", OnEnter)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        return btn
    end,
})
