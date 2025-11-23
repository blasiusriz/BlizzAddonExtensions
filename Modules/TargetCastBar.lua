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

-- Create a custom castbar frame
local function CreateCastBarFrame()

	local frame = CreateFrame("Frame", "BAE_TargetCastBar", UIParent)
	frame:SetSize(320, 30)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

	return frame, bar, icon
end

-- create the custom castbar frame
local customCastBarFrame, customCastBar, customCastBarIcon = CreateCastBarFrame()

-- Function to create an interrupt icon frame
local function CreateInterruptIconFrame()
	local parentFrame = customCastBarFrame
    local button = CreateFrame("Frame", nil, parentFrame)
	button:SetSize(30, 30)
	button:SetPoint("LEFT", parentFrame, "RIGHT", 4, 0)
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

-- Update the customcastbar frame
local function UpdateCastBarFrameShown(shown)
	if shown then
		customCastBarFrame:Show()
	else
		customCastBarFrame:Hide()
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
	customCastBarFrame:SetScale(targetCastBarScale)
	customCastBarFrame:SetPoint(targetCastBarPoint, UIParent, targetCastBarRelativePoint, targetCastBarXofs, targetCastBarYofs)

	C_CVar.SetCVar("showtargetcastbar", "1")
	interruptIcon.icon:SetTexture(GetInterruptSpellTexture(interruptSpellID))
end

local function SaveTargetCastbarSettings()
	db.point = targetCastBarPoint
	db.relativePoint = targetCastBarRelativePoint
	db.xOfs = targetCastBarXofs
	db.yOfs = targetCastBarYofs
	db.scale = targetCastBarScale
	customCastBarFrame:SetScale(targetCastBarScale)
	customCastBarFrame:SetPoint(targetCastBarPoint, UIParent, targetCastBarRelativePoint, targetCastBarXofs, targetCastBarYofs)
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

	-- BlizzAddonExtensions:DumpTable(targetCastBarFrame, false)

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

-- targetCastBarFrame shown/hidden hooks
hooksecurefunc(targetCastBarFrame, "UpdateShownState", function()
	local isShown = targetCastBarFrame:IsShown()
	UpdateCastBarFrameShown(isShown)
end)
hooksecurefunc(targetCastBarFrame, "Hide", function()
	UpdateCastBarFrameShown(false)
end)
hooksecurefunc(targetCastBarFrame, "SetValue", function()
	local value = targetCastBarFrame:GetValue()
	customCastBar:SetValue(value)
end)
hooksecurefunc(targetCastBarFrame, "SetMinMaxValues", function()
	local min, max = targetCastBarFrame:GetMinMaxValues()
	customCastBar:SetMinMaxValues(min, max)
end)
hooksecurefunc(targetCastBarFrame, "UpdateCastTimeTextShown", function()
	local text = targetCastBarFrame.Text:GetText()
	customCastBar.text:SetText(text)
end)
hooksecurefunc(targetCastBarFrame.Icon, "SetTexture", function()
	local texture = targetCastBarFrame.Icon:GetTexture()
	customCastBarIcon:SetTexture(texture)
	customCastBarIcon:Show()
end)
hooksecurefunc(targetCastBarFrame, "PlayFadeAnim", function()
	UpdateCastBarFrameShown(false)
end)
hooksecurefunc(targetCastBarFrame, "PlayFinishAnim", function()
	UpdateCastBarFrameShown(false)
end)
hooksecurefunc(targetCastBarFrame, "PlayInterruptAnims", function()
	local text = targetCastBarFrame.Text:GetText()
	customCastBar.text:SetText(text)
	-- delay hiding the castbar to allow interrupt text to be visible
	C_Timer.After(1, function()
		UpdateCastBarFrameShown(false)
	end)	
end)

-- Border Shield is shown on castbar, meaning spell is not interruptible
hooksecurefunc(targetCastBarFrame.BorderShield, "Show", function()
	customCastBar:SetStatusBarColor(0.5, 0.5, 0.5)
	UpdateInterruptIcon()
	interruptIcon:Hide()
end)

-- Border Shield is not shown on castbar, meaning spell is interruptible
hooksecurefunc(targetCastBarFrame.BorderShield, "Hide", function()
	customCastBar:SetStatusBarColor(1, 0, 0)
	UpdateInterruptIcon()
	interruptIcon:Show()
end)

-- Prevent Target Castbar Frame from being repositioned to default position
hooksecurefunc(targetCastBarFrame, "SetPoint", function()
	local meta = getmetatable(targetCastBarFrame).__index
	meta.ClearAllPoints(targetCastBarFrame)
	-- move default castbar offscreen
	meta.SetPoint(targetCastBarFrame, "CENTER", UIParent, "CENTER", 80000, 80000)
	meta.SetAlpha(targetCastBarFrame, 0.0)
end)

-- Interrupt Spell Icon Loop
interruptIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
interruptIcon:SetScript("OnEvent", function(self, event, spellID)
	if spellID ~= interruptSpellID then return end
	UpdateInterruptIcon()
end)

BlizzAddonExtensions:RegisterModule("TargetCastBar", module)
