local addonName, ns = ...

-- Vue "un seul sac" : tous les emplacements des sacs réunis.

local MAIN = { id = "view_main", labelKey = "VIEW_MAIN", header = true, noAssign = true, count = ns.View.CountText }
local TOPS = { MAIN }
local out = {}

ns.View.Register({
    id = "onebag", labelKey = "VIEW_ONEBAG", order = 2,
    noFree = true, stack = false, bulk = false,
    tops   = function() return TOPS end,
    groups = function(snap)
        local _, main = ns.View.GetSlots(snap)
        out[MAIN.id] = main
        return out
    end,
})
