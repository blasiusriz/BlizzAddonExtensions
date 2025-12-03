local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local db
local spellsIds = {
    1239675, -- Latent Energy
    1236975  -- Blighted Quiver
}
local auraIconSettings = {}
auraIconSettings[1239675] = { x = 270, y = 0, size = 48 }
auraIconSettings[1236975] = { x = 330, y = 0, size = 48 }
local auraIconCache = {}

local function CreateAuraIcon(spellId)
    local frame = CreateFrame("Frame", spellId, UIParent)
    local settings = auraIconSettings[spellId] or { x = 0, y = 0, size = 30 }

	frame:SetSize(settings.size, settings.size)
	frame:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
	frame:SetAlpha(1)

    -- Create icon texture
    frame.icon = frame:CreateTexture(nil, "BACKGROUND")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Create text frame
	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.text:SetPoint("CENTER")
	frame.text:SetJustifyH("CENTER")
	frame.text:SetSize(settings.size, settings.size)
    local fontPath, _, flags = frame.text:GetFont()
    frame.text:SetFont(fontPath, 24, flags)
    frame.text:SetTextColor(1, 1, 1)

    -- Set the icon and cooldown based on the aura
    local texture = _G.C_Spell.GetSpellTexture(spellId)
    frame.icon:SetTexture(texture)

    auraIconCache[spellId] = frame

    return frame
end

local function CreateAuraIconMidnight(spellId, index)
    local frame = CreateFrame("Frame", "Dummy" .. index, UIParent)
    local settings = { x = 0, y = 0, size = 48 }

    if index and index > 0 then
        settings.x = settings.x + (index - 1) * (settings.size + 10)
    end

	frame:SetSize(settings.size, settings.size)
	frame:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
	frame:SetAlpha(1)

    -- Create icon texture
    frame.icon = frame:CreateTexture(nil, "BACKGROUND")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Create text frame
	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.text:SetPoint("CENTER")
	frame.text:SetJustifyH("CENTER")
	frame.text:SetSize(settings.size, settings.size)
    local fontPath, _, flags = frame.text:GetFont()
    frame.text:SetFont(fontPath, 24, flags)
    frame.text:SetTextColor(1, 1, 1)

    -- Set the icon and cooldown based on the aura
    local texture = _G.C_Spell.GetSpellTexture(spellId)
    frame.icon:SetTexture(texture)

    auraIconCache[index] = frame

    return frame
end

local function GetOrCreateAuraIcon(spellId, index)
    if auraIconCache[spellId] then
        return auraIconCache[spellId]
    else
        return CreateAuraIcon(spellId, index)
    end
end

local function GetOrCreateAuraIconMidnight(spellId, index)
    if auraIconCache[index] then
        return auraIconCache[index]
    else
        return CreateAuraIconMidnight(spellId, index)
    end
end

function module:OnLoad()	

end

function module:OnAddonLoaded()
    BlizzAddonExtensions:Print("Auras initialized")  
end

function module:OnEnable()	

end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_AURA" and arg1 == "player" then
        local _, _, _, toc = GetBuildInfo()
        if toc >= 120000 then
            local auras = C_UnitAuras.GetUnitAuras("player", "HELPFUL")

            -- for i, aura in ipairs(auras) do
            --    -- print(i, aura.name, aura.spellId, aura.applications or 1, aura.expirationTime)
            --    local icon = GetOrCreateAuraIconMidnight(aura.spellId, i)
            --    local inCombat = UnitAffectingCombat("player")
            --    if icon then
            --        if inCombat then
            --            icon.text:SetText(aura.applications or 1)
            --            icon:Show()
            --        else
            --            icon:Hide()
            --        end
            --    end
            -- end
        else
            local inCombat = UnitAffectingCombat("player")
            for i,spellId in ipairs(spellsIds) do
                local icon = GetOrCreateAuraIcon(spellId, 0)
                local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
                if aura then
                    -- print("Aura:", aura.name, "SpellID:", aura.spellId, "Applications:", aura.applications)
                    if icon then
                        if inCombat then
                            icon.text:SetText(aura.applications)
                            icon:Show()
                        else
                            icon:Hide()
                        end                
                    end
                else
                    -- print("Aura with SpellID " .. spellId .. " not found.")
                    if icon then
                        icon.text:SetText("")
                        icon:Hide()
                    end
                end
            end
        end
    end
end)

BlizzAddonExtensions:RegisterModule("Auras", module)