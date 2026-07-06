--[[
	MenuScreens - Main Menu, Mode Select, Settings, and News screens.

	These screens are cosmetic/navigational only (no server data), so this
	module just builds them and hands back the screens + buttons that
	Main.client.luau needs to wire cross-screen navigation
	(Play -> Mode Select -> Lobbies, etc).
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local MenuScreens = {}

function MenuScreens.Build(UIKit)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT

	local handles = {}

	-- ============================================================
	-- SCREEN 1: MAIN MENU
	-- ============================================================
	local mainMenu = UIKit.NewScreen("MainMenu")

	local title = UIKit.CreateLabel({
		Text = "Jackblox: Party Games",
		Size = UDim2.fromScale(0.85, 0.2),
		Position = UDim2.fromScale(0.5, 0.32),
		TextColor = Palette.Purple,
		StrokeTransparency = 0.75,
		StrokeColor = Palette.White,
		Parent = mainMenu,
	})

	task.spawn(function()
		while title.Parent do
			TweenService:Create(title, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = 1.5 }):Play()
			task.wait(1.4)
			TweenService:Create(title, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = -1.5 }):Play()
			task.wait(1.4)
		end
	end)

	UIKit.CreateLabel({
		Text = "The couch-competitive party game collection",
		Size = UDim2.fromScale(0.6, 0.06),
		Position = UDim2.fromScale(0.5, 0.46),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = mainMenu,
	})

	local playButton = UIKit.CreateButton({
		Text = "PLAY",
		Size = UDim2.fromOffset(260, 80),
		Position = UDim2.fromScale(0.5, 0.62),
		Color = Palette.Pink,
		Parent = mainMenu,
	})

	-- ============================================================
	-- SCREEN 2: MODE SELECT
	-- ============================================================
	local modeSelect = UIKit.NewScreen("ModeSelect")

	UIKit.CreateLabel({
		Text = "Choose an Option",
		Size = UDim2.fromScale(0.8, 0.15),
		Position = UDim2.fromScale(0.5, 0.25),
		TextColor = Palette.Purple,
		StrokeTransparency = 0.75,
		Parent = modeSelect,
	})

	local modeButtonHolder = Instance.new("Frame")
	modeButtonHolder.Size = UDim2.fromScale(0.7, 0.2)
	modeButtonHolder.Position = UDim2.fromScale(0.5, 0.5)
	modeButtonHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	modeButtonHolder.BackgroundTransparency = 1
	modeButtonHolder.ZIndex = 6
	modeButtonHolder.Parent = modeSelect

	local modeListLayout = Instance.new("UIListLayout")
	modeListLayout.FillDirection = Enum.FillDirection.Horizontal
	modeListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	modeListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	modeListLayout.Padding = UDim.new(0, 30)
	modeListLayout.Parent = modeButtonHolder

	local lobbiesButton = UIKit.CreateButton({
		Text = "LOBBIES", Size = UDim2.fromOffset(220, 200), Position = UDim2.new(),
		Color = Palette.MonoLobbies, AnchorPoint = Vector2.new(0, 0), Parent = modeButtonHolder,
	})
	lobbiesButton.LayoutOrder = 1

	local settingsButton = UIKit.CreateButton({
		Text = "SETTINGS", Size = UDim2.fromOffset(220, 200), Position = UDim2.new(),
		Color = Palette.MonoSettings, AnchorPoint = Vector2.new(0, 0), Parent = modeButtonHolder,
	})
	settingsButton.LayoutOrder = 2

	local newsButton = UIKit.CreateButton({
		Text = "NEWS", Size = UDim2.fromOffset(220, 200), Position = UDim2.new(),
		Color = Palette.MonoNews, AnchorPoint = Vector2.new(0, 0), Parent = modeButtonHolder,
	})
	newsButton.LayoutOrder = 3

	local modeBackButton = UIKit.CreateButton({
		Text = "< BACK", Size = UDim2.fromOffset(160, 60), Position = UDim2.fromScale(0.5, 0.85),
		Color = Color3.fromRGB(220, 210, 235), TextColor = Palette.TextDark, Parent = modeSelect,
	})

	-- ============================================================
	-- SCREEN 3: SETTINGS
	-- ============================================================
	local settingsScreen = UIKit.NewScreen("SettingsScreen")

	local settingsPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.65, 0.8),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = settingsScreen,
	})

	UIKit.CreateLabel({
		Text = "Settings",
		Size = UDim2.fromScale(0.6, 0.09),
		Position = UDim2.fromScale(0.5, 0.08),
		TextColor = Palette.Purple,
		Parent = settingsPanel,
	})

	UIKit.CreateLabel({
		Text = "Audio & Display",
		Size = UDim2.fromScale(0.4, 0.05),
		Position = UDim2.fromScale(0.27, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
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
	})

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
		TextColor = Palette.TextDark,
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
		Text = "Assist Mode",
		Size = UDim2.fromScale(0.42, 0.05),
		Position = UDim2.fromScale(0.27, 0.7),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = settingsPanel,
	})

	UIKit.CreateSegmentGroup({
		Options = { "On", "Off" },
		DefaultIndex = 2,
		Size = UDim2.fromScale(0.42, 0.07),
		Position = UDim2.fromScale(0.06, 0.75),
		Parent = settingsPanel,
	})

	UIKit.CreateLabel({
		Text = "Key Bindings",
		Size = UDim2.fromScale(0.4, 0.05),
		Position = UDim2.fromScale(0.73, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = settingsPanel,
	})

	local keyBindHolder = Instance.new("Frame")
	keyBindHolder.Size = UDim2.fromScale(0.42, 0.55)
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
			Color = Palette.MonoLobbies,
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
		Text = "< BACK",
		Size = UDim2.fromOffset(150, 50),
		Position = UDim2.fromScale(0.27, 0.94),
		Color = Color3.fromRGB(220, 210, 235),
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
		Size = UDim2.fromScale(0.85, 0.85),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = newsScreen,
	})

	local closeNewsButton = UIKit.CreateButton({
		Text = "X",
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Color = Palette.Pink,
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
		AnchorPoint = Vector2.new(0, 0), Color = Palette.Teal, TextColor = Palette.TextDark,
		Radius = 10, LayoutOrder = 1, Parent = newsTabsHolder,
	})

	local mailTabButton = UIKit.CreateButton({
		Text = "Mail", Size = UDim2.fromScale(0.48, 1), Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0), Color = Palette.MonoSettings, TextColor = Palette.White,
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
		TextColor = Palette.Purple,
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
		row.BackgroundColor3 = i == 1 and Palette.Teal or Color3.fromRGB(240, 234, 250)
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
		TextColor = Palette.Purple,
		Parent = patchNotesFrame,
	})

	UIKit.CreateLabel({
		Text = "Our first game, a Quiplash-style joke-and-vote party game, is live. More original party games are on the way.",
		Size = UDim2.fromScale(0.95, 0.14),
		Position = UDim2.fromScale(0.5, 0.18),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
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
		TextColor = Palette.TextDark,
		Parent = mailTab,
	})

	updatesTabButton.MouseButton1Click:Connect(function()
		updatesTab.Visible = true
		mailTab.Visible = false
		updatesTabButton.BackgroundColor3 = Palette.Teal
		updatesTabButton.TextColor3 = Palette.TextDark
		mailTabButton.BackgroundColor3 = Palette.MonoSettings
		mailTabButton.TextColor3 = Palette.White
	end)

	mailTabButton.MouseButton1Click:Connect(function()
		updatesTab.Visible = false
		mailTab.Visible = true
		mailTabButton.BackgroundColor3 = Palette.Teal
		mailTabButton.TextColor3 = Palette.TextDark
		updatesTabButton.BackgroundColor3 = Palette.MonoSettings
		updatesTabButton.TextColor3 = Palette.White
	end)

	-- ============================================================
	-- LOCAL NAVIGATION (wiring that stays entirely within this module)
	-- ============================================================
	modeBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(mainMenu) end)
	settingsButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(settingsScreen) end)
	newsButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(newsScreen) end)
	settingsBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(modeSelect) end)
	closeNewsButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(modeSelect) end)

	handles.MainMenu = mainMenu
	handles.ModeSelect = modeSelect
	handles.SettingsScreen = settingsScreen
	handles.NewsScreen = newsScreen
	handles.PlayButton = playButton
	handles.LobbiesButton = lobbiesButton

	return handles
end

return MenuScreens
