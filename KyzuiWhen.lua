-----------------------------------------------------------
-- KyzuiWhen
-- @author Kyzeragon
-----------------------------------------------------------

KyzuiWhen = {}
KyzuiWhen.name = "KyzuiWhen"
KyzuiWhen.version = "1.0.0"

-- Defaults
local defaultOptions = {
    general = {
        debug = true,
    },
    alkosh = {
        enable = true,
        usePreset = false,
    },
    colossus = {
        enable = true,
    },
    block = {
        itemNotReady = false,
    },
    score = {
        enable = true,
    },
}

local defaultValues = {
}

---------------------------------------------------------------------
-- Initialize 
function KyzuiWhen:Initialize()
    -- Settings and saved variables
    self.savedOptions = ZO_SavedVars:NewAccountWide("KyzuiWhenSavedVariables", 1, "Options", defaultOptions)
    self.savedValues = ZO_SavedVars:NewAccountWide("KyzuiWhenSavedVariables", 1, "Values", defaultValues)

    -- Initialize modules
    ChatSpam:Initialize()

    KyzuiWhen:dbg("KyzUI when???")
end
 
---------------------------------------------------------------------
-- On Load
function KyzuiWhen.OnAddOnLoaded(_, addonName)
    if addonName == KyzuiWhen.name then
        EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name, EVENT_ADD_ON_LOADED)
        EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name, EVENT_PLAYER_ACTIVATED, KyzuiWhen.OnPlayerActivated)
        KyzuiWhen:Initialize()
    end
end
 
EVENT_MANAGER:RegisterForEvent(KyzuiWhen.name, EVENT_ADD_ON_LOADED, KyzuiWhen.OnAddOnLoaded)

---------------------------------------------------------------------
-- Post Load (player loaded)
function KyzuiWhen.OnPlayerActivated(_, initial)
    -- Every time player loads, check the event activations
    ChatSpam.CheckActivation()

    -- Soft dependency on pChat because its chat restore will overwrite
    for i = 1, #KyzuiWhen.messages do
        d("|c34EB61[KWdelay]|r " .. KyzuiWhen.messages[i])
    end
    KyzuiWhen.messages = {}
end

-- Collect messages for displaying later when addon is not fully loaded
KyzuiWhen.messages = {}
function KyzuiWhen:dbg(msg)
    if (not msg) then return end
    if (not KyzuiWhen.savedOptions.general.debug) then return end
    if (CHAT_SYSTEM.primaryContainer) then
        d("|c34EB61[KW]|r " .. msg)
    else
        KyzuiWhen.messages[#KyzuiWhen.messages + 1] = msg
    end
end

---------------------------------------------------------------------
-- Commands
function KyzuiWhen.handleCommand(argString)
    local args = {}
    local length = 0
    for word in argString:gmatch("%S+") do
        table.insert(args, word)
        length = length + 1
    end

    if (length == 0) then
        KyzuiWhen:dbg("Usage: /kw <command>")
        KyzuiWhen:dbg(string.format("debug: %s", KyzuiWhen.savedOptions.general.debug and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("alkosh: %s", KyzuiWhen.savedOptions.alkosh.enable and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("    usepreset: %s", KyzuiWhen.savedOptions.alkosh.usePreset and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("colossus: %s", KyzuiWhen.savedOptions.colossus.enable and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("itemnotready: %s", KyzuiWhen.savedOptions.block.itemNotReady and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("score: %s", KyzuiWhen.savedOptions.score.enable and "|c00FF00on|r" or "|cFF0000off|r"))
        return
    end

    -- Toggle debug
    if (args[1] == "debug") then
        KyzuiWhen.savedOptions.general.debug = not KyzuiWhen.savedOptions.general.debug
        KyzuiWhen:dbg("Debug (more like all printing) is now " .. tostring(KyzuiWhen.savedOptions.general.debug))

    -- Toggle alkosh
    elseif (args[1] == "alkosh") then
        if (length == 2 and args[2] == "usepreset") then
            KyzuiWhen.savedOptions.alkosh.usePreset = not KyzuiWhen.savedOptions.alkosh.usePreset
            KyzuiWhen:dbg("Alkosh using preset is now " .. tostring(KyzuiWhen.savedOptions.alkosh.usePreset))
            return
        end
        KyzuiWhen.savedOptions.alkosh.enable = not KyzuiWhen.savedOptions.alkosh.enable
        KyzuiWhen:dbg("Alkosh value chat spam is now " .. tostring(KyzuiWhen.savedOptions.alkosh.enable))
        ChatSpam.RegisterAlkosh(KyzuiWhen.savedOptions.alkosh.enable)

    -- Toggle colossus
    elseif (args[1] == "colossus") then
        KyzuiWhen.savedOptions.colossus.enable = not KyzuiWhen.savedOptions.colossus.enable
        KyzuiWhen:dbg("Colossus invulnerability chat spam is now " .. tostring(KyzuiWhen.savedOptions.colossus.enable))
        ChatSpam.RegisterColossus(KyzuiWhen.savedOptions.colossus.enable)

    -- Toggle itemNotReady
    elseif (args[1] == "itemnotready") then
        KyzuiWhen.savedOptions.block.itemNotReady = not KyzuiWhen.savedOptions.block.itemNotReady
        KyzuiWhen:dbg("Blocking \"Item not ready yet\" alert is now " .. tostring(KyzuiWhen.savedOptions.block.itemNotReady))

    -- Toggle score
    elseif (args[1] == "score") then
        KyzuiWhen.savedOptions.score.enable = not KyzuiWhen.savedOptions.score.enable
        KyzuiWhen:dbg("Score chat spam is now " .. tostring(KyzuiWhen.savedOptions.score.enable))
        ChatSpam.RegisterScore(KyzuiWhen.savedOptions.score.enable)

    -- Unknown
    else
        KyzuiWhen:dbg("Usage: /kw <debug>")
    end
end

SLASH_COMMANDS["/kw"] = KyzuiWhen.handleCommand
