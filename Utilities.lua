local BAE = BlizzAddonExtensions

BAE.Utilities = {}

-- Polyfill for C_StringUtil.TruncateWhenZero if not present

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

-- Debugging functions for auras

function BAE.Utilities.DumpAuraInfo(info, unit)
    if info.isFullUpdate then
        print("full update") -- loop over all auras, etc
        return
    end
    if info.addedAuras then
        for i, aura in pairs(info.addedAuras) do
            print(unit, "|cnGREEN_FONT_COLOR:added|r", aura.name, aura.applications)
            BAE.Utilities.DumpAura(aura)              
        end
    end
    if info.updatedAuraInstanceIDs then
        for i, v in pairs(info.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
            if aura then
                print(unit, "|cnYELLOW_FONT_COLOR:updated|r", aura.name)
                BAE.Utilities.DumpAura(aura)
            end
        end
    end
    if info.removedAuraInstanceIDs then
        for i, v in pairs(info.removedAuraInstanceIDs) do
            print(unit, "|cnRED_FONT_COLOR:removed|r", v)
        end 
    end
end

function BAE.Utilities.DumpAura(aura)
    print("Is Secure name:", aura.name, aura.auraInstanceID, issecretvalue(aura.name))                
    print("Is Secure auraInstanceID:", aura.name, aura.auraInstanceID, issecretvalue(aura.auraInstanceID))
    print("Is Secure duration:", aura.name, aura.duration, issecretvalue(aura.duration))
    print("Is Secure expirationTime:", aura.name, aura.expirationTime, issecretvalue(aura.expirationTime))
end

-- Create and manage aura frames

function BAE.Utilities.CreateAuraFrame(auraFrameCache, settings, orientation)
    local frame = CreateFrame("Frame", nil, UIParent)
    local defaultSettings = { x = 0, y = 0, size = 32, maxIconsPerRow = 6, padding = 5 }
    local cacheSize = #auraFrameCache
    local parentFrame
    local iconAlignment
    local offsetX
    local offsetY

    -- set up settings with defaults if missing
    orientation = orientation or "VERTICAL"
    settings = settings or defaultSettings
    for k, v in pairs(defaultSettings) do
        if settings[k] == nil then
            settings[k] = v
        end
    end

    if cacheSize == 0 then
        -- first icon
        parentFrame = UIParent
        iconAlignment = "TOPLEFT"
        offsetX = settings.x
        offsetY = settings.y       
    elseif (cacheSize % settings.maxIconsPerRow) == 0 then
        -- start new row/column
        parentFrame = auraFrameCache[cacheSize - (settings.maxIconsPerRow - 1)]
        if orientation == "VERTICAL" then
            iconAlignment = "TOPRIGHT"
            offsetX = settings.padding
            offsetY = 0
        else
            iconAlignment = "BOTTOMLEFT"
            offsetX = 0
            offsetY = settings.padding * -1
        end
    else
        -- continue current row/column
        parentFrame = auraFrameCache[cacheSize]
        if orientation == "VERTICAL" then
            iconAlignment = "BOTTOMLEFT"
            offsetX = 0
            offsetY = settings.padding * -1  
        else
            iconAlignment = "TOPRIGHT"
            offsetX = settings.padding
            offsetY = 0
        end            
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

function BAE.Utilities.HideFrame(frame)
    if frame then
        frame.text:SetText("")
        frame.icon:SetTexture(nil)
        frame:Hide()
    end
end

function BAE.Utilities.UpdateAuraFrame(frame, aura)
    if not frame then
        return
    end

    if not UnitAffectingCombat("player") then
        BAE.Utilities.HideFrame(frame)
        return
    end

    if aura then
        local applications = TruncateWhenZero(aura.applications or 0)
        frame.icon:SetTexture(aura.icon)
        frame.text:SetText(applications)
        frame.tooltipText = aura.name
        frame:Show()
    else
        BAE.Utilities.HideFrame(frame)
    end
end

-- State Utilities

function BAE.Utilities.IsInInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "party" or instanceType == "raid")
end

function BAE.Utilities.IsPlayerInCombat()
    return UnitAffectingCombat("player")
end