--[[
	UIKit - shared visual shell + widget factory for the Jackblox menu system.

	Owns the ScreenGui, animated background, floating party words, and the
	screen-switching (fade) machinery, plus the generic widget builders
	(labels, buttons, cards, text boxes, sliders, segment groups) that every
	screen module (MenuScreens, LobbyScreens, GameScreens) is built from.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIKit = {}

UIKit.Palette = {
	Background1 = Color3.fromRGB(255, 224, 235), -- light pink
	Background2 = Color3.fromRGB(226, 219, 255), -- light lavender
	Background3 = Color3.fromRGB(214, 245, 255), -- light cyan
	Background4 = Color3.fromRGB(255, 245, 214), -- light yellow

	TextDark = Color3.fromRGB(70, 45, 95),
	White = Color3.fromRGB(255, 255, 255),

	Pink = Color3.fromRGB(255, 133, 179),
	Purple = Color3.fromRGB(178, 138, 255),
	Teal = Color3.fromRGB(103, 219, 208),
	Yellow = Color3.fromRGB(255, 209, 102),

	CardBG = Color3.fromRGB(255, 255, 255),

	MonoLobbies = Color3.fromRGB(186, 150, 255),
	MonoSettings = Color3.fromRGB(160, 122, 232),
	MonoNews = Color3.fromRGB(210, 180, 255),

	Danger = Color3.fromRGB(230, 90, 90),
}

UIKit.HEADER_FONT = Enum.Font.FredokaOne
UIKit.BODY_FONT = Enum.Font.GothamMedium

local Palette = UIKit.Palette
local HEADER_FONT = UIKit.HEADER_FONT
local BODY_FONT = UIKit.BODY_FONT

-- ============================================================
-- ROOT + BACKGROUND
-- ============================================================
function UIKit.Init()
	local existing = playerGui:FindFirstChild("JackbloxUI")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JackbloxUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Palette.Background2
	background.BorderSizePixel = 0
	background.ZIndex = 1
	background.Parent = screenGui

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Palette.Background1),
		ColorSequenceKeypoint.new(0.33, Palette.Background2),
		ColorSequenceKeypoint.new(0.66, Palette.Background3),
		ColorSequenceKeypoint.new(1, Palette.Background4),
	})
	bgGradient.Rotation = 0
	bgGradient.Parent = background

	task.spawn(function()
		while background.Parent do
			local tween = TweenService:Create(bgGradient, TweenInfo.new(14, Enum.EasingStyle.Linear), {
				Rotation = bgGradient.Rotation + 360,
			})
			tween:Play()
			tween.Completed:Wait()
		end
	end)

	local blobColors = { Palette.Pink, Palette.Purple, Palette.Teal, Palette.Yellow }
	for i = 1, 5 do
		local blob = Instance.new("Frame")
		blob.Name = "Blob" .. i
		blob.Size = UDim2.fromScale(0.32, 0.32)
		blob.Position = UDim2.fromScale(math.random(0, 80) / 100, math.random(0, 80) / 100)
		blob.BackgroundColor3 = blobColors[((i - 1) % #blobColors) + 1]
		blob.BackgroundTransparency = 0.78
		blob.BorderSizePixel = 0
		blob.ZIndex = 1
		blob.Parent = background

		local blobCorner = Instance.new("UICorner")
		blobCorner.CornerRadius = UDim.new(1, 0)
		blobCorner.Parent = blob

		task.spawn(function()
			while blob.Parent do
				local dur = math.random(7, 13)
				local tween = TweenService:Create(blob, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.fromScale(math.random(0, 75) / 100, math.random(0, 75) / 100),
				})
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end

	local floatingLayer = Instance.new("Frame")
	floatingLayer.Name = "FloatingTextLayer"
	floatingLayer.Size = UDim2.fromScale(1, 1)
	floatingLayer.BackgroundTransparency = 1
	floatingLayer.Active = false
	floatingLayer.ZIndex = 3
	floatingLayer.Parent = screenGui

	local floatingWords = { "Party!", "Quip It!", "Bluff!", "Vote Now!", "Ha!", "Prompt!", "Cheer!", "Oops!", "Nice One!", "Zing!" }
	local floatingColors = { Palette.Pink, Palette.Purple, Palette.Teal, Palette.Yellow, Palette.TextDark }

	task.spawn(function()
		while floatingLayer.Parent do
			task.wait(math.random(10, 22) / 10)
			task.spawn(function()
				local label = Instance.new("TextLabel")
				label.Text = floatingWords[math.random(1, #floatingWords)]
				label.Font = HEADER_FONT
				label.TextColor3 = floatingColors[math.random(1, #floatingColors)]
				label.TextTransparency = 1
				label.TextStrokeTransparency = 1
				label.TextStrokeColor3 = Palette.White
				label.TextScaled = true
				label.BackgroundTransparency = 1
				label.Size = UDim2.fromOffset(170, 50)
				label.Position = UDim2.fromScale(math.random(5, 88) / 100, math.random(8, 86) / 100)
				label.Rotation = math.random(-8, 8)
				label.ZIndex = 3
				label.Parent = floatingLayer

				TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 0.1, TextStrokeTransparency = 0.55 }):Play()
				task.wait(2.3)
				local out = TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 })
				out:Play()
				out.Completed:Wait()
				label:Destroy()
			end)
		end
	end)

	local screens = Instance.new("Frame")
	screens.Name = "Screens"
	screens.Size = UDim2.fromScale(1, 1)
	screens.BackgroundTransparency = 1
	screens.ZIndex = 5
	screens.Parent = screenGui

	UIKit.ScreenGui = screenGui
	UIKit.ScreensContainer = screens

	return UIKit
end

-- ============================================================
-- GENERIC HELPERS
-- ============================================================
function UIKit.NewScreen(name)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.ZIndex = 5
	f.Parent = UIKit.ScreensContainer
	return f
end

function UIKit.AddCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 16)
	c.Parent = parent
	return c
end

function UIKit.AddStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Palette.TextDark
	s.Thickness = thickness or 1.2
	s.Transparency = transparency or 0.4
	s.Parent = parent
	return s
end

function UIKit.AddPadding(parent, all)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, all or 10)
	p.PaddingRight = UDim.new(0, all or 10)
	p.PaddingTop = UDim.new(0, all or 10)
	p.PaddingBottom = UDim.new(0, all or 10)
	p.Parent = parent
	return p
end

function UIKit.CreateLabel(props)
	local label = Instance.new("TextLabel")
	label.Text = props.Text or ""
	label.Font = props.Font or HEADER_FONT
	label.TextColor3 = props.TextColor or Palette.TextDark
	label.TextScaled = props.TextScaled ~= false
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Center
	label.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	label.Size = props.Size or UDim2.fromScale(0.5, 0.08)
	label.Position = props.Position or UDim2.fromScale(0.5, 0.1)
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	label.TextStrokeTransparency = props.StrokeTransparency or 1
	label.TextStrokeColor3 = props.StrokeColor or Palette.White
	label.ZIndex = props.ZIndex or 6
	label.LayoutOrder = props.LayoutOrder or 0
	label.Parent = props.Parent
	return label
end

function UIKit.CreateButton(props)
	local btn = Instance.new("TextButton")
	btn.Name = props.Name or "Button"
	btn.Text = props.Text or ""
	btn.Size = props.Size
	btn.Position = props.Position
	btn.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = props.Color or Palette.Purple
	btn.BorderSizePixel = 0
	btn.Font = HEADER_FONT
	btn.TextColor3 = props.TextColor or Palette.White
	btn.TextScaled = true
	btn.AutoButtonColor = true
	btn.ZIndex = props.ZIndex or 6
	btn.LayoutOrder = props.LayoutOrder or 0
	btn.Parent = props.Parent

	UIKit.AddCorner(btn, props.Radius or 14)
	UIKit.AddStroke(btn, Palette.TextDark, 1.1, 0.4)
	UIKit.AddPadding(btn, 8)

	local baseSize = props.Size
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { Size = baseSize + UDim2.fromOffset(6, 6) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { Size = baseSize }):Play()
	end)

	return btn
end

function UIKit.CreateCard(props)
	local card = Instance.new("Frame")
	card.Name = props.Name or "Card"
	card.Size = props.Size
	card.Position = props.Position
	card.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = props.Color or Palette.CardBG
	card.BackgroundTransparency = props.Transparency or 0.05
	card.BorderSizePixel = 0
	card.ZIndex = props.ZIndex or 6
	card.Parent = props.Parent

	UIKit.AddCorner(card, props.Radius or 18)
	UIKit.AddStroke(card, Palette.TextDark, 1, 0.7)
	return card
end

function UIKit.CreateTextBox(props)
	local box = Instance.new("TextBox")
	box.Text = props.Text or ""
	box.PlaceholderText = props.Placeholder or "Type here..."
	box.Size = props.Size
	box.Position = props.Position
	box.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	box.BackgroundColor3 = Palette.White
	box.TextColor3 = Palette.TextDark
	box.PlaceholderColor3 = Color3.fromRGB(170, 160, 190)
	box.Font = BODY_FONT
	box.TextScaled = true
	box.ClearTextOnFocus = false
	if props.MaxLength then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if #box.Text > props.MaxLength then
				box.Text = string.sub(box.Text, 1, props.MaxLength)
			end
		end)
	end
	box.ZIndex = props.ZIndex or 7
	box.Parent = props.Parent
	UIKit.AddCorner(box, 10)
	UIKit.AddStroke(box, Palette.Purple, 1.2, 0.3)
	UIKit.AddPadding(box, 6)
	return box
end

-- Simple draggable slider. Returns the frame + a getValue function.
function UIKit.CreateSlider(props)
	local min, max = props.Min or 0, props.Max or 100
	local value = props.Default or min
	local suffix = props.Suffix or "%"

	local holder = Instance.new("Frame")
	holder.Size = props.Size
	holder.Position = props.Position
	holder.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	holder.BackgroundTransparency = 1
	holder.ZIndex = props.ZIndex or 7
	holder.Parent = props.Parent

	UIKit.CreateLabel({
		Text = props.Label or "Slider",
		Size = UDim2.new(0.6, 0, 0, 18),
		Position = UDim2.fromScale(0, 0),
		AnchorPoint = Vector2.new(0, 0),
		XAlign = Enum.TextXAlignment.Left,
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		ZIndex = holder.ZIndex + 1,
		Parent = holder,
	})

	local valueLabel = UIKit.CreateLabel({
		Text = tostring(value) .. suffix,
		Size = UDim2.new(0.35, 0, 0, 18),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		XAlign = Enum.TextXAlignment.Right,
		Font = BODY_FONT,
		TextColor = Palette.Purple,
		ZIndex = holder.ZIndex + 1,
		Parent = holder,
	})

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 10)
	track.Position = UDim2.new(0, 0, 0, 26)
	track.BackgroundColor3 = Color3.fromRGB(225, 218, 240)
	track.BorderSizePixel = 0
	track.ZIndex = holder.ZIndex
	track.Parent = holder
	UIKit.AddCorner(track, 5)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Palette.Purple
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
	fill.ZIndex = holder.ZIndex + 1
	fill.Parent = track
	UIKit.AddCorner(fill, 5)

	local handle = Instance.new("TextButton")
	handle.Text = ""
	handle.Size = UDim2.fromOffset(18, 18)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
	handle.BackgroundColor3 = Palette.White
	handle.ZIndex = holder.ZIndex + 2
	handle.Parent = track
	UIKit.AddCorner(handle, 9)
	UIKit.AddStroke(handle, Palette.Purple, 2, 0)

	local dragging = false

	local function updateFromX(inputX)
		local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		handle.Position = UDim2.new(rel, 0, 0.5, 0)
		value = math.floor(min + rel * (max - min))
		valueLabel.Text = tostring(value) .. suffix
		if props.OnChange then
			props.OnChange(value)
		end
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			updateFromX(input.Position.X)
		end
	end)

	return holder, function() return value end
end

-- Segmented option group (e.g. Low/Medium/High). Returns the frame + getSelected().
function UIKit.CreateSegmentGroup(props)
	local options = props.Options
	local selectedIndex = props.DefaultIndex or 1

	local holder = Instance.new("Frame")
	holder.Size = props.Size
	holder.Position = props.Position
	holder.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	holder.BackgroundTransparency = 1
	holder.ZIndex = props.ZIndex or 7
	holder.Parent = props.Parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	local buttons = {}
	for i, optionText in ipairs(options) do
		local segBtn = Instance.new("TextButton")
		segBtn.Text = optionText
		segBtn.Size = UDim2.new(1 / #options, -4, 1, 0)
		segBtn.Font = BODY_FONT
		segBtn.TextScaled = true
		segBtn.TextColor3 = Palette.White
		segBtn.BorderSizePixel = 0
		segBtn.LayoutOrder = i
		segBtn.BackgroundColor3 = (i == selectedIndex) and Palette.Purple or Color3.fromRGB(210, 200, 230)
		segBtn.ZIndex = holder.ZIndex
		segBtn.Parent = holder
		UIKit.AddCorner(segBtn, 8)
		buttons[i] = segBtn
	end

	local function select(i)
		selectedIndex = i
		for idx, b in ipairs(buttons) do
			b.BackgroundColor3 = (idx == i) and Palette.Purple or Color3.fromRGB(210, 200, 230)
		end
		if props.OnChange then
			props.OnChange(options[i], i)
		end
	end

	for i, segBtn in ipairs(buttons) do
		segBtn.MouseButton1Click:Connect(function()
			select(i)
		end)
	end

	return holder, function() return options[selectedIndex], selectedIndex end
end

-- ============================================================
-- SCREEN TRANSITIONS
-- ============================================================
local currentScreen

local function fadeOut(frame, callback)
	local tweens = {}
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(0.2), { TextTransparency = 1 }))
		end
		if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(0.2), { BackgroundTransparency = 1 }))
		end
	end
	for _, tween in ipairs(tweens) do tween:Play() end
	task.delay(0.2, function()
		frame.Visible = false
		callback()
	end)
end

local function fadeIn(frame)
	frame.Visible = true
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:GetAttribute("OrigBG") == nil and (obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame")) then
			obj:SetAttribute("OrigBG", obj.BackgroundTransparency)
		end
		if obj:GetAttribute("OrigText") == nil and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
			obj:SetAttribute("OrigText", obj.TextTransparency)
		end
	end
	for _, obj in ipairs(frame:GetDescendants()) do
		local origBG = obj:GetAttribute("OrigBG")
		local origText = obj:GetAttribute("OrigText")
		if origBG then
			TweenService:Create(obj, TweenInfo.new(0.25), { BackgroundTransparency = origBG }):Play()
		end
		if origText then
			TweenService:Create(obj, TweenInfo.new(0.25), { TextTransparency = origText }):Play()
		end
	end
end

function UIKit.SwitchTo(newScreen)
	if currentScreen == newScreen then return end
	if currentScreen then
		fadeOut(currentScreen, function()
			fadeIn(newScreen)
		end)
	else
		fadeIn(newScreen)
	end
	currentScreen = newScreen
end

return UIKit
