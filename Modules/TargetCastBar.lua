local module = {}
local BlizzAddonExtensions = _G.BlizzAddonExtensions
local targetCastBarFrame = _G.TargetFrameSpellBar
local db
local targetCastBarPoint, targetCastBarRelativePoint, targetCastBarXofs, targetCastBarYofs, targetCastBarScale

-- List of Interrupt spells
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

-- Get the players interrupt spell
local _, class = UnitClass("player")
local interruptSpellID = INTERRUPT_SPELLS[class]

-- Function to create an interrupt icon frame
local function CreateInterruptIconFrame()
	local parentFrame = targetCastBarFrame
    local button = CreateFrame("Frame", nil, parentFrame)
	button:SetSize(20, 20)
	button:SetPoint("LEFT", targetCastBarFrame, "RIGHT", 4, -5)
	button:SetAlpha(1)

    -- Create icon texture
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

    -- Create cooldown frame
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()

    return button
end

-- Create the Interrupt Icon and attach it to the target castbar
local interruptIcon = CreateInterruptIconFrame()

-- Check if the interrupt spell can be used
local function IsInterruptReady()
    return not interruptIcon.cooldown:IsShown()
end

-- Update the interrupt cooldown icon
local function UpdateInterruptIcon()
    local spellCooldownInfo = _G.C_Spell.GetSpellCooldown(interruptSpellID)
	interruptIcon.cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration)
	local isCoolDownShown = interruptIcon.cooldown:IsShown()

	if isCoolDownShown then
		interruptIcon:SetAlpha(0.5)
	else
		interruptIcon:SetAlpha(1)
	end
end

-- Get the icon for the players interrupt spell
local function GetInterruptSpellTexture(interruptSpellID)
	return _G.C_Spell.GetSpellTexture(interruptSpellID)
end

local function ResetTargetCastbarSettings()
	targetCastBarPoint = "CENTER"
	targetCastBarRelativePoint = "CENTER"
	targetCastBarXofs = 0
	targetCastBarYofs = 0
	targetCastBarScale = 1
	targetCastBarFrame:SetScale(targetCastBarScale)
end

local function LoadTargetCastbarSettings()
	local scale = targetCastBarFrame:GetScale()
	targetCastBarPoint = db.point or "CENTER"
	targetCastBarRelativePoint = db.relativePoint or "CENTER"
	targetCastBarXofs = db.xOfs or 0
	targetCastBarYofs = db.yOfs or 0
	targetCastBarScale = db.scale or scale
	targetCastBarFrame:SetScale(targetCastBarScale)
	C_CVar.SetCVar("showtargetcastbar ", "1")
	interruptIcon.icon:SetTexture(GetInterruptSpellTexture(interruptSpellID))
end

local function SaveTargetCastbarSettings()
	db.point = targetCastBarPoint
	db.relativePoint = targetCastBarRelativePoint
	db.xOfs = targetCastBarXofs
	db.yOfs = targetCastBarYofs
	db.scale = targetCastBarScale
	targetCastBarFrame:SetScale(targetCastBarScale)
end

local function PrintTargetCastBarSettings()
	print("Target Cast Bar Point: " .. targetCastBarPoint .. ", Relative Point: " .. targetCastBarRelativePoint .. ", X: " .. targetCastBarXofs .. ", Y: " .. targetCastBarYofs .. ", Scale: " .. targetCastBarScale)
end

function module:OnLoad()	

end

function module:OnAddonLoaded()
	if not _TargetCastBar then
		_TargetCastBar = {}
		BlizzAddonExtensions:Print("Initializing Target Castbar DB")
	end
    db = _TargetCastBar

	-- restore saved position if available or revert to initial values
	LoadTargetCastbarSettings()

    BlizzAddonExtensions:Print("TargetCastBar initialized")
end

function module:OnEnable()	

end

function module:OnCommand(cmd, args)
    if cmd == "targetcastbarsetx" then
		targetCastBarXofs = args or 0
		SaveTargetCastbarSettings()
        BlizzAddonExtensions:Print("Target Cast Bar X set to: " .. targetCastBarXofs)
	elseif cmd == "targetcastbarsety" then		
		targetCastBarYofs = args or 0
		SaveTargetCastbarSettings()
        BlizzAddonExtensions:Print("Target Cast Bar Y set to: " .. targetCastBarYofs)
	elseif cmd == "targetcastbarsetscale" then		
		targetCastBarScale = args or 1
		SaveTargetCastbarSettings()
        BlizzAddonExtensions:Print("Target Cast Bar Scale set to: " .. targetCastBarScale)
	elseif cmd == "targetcastbarinfo" then
		PrintTargetCastBarSettings()
	elseif cmd == "targetcastbarreset" then
		ResetTargetCastbarSettings()
		SaveTargetCastbarSettings()
        BlizzAddonExtensions:Print("Target Cast Bar reset.")
		PrintTargetCastBarSettings()
    end
end

-- Border Shield is shown on castbar, meaning spell is not interruptible
hooksecurefunc(targetCastBarFrame.BorderShield, "Show", function()
	targetCastBarFrame:SetStatusBarColor(0.5, 0.5, 0.5)
	UpdateInterruptIcon()
	interruptIcon:Hide()
end)

-- Border Shield is not shown on castbar, meaning spell is interruptible
hooksecurefunc(targetCastBarFrame.BorderShield, "Hide", function()
	targetCastBarFrame:SetStatusBarColor(1, 0, 0)
	UpdateInterruptIcon()
	interruptIcon:Show()
end)

-- Prevent Target Castbar Frame from being repositioned to default position
hooksecurefunc(targetCastBarFrame, "SetPoint", function()
	local meta = getmetatable(targetCastBarFrame).__index
	meta.ClearAllPoints(targetCastBarFrame)
	meta.SetPoint(targetCastBarFrame, targetCastBarPoint, UIParent, targetCastBarRelativePoint, targetCastBarXofs, targetCastBarYofs)
end)

-- Interrupt Spell Icon Loop
interruptIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
interruptIcon:SetScript("OnEvent", function(self, event, spellID)
	if spellID ~= interruptSpellID then return end
	UpdateInterruptIcon()
end)

BlizzAddonExtensions:RegisterModule("TargetCastBar", module)
