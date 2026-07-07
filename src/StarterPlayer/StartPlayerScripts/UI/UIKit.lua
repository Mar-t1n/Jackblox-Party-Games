--[[
	UIKit - shared visual shell + widget factory for the Jackblox menu system.

	Owns the ScreenGui, static background, and the screen-switching (fade)
	machinery, plus the generic widget builders (labels, buttons, cards, text
	boxes, sliders, segment groups, avatars, speech bubbles) that every screen
	module (MenuScreens, LobbyScreens, GameScreens) is built from.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIKit = {}

-- Clean, flat Roblox-style palette (think Adopt Me / Brookhaven menus):
-- one calm background, white cards, a single accent color per action type.
UIKit.Palette = {
	Background = Color3.fromRGB(233, 238, 246),
	BackgroundDeep = Color3.fromRGB(213, 221, 235),

	TextDark = Color3.fromRGB(43, 51, 67),
	TextMuted = Color3.fromRGB(120, 128, 145),
	White = Color3.fromRGB(255, 255, 255),

	Pink = Color3.fromRGB(255, 105, 145),
	Purple = Color3.fromRGB(124, 92, 255),
	Teal = Color3.fromRGB(45, 200, 180),
	Yellow = Color3.fromRGB(255, 196, 61),
	Green = Color3.fromRGB(88, 199, 110),

	CardBG = Color3.fromRGB(255, 255, 255),
	CardMuted = Color3.fromRGB(244, 246, 250),

	MonoLobbies = Color3.fromRGB(124, 92, 255),
	MonoSettings = Color3.fromRGB(90, 100, 120),
	MonoNews = Color3.fromRGB(45, 170, 220),

	Danger = Color3.fromRGB(230, 90, 90),
	Locked = Color3.fromRGB(190, 196, 206),
}

UIKit.HEADER_FONT = Enum.Font.GothamBold
UIKit.BODY_FONT = Enum.Font.Gotham
UIKit.FUN_FONT = Enum.Font.FredokaOne

-- Placeholder mascot asset ids. Swap these rbxassetid values for the real
-- uploaded images once they exist in the Roblox asset library.
UIKit.MASCOTS = {
	"rbxassetid://104133752014920", -- orange blob w/ leaf hat + pinwheels
	"rbxassetid://121379093041208", -- blue raincloud
	"rbxassetid://72933597806578", -- yellow sun
	"rbxassetid://118971135808605", -- gray crescent moon
	"rbxassetid://124533450907974", -- blue flower cloud
	"rbxassetid://118260872113617", -- teal gear/cog
}

-- Placeholder ids for the 19 claymation title letters, in the exact order
-- the images were provided (each word spelled last-letter-first):
-- 1:! 2:S 3:E 4:M 5:A(GAMES) 6:G 7:Y 8:T 9:R 10:A(PARTY) 11:P
-- 12:x 13:o 14:l 15:b 16:k 17:c 18:a 19:J
UIKit.TITLE_LETTERS = {
	"rbxassetid://104098678396617", -- 1: !
	"rbxassetid://110177913698624", -- 2: S
	"rbxassetid://87371726004878", -- 3: E
	"rbxassetid://90003901387458", -- 4: M
	"rbxassetid://85162501112000", -- 5: A (GAMES)
	"rbxassetid://91765466171869", -- 6: G
	"rbxassetid://103897850157557", -- 7: Y
	"rbxassetid://72827414534376", -- 8: T
	"rbxassetid://97182924175481", -- 9: R
	"rbxassetid://100814258310676", -- 10: A (PARTY)
	"rbxassetid://84361178279519", -- 11: P
	"rbxassetid://140079995424809", -- 12: x
	"rbxassetid://106313208420338", -- 13: o
	"rbxassetid://112433977475171", -- 14: l
	"rbxassetid://125260447875559", -- 15: b
	"rbxassetid://117401085946014", -- 16: k
	"rbxassetid://101378655976869", -- 17: c
	"rbxassetid://91286066603013", -- 18: a
	"rbxassetid://76898224528677", -- 19: J
}

-- Placeholder background music asset id. Swap for the real uploaded track
-- once it exists in the Roblox asset library.
UIKit.MUSIC_ID = "rbxassetid://0"

-- App-wide wallpaper, shown behind every screen (main menu still layers its
-- own space scene on top of this).
UIKit.WALLPAPER_ID = "rbxassetid://80550034762356"

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

	local background = Instance.new("ImageLabel")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(255, 253, 240)
	background.BorderSizePixel = 0
	background.Image = UIKit.WALLPAPER_ID
	background.ScaleType = Enum.ScaleType.Crop
	background.ZIndex = 1
	background.Parent = screenGui

	local screens = Instance.new("Frame")
	screens.Name = "Screens"
	screens.Size = UDim2.fromScale(1, 1)
	screens.BackgroundTransparency = 1
	screens.ZIndex = 5
	screens.Parent = screenGui

	UIKit.ScreenGui = screenGui
	UIKit.ScreensContainer = screens

	-- Looping background music, independent of any single screen so it
	-- keeps playing across menu/lobby/gameplay transitions.
	local existingMusic = SoundService:FindFirstChild("BackgroundMusic")
	if existingMusic then
		existingMusic:Destroy()
	end

	local music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	music.SoundId = UIKit.MUSIC_ID
	music.Looped = true
	music.Volume = 0.5
	music.Parent = SoundService
	music:Play()

	UIKit.Music = music

	return UIKit
end

-- volumePercent is 0-100, matching the Settings screen's slider scale.
function UIKit.SetMusicVolume(volumePercent)
	if UIKit.Music then
		UIKit.Music.Volume = math.clamp(volumePercent, 0, 100) / 100
	end
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
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.85
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

	UIKit.AddCorner(btn, props.Radius or 12)
	UIKit.AddPadding(btn, 8)

	local baseSize = props.Size
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { Size = baseSize + UDim2.fromOffset(4, 4) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), { Size = baseSize }):Play()
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
	card.BackgroundTransparency = props.Transparency or 0
	card.BorderSizePixel = 0
	card.ZIndex = props.ZIndex or 6
	card.Parent = props.Parent

	UIKit.AddCorner(card, props.Radius or 16)
	UIKit.AddStroke(card, Palette.TextDark, 1, 0.9)
	return card
end

function UIKit.CreateTextBox(props)
	local box = Instance.new("TextBox")
	box.Text = props.Text or ""
	box.PlaceholderText = props.Placeholder or "Type here..."
	box.Size = props.Size
	box.Position = props.Position
	box.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	box.BackgroundColor3 = Palette.CardMuted
	box.TextColor3 = Palette.TextDark
	box.PlaceholderColor3 = Palette.TextMuted
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
	UIKit.AddCorner(box, 8)
	UIKit.AddStroke(box, Palette.Purple, 1, 0.6)
	UIKit.AddPadding(box, 6)
	return box
end

-- Roblox-headshot avatar image (round). Fetches asynchronously and swaps in
-- when ready so the UI never blocks waiting on the thumbnail service.
function UIKit.CreateAvatar(props)
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = props.Size
	avatar.Position = props.Position
	avatar.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	avatar.BackgroundColor3 = Palette.CardMuted
	avatar.BorderSizePixel = 0
	avatar.Image = ""
	avatar.ZIndex = props.ZIndex or 7
	avatar.Parent = props.Parent
	UIKit.AddCorner(avatar, props.Radius or 1000)
	if props.StrokeColor then
		UIKit.AddStroke(avatar, props.StrokeColor, props.StrokeThickness or 3, 0)
	end

	if props.UserId then
		task.spawn(function()
			local ok, content = pcall(function()
				return Players:GetUserThumbnailAsync(props.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok and avatar.Parent then
				avatar.Image = content
			end
		end)
	end

	return avatar
end

-- Quiplash-style speech bubble: rounded rectangle with a little pointer tail
-- pointing to the avatar underneath it. Returns the bubble frame; caller
-- attaches the avatar separately (see GameScreens) so bubble + avatar can be
-- laid out as one "who said this" unit.
function UIKit.CreateSpeechBubble(props)
	local bubble = Instance.new("Frame")
	bubble.Name = "SpeechBubble"
	bubble.Size = props.Size
	bubble.Position = props.Position
	bubble.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	bubble.BackgroundColor3 = Palette.White
	bubble.BorderSizePixel = 0
	bubble.ZIndex = props.ZIndex or 6
	bubble.Parent = props.Parent
	UIKit.AddCorner(bubble, props.Radius or 18)
	UIKit.AddStroke(bubble, Palette.TextDark, 2.5, 0)

	local tail = Instance.new("Frame")
	tail.Name = "Tail"
	tail.Size = UDim2.fromOffset(26, 26)
	tail.AnchorPoint = Vector2.new(0.5, 0)
	tail.Position = props.TailUp and UDim2.new(0.5, 0, 0, -10) or UDim2.new(0.5, 0, 1, -10)
	tail.Rotation = 45
	tail.BackgroundColor3 = Palette.White
	tail.BorderSizePixel = 0
	tail.ZIndex = bubble.ZIndex
	tail.Parent = bubble
	UIKit.AddCorner(tail, 6)
	UIKit.AddStroke(tail, Palette.TextDark, 2.5, 0)

	return bubble
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
	track.Size = UDim2.new(1, 0, 0, 8)
	track.Position = UDim2.new(0, 0, 0, 26)
	track.BackgroundColor3 = Palette.CardMuted
	track.BorderSizePixel = 0
	track.ZIndex = holder.ZIndex
	track.Parent = holder
	UIKit.AddCorner(track, 4)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Palette.Purple
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
	fill.ZIndex = holder.ZIndex + 1
	fill.Parent = track
	UIKit.AddCorner(fill, 4)

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
		segBtn.BackgroundColor3 = (i == selectedIndex) and Palette.Purple or Palette.CardMuted
		segBtn.ZIndex = holder.ZIndex
		segBtn.Parent = holder
		UIKit.AddCorner(segBtn, 8)
		buttons[i] = segBtn
		if i ~= selectedIndex then
			segBtn.TextColor3 = Palette.TextDark
		end
	end

	local function select(i)
		selectedIndex = i
		for idx, b in ipairs(buttons) do
			b.BackgroundColor3 = (idx == i) and Palette.Purple or Palette.CardMuted
			b.TextColor3 = (idx == i) and Palette.White or Palette.TextDark
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

-- Decorative mascot image scattered in menu whitespace. Purely cosmetic,
-- ignores input so it never blocks clicks on things behind/around it.
function UIKit.CreateMascot(props)
	local mascot = Instance.new("ImageLabel")
	mascot.Name = "Mascot"
	mascot.Image = props.Image or UIKit.MASCOTS[1]
	mascot.BackgroundTransparency = 1
	mascot.Size = props.Size or UDim2.fromOffset(140, 140)
	mascot.Position = props.Position
	mascot.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	mascot.Rotation = props.Rotation or 0
	mascot.ZIndex = props.ZIndex or 2
	mascot.ScaleType = Enum.ScaleType.Fit
	mascot.Parent = props.Parent

	local AVOID_RADIUS = 240
	local AVOID_MAX_PUSH = 90

	if props.Bob ~= false then
		local basePos = mascot.Position
		local currentOffset = Vector2.new(0, 0)

		-- Gentle idle bob so they still feel alive when the cursor is far away.
		task.spawn(function()
			while mascot.Parent do
				local dur = math.random(22, 34) / 10
				TweenService:Create(mascot, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Rotation = (props.Rotation or 0) + 3,
				}):Play()
				task.wait(dur)
				TweenService:Create(mascot, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Rotation = (props.Rotation or 0) - 3,
				}):Play()
				task.wait(dur)
			end
		end)

		-- Cursor avoidance: push the mascot away from the mouse when it gets
		-- close, then ease back to its resting spot once the cursor leaves.
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			if not mascot.Parent then
				conn:Disconnect()
				return
			end

			local mousePos = UserInputService:GetMouseLocation()
			local center = mascot.AbsolutePosition + mascot.AbsoluteSize * 0.5
			local diff = center - mousePos
			local dist = diff.Magnitude

			local targetOffset = Vector2.new(0, 0)
			if dist < AVOID_RADIUS and dist > 0.001 then
				local pushStrength = (AVOID_RADIUS - dist) / AVOID_RADIUS
				targetOffset = (diff / dist) * (pushStrength * AVOID_MAX_PUSH)
			end

			currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 8, 0, 1))
			mascot.Position = basePos + UDim2.fromOffset(currentOffset.X, currentOffset.Y)
		end)
	end

	return mascot
end

-- ============================================================
-- SCREEN TRANSITIONS
-- ============================================================
local currentScreen

local function fadeOut(frame, callback)
	local tweens = {}
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(0.15), { TextTransparency = 1 }))
		end
		if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") or obj:IsA("ImageLabel") then
			table.insert(tweens, TweenService:Create(obj, TweenInfo.new(0.15), { BackgroundTransparency = 1 }))
		end
	end
	for _, tween in ipairs(tweens) do tween:Play() end
	task.delay(0.15, function()
		frame.Visible = false
		callback()
	end)
end

local function fadeIn(frame)
	frame.Visible = true
	for _, obj in ipairs(frame:GetDescendants()) do
		if obj:GetAttribute("OrigBG") == nil and (obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") or obj:IsA("ImageLabel")) then
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
			TweenService:Create(obj, TweenInfo.new(0.2), { BackgroundTransparency = origBG }):Play()
		end
		if origText then
			TweenService:Create(obj, TweenInfo.new(0.2), { TextTransparency = origText }):Play()
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
