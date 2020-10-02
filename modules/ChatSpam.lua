ChatSpam = {
    units = {}, -- Attempt to cache unitIds to see what units get Alkosh/etc
}

function ChatSpam:Initialize()
    KyzuiWhen:dbg("    Initializing ChatSpam module...")

    -- Alkosh?
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, ChatSpam.OnCombatAlkosh)
    EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DAMAGE)
    EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 75752)

    -- Colossus?
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamColossus", EVENT_EFFECT_CHANGED, ChatSpam.OnEffectColossus)
    EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamColossus", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, 132831)

    -- Prehooks
    ChatSpam.SetUpAlertTextHooks()
end

-- Print out Alkosh values in chat
-- EVENT_COMBAT_EVENT (number eventCode, number ActionResult result, boolean isError, string abilityName, number abilityGraphic, number ActionSlotType abilityActionSlotType, string sourceName, number CombatUnitType sourceType, string targetName, number CombatUnitType targetType, number hitValue, number CombatMechanicType powerType, number DamageType damageType, boolean log, number sourceUnitId, number targetUnitId, number abilityId, number overflow)
function ChatSpam.OnCombatAlkosh(_, _, _, abilityName, _, _, sourceName, _, targetName, _, hitValue, _, _, _, sourceUnitId, targetUnitId, abilityId, _)
    if (not KyzuiWhen.savedOptions.alkosh.enable) then
        return
    end

    -- Print Alkosh values depending on if it's from yourself or others
    if (sourceName ~= nil and sourceName ~= "") then
        KyzuiWhen:dbg(string.format("Self Alkosh |c00FF00%d|r on |c999999%s (%d)|r", hitValue, targetName, targetUnitId))
        ChatSpam.units[targetUnitId] = targetName
    elseif (ChatSpam.units[targetUnitId] ~= nil) then
        KyzuiWhen:dbg(string.format("Other (%d) Alkosh |c00FFFF%d|r on |c999999%s (%d)|r", sourceUnitId, hitValue, ChatSpam.units[targetUnitId], targetUnitId))
    else
        KyzuiWhen:dbg(string.format("Other (%d) Alkosh |c00FFFF%d|r on |c999999Unknown (%d)|r", sourceUnitId, hitValue, targetUnitId))
    end
end

-- Print out major vulnerability invulnerability in chat
-- EVENT_EFFECT_CHANGED (number eventCode, MsgEffectResult changeType, number effectSlot, string effectName, string unitTag, number beginTime, number endTime, number stackCount, string iconName, string buffType, BuffEffectType effectType, AbilityType abilityType, StatusEffectType statusEffectType, string unitName, number unitId, number abilityId, CombatUnitType sourceType)
function ChatSpam.OnEffectColossus(_, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, _, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    if (not KyzuiWhen.savedOptions.colossus.enable) then
        return
    end

    -- KyzuiWhen:dbg(string.format("changeType %d, effectSlot %d, effectName %s, unitTag %s, beginTime %d, endTime %d, stackCount %d, buffType %s, effectType %d, abilityType %d, statusEffectType %d, unitName %s, unitId %s, abilityId %d, sourceType %d, abilityName %s", changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType, GetAbilityName(abilityId)))
    if (changeType == EFFECT_RESULT_GAINED) then
        KyzuiWhen:dbg(string.format("|c999999%s (%d)|r |cFF0000gained|r Invulnerability", unitName, unitId))
    elseif (changeType == EFFECT_RESULT_FADED) then
        KyzuiWhen:dbg(string.format("|c999999%s (%d)|r |c00FF00lost|r Invulnerability", unitName, unitId))
    end

    ChatSpam.units[unitId] = unitName


    -- [16:55:01] changeType 1, effectSlot 115, effectName Major Vulnerability Invulnerability, unitTag boss1, beginTime 2145, endTime 2165, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Shademother^F, unitId 5601, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:01] changeType 1, effectSlot 115, effectName Major Vulnerability Invulnerability, unitTag reticleover, beginTime 2145, endTime 2165, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Shademother^F, unitId 5601, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:03] changeType 1, effectSlot 80, effectName Major Vulnerability Invulnerability, unitTag , beginTime 2147, endTime 2167, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Skeletal Dire Wolf^n, unitId 43086, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:03] changeType 1, effectSlot 80, effectName Major Vulnerability Invulnerability, unitTag , beginTime 2147, endTime 2167, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Skeletal Dire Wolf^n, unitId 18955, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity

    -- [16:55:04] changeType 2, effectSlot 80, effectName Major Vulnerability Invulnerability, unitTag , beginTime 0, endTime 0, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Skeletal Dire Wolf^n, unitId 43086, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:04] changeType 2, effectSlot 80, effectName Major Vulnerability Invulnerability, unitTag , beginTime 0, endTime 0, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Skeletal Dire Wolf^n, unitId 18955, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:21] changeType 2, effectSlot 115, effectName Major Vulnerability Invulnerability, unitTag boss1, beginTime 0, endTime 0, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Shademother^F, unitId 5601, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity
    -- [16:55:21] changeType 2, effectSlot 115, effectName Major Vulnerability Invulnerability, unitTag reticleover, beginTime 0, endTime 0, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName Shademother^F, unitId 5601, abilityId 132831, sourceType 1, abilityName Major Vulnerability Immunity


    -- group member Colossus, look when fading
    -- [17:10:11] changeType 1, effectSlot 77, effectName Major Vulnerability Invulnerability, unitTag , beginTime 3055, endTime 3075, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName The Precursor, unitId 63074, abilityId 132831, sourceType 3, abilityName Major Vulnerability Immunity
    -- [17:10:23] changeType 2, effectSlot 77, effectName Major Vulnerability Invulnerability, unitTag reticleover, beginTime 0, endTime 0, stackCount 0, buffType , effectType 2, abilityType 0, statusEffectType 0, unitName The Precursor, unitId 63074, abilityId 132831, sourceType 3, abilityName Major Vulnerability Immunity
end

function ChatSpam.SetUpAlertTextHooks()
    local handlers = ZO_AlertText_GetHandlers()

    local function OnItemOnCooldown()
        return KyzuiWhen.savedOptions.block.itemNotReady
    end

    ZO_PreHook(handlers, EVENT_ITEM_ON_COOLDOWN, OnItemOnCooldown)
end