--[[
	GameController - drives the Quiplash-style round: prompt -> answer ->
	vote -> results.

	This is a MOCKED single-player loop: bot players stand in for real
	opponents so the round can be played and verified end-to-end before the
	server-authoritative version exists. The public API (StartMockRound /
	SubmitAnswer / SubmitVote / On*Ready events) is deliberately shaped like
	what a real networked GameController would expose, so GameScreens.lua
	won't need to change when this gets swapped for real RemoteEvents later
	- only the inside of this file will.
]]

local GameController = {}

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

local BOT_ANSWER_BANK = {
	"A rubber chicken with a pulley in the middle",
	"Three raccoons in a trench coat",
	"Mild disappointment",
	"The government (probably)",
	"A haunted vending machine",
	"Your Wi-Fi router, honestly",
	"An extremely confident squirrel",
	"Grandma's secret sauce",
	"A single, judgmental pigeon",
	"Whatever's in the office fridge",
	"A wizard who only knows one spell",
	"Static electricity and bad decisions",
}

local BOT_NAMES = { "Blorp", "Nugget", "Sir Waffles", "Kevin", "Spicy Steve", "Doctor Beans" }

local listeners = { PromptReady = {}, VotingReady = {}, ResultsReady = {} }

local function fire(eventName, ...)
	for _, callback in ipairs(listeners[eventName]) do
		task.spawn(callback, ...)
	end
end

local function subscribe(eventName, callback)
	table.insert(listeners[eventName], callback)
	return function()
		local list = listeners[eventName]
		local index = table.find(list, callback)
		if index then
			table.remove(list, index)
		end
	end
end

function GameController.OnPromptReady(callback)
	return subscribe("PromptReady", callback)
end

function GameController.OnVotingReady(callback)
	return subscribe("VotingReady", callback)
end

function GameController.OnResultsReady(callback)
	return subscribe("ResultsReady", callback)
end

local state = {}

local function pickUnique(pool, count)
	local shuffled = table.clone(pool)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	local picked = {}
	for i = 1, math.min(count, #shuffled) do
		picked[i] = shuffled[i]
	end
	return picked
end

local function advanceToVoting(voteSeconds)
	if state.answers then return end

	local myText = state.myAnswer
	if myText == nil or myText == "" then
		myText = "(no answer submitted)"
	end

	local answers = { { id = "me", text = myText, isMine = true, authorName = "You" } }
	local botTexts = pickUnique(BOT_ANSWER_BANK, state.numBots)
	for i, text in ipairs(botTexts) do
		table.insert(answers, {
			id = "bot" .. i,
			text = text,
			isMine = false,
			authorName = BOT_NAMES[((i - 1) % #BOT_NAMES) + 1] .. " (Bot)",
		})
	end

	for i = #answers, 2, -1 do
		local j = math.random(1, i)
		answers[i], answers[j] = answers[j], answers[i]
	end

	state.answers = answers
	fire("VotingReady", answers, voteSeconds)

	task.delay(voteSeconds, function()
		GameController._advanceToResults()
	end)
end

function GameController._advanceToResults()
	if state.results or not state.answers then return end

	local voteCounts = {}
	for _, answer in ipairs(state.answers) do
		voteCounts[answer.id] = 0
	end
	if state.myVote then
		voteCounts[state.myVote] += 1
	end

	for i = 1, state.numBots do
		local voterId = "bot" .. i
		local candidates = {}
		for _, answer in ipairs(state.answers) do
			if answer.id ~= voterId then
				table.insert(candidates, answer.id)
			end
		end
		local pick = candidates[math.random(1, #candidates)]
		voteCounts[pick] += 1
	end

	local results = {}
	for _, answer in ipairs(state.answers) do
		table.insert(results, {
			id = answer.id,
			text = answer.text,
			isMine = answer.isMine,
			authorName = answer.authorName,
			votes = voteCounts[answer.id] or 0,
		})
	end
	table.sort(results, function(a, b) return a.votes > b.votes end)

	state.results = results
	fire("ResultsReady", results)
end

-- Starts a solo-testable round. config.NumBots controls how many fake
-- opponents fill out the answer/vote pool (default 3, like a small lobby).
function GameController.StartMockRound(config)
	config = config or {}
	state = {
		numBots = config.NumBots or 3,
		myAnswer = nil,
		myVote = nil,
		answers = nil,
		results = nil,
	}

	local answerSeconds = config.AnswerSeconds or 20
	local voteSeconds = config.VoteSeconds or 15
	local prompt = PROMPTS[math.random(1, #PROMPTS)]

	fire("PromptReady", prompt, answerSeconds)

	task.delay(answerSeconds, function()
		advanceToVoting(voteSeconds)
	end)
end

function GameController.SubmitAnswer(text)
	if state.answers then return end -- round already moved on
	state.myAnswer = text
end

function GameController.SubmitVote(answerId)
	if state.myVote or not state.answers then return end
	if answerId == "me" then return end -- can't vote for your own answer
	state.myVote = answerId
end

function GameController.EndRound()
	state = {}
end

return GameController
