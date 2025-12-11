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
local auraIconCacheSize = 0
local _, _, _, toc = GetBuildInfo()

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

local function GetOrCreateAuraIcon(spellId, index)
    return auraIconCache[spellId] or CreateAuraIcon(spellId, index)
end

function module:OnLoad()	

end

function module:OnAddonLoaded()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if event == "UNIT_AURA" and unit == "player" then
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
    end)

    BlizzAddonExtensions:Print("Auras initialized")  
end

function module:OnEnable()	

end

if toc < 120000 then
    BlizzAddonExtensions:RegisterModule("Auras", module)
end
