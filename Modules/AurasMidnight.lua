local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local BAE = BlizzAddonExtensions
local db
local playerAuraFrameCache = {}
local _, _, _, toc = GetBuildInfo()

function module:OnLoad()

end

function module:OnAddonLoaded()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if unit == "player" then
            -- BAE.Utilities.DumpAuraInfo(info, unit)
            for i=1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL|PLAYER")
                if aura then
                    local auraFrame = playerAuraFrameCache[i] or BAE.Utilities.CreateAuraFrame(playerAuraFrameCache, {x = 1210, y = -500})
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

if toc >= 120000 then
    BlizzAddonExtensions:RegisterModule("AurasMidnight", module)
end