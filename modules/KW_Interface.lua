KW_Interface = {}

function KW_Interface:Initialize()
    -- in-combat reticle
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_InterfaceCombat", EVENT_PLAYER_COMBAT_STATE, KW_Interface.OnCombatStateChanged)
end

-- EVENT_PLAYER_COMBAT_STATE (number eventCode, boolean inCombat)
function KW_Interface.OnCombatStateChanged(_, inCombat)
    if (KyzuiWhen.savedOptions.reticle.enable) then
        if (inCombat) then
            -- KyzuiWhen:dbg("entered combat")
            KW_Interface.SetReticleColor({1,0,0,1})
        else
            -- KyzuiWhen:dbg("exited combat")
            KW_Interface.SetReticleColor({1,1,1,1})
        end
    end
end

function KW_Interface.SetReticleColor(color, inCombat)
    ZO_ReticleContainerReticle:SetColor(unpack(color))
    ZO_ReticleContainerReticle.animation:SetEndColor(unpack(color))
    ZO_ReticleContainerStealthIconStealthEye:SetColor(unpack(color))
end