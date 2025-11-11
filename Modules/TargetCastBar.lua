local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local db

local INTERRUPT_SPELLS = {
    WARRIOR = 6552,     -- Pummel
    ROGUE = 1766,       -- Kick
    MAGE = 2139,        -- Counterspell
    SHAMAN = 57994,     -- Wind Shear
    PALADIN = 96231,    -- Rebuke
    DEMONHUNTER = 183752,-- Disrupt
    MONK = 116705,      -- Spear Hand Strike
    DEATHKNIGHT = 47528, -- Mind Freeze
    HUNTER = 147362,    -- Counter Shot
    EVOKER = 351338,    -- Quell
}

local _, class = UnitClass("player")
local interruptSpellID = INTERRUPT_SPELLS[class]

local events = {
    "PLAYER_TARGET_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
}

local frame = CreateFrame("Frame", "BAE_TargetCastBar", UIParent)
frame:SetSize(320, 30)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
frame:Hide()

-- Background
frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints(frame)
frame.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
frame.bg:SetVertexColor(0, 0, 0, 0.6)

-- Border for the cast bar
local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
border:SetAllPoints(frame)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
})
border:SetBackdropBorderColor(0, 0, 0)

-- Spell icon on the left
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(30, 30)
icon:SetPoint("RIGHT", frame, "LEFT", -4, 0)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
icon:Hide()

-- Interrupt Icon
local interruptIcon = frame:CreateTexture(nil, "OVERLAY")
interruptIcon:SetSize(30, 30)
interruptIcon:SetPoint("LEFT", frame, "RIGHT", 4, 0)
interruptIcon:SetAlpha(0.7)
interruptIcon:Hide()

-- Border for the icon
local iconBorder = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
iconBorder:SetSize(32, 32)
iconBorder:SetPoint("CENTER", icon, "CENTER")
iconBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
})
iconBorder:SetBackdropBorderColor(0, 0, 0)
iconBorder:Hide()

-- Cast bar itself
local bar = CreateFrame("StatusBar", nil, frame)
bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
bar.text:SetPoint("CENTER")
bar.text:SetJustifyH("CENTER")
bar.text:SetSize(280, 20)

-- Dragging
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local cast = { active = false }

local function StopCastBar()
    cast.active = false
    frame:Hide()
    icon:Hide()
    iconBorder:Hide()
end

local function StartCastBar(name, iconTexture, notInterruptible, startTimeMS, endTimeMS, isChannel)
    cast.startTime = startTimeMS / 1000
    cast.endTime = endTimeMS / 1000
    cast.duration = cast.endTime - cast.startTime
    cast.active = true

    bar:SetMinMaxValues(0, cast.duration)
    bar:SetValue(0)
    bar.text:SetText(name)

    if notInterruptible then
        bar:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        bar:SetStatusBarColor(1, 0, 0)
    end

    if iconTexture then
        icon:SetTexture(iconTexture)
        icon:Show()
        iconBorder:Show()
    else
        icon:Hide()
        iconBorder:Hide()
    end

    frame:Show()
end

local function IsInterruptReady(spellID)
    local usable, noMana = _G.C_Spell.IsSpellUsable(spellID)
    local spellCooldownInfo = _G.C_Spell.GetSpellCooldown(spellID)

    return usable and (spellCooldownInfo.duration == 0)
end

local function GetInterruptSpellTexture(interruptSpellID)
	return _G.C_Spell.GetSpellTexture(interruptSpellID)
end

local function UpdateInterruptIcon()
	local _, _, _, _, _, _, _, notInterruptible, _
    _, _, _, _, _, _, _, notInterruptible, _ = UnitCastingInfo("target")

	if not notInterruptible and interruptSpellID then
		if IsInterruptReady(interruptSpellID) then
			interruptIcon:SetTexture(GetInterruptSpellTexture(interruptSpellID))
			interruptIcon:Show()
		else
			interruptIcon:Hide()
		end
	else
		interruptIcon:Hide()
	end
end

local function UpdateFromTarget()
	local name, text, texture, startTime, endTime, isTradeSkill, _, notInterruptible, _
    name, text, texture, startTime, endTime, isTradeSkill, _, notInterruptible, _ = UnitCastingInfo("target")
	
    if name then
        StartCastBar(name, texture, notInterruptible, startTime, endTime, false)
        return
    end
    name, _, texture, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo("target")
    if name then
        StartCastBar(name, texture, notInterruptible, startTime, endTime, true)
        return
    end
	
    StopCastBar()
end

for _, ev in ipairs(events) do frame:RegisterEvent(ev) end

frame:SetScript("OnEvent", function(_, event, unit)
    if unit and unit ~= "target" then return end
    UpdateFromTarget()
end)

frame:SetScript("OnUpdate", function(_, elapsed)
    if not cast.active then return end
    local now = GetTime()
    local elapsedTime = now - cast.startTime
    if elapsedTime >= cast.duration then
        StopCastBar()
        return
    end
    bar:SetValue(elapsedTime)
	
	UpdateInterruptIcon()
end)

-- Dummy cast for unlock mode
local function ShowDummyCast()
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0.5)
    bar.text:SetText("Example Spell")
    bar:SetStatusBarColor(1, 0, 0)
    icon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
    icon:Show()
    iconBorder:Show()
    frame:Show()
end

local function ResetCastbar()
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
end

local function SaveCastbar()
	local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()		
	db.point, db.relativePoint, db.xOfs, db.yOfs = point, relativePoint, xOfs, yOfs
end

function module:OnLoad()	
    BlizzAddonExtensions:Print("Module loaded: TargetCastBar")
end

function module:OnAddonLoaded()
	if not _TargetCastBar then
		_TargetCastBar = {}
		BlizzAddonExtensions:Print("Initializing Target Castbar DB")
	end
    db = _TargetCastBar

    -- Restore last known position
    if db.point and db.relativePoint then
        frame:ClearAllPoints()
        frame:SetPoint(db.point, UIParent, db.relativePoint, db.xOfs or 0, db.yOfs or 0)
		BlizzAddonExtensions:Print("Restored position.")
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
		BlizzAddonExtensions:Print("Using default position.")
    end
	
    BlizzAddonExtensions:Print("Module on addon loaded: TargetCastBar")
end

function module:OnEnable()	
    UpdateFromTarget()
end

function module:OnCommand(cmd)
    if cmd == "lock" then
        frame:EnableMouse(false)
        frame:SetMovable(false)
		
		-- Save position
		SaveCastbar()
		
        if not cast.active then
            frame:Hide()
            icon:Hide()
            iconBorder:Hide()
        end
        BlizzAddonExtensions:Print("TargetCastBar locked.")
    elseif cmd == "unlock" then
        frame:EnableMouse(true)
        frame:SetMovable(true)
        ShowDummyCast()
        BlizzAddonExtensions:Print("TargetCastBar unlocked.")
	elseif cmd == "reset" then
		ResetCastbar()
        BlizzAddonExtensions:Print("TargetCastBar reset.")	
    end
end

BlizzAddonExtensions:RegisterModule("TargetCastBar", module)
