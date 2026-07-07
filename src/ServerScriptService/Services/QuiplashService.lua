--[[
	QuiplashService - server-authoritative Quiplash round loop.

	Real Quiplash never has everyone answer every prompt: with P players in a
	session there are P prompts, and each prompt is answered by exactly two
	players (a rotating circular pairing so every player answers exactly two
	prompts total, each time with a different partner). Everyone else in the
	session spectates the prompt, then votes for whichever of the two answers
	is funnier once both are in.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Remotes = require(ReplicatedStorage.Remotes.GameRemotes)
local SessionRemotes = require(ReplicatedStorage.Remotes.SessionRemotes)
local SessionService = require(script.Parent.SessionService)

local QuiplashService = {}

local PROMPTS = {
	"The worst possible theme for a birthday party: ___",
	"You know the Wi-Fi is down when ___",
	"The real reason robots haven't taken over yet: ___",
	"A terrible name for a pet rock: ___",
	"The next update should definitely add ___",
	"Worst thing to hear your GPS say mid-road-trip: ___",
	"The secret ingredient in grandma's cookies: ___",
	"If lava were actually good for you, ___",
	"The world's least convincing disguise: ___",
	"What actually happened to the dinosaurs: ___",
}

local ANSWER_SECONDS = 20
local VOTE_SECONDS = 15

-- One entry per active session's match, keyed by sessionId.
local activeMatches = {}

local function shuffledCopy(list)
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = math.random(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- Circular adjacent pairing: for P players, produces P prompts where player i
-- answers alongside player i+1 (wrapping), so every player answers exactly
-- two prompts and no pair is asked twice.
local function buildPromptSchedule(players)
	local order = shuffledCopy(players)
	local numPlayers = #order
	local usedPrompts = shuffledCopy(PROMPTS)
	local schedule = {}

	for i = 1, numPlayers do
		local playerA = order[i]
		local playerB = order[(i % numPlayers) + 1]
		local promptText = usedPrompts[((i - 1) % #usedPrompts) + 1]
		table.insert(schedule, { playerA = playerA, playerB = playerB, promptText = promptText })
	end

	return schedule
end

local function filterAnswer(rawText, authorPlayer)
	if type(rawText) ~= "string" or rawText == "" then
		return "(no answer submitted)"
	end
	rawText = string.sub(rawText, 1, 80)

	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(rawText, authorPlayer.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)

	if ok then
		return filtered
	end
	return rawText
end

local function broadcastToSession(session, remote, ...)
	for _, member in ipairs(session.players) do
		if member.Parent then
			remote:FireClient(member, ...)
		end
	end
end

local function startPrompt(sessionId)
	local match = activeMatches[sessionId]
	if not match then return end

	local round = match.schedule[match.promptIndex]
	if not round then
		QuiplashService.EndMatch(sessionId)
		return
	end

	match.currentRound = {
		playerA = round.playerA,
		playerB = round.playerB,
		promptText = round.promptText,
		answerA = nil,
		answerB = nil,
		votesForA = 0,
		votesForB = 0,
		voters = {},
	}

	broadcastToSession(match.session, Remotes.PromptReady, {
		promptText = round.promptText,
		promptIndex = match.promptIndex,
		totalPrompts = #match.schedule,
		answerSeconds = ANSWER_SECONDS,
		playerAUserId = round.playerA.UserId,
		playerAName = round.playerA.Name,
		playerBUserId = round.playerB.UserId,
		playerBName = round.playerB.Name,
	})

	task.delay(ANSWER_SECONDS, function()
		QuiplashService._advanceToVoting(sessionId)
	end)
end

function QuiplashService._advanceToVoting(sessionId)
	local match = activeMatches[sessionId]
	if not match or not match.currentRound or match.currentRound.votingStarted then return end

	local round = match.currentRound
	round.votingStarted = true

	local answers = {
		{ id = "A", userId = round.playerA.UserId, name = round.playerA.Name, text = round.answerA or "(no answer submitted)" },
		{ id = "B", userId = round.playerB.UserId, name = round.playerB.Name, text = round.answerB or "(no answer submitted)" },
	}
	if math.random() > 0.5 then
		answers[1], answers[2] = answers[2], answers[1]
	end

	broadcastToSession(match.session, Remotes.VotingReady, {
		answers = answers,
		voteSeconds = VOTE_SECONDS,
		playerAUserId = round.playerA.UserId,
		playerBUserId = round.playerB.UserId,
	})

	task.delay(VOTE_SECONDS, function()
		QuiplashService._advanceToResults(sessionId)
	end)
end

function QuiplashService._advanceToResults(sessionId)
	local match = activeMatches[sessionId]
	if not match or not match.currentRound or match.currentRound.resultsShown then return end

	local round = match.currentRound
	round.resultsShown = true

	match.scores[round.playerA.UserId] = (match.scores[round.playerA.UserId] or 0) + round.votesForA
	match.scores[round.playerB.UserId] = (match.scores[round.playerB.UserId] or 0) + round.votesForB

	broadcastToSession(match.session, Remotes.ResultsReady, {
		results = {
			{ userId = round.playerA.UserId, name = round.playerA.Name, text = round.answerA or "(no answer submitted)", votes = round.votesForA },
			{ userId = round.playerB.UserId, name = round.playerB.Name, text = round.answerB or "(no answer submitted)", votes = round.votesForB },
		},
		promptIndex = match.promptIndex,
		totalPrompts = #match.schedule,
	})

	task.delay(4, function()
		if not activeMatches[sessionId] then return end
		match.promptIndex += 1
		startPrompt(sessionId)
	end)
end

function QuiplashService.StartMatch(session)
	if #session.players < 2 then return false, "Need at least 2 players to start" end

	activeMatches[session.sessionId] = {
		session = session,
		schedule = buildPromptSchedule(session.players),
		promptIndex = 1,
		scores = {},
		currentRound = nil,
	}

	startPrompt(session.sessionId)
	return true
end

function QuiplashService.SubmitAnswer(sessionId, player, text)
	local match = activeMatches[sessionId]
	if not match or not match.currentRound or match.currentRound.votingStarted then return end
	local round = match.currentRound

	if player == round.playerA and round.answerA == nil then
		round.answerA = filterAnswer(text, player)
	elseif player == round.playerB and round.answerB == nil then
		round.answerB = filterAnswer(text, player)
	end

	if round.answerA ~= nil and round.answerB ~= nil then
		QuiplashService._advanceToVoting(sessionId)
	end
end

function QuiplashService.SubmitVote(sessionId, player, choice)
	local match = activeMatches[sessionId]
	if not match or not match.currentRound or not match.currentRound.votingStarted or match.currentRound.resultsShown then return end
	local round = match.currentRound

	-- The two answering players can't vote on their own head-to-head.
	if player == round.playerA or player == round.playerB then return end
	if round.voters[player.UserId] then return end
	if choice ~= "A" and choice ~= "B" then return end

	round.voters[player.UserId] = true
	if choice == "A" then
		round.votesForA += 1
	else
		round.votesForB += 1
	end

	local eligibleVoters = 0
	for _, member in ipairs(match.session.players) do
		if member ~= round.playerA and member ~= round.playerB then
			eligibleVoters += 1
		end
	end
	if round.votesForA + round.votesForB >= eligibleVoters then
		QuiplashService._advanceToResults(sessionId)
	end
end

function QuiplashService.EndMatch(sessionId)
	local match = activeMatches[sessionId]
	if not match then return end

	local leaderboard = {}
	for _, member in ipairs(match.session.players) do
		table.insert(leaderboard, {
			userId = member.UserId,
			name = member.Name,
			score = match.scores[member.UserId] or 0,
		})
	end
	table.sort(leaderboard, function(a, b) return a.score > b.score end)

	broadcastToSession(match.session, Remotes.MatchComplete, { leaderboard = leaderboard })

	match.session.status = "Waiting"
	for _, member in ipairs(match.session.players) do
		SessionRemotes.SessionUpdated:FireClient(member, SessionService.GetPublicSession(match.session))
	end

	activeMatches[sessionId] = nil
end

function QuiplashService.IsMatchActive(sessionId)
	return activeMatches[sessionId] ~= nil
end

return QuiplashService
