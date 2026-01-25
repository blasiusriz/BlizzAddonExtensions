local module = {}
local BAE = BlizzAddonExtensions
local db
local playerMissingBuffsFrameCache = {}
local _, _, _, toc = GetBuildInfo()

local weaponFrame
local flasksFrame
local foodFrame

local weaponEnchantInfo = {
    7495  -- Algari Mana Oil
}
local weaponOils = {
    451869  -- Algari Mana Oil
}
local flasks = {
    432021  -- Flask of Alchemical Chaos
}   
local food = {
    457482  -- Hearty Beledar's Bounty
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
    -- print("Main Enchant:", tostring(mainEnchant))
    -- print("Main Enchant ID:", mainID)   
    if mainEnchant then
        for _, spellID in ipairs(auraList) do        
            if spellID == mainID then
                return true
            end
        end
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

local function CreateMissingBuffFrame(spellId)
    local frame = BAE.Utilities.CreateAuraFrame(playerMissingBuffsFrameCache, { x = 960, y = -500, size = 40, maxIconsPerRow = 10, padding = 5 }, "HORIZONTAL")
    local texture = _G.C_Spell.GetSpellTexture(spellId)
    frame.icon:SetTexture(texture)   
    return frame
end

local function CreateMissingBuffsFrames()
    weaponFrame = CreateMissingBuffFrame(weaponOils[1])
    flasksFrame = CreateMissingBuffFrame(flasks[1])
    foodFrame = CreateMissingBuffFrame(food[1])     
end

function module:OnLoad()

end

function module:OnAddonLoaded()
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

if toc >= 120000 then
    BlizzAddonExtensions:RegisterModule("MissingBuffs", module)
end