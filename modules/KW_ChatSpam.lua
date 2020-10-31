KW_ChatSpam = {
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

---------------------------------------------------------------------
-- UTIL
---------------------------------------------------------------------

local function stripSuffix(unitName)
    local index = string.find(unitName, "^", 1, true)
    if (index) then
        return string.sub(unitName, 1, index - 1)
    else
        return unitName
    end
end


---------------------------------------------------------------------
-- EVENT HANDLERS
---------------------------------------------------------------------

-- Print out Alkosh values in chat
-- EVENT_COMBAT_EVENT (number eventCode, number ActionResult result, boolean isError, string abilityName, number abilityGraphic, number ActionSlotType abilityActionSlotType, string sourceName, number CombatUnitType sourceType, string targetName, number CombatUnitType targetType, number hitValue, number CombatMechanicType powerType, number DamageType damageType, boolean log, number sourceUnitId, number targetUnitId, number abilityId, number overflow)
local function OnCombatAlkosh(_, _, _, abilityName, _, _, sourceName, _, targetName, _, hitValue, _, _, _, _, targetUnitId, abilityId, _)
    local targetColor = "|c999999"
    if (KW_ChatSpam.bosses[targetUnitId]) then
        targetColor = "|cFF66CC"
    end

    -- Print Alkosh values depending on if it's from yourself or others
    if (sourceName ~= nil and sourceName ~= "") then
        KyzuiWhen:dbg(string.format("Self Alkosh |c00FF00%d|r on %s%s|r", hitValue, targetColor, stripSuffix(targetName)))
        KW_ChatSpam.unitIds[targetUnitId] = targetName
    elseif (KW_ChatSpam.unitIds[targetUnitId] ~= nil) then
        KyzuiWhen:dbg(string.format("Other Alkosh |c00FFFF%d|r on %s%s|r", hitValue, targetColor, stripSuffix(KW_ChatSpam.unitIds[targetUnitId])))
    else
        KyzuiWhen:dbg(string.format("Other Alkosh |c00FFFF%d|r on %sUnknown|r", hitValue, targetColor))
    end
end

-- Print out major vulnerability invulnerability in chat
-- EVENT_EFFECT_CHANGED (number eventCode, MsgEffectResult changeType, number effectSlot, string effectName, string unitTag, number beginTime, number endTime, number stackCount, string iconName, string buffType, BuffEffectType effectType, AbilityType abilityType, StatusEffectType statusEffectType, string unitName, number unitId, number abilityId, CombatUnitType sourceType)
local function OnEffectColossus(_, changeType, _, _, unitTag, beginTime, endTime, stackCount, _, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    if (unitTag == "reticleover" and KW_ChatSpam.bosses[unitId]) then
        return -- do not display double line if reticle over a boss
    end

    local targetColor = "|c999999"
    if (string.find(unitTag, "^boss")) then
        KW_ChatSpam.bosses[unitId] = true
        targetColor = "|cFF66CC"
    end

    if (changeType == EFFECT_RESULT_GAINED) then
        KyzuiWhen:dbg(string.format("%s%s|r |cFF0000gained|r Invulnerability", targetColor, stripSuffix(unitName)))
    elseif (changeType == EFFECT_RESULT_FADED) then
        KyzuiWhen:dbg(string.format("%s%s|r |c00FF00lost|r Invulnerability", targetColor, stripSuffix(unitName)))
    end

    KW_ChatSpam.unitIds[unitId] = unitName
end

-- Use effects to cache enemy info
-- EVENT_EFFECT_CHANGED (number eventCode, MsgEffectResult changeType, number effectSlot, string effectName, string unitTag, number beginTime, number endTime, number stackCount, string iconName, string buffType, BuffEffectType effectType, AbilityType abilityType, StatusEffectType statusEffectType, string unitName, number unitId, number abilityId, CombatUnitType sourceType)
local function OnEffect(_, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, _, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
    if (changeType ~= EFFECT_RESULT_GAINED) then
        return
    end

    if (string.find(unitTag, "^boss")) then
        KW_ChatSpam.bosses[unitId] = true
    end
    KW_ChatSpam.unitIds[unitId] = unitName
end

-- EVENT_RAID_TRIAL_SCORE_UPDATE (number eventCode, RaidPointReason scoreUpdateReason, number scoreAmount, number totalScore)
local function OnScoreUpdate(_, scoreUpdateReason, scoreAmount, totalScore)
    if (KyzuiWhen.savedOptions.score.enable) then
        if (scoreUpdateReason == RAID_POINT_REASON_LIFE_REMAINING) then
            return
        end

        local reason = KW_ChatSpam.pointReason[scoreUpdateReason]
        if (not reason) then
            reason = "UNKNOWN"
        end
        KyzuiWhen:dbg(string.format("|c888888%s |cAAFFAA%d|r", reason, scoreAmount))
    end
end


---------------------------------------------------------------------
-- REGISTER
---------------------------------------------------------------------

function KW_ChatSpam.RegisterAlkosh(register)
    if (register and not KW_ChatSpam.activeEvents.alkosh) then
        -- Alkosh hit
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_ChatSpamAlkosh", EVENT_COMBAT_EVENT, OnCombatAlkosh)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "KW_ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DAMAGE)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "KW_ChatSpamAlkosh", EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, 75752)

        -- Magsteal for cache
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_ChatSpamMagsteal", EVENT_EFFECT_CHANGED, OnEffect)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "KW_ChatSpamMagsteal", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, 39100)
        KyzuiWhen:dbg("Registered Alkosh")
    elseif (not register and KW_ChatSpam.activeEvents.alkosh) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "KW_ChatSpamAlkosh", EVENT_COMBAT_EVENT)
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "KW_ChatSpamMagsteal", EVENT_EFFECT_CHANGED)
        KyzuiWhen:dbg("Unregistered Alkosh")
    end
    KW_ChatSpam.activeEvents.alkosh = register
end

function KW_ChatSpam.RegisterColossus(register)
    if (register and not KW_ChatSpam.activeEvents.colossus) then
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_ChatSpamColossus", EVENT_EFFECT_CHANGED, OnEffectColossus)
        EVENT_MANAGER:AddFilterForEvent(KyzuiWhen.name .. "KW_ChatSpamColossus", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, 132831)
        KyzuiWhen:dbg("Registered Colossus")
    elseif (not register and KW_ChatSpam.activeEvents.colossus) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "KW_ChatSpamColossus", EVENT_EFFECT_CHANGED)
        KyzuiWhen:dbg("Unregistered Colossus")
    end
    KW_ChatSpam.activeEvents.colossus = register
end

function KW_ChatSpam.RegisterScore(register)
    if (register and not KW_ChatSpam.activeEvents.score) then
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_ChatSpamScore", EVENT_RAID_TRIAL_SCORE_UPDATE, OnScoreUpdate)
        KyzuiWhen:dbg("Registered Score")
    elseif (not register and KW_ChatSpam.activeEvents.score) then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name .. "KW_ChatSpamScore", EVENT_RAID_TRIAL_SCORE_UPDATE)
        KyzuiWhen:dbg("Unregistered Score")
    end
    KW_ChatSpam.activeEvents.score = register
end


-- Block the "Item not ready yet" spam when using potion that's still on cooldown
local function SetUpAlertTextHooks()
    local handlers = ZO_AlertText_GetHandlers()

    local function OnItemOnCooldown()
        return KyzuiWhen.savedOptions.block.itemNotReady
    end

    ZO_PreHook(handlers, EVENT_ITEM_ON_COOLDOWN, OnItemOnCooldown)
end


---------------------------------------------------------------------
-- ZONE ENTERED
---------------------------------------------------------------------

function KW_ChatSpam.CheckActivation()
    local zoneId = GetZoneId(GetUnitZoneIndex("player"))
    KyzuiWhen:dbg(string.format("|cAAAAAAChecking activation... %s (%d)|r", GetZoneNameById(zoneId), zoneId))

    -- Alkosh
    if (KyzuiWhen.savedOptions.alkosh.usePreset and KW_ChatSpam.hideAlkoshZones[zoneId]) then
        KW_ChatSpam.RegisterAlkosh(false)
    else
        KW_ChatSpam.RegisterAlkosh(KyzuiWhen.savedOptions.alkosh.enable)
    end

    -- Colossus?
    if (not KyzuiWhen.savedOptions.colossus.bossOnly or DoesUnitExist("boss1")) then
        KW_ChatSpam.RegisterColossus(KyzuiWhen.savedOptions.colossus.enable)
    end

    -- Score
    KW_ChatSpam.RegisterScore(KyzuiWhen.savedOptions.score.enable)

    -- [10:08:08] [KW] Checking activation... Blackrose Prison (1082)
end

---------------------------------------------------------------------
-- INITIALIZE
---------------------------------------------------------------------

function KW_ChatSpam:Initialize()
    -- Prehooks
    SetUpAlertTextHooks()

    -- Bosses changed
    EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name .. "KW_ChatSpamBossesChanged", EVENT_BOSSES_CHANGED, function()
        if (KyzuiWhen.savedOptions.colossus.bossOnly) then
            if (DoesUnitExist("boss1")) then
                KW_ChatSpam.RegisterColossus(KyzuiWhen.savedOptions.colossus.enable)
            else
                KW_ChatSpam.RegisterColossus(false)
            end
        end
    end)

    KW_ChatSpam.CheckActivation()
end

