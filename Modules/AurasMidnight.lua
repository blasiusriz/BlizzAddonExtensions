local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local BAE = BlizzAddonExtensions
local db
local playerAuraFrameCache = {}
local _, _, _, toc = GetBuildInfo()
local settings = {}


local function ResetAurasSettings()
    settings.x = 100
    settings.y = -100
    settings.size = 40
    settings.maxIconsPerRow = 3
    settings.padding = 5

    if playerAuraFrameCache[1] then
        playerAuraFrameCache[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x, settings.y)
        for _, frame in ipairs(playerAuraFrameCache) do        
            frame:SetSize(settings.size, settings.size)
        end    
    end    
end

local function LoadAurasSettings()
    settings.x = db.x or 100
    settings.y = db.y or -100
    settings.size = db.size or 32
    settings.maxIconsPerRow = db.maxIconsPerRow or 6
    settings.padding = db.padding or 5
end

local function SaveAurasSettings()
    db.x = settings.x
    db.y = settings.y
    db.size = settings.size
    db.maxIconsPerRow = settings.maxIconsPerRow
    db.padding = settings.padding

    if playerAuraFrameCache[1] then
        playerAuraFrameCache[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x, settings.y)
        for _, frame in ipairs(playerAuraFrameCache) do        
            frame:SetSize(settings.size, settings.size)
        end    
    end    
end

function module:OnLoad()

end

function module:OnAddonLoaded()
	if not _Auras then
		_Auras = {}
		BlizzAddonExtensions:Print("Initializing Auras DB")
	end
    db = _Auras

	-- restore saved position if available or revert to initial values
	LoadAurasSettings()

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if unit == "player" then
            -- BAE.Utilities.DumpAuraInfo(info, unit)
            for i=1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL|PLAYER")
                if aura then
                    local auraFrame = playerAuraFrameCache[i] or BAE.Utilities.CreateAuraFrame(playerAuraFrameCache, settings)
                    BAE.Utilities.UpdateAuraFrame(auraFrame, aura)
                else
                    local auraFrame = playerAuraFrameCache[i]
                    BAE.Utilities.HideFrame(auraFrame)
                end
            end
        end
    end)

    BlizzAddonExtensions:Print("Auras for Midnight initialized")  
end

function module:OnEnable()	

end

function module:OnCommand(cmd, args)
    if cmd == "aurassetx" then
		settings.x = args or 0
		SaveAurasSettings()
        BlizzAddonExtensions:Print("Auras X set to: " .. settings.x)
	elseif cmd == "aurassety" then		
		settings.y = args or 0
		SaveAurasSettings()
        BlizzAddonExtensions:Print("Auras Y set to: " .. settings.y)
	elseif cmd == "auraspadding" then		
		settings.padding = args or 0
		SaveAurasSettings()
        BlizzAddonExtensions:Print("Auras Padding set to: " .. settings.padding)
	elseif cmd == "aurassize" then		
		settings.size = args or 0
		SaveAurasSettings()
        BlizzAddonExtensions:Print("Auras Size set to: " .. settings.size)                
	elseif cmd == "aurasreset" then
		ResetAurasSettings()
		SaveAurasSettings()
        BlizzAddonExtensions:Print("Auras reset.")
		PrintAurasSettings()
    end
end

if toc >= 120000 then
    BlizzAddonExtensions:RegisterModule("AurasMidnight", module)
end