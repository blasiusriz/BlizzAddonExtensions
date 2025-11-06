local module = {}

local frame = CreateFrame("Frame", "BAE_TargetCastBar", UIParent)
frame:SetSize(320, 26)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
frame:Hide()

frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints(frame)
frame.bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
frame.bg:SetVertexColor(0,0,0,0.6)

local bar = CreateFrame("StatusBar", nil, frame)
bar:SetAllPoints(frame)
bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
bar.text:SetPoint("CENTER")
bar.text:SetJustifyH("CENTER")
bar.text:SetSize(280, 20)

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local cast = { active = false }

-- Helper: show a dummy cast bar for positioning
local function ShowDummyCast()
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0.5)
    bar.text:SetText("Example Spell")
    bar:SetStatusBarColor(1, 0, 0)
    frame:Show()
end

local function StopCastBar()
    cast.active = false
    frame:Hide()
end

local function StartCastBar(name, notInterruptible, startTimeMS, endTimeMS, isChannel)
    cast.startTime = startTimeMS / 1000
    cast.endTime = endTimeMS / 1000
    cast.duration = cast.endTime - cast.startTime
    cast.active = true

    bar:SetMinMaxValues(0, cast.duration)
    bar:SetValue(0)
    bar.text:SetText(name)

    if notInterruptible then
        bar:SetStatusBarColor(0.5,0.5,0.5)
    else
        bar:SetStatusBarColor(1,0,0)
    end

    frame:Show()
end

local function UpdateFromTarget()
    local name, _, _, startTime, endTime, _, notInterruptible = UnitCastingInfo("target")
    if name then
        StartCastBar(name, notInterruptible, startTime, endTime, false)
        return
    end
    name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo("target")
    if name then
        StartCastBar(name, notInterruptible, startTime, endTime, true)
        return
    end
    StopCastBar()
end

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
end)

function module:OnLoad()
    BlizzAddonExtensions:Print("Module loaded: TargetCastBar")
end

function module:OnEnable()
    UpdateFromTarget()
end

function module:OnCommand(cmd)
    if cmd == "lock" then
        frame:EnableMouse(false)
        frame:SetMovable(false)
        -- Hide dummy if no real cast active
        if not cast.active then
            frame:Hide()
        end
        BlizzAddonExtensions:Print("TargetCastBar locked.")
    elseif cmd == "unlock" then
        frame:EnableMouse(true)
        frame:SetMovable(true)
        ShowDummyCast() -- make it visible for moving
        BlizzAddonExtensions:Print("TargetCastBar unlocked (dummy cast visible).")
    end
end

BlizzAddonExtensions:RegisterModule("TargetCastBar", module)