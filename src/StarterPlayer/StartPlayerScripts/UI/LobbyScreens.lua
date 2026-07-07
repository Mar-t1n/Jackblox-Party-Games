--[[
	LobbyScreens - Create Game (Roblox-style settings), Server Browser, and the
	post-join pregame lobby, all driven by real SessionController data.
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local LobbyScreens = {}

-- config.OnStartMatch(session) is called when the host presses Start Match;
-- Main.client.luau owns what "starting a match" actually does.
function LobbyScreens.Build(UIKit, SessionController, config)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT
	config = config or {}

	local handles = {}
	local currentSession = nil -- last PublicSession we joined/created, kept in sync via SessionUpdated
	local pendingMaxPlayers = 8
	local pendingIsPublic = true

	local function flashErrorOn(errorBanner, message)
		errorBanner.Text = message
		TweenService:Create(errorBanner, TweenInfo.new(0.2), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
		task.delay(3, function()
			if errorBanner.Text == message then
				TweenService:Create(errorBanner, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end

	-- ============================================================
	-- SCREEN: CREATE GAME (Roblox "create a game" style settings form)
	-- ============================================================
	local createGameScreen = UIKit.NewScreen("CreateGameScreen")

	local createPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.5, 0.75),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = createGameScreen,
	})

	UIKit.CreateLabel({
		Text = "Create a Quiplash Room",
		Size = UDim2.fromScale(0.85, 0.09),
		Position = UDim2.fromScale(0.5, 0.09),
		TextColor = Palette.TextDark,
		Parent = createPanel,
	})

	UIKit.CreateLabel({
		Text = "Room Name",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.19),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		XAlign = Enum.TextXAlignment.Left,
		Parent = createPanel,
	})

	local roomNameBox = UIKit.CreateTextBox({
		Placeholder = "e.g. Ally's Lobby",
		Size = UDim2.fromScale(0.8, 0.08),
		Position = UDim2.fromScale(0.5, 0.27),
		MaxLength = 32,
		Parent = createPanel,
	})

	UIKit.CreateLabel({
		Text = "Max Players",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.4),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		XAlign = Enum.TextXAlignment.Left,
		Parent = createPanel,
	})

	UIKit.CreateSegmentGroup({
		Options = { "4", "6", "8" },
		DefaultIndex = 3,
		Size = UDim2.fromScale(0.8, 0.08),
		Position = UDim2.fromScale(0.1, 0.47),
		AnchorPoint = Vector2.new(0, 0),
		Parent = createPanel,
		OnChange = function(optionText)
			pendingMaxPlayers = tonumber(optionText) or 8
		end,
	})

	UIKit.CreateLabel({
		Text = "Room Privacy",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.61),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		XAlign = Enum.TextXAlignment.Left,
		Parent = createPanel,
	})

	UIKit.CreateSegmentGroup({
		Options = { "Public", "Private (code only)" },
		DefaultIndex = 1,
		Size = UDim2.fromScale(0.8, 0.08),
		Position = UDim2.fromScale(0.1, 0.68),
		AnchorPoint = Vector2.new(0, 0),
		Parent = createPanel,
		OnChange = function(_, index)
			pendingIsPublic = index == 1
		end,
	})

	local createRoomButton = UIKit.CreateButton({
		Text = "CREATE ROOM",
		Size = UDim2.fromScale(0.55, 0.09),
		Position = UDim2.fromScale(0.5, 0.86),
		Color = Palette.Purple,
		Parent = createPanel,
	})

	local createBackButton = UIKit.CreateButton({
		Text = "Back",
		Size = UDim2.fromOffset(120, 44),
		Position = UDim2.fromScale(0.06, 0.06),
		AnchorPoint = Vector2.new(0, 0),
		Color = Palette.CardMuted,
		TextColor = Palette.TextDark,
		Parent = createGameScreen,
	})

	-- ============================================================
	-- SCREEN: SERVER BROWSER (join by code / browse public rooms)
	-- ============================================================
	local lobbiesBrowser = UIKit.NewScreen("LobbiesBrowser")

	UIKit.CreateLabel({
		Text = "Quiplash Servers",
		Size = UDim2.fromScale(0.6, 0.08),
		Position = UDim2.fromScale(0.5, 0.09),
		TextColor = Palette.TextDark,
		Parent = lobbiesBrowser,
	})

	local errorBanner = UIKit.CreateLabel({
		Text = "",
		Size = UDim2.fromScale(0.5, 0.04),
		Position = UDim2.fromScale(0.5, 0.15),
		Font = BODY_FONT,
		TextColor = Palette.Danger,
		Parent = lobbiesBrowser,
	})
	errorBanner.TextTransparency = 1

	local browserBackButton = UIKit.CreateButton({
		Text = "Back",
		Size = UDim2.fromOffset(120, 44),
		Position = UDim2.fromScale(0.06, 0.06),
		AnchorPoint = Vector2.new(0, 0),
		Color = Palette.CardMuted,
		TextColor = Palette.TextDark,
		Parent = lobbiesBrowser,
	})

	local createShortcutButton = UIKit.CreateButton({
		Text = "+ Create Room",
		Size = UDim2.fromOffset(180, 46),
		Position = UDim2.fromScale(0.94, 0.06),
		AnchorPoint = Vector2.new(1, 0),
		Color = Palette.Purple,
		Parent = lobbiesBrowser,
	})

	local joinCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.32, 0.18),
		Position = UDim2.fromScale(0.27, 0.3),
		Parent = lobbiesBrowser,
	})

	UIKit.CreateLabel({
		Text = "Join by Code",
		Size = UDim2.fromScale(0.9, 0.22),
		Position = UDim2.fromScale(0.5, 0.24),
		TextColor = Palette.TextDark,
		Parent = joinCard,
	})

	local joinIdBox = UIKit.CreateTextBox({
		Placeholder = "Room Code",
		Size = UDim2.fromScale(0.55, 0.32),
		Position = UDim2.fromScale(0.32, 0.65),
		Parent = joinCard,
	})

	local joinByIdButton = UIKit.CreateButton({
		Text = "JOIN",
		Size = UDim2.fromScale(0.32, 0.32),
		Position = UDim2.fromScale(0.83, 0.65),
		Color = Palette.Teal,
		TextColor = Palette.TextDark,
		Parent = joinCard,
	})

	local publicRoomsCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.32, 0.55),
		Position = UDim2.fromScale(0.27, 0.68),
		Parent = lobbiesBrowser,
	})

	UIKit.CreateLabel({
		Text = "Public Rooms",
		Size = UDim2.fromScale(0.9, 0.1),
		Position = UDim2.fromScale(0.5, 0.09),
		TextColor = Palette.TextDark,
		Parent = publicRoomsCard,
	})

	local publicRoomsList = Instance.new("ScrollingFrame")
	publicRoomsList.Size = UDim2.fromScale(0.9, 0.78)
	publicRoomsList.Position = UDim2.fromScale(0.5, 0.53)
	publicRoomsList.AnchorPoint = Vector2.new(0.5, 0.5)
	publicRoomsList.BackgroundTransparency = 1
	publicRoomsList.BorderSizePixel = 0
	publicRoomsList.ScrollBarThickness = 6
	publicRoomsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	publicRoomsList.CanvasSize = UDim2.new()
	publicRoomsList.ZIndex = 7
	publicRoomsList.Parent = publicRoomsCard

	local publicRoomsLayout = Instance.new("UIListLayout")
	publicRoomsLayout.Padding = UDim.new(0, 6)
	publicRoomsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	publicRoomsLayout.Parent = publicRoomsList

	local emptyRoomsLabel = UIKit.CreateLabel({
		Text = "No public rooms yet - create one!",
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(),
		AnchorPoint = Vector2.new(0, 0),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		ZIndex = 7,
		Parent = publicRoomsList,
	})

	local function renderSessionList(sessionList)
		for _, child in ipairs(publicRoomsList:GetChildren()) do
			if child:IsA("Frame") and child.Name == "RoomRow" then
				child:Destroy()
			end
		end

		emptyRoomsLabel.Visible = #sessionList == 0

		for i, session in ipairs(sessionList) do
			local row = Instance.new("Frame")
			row.Name = "RoomRow"
			row.Size = UDim2.new(1, 0, 0, 40)
			row.BackgroundColor3 = Palette.CardMuted
			row.LayoutOrder = i
			row.ZIndex = 7
			row.Parent = publicRoomsList
			UIKit.AddCorner(row, 8)

			UIKit.CreateLabel({
				Text = string.format("%s (%d/%d)", session.roomName, session.playerCount, session.maxPlayers),
				Size = UDim2.fromScale(0.65, 1),
				Position = UDim2.fromScale(0.05, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 8,
				Parent = row,
			})

			local joinRowButton = UIKit.CreateButton({
				Text = session.status == "Waiting" and "Join" or session.status,
				Size = UDim2.fromScale(0.28, 0.75),
				Position = UDim2.fromScale(0.97, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = Palette.Teal,
				TextColor = Palette.TextDark,
				Radius = 8,
				ZIndex = 8,
				Parent = row,
			})

			if session.status ~= "Waiting" then
				joinRowButton.AutoButtonColor = false
				joinRowButton.BackgroundColor3 = Palette.Locked
			else
				joinRowButton.MouseButton1Click:Connect(function()
					SessionController.JoinSession(session.sessionId)
				end)
			end
		end
	end

	SessionController.OnSessionListUpdated(renderSessionList)
	renderSessionList(SessionController.FetchSessions())

	-- ============================================================
	-- SCREEN: PREGAME LOBBY (avatar grid of everyone in the room)
	-- ============================================================
	local waitingRoom = UIKit.NewScreen("WaitingRoom")

	local waitingPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.65, 0.78),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = waitingRoom,
	})

	local waitingRoomName = UIKit.CreateLabel({
		Text = "Lobby",
		Size = UDim2.fromScale(0.8, 0.09),
		Position = UDim2.fromScale(0.5, 0.08),
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	local waitingRoomCode = UIKit.CreateLabel({
		Text = "Code: ------",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.15),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = waitingPanel,
	})

	local playerCountLabel = UIKit.CreateLabel({
		Text = "0/8 players",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.21),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = waitingPanel,
	})

	local playerGrid = Instance.new("ScrollingFrame")
	playerGrid.Size = UDim2.fromScale(0.88, 0.48)
	playerGrid.Position = UDim2.fromScale(0.5, 0.5)
	playerGrid.AnchorPoint = Vector2.new(0.5, 0.5)
	playerGrid.BackgroundTransparency = 1
	playerGrid.BorderSizePixel = 0
	playerGrid.ScrollBarThickness = 6
	playerGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playerGrid.CanvasSize = UDim2.new()
	playerGrid.ZIndex = 7
	playerGrid.Parent = waitingPanel

	local playerGridLayout = Instance.new("UIGridLayout")
	playerGridLayout.CellSize = UDim2.fromOffset(120, 140)
	playerGridLayout.CellPadding = UDim2.fromOffset(14, 14)
	playerGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	playerGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerGridLayout.Parent = playerGrid

	local statusLabel = UIKit.CreateLabel({
		Text = "Waiting for host to start...",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.8),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = waitingPanel,
	})

	local startMatchButton = UIKit.CreateButton({
		Text = "START MATCH",
		Size = UDim2.fromScale(0.4, 0.08),
		Position = UDim2.fromScale(0.5, 0.89),
		Color = Palette.Purple,
		Parent = waitingPanel,
	})

	local leaveButton = UIKit.CreateButton({
		Text = "LEAVE",
		Size = UDim2.fromOffset(140, 44),
		Position = UDim2.fromScale(0.5, 0.97),
		Color = Palette.CardMuted,
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	local function renderWaitingRoom(session)
		currentSession = session
		local isHost = session.hostUserId == localPlayer.UserId

		waitingRoomName.Text = session.roomName
		waitingRoomCode.Text = "Code: " .. string.sub(session.sessionId, 1, 8)
		playerCountLabel.Text = string.format("%d/%d players", #session.playerNames, session.maxPlayers)

		for _, child in ipairs(playerGrid:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, name in ipairs(session.playerNames) do
			local userId = session.playerUserIds and session.playerUserIds[i]
			local isSessionHost = name == session.hostName

			local tile = Instance.new("Frame")
			tile.BackgroundColor3 = Palette.CardMuted
			tile.LayoutOrder = i
			tile.ZIndex = 7
			tile.Parent = playerGrid
			UIKit.AddCorner(tile, 12)

			UIKit.CreateAvatar({
				UserId = userId,
				Size = UDim2.fromOffset(84, 84),
				Position = UDim2.fromScale(0.5, 0.37),
				StrokeColor = isSessionHost and Palette.Yellow or nil,
				ZIndex = 8,
				Parent = tile,
			})

			UIKit.CreateLabel({
				Text = isSessionHost and (name .. " (Host)") or name,
				Size = UDim2.fromScale(0.94, 0.2),
				Position = UDim2.fromScale(0.5, 0.85),
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 8,
				Parent = tile,
			})
		end

		startMatchButton.Visible = isHost
		statusLabel.Visible = not isHost
		statusLabel.Text = session.status == "Full" and "Room is full - ready when host is!" or "Waiting for host to start..."
	end

	SessionController.OnSessionJoined(function(session)
		renderWaitingRoom(session)
		UIKit.SwitchTo(waitingRoom)
	end)

	SessionController.OnSessionUpdated(function(session)
		if currentSession and currentSession.sessionId == session.sessionId then
			renderWaitingRoom(session)
		end
	end)

	SessionController.OnSessionActionFailed(function(message)
		flashErrorOn(errorBanner, message)
	end)

	-- ============================================================
	-- WIRING
	-- ============================================================
	createRoomButton.MouseButton1Click:Connect(function()
		SessionController.CreateSession("Quiplash", roomNameBox.Text, {
			maxPlayers = pendingMaxPlayers,
			isPublic = pendingIsPublic,
		})
	end)

	joinByIdButton.MouseButton1Click:Connect(function()
		local code = joinIdBox.Text
		if code == nil or code == "" then
			flashErrorOn(errorBanner, "Enter a room code first")
			return
		end
		SessionController.JoinSession(code)
	end)

	createBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(lobbiesBrowser) end)
	browserBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(config.ModeSelect) end)
	createShortcutButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(createGameScreen) end)

	leaveButton.MouseButton1Click:Connect(function()
		if currentSession then
			SessionController.LeaveSession(currentSession.sessionId)
			currentSession = nil
		end
		UIKit.SwitchTo(lobbiesBrowser)
	end)

	startMatchButton.MouseButton1Click:Connect(function()
		if currentSession and config.OnStartMatch then
			config.OnStartMatch(currentSession)
		end
	end)

	handles.LobbiesBrowser = lobbiesBrowser
	handles.CreateGameScreen = createGameScreen
	handles.WaitingRoom = waitingRoom

	return handles
end

return LobbyScreens
