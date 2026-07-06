--[[
	GameScreens - the Quiplash round itself: Answer -> Vote -> Results.

	Driven entirely by GameController events (OnPromptReady / OnVotingReady /
	OnResultsReady), so this module doesn't know or care whether the round is
	mocked locally or (eventually) driven by real server RemoteEvents - it
	just reacts to whatever GameController fires.
]]

local RunService = game:GetService("RunService")

local GameScreens = {}

-- config.OnBackToLobby() / config.OnPlayAgain() let Main.client.luau decide
-- what "back to lobby" and "play again" actually navigate to/trigger.
function GameScreens.Build(UIKit, GameController, config)
	local Palette = UIKit.Palette
	local BODY_FONT = UIKit.BODY_FONT
	config = config or {}

	local handles = {}

	-- ============================================================
	-- SCREEN: ANSWER (prompt shown + player types a response)
	-- ============================================================
	local answerScreen = UIKit.NewScreen("AnswerScreen")

	local answerCard = UIKit.CreateCard({
		Size = UDim2.fromScale(0.6, 0.55),
		Position = UDim2.fromScale(0.5, 0.45),
		Parent = answerScreen,
	})

	local timerLabel = UIKit.CreateLabel({
		Text = "20",
		Size = UDim2.fromScale(0.15, 0.1),
		Position = UDim2.fromScale(0.5, -0.08),
		TextColor = Palette.Purple,
		Parent = answerCard,
	})

	local promptLabel = UIKit.CreateLabel({
		Text = "Waiting for prompt...",
		Size = UDim2.fromScale(0.85, 0.3),
		Position = UDim2.fromScale(0.5, 0.22),
		TextColor = Palette.Purple,
		Parent = answerCard,
	})

	local answerBox = UIKit.CreateTextBox({
		Placeholder = "Type your funniest answer...",
		Size = UDim2.fromScale(0.85, 0.2),
		Position = UDim2.fromScale(0.5, 0.55),
		MaxLength = 80,
		Parent = answerCard,
	})

	local submitAnswerButton = UIKit.CreateButton({
		Text = "SUBMIT",
		Size = UDim2.fromScale(0.4, 0.14),
		Position = UDim2.fromScale(0.5, 0.85),
		Color = Palette.Pink,
		Parent = answerCard,
	})

	local answerLockedLabel = UIKit.CreateLabel({
		Text = "Answer locked in! Waiting for other players...",
		Size = UDim2.fromScale(0.85, 0.1),
		Position = UDim2.fromScale(0.5, 0.85),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = answerCard,
	})
	answerLockedLabel.Visible = false

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

	local answerCountdownConn = nil

	local function submitAnswer()
		if answerBox.Text == "" then return end
		GameController.SubmitAnswer(answerBox.Text)
		answerBox.TextEditable = false
		submitAnswerButton.Visible = false
		answerLockedLabel.Visible = true
	end

	submitAnswerButton.MouseButton1Click:Connect(submitAnswer)

	GameController.OnPromptReady(function(prompt, answerSeconds)
		promptLabel.Text = prompt
		answerBox.Text = ""
		answerBox.TextEditable = true
		submitAnswerButton.Visible = true
		answerLockedLabel.Visible = false
		timerLabel.Text = tostring(answerSeconds)

		if answerCountdownConn then
			answerCountdownConn:Disconnect()
		end
		answerCountdownConn = runCountdown(answerSeconds, function(remaining)
			timerLabel.Text = tostring(remaining)
			if remaining <= 0 and answerBox.TextEditable then
				-- Timed out without submitting: lock in whatever was typed.
				submitAnswer()
			end
		end)

		UIKit.SwitchTo(answerScreen)
	end)

	-- ============================================================
	-- SCREEN: VOTE (pick the funniest answer that isn't your own)
	-- ============================================================
	local voteScreen = UIKit.NewScreen("VoteScreen")

	UIKit.CreateLabel({
		Text = "Vote for the funniest answer!",
		Size = UDim2.fromScale(0.7, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.Purple,
		StrokeTransparency = 0.75,
		Parent = voteScreen,
	})

	local voteTimerLabel = UIKit.CreateLabel({
		Text = "15",
		Size = UDim2.fromScale(0.1, 0.06),
		Position = UDim2.fromScale(0.5, 0.18),
		TextColor = Palette.Teal,
		Parent = voteScreen,
	})

	local voteCardsHolder = Instance.new("Frame")
	voteCardsHolder.Size = UDim2.fromScale(0.8, 0.6)
	voteCardsHolder.Position = UDim2.fromScale(0.5, 0.55)
	voteCardsHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	voteCardsHolder.BackgroundTransparency = 1
	voteCardsHolder.ZIndex = 6
	voteCardsHolder.Parent = voteScreen

	local voteCardsLayout = Instance.new("UIListLayout")
	voteCardsLayout.Padding = UDim.new(0, 12)
	voteCardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	voteCardsLayout.Parent = voteCardsHolder

	local voteLockedLabel = UIKit.CreateLabel({
		Text = "Vote locked in! Waiting for results...",
		Size = UDim2.fromScale(0.6, 0.06),
		Position = UDim2.fromScale(0.5, 0.92),
		Font = BODY_FONT,
		TextColor = Palette.TextDark,
		Parent = voteScreen,
	})
	voteLockedLabel.Visible = false

	local voteCountdownConn = nil

	GameController.OnVotingReady(function(answers, voteSeconds)
		for _, child in ipairs(voteCardsHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		voteLockedLabel.Visible = false
		voteTimerLabel.Text = tostring(voteSeconds)

		local voted = false

		for i, answer in ipairs(answers) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 60)
			row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			row.LayoutOrder = i
			row.ZIndex = 6
			row.Parent = voteCardsHolder
			UIKit.AddCorner(row, 12)
			UIKit.AddStroke(row, Palette.TextDark, 1, 0.7)

			UIKit.CreateLabel({
				Text = answer.text,
				Size = UDim2.fromScale(0.68, 0.8),
				Position = UDim2.fromScale(0.04, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 7,
				Parent = row,
			})

			if answer.isMine then
				UIKit.CreateLabel({
					Text = "Your answer",
					Size = UDim2.fromScale(0.25, 0.6),
					Position = UDim2.fromScale(0.97, 0.5),
					AnchorPoint = Vector2.new(1, 0.5),
					Font = BODY_FONT,
					TextColor = Palette.TextDark,
					ZIndex = 7,
					Parent = row,
				})
			else
				local voteButton = UIKit.CreateButton({
					Text = "Vote",
					Size = UDim2.fromScale(0.2, 0.6),
					Position = UDim2.fromScale(0.97, 0.5),
					AnchorPoint = Vector2.new(1, 0.5),
					Color = Palette.Teal,
					TextColor = Palette.TextDark,
					Radius = 8,
					ZIndex = 7,
					Parent = row,
				})
				voteButton.MouseButton1Click:Connect(function()
					if voted then return end
					voted = true
					GameController.SubmitVote(answer.id)
					voteLockedLabel.Visible = true
					for _, sibling in ipairs(voteCardsHolder:GetChildren()) do
						local btn = sibling:FindFirstChildOfClass("TextButton")
						if btn then
							btn.AutoButtonColor = false
							btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
						end
					end
				end)
			end
		end

		if voteCountdownConn then
			voteCountdownConn:Disconnect()
		end
		voteCountdownConn = runCountdown(voteSeconds, function(remaining)
			voteTimerLabel.Text = tostring(remaining)
		end)

		UIKit.SwitchTo(voteScreen)
	end)

	-- ============================================================
	-- SCREEN: RESULTS
	-- ============================================================
	local resultsScreen = UIKit.NewScreen("ResultsScreen")

	UIKit.CreateLabel({
		Text = "Results",
		Size = UDim2.fromScale(0.6, 0.1),
		Position = UDim2.fromScale(0.5, 0.1),
		TextColor = Palette.Purple,
		StrokeTransparency = 0.75,
		Parent = resultsScreen,
	})

	local resultsHolder = Instance.new("Frame")
	resultsHolder.Size = UDim2.fromScale(0.7, 0.6)
	resultsHolder.Position = UDim2.fromScale(0.5, 0.5)
	resultsHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsHolder.BackgroundTransparency = 1
	resultsHolder.ZIndex = 6
	resultsHolder.Parent = resultsScreen

	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 10)
	resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	resultsLayout.Parent = resultsHolder

	local playAgainButton = UIKit.CreateButton({
		Text = "PLAY AGAIN",
		Size = UDim2.fromOffset(220, 60),
		Position = UDim2.fromScale(0.36, 0.92),
		Color = Palette.Pink,
		Parent = resultsScreen,
	})

	local backToLobbyButton = UIKit.CreateButton({
		Text = "BACK TO LOBBY",
		Size = UDim2.fromOffset(220, 60),
		Position = UDim2.fromScale(0.64, 0.92),
		Color = Color3.fromRGB(220, 210, 235),
		TextColor = Palette.TextDark,
		Parent = resultsScreen,
	})

	GameController.OnResultsReady(function(results)
		for _, child in ipairs(resultsHolder:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, result in ipairs(results) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 54)
			row.BackgroundColor3 = (i == 1) and Palette.Yellow or Color3.fromRGB(255, 255, 255)
			row.LayoutOrder = i
			row.ZIndex = 6
			row.Parent = resultsHolder
			UIKit.AddCorner(row, 12)
			UIKit.AddStroke(row, Palette.TextDark, 1, 0.7)

			UIKit.CreateLabel({
				Text = string.format("#%d  %s", i, result.text),
				Size = UDim2.fromScale(0.65, 0.7),
				Position = UDim2.fromScale(0.04, 0.32),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = "by " .. result.authorName,
				Size = UDim2.fromScale(0.65, 0.35),
				Position = UDim2.fromScale(0.04, 0.75),
				AnchorPoint = Vector2.new(0, 0.5),
				XAlign = Enum.TextXAlignment.Left,
				YAlign = Enum.TextYAlignment.Top,
				Font = BODY_FONT,
				TextColor = Palette.TextDark,
				ZIndex = 7,
				Parent = row,
			})

			UIKit.CreateLabel({
				Text = result.votes .. (result.votes == 1 and " vote" or " votes"),
				Size = UDim2.fromScale(0.25, 0.7),
				Position = UDim2.fromScale(0.97, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				TextColor = Palette.Purple,
				ZIndex = 7,
				Parent = row,
			})
		end

		UIKit.SwitchTo(resultsScreen)
	end)

	playAgainButton.MouseButton1Click:Connect(function()
		if config.OnPlayAgain then
			config.OnPlayAgain()
		end
	end)

	backToLobbyButton.MouseButton1Click:Connect(function()
		if config.OnBackToLobby then
			config.OnBackToLobby()
		end
	end)

	handles.AnswerScreen = answerScreen
	handles.VoteScreen = voteScreen
	handles.ResultsScreen = resultsScreen

	return handles
end

return GameScreens
