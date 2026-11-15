local addonName, ns = ...

-- Réglages dans BagViewerLogDB (SavedVariables propre : l'API Classic n'a pas
-- de stockage par module).

local DEFAULTS = {}

ns.Settings = {}

local function Store()
    local db = _G.BagViewerLogDB
    if not db then
        db = {}
        _G.BagViewerLogDB = db
    end
    return db
end

function ns.Settings.Get(key)
    local v = Store()[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

function ns.Settings.Set(key, value)
    Store()[key] = value
end

-- Sous-table persistante, créée à la demande.
function ns.Settings.Table(key)
    local s = Store()
    s[key] = s[key] or {}
    return s[key]
end
