ChatSpam = {
    units = {}, -- Attempt to cache unitIds to see what units get Alkosh/etc

    pointReason = {
        [0]  = "KILL_NOXP_MONSTER",
        [1]  = "KILL_NORMAL_MONSTER",
        [2]  = "KILL_BANNERMEN",
        [3]  = "KILL_CHAMPION",
        [4]  = "KILL_MINIBOSS",
        [5]  = "KILL_BOSS",
        [6]  = "BONUS_ACTIVITY_LOW",
        [7]  = "BONUS_ACTIVITY_MEDIUM",
        [8]  = "BONUS_ACTIVITY_HIGH",
        [9]  = "LIFE_REMAINING",
        [10] = "BONUS_POINT_ONE",
        [11] = "BONUS_POINT_TWO",
        [12] = "BONUS_POINT_THREE",
        [13] = "SOLO_ARENA_PICKUP_ONE",
        [14] = "SOLO_ARENA_PICKUP_TWO",
        [15] = "SOLO_ARENA_PICKUP_THREE",
        [16] = "SOLO_ARENA_PICKUP_FOUR",
        [17] = "SOLO_ARENA_COMPLETE",
    },
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

    -- Score
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamScore", EVENT_RAID_TRIAL_SCORE_UPDATE, ChatSpam.OnScoreUpdate)
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

    if (changeType == EFFECT_RESULT_GAINED) then
        KyzuiWhen:dbg(string.format("|c999999%s (%d)|r |cFF0000gained|r Invulnerability", unitName, unitId))
    elseif (changeType == EFFECT_RESULT_FADED) then
        KyzuiWhen:dbg(string.format("|c999999%s (%d)|r |c00FF00lost|r Invulnerability", unitName, unitId))
    end

    ChatSpam.units[unitId] = unitName
end

-- Block the "Item not ready yet" spam when using potion that's still on cooldown
function ChatSpam.SetUpAlertTextHooks()
    local handlers = ZO_AlertText_GetHandlers()

    local function OnItemOnCooldown()
        return KyzuiWhen.savedOptions.block.itemNotReady
    end

    ZO_PreHook(handlers, EVENT_ITEM_ON_COOLDOWN, OnItemOnCooldown)
end

-- EVENT_RAID_TRIAL_SCORE_UPDATE (number eventCode, RaidPointReason scoreUpdateReason, number scoreAmount, number totalScore)
function ChatSpam.OnScoreUpdate(_, scoreUpdateReason, scoreAmount, totalScore)
    if (KyzuiWhen.savedOptions.score.enable) then
        if (scoreUpdateReason == RAID_POINT_REASON_LIFE_REMAINING) then
            return
        end

        KyzuiWhen:dbg(string.format("|c888888Score +|cAAAAAA%d |c888888%s|r", scoreAmount, ChatSpam.pointReason[scoreUpdateReason]))
    end
end
