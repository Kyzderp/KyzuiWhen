ChatSpam = {
    activeEvents = {
        alkosh = false,
        colossus = false,
        score = false,
    },

    unitIds = {}, -- Attempt to cache unitIds to see what units get Alkosh/etc
    bosses = {}, -- Cache which unitIds are bosses for coloring

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

    -- My personal preset for Alkosh spam. Hides the Alkosh spam in these zone IDs
    hideAlkoshZones = {
        [1082] = true, -- Blackrose Prison
    },
}

function ChatSpam:Initialize()
    KyzuiWhen:dbg("    Initializing ChatSpam module...")

    -- Prehooks
    ChatSpam.SetUpAlertTextHooks()

    -- Bosses changed
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamBossesChanged", EVENT_BOSSES_CHANGED, function()
        if (KyzuiWhen.savedOptions.colossus.bossOnly) then
            if (DoesUnitExist("boss1")) then
                ChatSpam.RegisterColossus(KyzuiWhen.savedOptions.colossus.enable)
            else
                ChatSpam.RegisterColossus(false)
            end
        end
    end)

    ChatSpam.CheckActivation()
end

function ChatSpam.CheckActivation()
    local zoneId = GetZoneId(GetUnitZoneIndex("player"))
    KyzuiWhen:dbg(string.format("|cAAAAAAChecking activation... %s (%d)|r", GetZoneNameById(zoneId), zoneId))

    -- Alkosh
    if (KyzuiWhen.savedOptions.alkosh.usePreset and ChatSpam.hideAlkoshZones[zoneId]) then
        ChatSpam.RegisterAlkosh(false)
    else
        ChatSpam.RegisterAlkosh(KyzuiWhen.savedOptions.alkosh.enable)
    end

    -- Colossus?
    if (not KyzuiWhen.savedOptions.colossus.bossOnly or DoesUnitExist("boss1")) then
        ChatSpam.RegisterColossus(KyzuiWhen.savedOptions.colossus.enable)
    end

    -- Score
    ChatSpam.RegisterScore(KyzuiWhen.savedOptions.score.enable)
end

function ChatSpam.RegisterAlkosh(register)
    if (register and not ChatSpam.activeEvents.alkosh) then
        -- Alkosh hit
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, ChatSpam.OnCombatAlkosh)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DAMAGE)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 75752)

        -- Magsteal for cache
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamMagsteal", EVENT_EFFECT_CHANGED, ChatSpam.OnEffect)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamMagsteal", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, 39100)
        KyzuiWhen:dbg("Registered Alkosh")
    elseif (not register and ChatSpam.activeEvents.alkosh) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "ChatSpamAlkosh", EVENT_COMBAT_EVENT)
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "ChatSpamMagsteal", EVENT_EFFECT_CHANGED)
        KyzuiWhen:dbg("Unregistered Alkosh")
    end
    ChatSpam.activeEvents.alkosh = register
end

function ChatSpam.RegisterColossus(register)
    if (register and not ChatSpam.activeEvents.colossus) then
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamColossus", EVENT_EFFECT_CHANGED, ChatSpam.OnEffectColossus)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "ChatSpamColossus", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, 132831)
        KyzuiWhen:dbg("Registered Colossus")
    elseif (not register and ChatSpam.activeEvents.colossus) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "ChatSpamColossus", EVENT_EFFECT_CHANGED)
        KyzuiWhen:dbg("Unregistered Colossus")
    end
    ChatSpam.activeEvents.colossus = register
end

function ChatSpam.RegisterScore(register)
    if (register and not ChatSpam.activeEvents.score) then
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "ChatSpamScore", EVENT_RAID_TRIAL_SCORE_UPDATE, ChatSpam.OnScoreUpdate)
        KyzuiWhen:dbg("Registered Score")
    elseif (not register and ChatSpam.activeEvents.score) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "ChatSpamScore", EVENT_RAID_TRIAL_SCORE_UPDATE)
        KyzuiWhen:dbg("Unregistered Score")
    end
    ChatSpam.activeEvents.score = register
end

-- Print out Alkosh values in chat
-- EVENT_COMBAT_EVENT (number eventCode, number ActionResult result, boolean isError, string abilityName, number abilityGraphic, number ActionSlotType abilityActionSlotType, string sourceName, number CombatUnitType sourceType, string targetName, number CombatUnitType targetType, number hitValue, number CombatMechanicType powerType, number DamageType damageType, boolean log, number sourceUnitId, number targetUnitId, number abilityId, number overflow)
function ChatSpam.OnCombatAlkosh(_, _, _, abilityName, _, _, sourceName, _, targetName, _, hitValue, _, _, _, _, targetUnitId, abilityId, _)
    local targetColor = "|c999999"
    if (ChatSpam.bosses[targetUnitId]) then
        targetColor = "|cFF66CC"
    end

    -- Print Alkosh values depending on if it's from yourself or others
    if (sourceName ~= nil and sourceName ~= "") then
        KyzuiWhen:dbg(string.format("Self Alkosh |c00FF00%d|r on %s%s|r", hitValue, targetColor, ChatSpam.stripSuffix(targetName)))
        ChatSpam.unitIds[targetUnitId] = targetName
    elseif (ChatSpam.unitIds[targetUnitId] ~= nil) then
        KyzuiWhen:dbg(string.format("Other Alkosh |c00FFFF%d|r on %s%s|r", hitValue, targetColor, ChatSpam.stripSuffix(ChatSpam.unitIds[targetUnitId])))
    else
        KyzuiWhen:dbg(string.format("Other Alkosh |c00FFFF%d|r on %sUnknown|r", hitValue, targetColor))
    end
end

-- Print out major vulnerability invulnerability in chat
-- EVENT_EFFECT_CHANGED (number eventCode, MsgEffectResult changeType, number effectSlot, string effectName, string unitTag, number beginTime, number endTime, number stackCount, string iconName, string buffType, BuffEffectType effectType, AbilityType abilityType, StatusEffectType statusEffectType, string unitName, number unitId, number abilityId, CombatUnitType sourceType)
function ChatSpam.OnEffectColossus(_, changeType, _, _, unitTag, beginTime, endTime, stackCount, _, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    if (unitTag == "reticleover" and ChatSpam.bosses[unitId]) then
        return -- do not display double line if reticle over a boss
    end

    local targetColor = "|c999999"
    if (string.find(unitTag, "^boss")) then
        ChatSpam.bosses[unitId] = true
        targetColor = "|cFF66CC"
    end

    if (changeType == EFFECT_RESULT_GAINED) then
        KyzuiWhen:dbg(string.format("%s%s|r |cFF0000gained|r Invulnerability", targetColor, ChatSpam.stripSuffix(unitName)))
    elseif (changeType == EFFECT_RESULT_FADED) then
        KyzuiWhen:dbg(string.format("%s%s|r |c00FF00lost|r Invulnerability", targetColor, ChatSpam.stripSuffix(unitName)))
    end

    ChatSpam.unitIds[unitId] = unitName
end

-- Use effects to cache enemy info
-- EVENT_EFFECT_CHANGED (number eventCode, MsgEffectResult changeType, number effectSlot, string effectName, string unitTag, number beginTime, number endTime, number stackCount, string iconName, string buffType, BuffEffectType effectType, AbilityType abilityType, StatusEffectType statusEffectType, string unitName, number unitId, number abilityId, CombatUnitType sourceType)
function ChatSpam.OnEffect(_, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, _, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    if (changeType ~= EFFECT_RESULT_GAINED) then
        return
    end

    if (string.find(unitTag, "^boss")) then
        ChatSpam.bosses[unitId] = true
    end
    ChatSpam.unitIds[unitId] = unitName
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

        KyzuiWhen:dbg(string.format("|c888888%s |cAAFFAA%d|r", ChatSpam.pointReason[scoreUpdateReason], scoreAmount))
    end
end

function ChatSpam.stripSuffix(unitName)
    local index = string.find(unitName, "^", 1, true)
    if (index) then
        return string.sub(unitName, 1, index - 1)
    else
        return unitName
    end
end
