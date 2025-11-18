-- Core file that handles initialization, module registration, and slash commands
BlizzAddonExtensions = {}
local BAE = BlizzAddonExtensions
BAE.modules = {}

function BAE:RegisterModule(name, module)
    if not name or not module then return end
    self.modules[name] = module
    if module.OnLoad then module:OnLoad() end
end

function BAE:Print(msg)
    print("|cff00ccffBlizzAddonExtensions:|r " .. tostring(msg))
end

local function InitializeModules()
    for name, module in pairs(BAE.modules) do
        if module.OnEnable then module:OnEnable() end
    end
    BAE:Print("All modules initialized run.")
end

local function OnAddonLoaded()
    for name, module in pairs(BAE.modules) do
        if module.OnAddonLoaded then module:OnAddonLoaded() end
    end
    BAE:Print("All modules loaded.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BlizzAddonExtensions" then			
        BAE:Print("Loaded successfully.")
				
		-- Modules On Addon Loaded
		OnAddonLoaded()
    elseif event == "PLAYER_LOGIN" then
        InitializeModules()
    end
end)

-- Slash command for general control
SLASH_BAE1 = "/bae"
SlashCmdList["BAE"] = function(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
    cmd = cmd:lower():trim()
    args = args:trim()

    if cmd == "list" then
        BAE:Print("Loaded modules:")
        for name in pairs(BAE.modules) do
            print(" - " .. name)
        end
    elseif cmd == "help" then
        BAE:Print("Commands: /bae list | /bae targetCastBarSetX . | /bae targetCastBarSetY . | /bae targetCastBarSetScale . | /bae targetCastBarReset")       
    else
        -- pass commands to modules that support them
        for _, module in pairs(BAE.modules) do
            if module.OnCommand then module:OnCommand(cmd, args) end
        end
    end
end

if not string.trim then
    function string.trim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
end