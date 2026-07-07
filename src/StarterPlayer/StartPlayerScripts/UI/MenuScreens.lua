--[[
	MenuScreens - Main Menu, Select Game, Settings, and News screens.

	These screens are cosmetic/navigational only (no server data), so this
	module just builds them and hands back the screens + buttons that
	Main.client.luau needs to wire cross-screen navigation
	(Play -> Select Game -> Create Game, etc).
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MenuScreens = {}

-- Claymation title letters, referencing UIKit.TITLE_LETTERS by index (see
-- that table for which image slot is which letter). widthRatio approximates
-- each letter's width relative to its row height so skinny letters (l, !)
-- don't leave huge gaps and wide ones (M) don't get squashed.
local JACKBLOX_LETTERS = {
	{ idx = 19, widthRatio = 0.85 }, -- J
	{ idx = 18, widthRatio = 0.85 }, -- a
	{ idx = 17, widthRatio = 0.8 }, -- c
	{ idx = 16, widthRatio = 0.85 }, -- k
	{ idx = 15, widthRatio = 0.85 }, -- b
	{ idx = 14, widthRatio = 0.45 }, -- l
	{ idx = 13, widthRatio = 0.85 }, -- o
	{ idx = 12, widthRatio = 0.85 }, -- x
}

local PARTY_LETTERS = {
	{ idx = 11, widthRatio = 0.8 }, -- P
	{ idx = 10, widthRatio = 0.85 }, -- A
	{ idx = 9, widthRatio = 0.8 }, -- R
	{ idx = 8, widthRatio = 0.8 }, -- T
	{ idx = 7, widthRatio = 0.8 }, -- Y
}

local GAMES_LETTERS = {
	{ idx = 6, widthRatio = 0.85 }, -- G
	{ idx = 5, widthRatio = 0.85 }, -- A
	{ idx = 4, widthRatio = 1.05 }, -- M
	{ idx = 3, widthRatio = 0.75 }, -- E
	{ idx = 2, widthRatio = 0.75 }, -- S
	{ idx = 1, widthRatio = 0.65 }, -- !
}

-- Builds one row of letters, each jiggling independently (random rotation
-- wobble with its own duration/phase so the whole word feels alive rather
-- than swaying in unison).
local function buildLetterRow(UIKit, parent, letters, rowHeight, layoutOrder)
	local row = Instance.new("Frame")
	row.Name = "LetterRow"
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.new(0, 0, 0, rowHeight)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.ZIndex = 4
	row.Parent = parent

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 2)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	for i, letter in ipairs(letters) do
		local cellWidth = math.floor(rowHeight * letter.widthRatio)

		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromOffset(cellWidth, rowHeight)
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = i
		cell.ZIndex = 4
		cell.Parent = row

		local image = Instance.new("ImageLabel")
		image.Size = UDim2.fromScale(1, 1)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.BackgroundTransparency = 1
		image.Image = UIKit.TITLE_LETTERS[letter.idx]
		image.ScaleType = Enum.ScaleType.Fit
		image.ZIndex = 4
		image.Parent = cell

		task.spawn(function()
			task.wait(math.random(0, 200) / 100)
			while image.Parent do
				local dur = math.random(9, 20) / 10
				local wobble = math.random(6, 14)
				TweenService:Create(image, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = wobble }):Play()
				task.wait(dur)
				TweenService:Create(image, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = -wobble }):Play()
				task.wait(dur)
			end
		end)

		-- Cursor avoidance: each letter scoots away from the mouse when it
		-- gets close, then eases back to its resting spot.
		local LETTER_AVOID_RADIUS = 110
		local LETTER_AVOID_MAX_PUSH = 38
		local basePosition = image.Position
		local currentOffset = Vector2.new(0, 0)

		local avoidConn
		avoidConn = RunService.RenderStepped:Connect(function(dt)
			if not image.Parent then
				avoidConn:Disconnect()
				return
			end

			local mousePos = UserInputService:GetMouseLocation()
			local center = image.AbsolutePosition + image.AbsoluteSize * 0.5
			local diff = center - mousePos
			local dist = diff.Magnitude

			local targetOffset = Vector2.new(0, 0)
			if dist < LETTER_AVOID_RADIUS and dist > 0.001 then
				local pushStrength = (LETTER_AVOID_RADIUS - dist) / LETTER_AVOID_RADIUS
				targetOffset = (diff / dist) * (pushStrength * LETTER_AVOID_MAX_PUSH)
			end

			currentOffset = currentOffset:Lerp(targetOffset, math.clamp(dt * 9, 0, 1))
			image.Position = basePosition + UDim2.fromOffset(currentOffset.X, currentOffset.Y)
		end)
	end

	return row
end

-- Scattered layout for the 6 mascot images: mix of corners/edges so the
-- title and Play button in the middle stay clear.
local MASCOT_LAYOUT = {
	{ Position = UDim2.fromScale(0.16, 0.24), Size = UDim2.fromOffset(420, 420), Rotation = -8 },
	{ Position = UDim2.fromScale(0.84, 0.22), Size = UDim2.fromOffset(380, 380), Rotation = 10 },
	{ Position = UDim2.fromScale(0.1, 0.66), Size = UDim2.fromOffset(450, 450), Rotation = 6 },
	{ Position = UDim2.fromScale(0.89, 0.68), Size = UDim2.fromOffset(420, 420), Rotation = -6 },
	{ Position = UDim2.fromScale(0.28, 0.78), Size = UDim2.fromOffset(340, 340), Rotation = -4 },
	{ Position = UDim2.fromScale(0.73, 0.8), Size = UDim2.fromOffset(350, 350), Rotation = 8 },
}

function MenuScreens.Build(UIKit)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT

	local handles = {}

	-- ============================================================
	-- SCREEN 1: MAIN MENU
	-- ============================================================
	local mainMenu = UIKit.NewScreen("MainMenu")

	for i, layout in ipairs(MASCOT_LAYOUT) do
		UIKit.CreateMascot({
			Image = UIKit.MASCOTS[i],
			Size = layout.Size,
			Position = layout.Position,
			Rotation = layout.Rotation,
			Parent = mainMenu,
		})
	end

	local titleCard = Instance.new("Frame")
	titleCard.Size = UDim2.fromScale(0.6, 0.36)
	titleCard.Position = UDim2.fromScale(0.5, 0.34)
	titleCard.AnchorPoint = Vector2.new(0.5, 0.5)
	titleCard.BackgroundTransparency = 1
	titleCard.ZIndex = 4
	titleCard.Parent = mainMenu

	local wordStack = Instance.new("Frame")
	wordStack.Name = "WordStack"
	wordStack.AutomaticSize = Enum.AutomaticSize.XY
	wordStack.Size = UDim2.new()
	wordStack.Position = UDim2.fromScale(0.5, 0)
	wordStack.AnchorPoint = Vector2.new(0.5, 0)
	wordStack.BackgroundTransparency = 1
	wordStack.ZIndex = 4
	wordStack.Parent = titleCard

	local wordStackLayout = Instance.new("UIListLayout")
	wordStackLayout.FillDirection = Enum.FillDirection.Vertical
	wordStackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	wordStackLayout.Padding = UDim.new(0, 6)
	wordStackLayout.SortOrder = Enum.SortOrder.LayoutOrder
	wordStackLayout.Parent = wordStack

	buildLetterRow(UIKit, wordStack, JACKBLOX_LETTERS, 120, 1)
	buildLetterRow(UIKit, wordStack, PARTY_LETTERS, 90, 2)
	buildLetterRow(UIKit, wordStack, GAMES_LETTERS, 90, 3)

	-- Play button lives on its own, well below the title, as a jiggling
	-- image logo rather than a text button.
	local playButton = Instance.new("ImageButton")
	playButton.Name = "PlayButton"
	playButton.Size = UDim2.fromOffset(340, 340)
	playButton.Position = UDim2.fromScale(0.5, 0.78)
	playButton.AnchorPoint = Vector2.new(0.5, 0.5)
	playButton.BackgroundTransparency = 1
	playButton.Image = "rbxassetid://105601639847476"
	playButton.ScaleType = Enum.ScaleType.Fit
	playButton.ZIndex = 4
	playButton.Parent = mainMenu

	local playBaseSize = playButton.Size
	task.spawn(function()
		while playButton.Parent do
			TweenService:Create(playButton, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = playBaseSize + UDim2.fromOffset(14, 14),
			}):Play()
			task.wait(0.6)
			TweenService:Create(playButton, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = playBaseSize,
			}):Play()
			task.wait(0.6)
		end
	end)

	task.spawn(function()
		task.wait(math.random(0, 100) / 100)
		while playButton.Parent do
			local dur = math.random(9, 16) / 10
			local wobble = math.random(5, 9)
			TweenService:Create(playButton, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = wobble }):Play()
			task.wait(dur)
			TweenService:Create(playButton, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = -wobble }):Play()
			task.wait(dur)
		end
	end)

	-- Punchy click feedback: grows on press, snaps back with a little
	-- overshoot on release.
	playButton.MouseButton1Down:Connect(function()
		TweenService:Create(playButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = playBaseSize + UDim2.fromOffset(40, 40),
		}):Play()
	end)

	local function releasePlayButton()
		TweenService:Create(playButton, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = playBaseSize,
		}):Play()
	end
	playButton.MouseButton1Up:Connect(releasePlayButton)
	playButton.MouseLeave:Connect(releasePlayButton)

	local topBarHolder = Instance.new("Frame")
	topBarHolder.Size = UDim2.fromOffset(220, 50)
	topBarHolder.Position = UDim2.fromScale(0.98, 0.03)
	topBarHolder.AnchorPoint = Vector2.new(1, 0)
	topBarHolder.BackgroundTransparency = 1
	topBarHolder.ZIndex = 6
	topBarHolder.Parent = mainMenu

	local topBarLayout = Instance.new("UIListLayout")
	topBarLayout.FillDirection = Enum.FillDirection.Horizontal
	topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	topBarLayout.Padding = UDim.new(0, 10)
	topBarLayout.Parent = topBarHolder

	local settingsShortcut = UIKit.CreateButton({
		Text = "Settings", Size = UDim2.fromOffset(100, 40), Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.CardBG, TextColor = Palette.TextDark,
		Radius = 10, LayoutOrder = 1, Parent = topBarHolder,
	})

	local newsShortcut = UIKit.CreateButton({
		Text = "News", Size = UDim2.fromOffset(100, 40), Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.CardBG, TextColor = Palette.TextDark,
		Radius = 10, LayoutOrder = 2, Parent = topBarHolder,
	})

	-- ============================================================
	-- SCREEN 2: SELECT GAME
	-- ============================================================
	local modeSelect = UIKit.NewScreen("ModeSelect")

	UIKit.CreateLabel({
		Text = "Select a Game",
		Size = UDim2.fromScale(0.8, 0.1),
		Position = UDim2.fromScale(0.5, 0.14),
		TextColor = Palette.TextDark,
		Parent = modeSelect,
	})

	local gameGrid = Instance.new("Frame")
	gameGrid.Size = UDim2.fromScale(0.85, 0.6)
	gameGrid.Position = UDim2.fromScale(0.5, 0.52)
	gameGrid.AnchorPoint = Vector2.new(0.5, 0.5)
	gameGrid.BackgroundTransparency = 1
	gameGrid.ZIndex = 6
	gameGrid.Parent = modeSelect

	local gameGridLayout = Instance.new("UIGridLayout")
	gameGridLayout.CellSize = UDim2.fromScale(0.23, 0.85)
	gameGridLayout.CellPadding = UDim2.fromScale(0.026, 0)
	gameGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gameGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gameGridLayout.Parent = gameGrid

	local function buildGameTile(name, subtitle, available, layoutOrder)
		local tile = Instance.new("Frame")
		tile.BackgroundColor3 = Palette.CardBG
		tile.BorderSizePixel = 0
		tile.LayoutOrder = layoutOrder
		tile.ZIndex = 6
		tile.Parent = gameGrid
		UIKit.AddCorner(tile, 16)
		UIKit.AddStroke(tile, Palette.TextDark, 1, 0.9)

		UIKit.CreateLabel({
			Text = name,
			Size = UDim2.fromScale(0.85, 0.18),
			Position = UDim2.fromScale(0.5, 0.62),
			TextColor = available and Palette.TextDark or Palette.TextMuted,
			ZIndex = 7,
			Parent = tile,
		})

		UIKit.CreateLabel({
			Text = subtitle,
			Size = UDim2.fromScale(0.85, 0.12),
			Position = UDim2.fromScale(0.5, 0.76),
			Font = BODY_FONT,
			TextColor = Palette.TextMuted,
			ZIndex = 7,
			Parent = tile,
		})

		local playTile = UIKit.CreateButton({
			Text = available and "PLAY" or "SOON",
			Size = UDim2.fromScale(0.7, 0.16),
			Position = UDim2.fromScale(0.5, 0.9),
			Color = available and Palette.Purple or Palette.Locked,
			Radius = 10,
			ZIndex = 7,
			Parent = tile,
		})
		if not available then
			playTile.AutoButtonColor = false
		end

		return playTile
	end

	local quiplashTile = buildGameTile("Quiplash", "2 players, funniest answer wins", true, 1)
	buildGameTile("Trivia Clash", "Coming soon", false, 2)
	buildGameTile("Draw It!", "Coming soon", false, 3)
	buildGameTile("Word Bomb", "Coming soon", false, 4)

	local modeBackButton = UIKit.CreateButton({
		Text = "Back", Size = UDim2.fromOffset(140, 50), Position = UDim2.fromScale(0.06, 0.06),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.CardBG, TextColor = Palette.TextDark, Parent = modeSelect,
	})

	-- ============================================================
	-- SCREEN 3: SETTINGS
	-- ============================================================
	local settingsScreen = UIKit.NewScreen("SettingsScreen")

	local settingsPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.6, 0.75),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = settingsScreen,
	})

	UIKit.CreateLabel({
		Text = "Settings",
		Size = UDim2.fromScale(0.6, 0.09),
		Position = UDim2.fromScale(0.5, 0.08),
		TextColor = Palette.TextDark,
		Parent = settingsPanel,
	})

	UIKit.CreateLabel({
		Text = "Audio & Display",
		Size = UDim2.fromScale(0.4, 0.05),
		Position = UDim2.fromScale(0.27, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = settingsPanel,
	})

	UIKit.CreateSlider({
		Label = "Sound Volume",
		Default = 70,
		Size = UDim2.fromScale(0.42, 0.08),
		Position = UDim2.fromScale(0.06, 0.23),
		Parent = settingsPanel,
	})

	UIKit.CreateSlider({
		Label = "Music Volume",
		Default = 60,
		Size = UDim2.fromScale(0.42, 0.08),
		Position = UDim2.fromScale(0.06, 0.34),
		Parent = settingsPanel,
		OnChange = function(value)
			UIKit.SetMusicVolume(value)
		end,
	})
	UIKit.SetMusicVolume(60)

	UIKit.CreateSlider({
		Label = "Brightness",
		Default = 50,
		Size = UDim2.fromScale(0.42, 0.08),
		Position = UDim2.fromScale(0.06, 0.45),
		Parent = settingsPanel,
	})

	UIKit.CreateLabel({
		Text = "Graphics Quality",
		Size = UDim2.fromScale(0.42, 0.05),
		Position = UDim2.fromScale(0.27, 0.56),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = settingsPanel,
	})

	UIKit.CreateSegmentGroup({
		Options = { "Low", "Medium", "High" },
		DefaultIndex = 2,
		Size = UDim2.fromScale(0.42, 0.07),
		Position = UDim2.fromScale(0.06, 0.61),
		Parent = settingsPanel,
		OnChange = function(optionText)
			print("[Jackblox] Quality set to " .. optionText)
		end,
	})

	UIKit.CreateLabel({
		Text = "Key Bindings",
		Size = UDim2.fromScale(0.4, 0.05),
		Position = UDim2.fromScale(0.73, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = settingsPanel,
	})

	local keyBindHolder = Instance.new("Frame")
	keyBindHolder.Size = UDim2.fromScale(0.42, 0.65)
	keyBindHolder.Position = UDim2.fromScale(0.52, 0.22)
	keyBindHolder.BackgroundTransparency = 1
	keyBindHolder.ZIndex = 7
	keyBindHolder.Parent = settingsPanel

	local keyBindLayout = Instance.new("UIListLayout")
	keyBindLayout.Padding = UDim.new(0, 8)
	keyBindLayout.Parent = keyBindHolder

	local defaultBinds = {
		{ Action = "Move Forward", Key = "W" },
		{ Action = "Move Back", Key = "S" },
		{ Action = "Jump", Key = "Space" },
		{ Action = "Attack", Key = "MB1" },
		{ Action = "Dash", Key = "Shift" },
		{ Action = "Interact", Key = "E" },
	}

	for i, bind in ipairs(defaultBinds) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i
		row.ZIndex = 7
		row.Parent = keyBindHolder

		UIKit.CreateLabel({
			Text = bind.Action,
			Size = UDim2.fromScale(0.55, 1),
			Position = UDim2.fromScale(0, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			XAlign = Enum.TextXAlignment.Left,
			Font = BODY_FONT,
			TextColor = Palette.TextDark,
			ZIndex = 8,
			Parent = row,
		})

		local remapButton = UIKit.CreateButton({
			Text = bind.Key,
			Size = UDim2.fromScale(0.4, 0.85),
			Position = UDim2.fromScale(1, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = Palette.CardMuted,
			TextColor = Palette.TextDark,
			Radius = 8,
			ZIndex = 8,
			Parent = row,
		})

		remapButton.MouseButton1Click:Connect(function()
			remapButton.Text = "Press a key..."
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					remapButton.Text = input.KeyCode.Name
					conn:Disconnect()
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
					remapButton.Text = input.UserInputType == Enum.UserInputType.MouseButton1 and "MB1" or "MB2"
					conn:Disconnect()
				end
			end)
		end)
	end

	local settingsBackButton = UIKit.CreateButton({
		Text = "Back",
		Size = UDim2.fromOffset(150, 50),
		Position = UDim2.fromScale(0.27, 0.94),
		Color = Palette.CardMuted,
		TextColor = Palette.TextDark,
		Parent = settingsPanel,
	})

	UIKit.CreateButton({
		Text = "Reset Defaults",
		Size = UDim2.fromOffset(180, 50),
		Position = UDim2.fromScale(0.73, 0.94),
		Color = Palette.Yellow,
		TextColor = Palette.TextDark,
		Parent = settingsPanel,
	})

	-- ============================================================
	-- SCREEN 4: NEWS (Updates tab + Mail tab)
	-- ============================================================
	local newsScreen = UIKit.NewScreen("NewsScreen")

	local newsPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.7, 0.75),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = newsScreen,
	})

	local closeNewsButton = UIKit.CreateButton({
		Text = "X",
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Color = Palette.CardMuted,
		TextColor = Palette.TextDark,
		Radius = 18,
		Parent = newsPanel,
	})

	local newsTabsHolder = Instance.new("Frame")
	newsTabsHolder.Size = UDim2.fromScale(0.3, 0.06)
	newsTabsHolder.Position = UDim2.fromScale(0.02, 0.02)
	newsTabsHolder.BackgroundTransparency = 1
	newsTabsHolder.ZIndex = 7
	newsTabsHolder.Parent = newsPanel

	local newsTabsLayout = Instance.new("UIListLayout")
	newsTabsLayout.FillDirection = Enum.FillDirection.Horizontal
	newsTabsLayout.Padding = UDim.new(0, 8)
	newsTabsLayout.Parent = newsTabsHolder

	local updatesTabButton = UIKit.CreateButton({
		Text = "Updates", Size = UDim2.fromScale(0.48, 1), Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.Purple, TextColor = Palette.White,
		Radius = 10, LayoutOrder = 1, Parent = newsTabsHolder,
	})

	local mailTabButton = UIKit.CreateButton({
		Text = "Mail", Size = UDim2.fromScale(0.48, 1), Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.CardMuted, TextColor = Palette.TextDark,
		Radius = 10, LayoutOrder = 2, Parent = newsTabsHolder,
	})

	local updatesTab = Instance.new("Frame")
	updatesTab.Size = UDim2.fromScale(1, 0.88)
	updatesTab.Position = UDim2.fromScale(0, 0.1)
	updatesTab.BackgroundTransparency = 1
	updatesTab.ZIndex = 6
	updatesTab.Visible = true
	updatesTab.Parent = newsPanel

	local updateLogList = Instance.new("ScrollingFrame")
	updateLogList.Size = UDim2.fromScale(0.22, 1)
	updateLogList.BackgroundTransparency = 1
	updateLogList.BorderSizePixel = 0
	updateLogList.ScrollBarThickness = 6
	updateLogList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	updateLogList.CanvasSize = UDim2.new()
	updateLogList.ZIndex = 7
	updateLogList.Parent = updatesTab

	UIKit.CreateLabel({
		Text = "UPDATE LOGS",
		Size = UDim2.fromScale(1, 0.06),
		Position = UDim2.fromScale(0.5, 0.03),
		TextColor = Palette.TextDark,
		Parent = updateLogList,
	})

	local updateLogLayout = Instance.new("UIListLayout")
	updateLogLayout.Padding = UDim.new(0, 6)
	updateLogLayout.SortOrder = Enum.SortOrder.LayoutOrder
	updateLogLayout.Parent = updateLogList

	local updateLogSpacer = Instance.new("Frame")
	updateLogSpacer.Size = UDim2.new(1, 0, 0, 30)
	updateLogSpacer.BackgroundTransparency = 1
	updateLogSpacer.LayoutOrder = 0
	updateLogSpacer.Parent = updateLogList

	local sampleUpdates = {
		{ Num = "1.0", Tag = "Launch" },
	}
	for i, u in ipairs(sampleUpdates) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 46)
		row.BackgroundColor3 = i == 1 and Palette.Teal or Palette.CardMuted
		row.LayoutOrder = i
		row.ZIndex = 7
		row.Parent = updateLogList
		UIKit.AddCorner(row, 10)

		UIKit.CreateLabel({
			Text = u.Num,
			Size = UDim2.fromScale(0.35, 1),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			TextColor = Palette.TextDark,
			ZIndex = 8,
			Parent = row,
		})

		UIKit.CreateLabel({
			Text = u.Tag,
			Size = UDim2.fromScale(0.55, 0.7),
			Position = UDim2.fromScale(0.98, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Font = BODY_FONT,
			TextColor = Palette.TextDark,
			XAlign = Enum.TextXAlignment.Right,
			ZIndex = 8,
			Parent = row,
		})
	end

	local patchNotesFrame = Instance.new("Frame")
	patchNotesFrame.Size = UDim2.fromScale(0.76, 1)
	patchNotesFrame.Position = UDim2.fromScale(0.24, 0)
	patchNotesFrame.BackgroundTransparency = 1
	patchNotesFrame.ZIndex = 6
	patchNotesFrame.Parent = updatesTab

	UIKit.CreateLabel({
		Text = "Welcome to Jackblox: Party Games!",
		Size = UDim2.fromScale(1, 0.1),
		Position = UDim2.fromScale(0.5, 0.06),
		TextColor = Palette.TextDark,
		Parent = patchNotesFrame,
	})

	UIKit.CreateLabel({
		Text = "Our first game, Quiplash, is live. More original party games are on the way.",
		Size = UDim2.fromScale(0.95, 0.14),
		Position = UDim2.fromScale(0.5, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		YAlign = Enum.TextYAlignment.Top,
		Parent = patchNotesFrame,
	})

	local mailTab = Instance.new("Frame")
	mailTab.Size = UDim2.fromScale(1, 0.88)
	mailTab.Position = UDim2.fromScale(0, 0.1)
	mailTab.BackgroundTransparency = 1
	mailTab.ZIndex = 6
	mailTab.Visible = false
	mailTab.Parent = newsPanel

	UIKit.CreateLabel({
		Text = "No new mail yet - check back after your first match!",
		Size = UDim2.fromScale(0.8, 0.1),
		Position = UDim2.fromScale(0.5, 0.5),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = mailTab,
	})

	updatesTabButton.MouseButton1Click:Connect(function()
		updatesTab.Visible = true
		mailTab.Visible = false
		updatesTabButton.BackgroundColor3 = Palette.Purple
		updatesTabButton.TextColor3 = Palette.White
		mailTabButton.BackgroundColor3 = Palette.CardMuted
		mailTabButton.TextColor3 = Palette.TextDark
	end)

	mailTabButton.MouseButton1Click:Connect(function()
		updatesTab.Visible = false
		mailTab.Visible = true
		mailTabButton.BackgroundColor3 = Palette.Purple
		mailTabButton.TextColor3 = Palette.White
		updatesTabButton.BackgroundColor3 = Palette.CardMuted
		updatesTabButton.TextColor3 = Palette.TextDark
	end)

	-- ============================================================
	-- LOCAL NAVIGATION (wiring that stays entirely within this module)
	-- ============================================================
	modeBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(mainMenu) end)
	settingsShortcut.MouseButton1Click:Connect(function() UIKit.SwitchTo(settingsScreen) end)
	newsShortcut.MouseButton1Click:Connect(function() UIKit.SwitchTo(newsScreen) end)
	settingsBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(mainMenu) end)
	closeNewsButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(mainMenu) end)

	handles.MainMenu = mainMenu
	handles.ModeSelect = modeSelect
	handles.SettingsScreen = settingsScreen
	handles.NewsScreen = newsScreen
	handles.PlayButton = playButton
	handles.QuiplashButton = quiplashTile

	return handles
end

return MenuScreens
