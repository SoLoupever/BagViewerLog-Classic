local addonName, ns = ...

-- Capacités du client, détectées par globals (pas par numéro de version).
-- modernBags : UI de sacs "moderne" (Forever) ; sinon UI Classic historique.

local modern = _G.ContainerFrameItemButtonMixin ~= nil

ns.Env = {
    modernBags = modern,
    canSort    = modern and type(C_Container.SortBags) == "function",
}
