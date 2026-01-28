local module = {}
local BAE = BlizzAddonExtensions
local db
local playerMissingBuffsFrameCache = {}
local _, _, _, toc = GetBuildInfo()
local settings = {}

local weaponFrame
local flasksFrame
local foodFrame

local weaponEnchantInfo = {
    7495, -- Algari Mana Oil
    6498  -- Living Weapon
}
local weaponOils = {
    451869  -- Algari Mana Oil
}
local flasks = {
    432021,  -- Flask of Alchemical Chaos
    431972   -- FLask of ...
}   
local food = {
    462180  -- Hearty Beledar's Bounty
}

local function PlayerAuraExists(auraList)
    for _, spellID in ipairs(auraList) do        
        if C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
            return true
        end
    end
    return false
end

local function WeaponEnchantExists(auraList)
    local mainEnchant, mainExpiration, mainCharges, mainID, offEnchant, offExpiration, offCharges, offID = GetWeaponEnchantInfo()

    if mainEnchant then
        for _, spellID in ipairs(auraList) do        
            if spellID == mainID then
                return true
            end
        end
    end

    if mainEnchant then
        print("Main Weapon enchanted with Enchant ID", mainID, "consider adding it to whitelist")
    end

    return false
end

local function CheckMissingBuffs()
    if not WeaponEnchantExists(weaponEnchantInfo) then
        weaponFrame:Show()
    else
        weaponFrame:Hide()
    end
    if not PlayerAuraExists(flasks) then
        flasksFrame:Show()
    else
        flasksFrame:Hide()
    end
    if not PlayerAuraExists(food) then
        foodFrame:Show()
    else
        foodFrame:Hide()
    end
end

local function HideAllBuffFrames()
    weaponFrame:Hide()
    flasksFrame:Hide()
    foodFrame:Hide()
end

local function CreateMissingBuffFrame(spellId, settings)
    local frame = BAE.Utilities.CreateAuraFrame(playerMissingBuffsFrameCache, settings, "HORIZONTAL")
    local texture = _G.C_Spell.GetSpellTexture(spellId)
    frame.icon:SetTexture(texture)   
    return frame
end

local function CreateMissingBuffsFrames()
    weaponFrame = CreateMissingBuffFrame(weaponOils[1], settings)
    flasksFrame = CreateMissingBuffFrame(flasks[1], settings)
    foodFrame = CreateMissingBuffFrame(food[1], settings)     
end

local function ResetMissingBuffsSettings()
    settings.x = 10
    settings.y = -10
    settings.size = 40
    settings.maxIconsPerRow = 3
    settings.padding = 5

    playerMissingBuffsFrameCache[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x, settings.y)
    for _, frame in ipairs(playerMissingBuffsFrameCache) do        
        frame:SetSize(settings.size, settings.size)
    end    
end

local function LoadMissingBuffsSettings()
    settings.x = db.x or 10
    settings.y = db.y or -10
    settings.size = db.size or 40
    settings.maxIconsPerRow = db.maxIconsPerRow or 3
    settings.padding = db.padding or 5
end

local function SaveMissingBuffsSettings()
    db.x = settings.x
    db.y = settings.y
    db.size = settings.size
    db.maxIconsPerRow = settings.maxIconsPerRow
    db.padding = settings.padding

    playerMissingBuffsFrameCache[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x, settings.y)
    for _, frame in ipairs(playerMissingBuffsFrameCache) do        
        frame:SetSize(settings.size, settings.size)
    end    
end

local function PrintMissingBuffsSettings()
	print("Missing Buffs X: " .. settings.x .. ", Y: " .. settings.y .. ", Size: " .. settings.size .. ", Padding: " .. settings.padding)
end

function module:OnLoad()

end

function module:OnAddonLoaded()
	if not _MissingBuffs then
		_MissingBuffs = {}
		BlizzAddonExtensions:Print("Initializing MissingBuffs DB")
	end
    db = _MissingBuffs

	-- restore saved position if available or revert to initial values
	LoadMissingBuffsSettings()

    local frame = CreateFrame("Frame")
    CreateMissingBuffsFrames()

    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if BAE.Utilities.IsInInstance() then
            if event == "UNIT_AURA" and unit == "player" then
                if not BAE.Utilities.IsPlayerInCombat() then
                    CheckMissingBuffs()
                end
            elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
                CheckMissingBuffs()
            elseif event == "PLAYER_REGEN_DISABLED" then
                HideAllBuffFrames()           
            end
        else
            HideAllBuffFrames()
        end
    end)

    BlizzAddonExtensions:Print("MissingBuffs initialized")  
end

function module:OnEnable()	

end

function module:OnCommand(cmd, args)
    if cmd == "missingbuffssetx" then
		settings.x = args or 0
		SaveMissingBuffsSettings()
        BlizzAddonExtensions:Print("Missing Buffs X set to: " .. settings.x)
	elseif cmd == "missingbuffssety" then		
		settings.y = args or 0
		SaveMissingBuffsSettings()
        BlizzAddonExtensions:Print("Missing Buffs Y set to: " .. settings.y)
	elseif cmd == "missingbuffspadding" then		
		settings.padding = args or 0
		SaveMissingBuffsSettings()
        BlizzAddonExtensions:Print("Missing Buffs Padding set to: " .. settings.padding)
	elseif cmd == "missingbuffssize" then		
		settings.size = args or 0
		SaveMissingBuffsSettings()
        BlizzAddonExtensions:Print("Missing Buffs Size set to: " .. settings.size)                
	elseif cmd == "missingbuffsreset" then
		ResetMissingBuffsSettings()
		SaveMissingBuffsSettings()
        BlizzAddonExtensions:Print("Missing buffs reset.")
		PrintMissingBuffsSettings()
    end
end

if toc >= 120000 then
    BlizzAddonExtensions:RegisterModule("MissingBuffs", module)
end