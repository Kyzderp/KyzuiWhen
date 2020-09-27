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
    },
    colossus = {
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
    EVENT_MANAGER:UnregisterForEvent(KyzuiWhen.name, EVENT_PLAYER_ACTIVATED)

    -- Soft dependency on pChat because its chat restore will overwrite
    for i = 1, #KyzuiWhen.messages do
        d(KyzuiWhen.messages[i])
    end
    KyzuiWhen.messages = {}
end

-- Collect messages for displaying later when addon is not fully loaded
KyzuiWhen.messages = {}
function KyzuiWhen:dbg(msg)
    if (not msg) then return end
    if (not KyzuiWhen.savedOptions.general.debug) then return end
    if (CHAT_SYSTEM.primaryContainer) then
        d("[KW] " .. msg)
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
        KyzuiWhen:dbg("Usage: /kw <show||debug||alkosh||colossus>")
        return
    end

    -- ez print the stuff
    if (args[1] == "show") then
        KyzuiWhen:dbg(string.format("All debug: %s", KyzuiWhen.savedOptions.general.debug and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("Alkosh: %s", KyzuiWhen.savedOptions.alkosh.enable and "|c00FF00on|r" or "|cFF0000off|r"))
        KyzuiWhen:dbg(string.format("Colossus: %s", KyzuiWhen.savedOptions.colossus.enable and "|c00FF00on|r" or "|cFF0000off|r"))

    -- Toggle debug
    elseif (args[1] == "debug") then
        KyzuiWhen.savedOptions.general.debug = not KyzuiWhen.savedOptions.general.debug
        KyzuiWhen:dbg("Debug (more like all printing) is now " .. tostring(KyzuiWhen.savedOptions.general.debug))

    -- Toggle alkosh
    elseif (args[1] == "alkosh") then
        KyzuiWhen.savedOptions.alkosh.enable = not KyzuiWhen.savedOptions.alkosh.enable
        KyzuiWhen:dbg("Alkosh value chat spam is now " .. tostring(KyzuiWhen.savedOptions.alkosh.enable))

    -- Toggle colossus
    elseif (args[1] == "colossus") then
        KyzuiWhen.savedOptions.colossus.enable = not KyzuiWhen.savedOptions.colossus.enable
        KyzuiWhen:dbg("Colossus invulnerability chat spam is now " .. tostring(KyzuiWhen.savedOptions.colossus.enable))

    -- Unknown
    else
        KyzuiWhen:dbg("Usage: /kw <debug>")
    end
end

SLASH_COMMANDS["/kw"] = KyzuiWhen.handleCommand
