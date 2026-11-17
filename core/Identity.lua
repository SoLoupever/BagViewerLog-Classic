local addonName, ns = ...

-- (nom, royaume) du perso connecté, même clé que la base ViewerLog.
-- Forever : le nom peut porter un suffixe, UnitName seul ne suffit pas.

function ns.GetPlayer()
    local vl = ns.vl
    if vl and vl.GetPlayerIdentity then
        local realm, name = vl.GetPlayerIdentity()
        if realm and name then return name, realm end
    end
    return UnitName("player"), GetRealmName()
end
