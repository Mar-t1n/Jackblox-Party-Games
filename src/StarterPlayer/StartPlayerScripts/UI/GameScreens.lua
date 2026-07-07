--[[
	GameScreens - the Quiplash round itself: Answer -> Vote -> Results ->
	(next prompt) -> Leaderboard, Quiplash-style: only two players answer any
	given prompt, everyone else spectates and then votes.
]]

local RunService = game:GetService("RunService")

local GameScreens = {}

-- config.OnBackToLobby() lets Main.client.luau decide what "back to lobby"
-- actually navigates to.
function GameScreens.Build(UIKit, GameController, config)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT
	config = config or {}

	local handles = {}

	local function runCountdown(seconds, onTick)
		local deadline = os.clock() + seconds
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local remaining = math.max(0, math.ceil(deadline - os.clock()))
			onTick(remaining)
			if remaining <= 0 then
				connection:Disconnect()
			end
		end)
		return connection
	end

	-- ============================================================
	-- SCREEN: ANSWER (the two assigned players type; everyone else spectates)
	-- ============================================================
	local answerScreen = UIKit.NewScreen("AnswerScreen")

	UIKit.CreateLabel({
		Text = "",
		Size = UDim2.fromScale(0.1, 0.05),
		Position = UDim2.fromScale(0.5, 0.04),
		Parent = answerScreen,
	}) -- spacer keeps layout stable across states without shifting the card

	local matchupHolder = Instance.new("Frame")
	matchupHolder.Size = UDim2.fromScale(0.6, 0.14)
	matchupHolder.Position = UDim2.fromScale(0.5, 0.14)
	matchupHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	matchupHolder.BackgroundTransparency = 1
	matchupHolder.ZIndex = 6
	matchupHolder.Parent = answerScreen

	local avatarA = UIKit.CreateAvatar({
		Size = UDim2.fromOffset(72, 72),
		Position = UDim2.fromScale(0.28, 0.35),
		Parent = matchupHolder,
	})
	local nameA = UIKit.CreateLabel({
		Text = "Player A",
		Size = UDim2.fromScale(0.4, 0.3),
		Position = UDim2.fromScale(0.28, 0.85),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = matchupHolder,
	})

	UIKit.CreateLabel({
		Text = "VS",
		Size = UDim2.fromScale(0.15, 0.3),
		Position = UDim2.fromScale(0.5, 0.35),
		TextColor = Palette.Purple,
		Parent = matchupHolder,
	})

	local avatarB = UIKit.CreateAvatar({
		Size = UDim2.fromOffset(72, 72),
		Position = UDim2.fromScale(0.72, 0.35),
		Parent = matchupHolder,
	})
	local nameB = UIKit.CreateLabel({
		Text = "Player B",
		Size = UDim2.fromScale(0.4, 0.3),
		Position = UDim2.fromScale(0.72, 0.85),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = matchupHolder,
	})

	local answerCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.55, 0.5),
		Position = UDim2.fromScale(0.5, 0.6),
		Parent = answerScreen,
	})

	local timerLabel = UIKit.CreateLabel({
		Text = "20",
		Size = UDim2.fromScale(0.14, 0.12),
		Position = UDim2.fromScale(0.5, -0.09),
		TextColor = Palette.Purple,
		Parent = answerCard,
	})

	local promptLabel = UIKit.CreateLabel({
		Text = "Waiting for prompt...",
		Size = UDim2.fromScale(0.85, 0.32),
		Position = UDim2.fromScale(0.5, 0.24),
		TextColor = Palette.TextDark,
		Parent = answerCard,
	})

	local answerBox = UIKit.CreateTextBox({
		Placeholder = "Type your funniest answer...",
		Size = UDim2.fromScale(0.85, 0.22),
		Position = UDim2.fromScale(0.5, 0.58),
		MaxLength = 80,
		Parent = answerCard,
	})

	local submitAnswerButton = UIKit.CreateButton({
		Text = "SUBMIT",
		Size = UDim2.fromScale(0.4, 0.15),
		Position = UDim2.fromScale(0.5, 0.86),
		Color = Palette.Purple,
		Parent = answerCard,
	})

	local spectateLabel = UIKit.CreateLabel({
		Text = "Waiting for both players to answer...",
		Size = UDim2.fromScale(0.85, 0.15),
		Position = UDim2.fromScale(0.5, 0.7),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = answerCard,
	})
	spectateLabel.Visible = false

	local answerLockedLabel = UIKit.CreateLabel({
		Text = "Answer locked in! Waiting for the other player...",
		Size = UDim2.fromScale(0.85, 0.12),
		Position = UDim2.fromScale(0.5, 0.86),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = answerCard,
	})
	answerLockedLabel.Visible = false

	local answerCountdownConn = nil
	local hasSubmitted = false

	local function submitAnswer()
		if hasSubmitted or answerBox.Text == "" then return end
		hasSubmitted = true
		GameController.SubmitAnswer(answerBox.Text)
		answerBox.TextEditable = false
		submitAnswerButton.Visible = false
		answerLockedLabel.Visible = true
	end

	submitAnswerButton.MouseButton1Click:Connect(submitAnswer)

	GameController.OnPromptReady(function(payload)
		nameA.Text = payload.playerAName
		nameB.Text = payload.playerBName
		avatarA.Image = ""
		avatarB.Image = ""
		task.spawn(function()
			local ok, content = pcall(function()
				return game:GetService("Players"):GetUserThumbnailAsync(payload.playerAUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then avatarA.Image = content end
		end)
		task.spawn(function()
			local ok, content = pcall(function()
				return game:GetService("Players"):GetUserThumbnailAsync(payload.playerBUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then avatarB.Image = content end
		end)

		promptLabel.Text = payload.promptText
		hasSubmitted = false
		timerLabel.Text = tostring(payload.answerSeconds)

		if payload.isParticipant then
			answerBox.Text = ""
			answerBox.TextEditable = true
			answerBox.Visible = true
			submitAnswerButton.Visible = true
			answerLockedLabel.Visible = false
			spectateLabel.Visible = false
		else
			answerBox.Visible = false
			submitAnswerButton.Visible = false
			answerLockedLabel.Visible = false
			spectateLabel.Visible = true
		end

		if answerCountdownConn then
			answerCountdownConn:Disconnect()
		end
		answerCountdownConn = runCountdown(payload.answerSeconds, function(remaining)
			timerLabel.Text = tostring(remaining)
			if remaining <= 0 and payload.isParticipant and answerBox.TextEditable then
				submitAnswer()
			end
		end)

		UIKit.SwitchTo(answerScreen)
	end)

	-- ============================================================
	-- SCREEN: VOTE (head-to-head speech bubbles)
	-- ============================================================
	local voteScreen = UIKit.NewScreen("VoteScreen")

	UIKit.CreateLabel({
		Text = "Vote for the funniest answer!",
		Size = UDim2.fromScale(0.7, 0.09),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.TextDark,
		Parent = voteScreen,
	})

	local voteTimerLabel = UIKit.CreateLabel({
		Text = "15",
		Size = UDim2.fromScale(0.1, 0.06),
		Position = UDim2.fromScale(0.5, 0.17),
		TextColor = Palette.Purple,
		Parent = voteScreen,
	})

	local voteLockedLabel = UIKit.CreateLabel({
		Text = "Vote locked in! Waiting for results...",
		Size = UDim2.fromScale(0.6, 0.05),
		Position = UDim2.fromScale(0.5, 0.93),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = voteScreen,
	})
	voteLockedLabel.Visible = false

	local voteCountdownConn = nil

	local function buildAnswerColumn(anchorX)
		local avatar = UIKit.CreateAvatar({
			Size = UDim2.fromOffset(90, 90),
			Position = UDim2.fromScale(anchorX, 0.32),
			ZIndex = 6,
			Parent = voteScreen,
		})

		local nameLabel = UIKit.CreateLabel({
			Text = "",
			Size = UDim2.fromScale(0.24, 0.05),
			Position = UDim2.fromScale(anchorX, 0.42),
			Font = BODY_FONT,
			TextColor = Palette.TextDark,
			ZIndex = 6,
			Parent = voteScreen,
		})

		local bubble = UIKit.CreateSpeechBubble({
			Size = UDim2.fromScale(0.32, 0.28),
			Position = UDim2.fromScale(anchorX, 0.62),
			TailUp = true,
			ZIndex = 6,
			Parent = voteScreen,
		})

		local textLabel = UIKit.CreateLabel({
			Text = "",
			Size = UDim2.fromScale(0.85, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			Font = BODY_FONT,
			TextColor = Palette.TextDark,
			ZIndex = bubble.ZIndex + 1,
			Parent = bubble,
		})

		local voteButton = UIKit.CreateButton({
			Text = "VOTE",
			Size = UDim2.fromScale(0.2, 0.09),
			Position = UDim2.fromScale(anchorX, 0.88),
			Color = Palette.Teal,
			TextColor = Palette.TextDark,
			ZIndex = 6,
			Parent = voteScreen,
		})

		local tag = UIKit.CreateLabel({
			Text = "",
			Size = UDim2.fromScale(0.24, 0.06),
			Position = UDim2.fromScale(anchorX, 0.88),
			Font = BODY_FONT,
			TextColor = Palette.TextMuted,
			ZIndex = 6,
			Parent = voteScreen,
		})
		tag.Visible = false

		return { avatar = avatar, nameLabel = nameLabel, textLabel = textLabel, voteButton = voteButton, tag = tag }
	end

	local columnA = buildAnswerColumn(0.27)
	local columnB = buildAnswerColumn(0.73)

	local function fillColumn(column, answer, choiceId, canVote, voted, onVote)
		column.nameLabel.Text = answer.name
		column.textLabel.Text = answer.text
		task.spawn(function()
			local ok, content = pcall(function()
				return game:GetService("Players"):GetUserThumbnailAsync(answer.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then column.avatar.Image = content end
		end)

		if canVote then
			column.voteButton.Visible = true
			column.tag.Visible = false
			column.voteButton.AutoButtonColor = true
			column.voteButton.BackgroundColor3 = Palette.Teal
			local conn
			conn = column.voteButton.MouseButton1Click:Connect(function()
				onVote(choiceId)
				conn:Disconnect()
			end)
		else
			column.voteButton.Visible = false
			column.tag.Visible = true
			column.tag.Text = "Your answer"
		end
	end

	GameController.OnVotingReady(function(payload)
		voteLockedLabel.Visible = false
		voteTimerLabel.Text = tostring(payload.voteSeconds)

		local voted = false
		local function onVote(choiceId)
			if voted then return end
			voted = true
			GameController.SubmitVote(choiceId)
			voteLockedLabel.Visible = true
			columnA.voteButton.Visible = false
			columnB.voteButton.Visible = false
		end

		for _, answer in ipairs(payload.answers) do
			local column = (answer.id == "A") and columnA or columnB
			fillColumn(column, answer, answer.id, payload.canVote, voted, onVote)
		end

		if voteCountdownConn then
			voteCountdownConn:Disconnect()
		end
		voteCountdownConn = runCountdown(payload.voteSeconds, function(remaining)
			voteTimerLabel.Text = tostring(remaining)
		end)

		UIKit.SwitchTo(voteScreen)
	end)

	-- ============================================================
	-- SCREEN: RESULTS (per-prompt vote reveal)
	-- ============================================================
	local resultsScreen = UIKit.NewScreen("ResultsScreen")

	UIKit.CreateLabel({
		Text = "Results",
		Size = UDim2.fromScale(0.6, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.TextDark,
		Parent = resultsScreen,
	})

	local resultsHolder = Instance.new("Frame")
	resultsHolder.Size = UDim2.fromScale(0.6, 0.55)
	resultsHolder.Position = UDim2.fromScale(0.5, 0.52)
	resultsHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsHolder.BackgroundTransparency = 1
	resultsHolder.ZIndex = 6
	resultsHolder.Parent = resultsScreen

	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 10)
	resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	resultsLayout.Parent = resultsHolder

	UIKit.CreateLabel({
		Text = "Next prompt coming up...",
		Size = UDim2.fromScale(0.6, 0.06),
		Position = UDim2.fromScale(0.5, 0.92),
		Font = BODY_FONT,
		TextColor = Palette.TextMuted,
		Parent = resultsScreen,
	})

	GameController.OnResultsReady(function(payload)
		for _, child in ipairs(resultsHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local sorted = table.clone(payload.results)
		table.sort(sorted, function(a, b) return a.votes > b.votes end)

		for i, result in ipairs(sorted) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 70)
			row.BackgroundColor3 = (i == 1) and Palette.Yellow or Palette.CardMuted
			row.LayoutOrder = i
			row.ZIndex = 6
			row.Parent = resultsHolder
			UIKit.AddCorner(row, 12)

			UIKit.CreateAvatar({
				UserId = result.userId,
				Size = UDim2.fromOffset(50, 50),
				Position = UDim2.fromScale(0.06, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = string.format("%s: %s", result.name, result.text),
				Size = UDim2.fromScale(0.62, 0.7),
				Position = UDim2.fromScale(0.16, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = result.votes .. (result.votes == 1 and " vote" or " votes"),
				Size = UDim2.fromScale(0.22, 0.7),
				Position = UDim2.fromScale(0.97, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				TextColor = Palette.Purple,
				ZIndex = 7,
				Parent = row,
			})
		end

		UIKit.SwitchTo(resultsScreen)
	end)

	-- ============================================================
	-- SCREEN: LEADERBOARD (whole-match wrap-up)
	-- ============================================================
	local leaderboardScreen = UIKit.NewScreen("LeaderboardScreen")

	UIKit.CreateLabel({
		Text = "Final Scores",
		Size = UDim2.fromScale(0.6, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.TextDark,
		Parent = leaderboardScreen,
	})

	local leaderboardHolder = Instance.new("Frame")
	leaderboardHolder.Size = UDim2.fromScale(0.5, 0.55)
	leaderboardHolder.Position = UDim2.fromScale(0.5, 0.5)
	leaderboardHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	leaderboardHolder.BackgroundTransparency = 1
	leaderboardHolder.ZIndex = 6
	leaderboardHolder.Parent = leaderboardScreen

	local leaderboardLayout = Instance.new("UIListLayout")
	leaderboardLayout.Padding = UDim.new(0, 8)
	leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leaderboardLayout.Parent = leaderboardHolder

	local backToLobbyButton = UIKit.CreateButton({
		Text = "BACK TO LOBBY",
		Size = UDim2.fromOffset(220, 60),
		Position = UDim2.fromScale(0.5, 0.92),
		Color = Palette.Purple,
		Parent = leaderboardScreen,
	})

	GameController.OnMatchComplete(function(payload)
		for _, child in ipairs(leaderboardHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, entry in ipairs(payload.leaderboard) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 60)
			row.BackgroundColor3 = (i == 1) and Palette.Yellow or Palette.CardMuted
			row.LayoutOrder = i
			row.ZIndex = 6
			row.Parent = leaderboardHolder
			UIKit.AddCorner(row, 12)

			UIKit.CreateAvatar({
				UserId = entry.userId,
				Size = UDim2.fromOffset(44, 44),
				Position = UDim2.fromScale(0.06, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = string.format("#%d  %s", i, entry.name),
				Size = UDim2.fromScale(0.55, 0.7),
				Position = UDim2.fromScale(0.18, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = entry.score .. (entry.score == 1 and " pt" or " pts"),
				Size = UDim2.fromScale(0.22, 0.7),
				Position = UDim2.fromScale(0.97, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				TextColor = Palette.Purple,
				ZIndex = 7,
				Parent = row,
			})
		end

		UIKit.SwitchTo(leaderboardScreen)
	end)

	backToLobbyButton.MouseButton1Click:Connect(function()
		if config.OnBackToLobby then
			config.OnBackToLobby()
		end
	end)

	handles.AnswerScreen = answerScreen
	handles.VoteScreen = voteScreen
	handles.ResultsScreen = resultsScreen
	handles.LeaderboardScreen = leaderboardScreen

	return handles
end

return GameScreens
