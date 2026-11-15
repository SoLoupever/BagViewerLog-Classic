local addonName, ns = ...

-- Cadre de banque : types et onglets viennent de
-- ns.Bank, les emplacements sont de vrais boutons (dépôt / retrait natifs).
-- Tous les onglets du type actif sont fusionnés en une seule vue par catégories ;
-- la hauteur suit le contenu.

local C  = ns.UI.Colors
local IB = ns.UI.NewItemButtons()

local COLS, SLOT, GAP, PAD = 20, 37, 4, 12
local SCROLLBAR_W = 24
local TOP_CHROME, BOTTOM_CHROME = 80, 52

local CONTENT_W = COLS * SLOT + (COLS - 1) * GAP
local FRAME_W   = PAD * 2 + CONTENT_W + SCROLLBAR_W

local frame, content, emptyText, Grid
local typeBtns = {}
local curType, keepInteraction
local EMPTY_SNAP = { groups = {}, free = {}, numTabs = 0 }

local Refresh

-- ── Boutons ───────────────────────────────────────────────────────
local function Highlight(btn, on)
    local c = on and C.btnHoverBorder or C.btnBorder
    btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    btn.selected = on
end

local SwitchType

local function GetTypeButton(i)
    local b = typeBtns[i]
    if not b then
        b = ns.UI.Button(frame, 110, 26, "")
        b:SetScript("OnLeave", function(s) Highlight(s, s.selected) end)
        b:SetScript("OnClick", function(s) SwitchType(s.typeID) end)
        typeBtns[i] = b
    end
    return b
end

-- ── Grille ────────────────────────────────────────────────────────
local function Layout()
    local def = curType and ns.Bank.GetType(curType)
    local snap = def and ns.Bank.Get(curType) or EMPTY_SNAP

    local contentH = Grid.Render(snap, { holding = ns.Cursor.GetItemID() ~= nil, showCustom = false })
    content:SetHeight(contentH)
    emptyText:SetShown(snap.numTabs == 0)
    -- La fenêtre suit le contenu, plafonnée à la hauteur de l'écran.
    frame:SetHeight(math.min(contentH + TOP_CHROME + BOTTOM_CHROME, UIParent:GetHeight()))
end

function SwitchType(id)
    curType = id
    Refresh()
end

Refresh = function()
    local types = ns.Bank.GetTypes()

    if not (curType and ns.Bank.GetType(curType)) then
        curType = types[1] and types[1].id
    end

    -- Un seul type : pas de sélecteur.
    local showTypes = #types > 1
    for i, def in ipairs(types) do
        if not showTypes then break end
        local b = GetTypeButton(i)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + (i - 1) * 116, -44)
        b.label:SetText(ns.L(def.labelKey))
        b.typeID = def.id
        Highlight(b, def.id == curType)
        b:Show()
    end
    for i = (showTypes and #types or 0) + 1, #typeBtns do typeBtns[i]:Hide() end

    Layout()
end

-- ── Construction ──────────────────────────────────────────────────
local function Build()
    frame = ns.UI.Flat(UIParent, "bg", "border")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
    frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], C.border[4])
    _G["BagViewerLogBankFrame"] = frame
    frame:SetSize(FRAME_W, TOP_CHROME + BOTTOM_CHROME)
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("DIALOG")   -- au-dessus du chat (HIGH)
    frame:EnableMouse(true)
    frame:Hide()
    table.insert(UISpecialFrames, "BagViewerLogBankFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    title:SetText(ns.L("BANK_TITLE"))

    local close = ns.UI.Button(frame, 26, 26, "X")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    local blizz = ns.UI.Button(frame, 160, 26, ns.L("BANK_BLIZZARD"))
    blizz:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    blizz:SetScript("OnClick", function() ns.Fire("BANK_BLIZZARD_REQUESTED") end)
    local hover = blizz:GetScript("OnEnter")
    blizz:SetScript("OnEnter", function(s)
        hover(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP")
        GameTooltip:AddLine(ns.L("BANK_BLIZZARD_TIP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    local leave = blizz:GetScript("OnLeave")
    blizz:SetScript("OnLeave", function(s)
        leave(s)
        GameTooltip_Hide()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     frame, "TOPLEFT",     PAD, -TOP_CHROME)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(PAD + SCROLLBAR_W), BOTTOM_CHROME)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    IB.SetContainer(content)
    Grid = ns.UI.NewCategoryGrid({
        content = content, IB = IB, Sections = ns.UI.NewSections(),
        cols = COLS, prefix = "bank:", refresh = Refresh, usePlus = true,
    })

    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetTextColor(C.textDim[1], C.textDim[2], C.textDim[3], 1)
    emptyText:SetText(ns.L("BANK_NO_TABS"))

    frame:SetScript("OnShow", function()
        curType = nil
        ns.Bank.SetActive(true)
        Refresh()
    end)
    frame:SetScript("OnHide", function()
        ns.Bank.SetActive(false)
        IB.ReleaseAll()
        -- ÉCHAP ou X : l'interaction banquier se ferme aussi.
        if not keepInteraction and _G.BankFrame and _G.BankFrame:IsShown() then
            HideUIPanel(_G.BankFrame)
        end
        keepInteraction = false
    end)

    ns.On("BANK_CHANGED", function()
        if frame:IsShown() then Refresh() end
    end)

    -- Objet tenu au curseur ("+") et changements de classement : un seul
    -- rendu par image, même si plusieurs événements arrivent ensemble.
    local queued = false
    local function QueueLayout()
        if queued then return end
        queued = true
        C_Timer.After(0, function()
            queued = false
            if frame:IsShown() then Layout() end
        end)
    end
    for _, ev in ipairs({ "CURSOR_ITEM_CHANGED", "ASSIGN_CHANGED", "CATEGORIES_CHANGED" }) do
        ns.On(ev, QueueLayout)
    end
end

-- ── API du cadre ──────────────────────────────────────────────────
ns.UI.Bank = {}

function ns.UI.Bank.Show()
    if not frame then Build() end
    frame:Show()
end

-- keep : masque la vue sans fermer l'interaction (passage au cadre Blizzard).
function ns.UI.Bank.Hide(keep)
    if not frame then return end
    keepInteraction = keep and frame:IsShown() or false
    frame:Hide()
end

function ns.UI.Bank.IsShown()
    return frame ~= nil and frame:IsShown()
end
