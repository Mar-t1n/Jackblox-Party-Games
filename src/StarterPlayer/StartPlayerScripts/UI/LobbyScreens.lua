--[[
	LobbyScreens - "Find/Create a Room" browser and the post-join waiting
	room, both driven by real SessionController data (no sample/hardcoded
	rows). This is the piece that used to be entirely fake in the template:
	Create/Join/Leave now call the real session RemoteEvents, and the room
	list re-renders every time the server broadcasts SessionListUpdated.
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local LobbyScreens = {}

-- config.OnStartMatch(session) is called when the host presses Start Match;
-- Main.client.luau owns what "starting a match" actually does (today: kick
-- off GameController's mock round) so this module doesn't need to know
-- anything about the game loop.
function LobbyScreens.Build(UIKit, SessionController, config)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT
	config = config or {}

	local handles = {}
	local currentSession = nil -- last PublicSession we joined/created, kept in sync via SessionUpdated

	-- ============================================================
	-- SCREEN: LOBBIES BROWSER
	-- ============================================================
	local lobbiesBrowser = UIKit.NewScreen("LobbiesBrowser")

	UIKit.CreateLabel({
		Text = "FIND A LOBBY",
		Size = UDim2.fromScale(0.6, 0.1),
		Position = UDim2.fromScale(0.5, 0.07),
		TextColor = Palette.Purple,
		StrokeTransparency = 0.75,
		Parent = lobbiesBrowser,
	})

	-- Transient error banner for SessionActionFailed (e.g. "Session is full").
	local errorBanner = UIKit.CreateLabel({
		Text = "",
		Size = UDim2.fromScale(0.5, 0.05),
		Position = UDim2.fromScale(0.5, 0.13),
		Font = BODY_FONT,
		TextColor = Palette.Danger,
		StrokeTransparency = 0.5,
		Parent = lobbiesBrowser,
	})
	errorBanner.TextTransparency = 1
	errorBanner.TextStrokeTransparency = 1

	local function flashError(message)
		errorBanner.Text = message
		TweenService:Create(errorBanner, TweenInfo.new(0.2), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
		task.delay(3, function()
			if errorBanner.Text == message then
				TweenService:Create(errorBanner, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end

	local createRoomCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.32, 0.55),
		Position = UDim2.fromScale(0.27, 0.55),
		Color = Palette.CardBG,
		Parent = lobbiesBrowser,
	})

	UIKit.CreateLabel({
		Text = "Create a Room",
		Size = UDim2.fromScale(0.9, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.Purple,
		Parent = createRoomCard,
	})

	UIKit.CreateLabel({
		Text = "Give your room a name, then jump right in as the host.",
		Size = UDim2.fromScale(0.85, 0.08),
		Position = UDim2.fromScale(0.5, 0.19),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = createRoomCard,
	})

	UIKit.CreateLabel({
		Text = "Name your room",
		Size = UDim2.fromScale(0.85, 0.06),
		Position = UDim2.fromScale(0.5, 0.3),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		XAlign = Enum.TextXAlignment.Left,
		Parent = createRoomCard,
	})

	local roomNameBox = UIKit.CreateTextBox({
		Placeholder = "e.g. Ally's Lobby",
		Size = UDim2.fromScale(0.85, 0.1),
		Position = UDim2.fromScale(0.5, 0.39),
		MaxLength = 32,
		Parent = createRoomCard,
	})

	UIKit.CreateLabel({
		Text = "Game: Quiplash (more coming soon)",
		Size = UDim2.fromScale(0.85, 0.07),
		Position = UDim2.fromScale(0.5, 0.55),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = createRoomCard,
	})

	local createRoomButton = UIKit.CreateButton({
		Text = "CREATE",
		Size = UDim2.fromScale(0.6, 0.13),
		Position = UDim2.fromScale(0.5, 0.85),
		Color = Palette.Pink,
		Parent = createRoomCard,
	})

	local joinCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.32, 0.24),
		Position = UDim2.fromScale(0.68, 0.42),
		Parent = lobbiesBrowser,
	})

	UIKit.CreateLabel({
		Text = "Join by Code",
		Size = UDim2.fromScale(0.9, 0.15),
		Position = UDim2.fromScale(0.5, 0.2),
		TextColor = Palette.Purple,
		Parent = joinCard,
	})

	UIKit.CreateLabel({
		Text = "Enter a room code a friend shared with you.",
		Size = UDim2.fromScale(0.85, 0.12),
		Position = UDim2.fromScale(0.5, 0.4),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = joinCard,
	})

	local joinIdBox = UIKit.CreateTextBox({
		Placeholder = "Room Code",
		Size = UDim2.fromScale(0.6, 0.2),
		Position = UDim2.fromScale(0.35, 0.68),
		Parent = joinCard,
	})

	local joinByIdButton = UIKit.CreateButton({
		Text = "JOIN",
		Size = UDim2.fromScale(0.28, 0.2),
		Position = UDim2.fromScale(0.82, 0.68),
		Color = Palette.Teal,
		TextColor = Palette.TextDark,
		Parent = joinCard,
	})

	UIKit.CreateLabel({
		Text = "OR...",
		Size = UDim2.fromScale(0.3, 0.04),
		Position = UDim2.fromScale(0.68, 0.56),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = lobbiesBrowser,
	})

	local publicRoomsCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.32, 0.28),
		Position = UDim2.fromScale(0.68, 0.78),
		Parent = lobbiesBrowser,
	})

	UIKit.CreateLabel({
		Text = "Public Rooms",
		Size = UDim2.fromScale(0.9, 0.14),
		Position = UDim2.fromScale(0.5, 0.15),
		TextColor = Palette.Purple,
		Parent = publicRoomsCard,
	})

	local publicRoomsList = Instance.new("ScrollingFrame")
	publicRoomsList.Size = UDim2.fromScale(0.9, 0.75)
	publicRoomsList.Position = UDim2.fromScale(0.5, 0.58)
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
		TextColor = Palette.TextDark,
		ZIndex = 7,
		Parent = publicRoomsList,
	})

	-- Renders the real session list. Called on the initial fetch and every
	-- time the server broadcasts an update, so this list never goes stale.
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
			row.Size = UDim2.new(1, 0, 0, 34)
			row.BackgroundColor3 = Color3.fromRGB(240, 234, 250)
			row.LayoutOrder = i
			row.ZIndex = 7
			row.Parent = publicRoomsList
			UIKit.AddCorner(row, 8)

			UIKit.CreateLabel({
				Text = string.format("%s (%d/%d)", session.roomName, session.playerCount, session.maxPlayers),
				Size = UDim2.fromScale(0.65, 1),
				Position = UDim2.fromScale(0.03, 0.5),
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
				joinRowButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			else
				joinRowButton.MouseButton1Click:Connect(function()
					SessionController.JoinSession(session.sessionId)
				end)
			end
		end
	end

	SessionController.OnSessionListUpdated(renderSessionList)
	renderSessionList(SessionController.FetchSessions())

	local lobbiesBackButton = UIKit.CreateButton({
		Text = "< BACK",
		Size = UDim2.fromOffset(160, 55),
		Position = UDim2.fromScale(0.5, 0.95),
		Color = Color3.fromRGB(220, 210, 235),
		TextColor = Palette.TextDark,
		Parent = lobbiesBrowser,
	})

	-- ============================================================
	-- SCREEN: WAITING ROOM (post create/join, pre-match)
	-- ============================================================
	local waitingRoom = UIKit.NewScreen("WaitingRoom")

	local waitingPanel = UIKit.CreateCard({
		Size = UDim2.fromScale(0.6, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = waitingRoom,
	})

	local waitingRoomName = UIKit.CreateLabel({
		Text = "Lobby",
		Size = UDim2.fromScale(0.8, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.Purple,
		Parent = waitingPanel,
	})

	local waitingRoomCode = UIKit.CreateLabel({
		Text = "Code: ------",
		Size = UDim2.fromScale(0.8, 0.06),
		Position = UDim2.fromScale(0.5, 0.19),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	UIKit.CreateLabel({
		Text = "Players",
		Size = UDim2.fromScale(0.8, 0.05),
		Position = UDim2.fromScale(0.5, 0.28),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	local playersList = Instance.new("ScrollingFrame")
	playersList.Size = UDim2.fromScale(0.8, 0.35)
	playersList.Position = UDim2.fromScale(0.5, 0.5)
	playersList.AnchorPoint = Vector2.new(0.5, 0.5)
	playersList.BackgroundColor3 = Color3.fromRGB(245, 240, 252)
	playersList.BorderSizePixel = 0
	playersList.ScrollBarThickness = 6
	playersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersList.CanvasSize = UDim2.new()
	playersList.ZIndex = 7
	playersList.Parent = waitingPanel
	UIKit.AddCorner(playersList, 10)

	local playersLayout = Instance.new("UIListLayout")
	playersLayout.Padding = UDim.new(0, 4)
	playersLayout.Parent = playersList

	local statusLabel = UIKit.CreateLabel({
		Text = "Waiting for host to start...",
		Size = UDim2.fromScale(0.8, 0.06),
		Position = UDim2.fromScale(0.5, 0.72),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	local startMatchButton = UIKit.CreateButton({
		Text = "START MATCH",
		Size = UDim2.fromScale(0.4, 0.09),
		Position = UDim2.fromScale(0.5, 0.82),
		Color = Palette.Pink,
		Parent = waitingPanel,
	})

	local leaveButton = UIKit.CreateButton({
		Text = "LEAVE",
		Size = UDim2.fromOffset(140, 45),
		Position = UDim2.fromScale(0.5, 0.94),
		Color = Color3.fromRGB(220, 210, 235),
		TextColor = Palette.TextDark,
		Parent = waitingPanel,
	})

	local function renderWaitingRoom(session)
		currentSession = session
		local isHost = session.hostUserId == localPlayer.UserId

		waitingRoomName.Text = session.roomName
		waitingRoomCode.Text = "Code: " .. string.sub(session.sessionId, 1, 8)

		for _, child in ipairs(playersList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, name in ipairs(session.playerNames) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 32)
			row.Position = UDim2.new(0, 4, 0, 0)
			row.BackgroundColor3 = (name == session.hostName) and Palette.Yellow or Color3.fromRGB(255, 255, 255)
			row.LayoutOrder = i
			row.ZIndex = 7
			row.Parent = playersList
			UIKit.AddCorner(row, 8)

			UIKit.CreateLabel({
				Text = (name == session.hostName) and ("Crown: " .. name) or name,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.05, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 8,
				Parent = row,
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

	SessionController.OnSessionActionFailed(flashError)

	-- ============================================================
	-- WIRING
	-- ============================================================
	createRoomButton.MouseButton1Click:Connect(function()
		SessionController.CreateSession("Quiplash", roomNameBox.Text)
	end)

	joinByIdButton.MouseButton1Click:Connect(function()
		local code = joinIdBox.Text
		if code == nil or code == "" then
			flashError("Enter a room code first")
			return
		end
		SessionController.JoinSession(code)
	end)

	lobbiesBackButton.MouseButton1Click:Connect(function() UIKit.SwitchTo(config.ModeSelect) end)

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
	handles.WaitingRoom = waitingRoom

	return handles
end

return LobbyScreens
