local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local db
local auraFrameCache = {}
local _, _, _, toc = GetBuildInfo()

if not _G.C_StringUtil then
    _G.C_StringUtil = {}
end

local TruncateWhenZero = _G.C_StringUtil.TruncateWhenZero or function(i)
    if i and i > 0 then
        return i
    else
        return ""
    end
end

local function CreateAuraFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    local settings = { x = 1350, y = -400, size = 40, offsetX = 0, offsetY = -5, offsetX2 = 5, offsetY2 = 0 }
    local cacheSize = #auraFrameCache
    local breaks = 0
    local maxIconsPerRow = 5
    local parentFrame
    local iconAlignment
    local offsetX
    local offsetY

    if cacheSize == 0 then
        parentFrame = UIParent
        iconAlignment = "TOPLEFT"
        offsetX = settings.x
        offsetY = settings.y       
    elseif (cacheSize % maxIconsPerRow) == 0 then
        parentFrame = auraFrameCache[cacheSize - (maxIconsPerRow - 1)]
        iconAlignment = "TOPRIGHT"
        offsetX = settings.offsetX2
        offsetY = settings.offsetY2
    else
        parentFrame = auraFrameCache[cacheSize]
        iconAlignment = "BOTTOMLEFT"
        offsetX = settings.offsetX
        offsetY = settings.offsetY        
    end

	frame:SetSize(settings.size, settings.size)
    frame:SetPoint("TOPLEFT", parentFrame, iconAlignment, offsetX, offsetY)

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
    frame.text:SetFont(fontPath, math.floor(settings.size / 2), flags)
    frame.text:SetTextColor(1, 1, 1)

    -- Tooltip handlers
    frame.tooltipText = "Aura Icon Tooltip"
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(frame.tooltipText, 1, 1, 1, 1, true)
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)    

    -- Hide at start
    frame:Hide()

    table.insert(auraFrameCache, frame)

    return frame
end

local function HideFrame(frame)
    if frame then
        frame.text:SetText("")
        frame.icon:SetTexture(nil)
        frame:Hide()
    end
end

local function UpdateAuraFrame(frame, aura)
    if not frame then
        return
    end

    if not UnitAffectingCombat("player") then
        HideFrame(frame)
        return
    end

    if aura then
        local applications = TruncateWhenZero(aura.applications or 0)
        frame.icon:SetTexture(aura.icon)
        frame.text:SetText(applications)
        frame.tooltipText = aura.name
        frame:Show()
    else
        HideFrame(frame)
    end
end

function module:OnLoad()

end

function module:OnAddonLoaded()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if unit == "player" then
            for i=1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL|PLAYER")
                if aura then
                    local auraFrame = auraFrameCache[i] or CreateAuraFrame()
                    UpdateAuraFrame(auraFrame, aura)
                else
                    local auraFrame = auraFrameCache[i]
                    HideFrame(auraFrame)
                end
            end
        end
    end)

    BlizzAddonExtensions:Print("Auras for Midnight initialized")  
end

function module:OnEnable()	

end

local function DumpAuraInfo(info)
    if info.isFullUpdate then
        print("full update") -- loop over all auras, etc
        return
    end
    if info.addedAuras then
        for i, v in pairs(info.addedAuras) do
            print(unit, "|cnGREEN_FONT_COLOR:added|r", v.name, v.isNameplateOnly, v.applications)
        end
    end
    if info.updatedAuraInstanceIDs then
        for i, v in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
            if aura then
                print(unit, "|cnYELLOW_FONT_COLOR:updated|r", aura.name)
                print("Is Secure auraInstanceID:", aura.name, aura.auraInstanceID, issecretvalue(aura.auraInstanceID))
                print("Is Secure duration:", aura.name, aura.duration, issecretvalue(aura.duration))
                print("Is Secure expirationTime:", aura.name, aura.expirationTime, issecretvalue(aura.expirationTime))                  
            end
        end
    end
    if info.removedAuraInstanceIDs then
        for i, v in pairs(info.removedAuraInstanceIDs) do
            print(unit, "|cnRED_FONT_COLOR:removed|r", v)
        end 
    end
end

if toc >= 120000 then
    BlizzAddonExtensions:RegisterModule("AurasMidnight", module)
end