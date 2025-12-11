local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local db
local taskQueue = {}
local auraIconCache = {}
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

local function RunNextTask()
    local task = table.remove(taskQueue, 1)
    if not task then return end

    task()  
    RunNextTask()
end

local function EnqueueTask(taskFunc)
    table.insert(taskQueue, taskFunc)
    RunNextTask()
end

local function CreateAuraIcon(instanceId)
    local frame = CreateFrame("Frame", nil, UIParent)
    local settings = { x = 1450, y = -400, size = 40, offsetX = 0, offsetY = -5, offsetX2 = 5, offsetY2 = 0 }
    local cacheSize = #auraIconCache
    local breaks = 0
    local maxIconsPerRow = 10
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
        parentFrame = auraIconCache[cacheSize - (maxIconsPerRow - 1)].aura
        iconAlignment = "TOPRIGHT"
        offsetX = settings.offsetX2
        offsetY = settings.offsetY2
    else
        parentFrame = auraIconCache[cacheSize].aura
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

    table.insert(auraIconCache, {aura = frame, instanceId = instanceId})

    return frame
end

-- local inCombat = UnitAffectingCombat("player")

local function GetAvailableAuraIcon(instanceId)
    for i, v in pairs(auraIconCache) do
        if v.instanceId == nil then
            -- print("|cnGREEN_FONT_COLOR:found unused icon for:|r", instanceId, "at index", i)
            v.instanceId = instanceId
            return v.aura
        end
    end
    -- print("|cnYELLOW_FONT_COLOR:created new icon for:|r", instanceId)
    return CreateAuraIcon(instanceId)
end

local function UnsetIcon(icon)
    if icon then
        icon.text:SetText("")
        icon.icon:SetTexture(nil)
        icon:Hide()
    end
end

local function UnloudAuraIcon(instanceId)
    for i, v in pairs(auraIconCache) do
        if v.instanceId == instanceId then
            -- print("|cnGREEN_FONT_COLOR:unloaded instance:|r", instanceId)
            v.instanceId = nil
            UnsetIcon(v.aura)
            return
        end
    end
    -- print("|cnRED_FONT_COLOR:unable to unload instance:|r", instanceId)
end

local function ReorderAuraIcons()
    for i, v in pairs(auraIconCache) do
        if v.instanceId == nil then
            if auraIconCache[i + 1] then
                -- print("|cnGREEN_FONT_COLOR:Moving:|r", i + 1, "to", i)
                local nextIcon = auraIconCache[i + 1].aura
                local nextInstanceId = auraIconCache[i + 1].instanceId
                auraIconCache[i] = auraIconCache[i + 1]
                UnsetIcon(nextIcon)
                nextInstanceId = nil
            end
        end
    end
end

local function GetAuraIcon(instanceId)
    for i, v in pairs(auraIconCache) do
        if v.instanceId == instanceId then
            -- print("|cnGREEN_FONT_COLOR:found icon for instance:|r", instanceId)
            return v.aura
        end
    end
    -- print("|cnRED_FONT_COLOR:unable to find icon for instance:|r", instanceId)
    return nil
end

local function UpdateAuraIcon(icon, aura)
    if icon and aura then
        local applications = TruncateWhenZero(aura.applications or 0)

        local texture = _G.C_Spell.GetSpellTexture(aura.spellId)
        icon.icon:SetTexture(texture)
        icon.text:SetText(applications)
        icon.tooltipText = aura.name
        icon:Show()
    end
end

function module:OnLoad()

end

function module:OnAddonLoaded()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(self, event, unit, info)
        if unit == "player" then
            if info.isFullUpdate then
                -- print("full update") -- loop over all auras, etc
                return
            end
            if info.addedAuras then
                for i, v in pairs(info.addedAuras) do
                    -- print(unit, "|cnGREEN_FONT_COLOR:added|r", v.name, v.isNameplateOnly, v.applications)
                    local icon = GetAvailableAuraIcon(v.auraInstanceID)
                    EnqueueTask(UpdateAuraIcon(icon, v))
                    -- print(v.auraInstanceID, issecretvalue(v.auraInstanceID))
                    -- print(v.name, issecretvalue(v.name))
                    -- print(v.spellId, issecretvalue(v.spellId))
                end
            end
            if info.updatedAuraInstanceIDs then
                for i, v in pairs(info.updatedAuraInstanceIDs) do
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
                    local icon = GetAuraIcon(v)
                    if aura and icon then
                        -- print(unit, "|cnYELLOW_FONT_COLOR:updated|r", aura.name)
                        EnqueueTask(UpdateAuraIcon(icon, aura))                      
                    end
                end
            end
            if info.removedAuraInstanceIDs then
                for i, v in pairs(info.removedAuraInstanceIDs) do
                    -- print(unit, "|cnRED_FONT_COLOR:removed|r", v)
                    EnqueueTask(UnloudAuraIcon(v))
                end
                -- EnqueueTask(ReorderAuraIcons())
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