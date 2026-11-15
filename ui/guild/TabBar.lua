local addonName, ns = ...

-- Barre d'onglets : « Tous » + un bouton par onglet (coffre de guilde, banque).
-- ns.UI.GuildTabBar.New(parent, onSelect(index|nil), opts)
--   -> { Update(tabs, filter), Hide(), SetWidth(largeur, écart) }.
-- opts (optionnel) : { y = ordonnée, allKey = clé du bouton « Tous »,
-- always = tous les onglets affichés, sans canView }.

local C = ns.UI.Colors
local W, GAP = 84, 4

local function Highlight(btn, on)
    local c = on and C.btnHoverBorder or C.btnBorder
    btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    btn.selected = on
end

local function NewButton(parent, onSelect, w)
    local b = ns.UI.Button(parent, w, 26, "")
    b.label:SetWidth(w - 8)
    b.label:SetWordWrap(false)
    b:SetScript("OnLeave", function(s)
        Highlight(s, s.selected)
        GameTooltip_Hide()
    end)
    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(C.btnHoverBorder[1], C.btnHoverBorder[2], C.btnHoverBorder[3], 1)
        if s.tip then
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:SetText(s.tip)
        end
    end)
    b:SetScript("OnClick", function(s) onSelect(s.index) end)
    return b
end

ns.UI.GuildTabBar = {}

function ns.UI.GuildTabBar.New(parent, onSelect, opts)
    local bar = {}
    local y = opts and opts.y or -44
    local allKey = opts and opts.allKey or "GUILD_ALL"
    local always = opts and opts.always
    local w, step = W, W + GAP
    local btns = {}   -- [1] = « Tous », [i + 1] = onglet i

    local function Place(b, i)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (i - 1) * step, y)
    end

    local function Get(i)
        local b = btns[i]
        if not b then
            b = NewButton(parent, onSelect, w)
            Place(b, i)
            btns[i] = b
        end
        return b
    end

    -- Largeur des boutons (mode compact) : existants et à venir.
    function bar.SetWidth(width, gap)
        w, step = width, width + gap
        for i = 1, #btns do
            btns[i]:SetWidth(w)
            btns[i].label:SetWidth(w - 8)
            Place(btns[i], i)
        end
    end

    function bar.Update(tabs, filter)
        local n = 1
        local all = Get(1)
        all.index, all.tip = nil, nil
        all.label:SetText(ns.L(allKey))
        Highlight(all, filter == nil)
        all:Show()
        for i = 1, #tabs do
            local t = tabs[i]
            if always or t.canView then
                n = n + 1
                local b = Get(n)
                b.index, b.tip = i, t.name
                b.label:SetText(t.name)
                Highlight(b, filter == i)
                b:Show()
            end
        end
        for i = n + 1, #btns do btns[i]:Hide() end
    end

    function bar.Hide()
        for i = 1, #btns do btns[i]:Hide() end
    end

    return bar
end
