--[[
	GameController - the client's only touchpoint with the Quiplash round
	RemoteEvents. Each prompt is answered by exactly two players (server-
	assigned); everyone else in the session spectates until voting opens.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Remotes.GameRemotes)

local localPlayer = Players.LocalPlayer

local GameController = {}

local listeners = { PromptReady = {}, VotingReady = {}, ResultsReady = {}, MatchComplete = {} }

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

function GameController.OnMatchComplete(callback)
	return subscribe("MatchComplete", callback)
end

function GameController.StartMatch(sessionId)
	Remotes.StartMatch:FireServer(sessionId)
end

function GameController.SubmitAnswer(text)
	Remotes.SubmitAnswer:FireServer(text)
end

function GameController.SubmitVote(choice)
	Remotes.SubmitVote:FireServer(choice)
end

Remotes.PromptReady.OnClientEvent:Connect(function(payload)
	payload.isParticipant = payload.playerAUserId == localPlayer.UserId or payload.playerBUserId == localPlayer.UserId
	payload.isPlayerA = payload.playerAUserId == localPlayer.UserId
	fire("PromptReady", payload)
end)

Remotes.VotingReady.OnClientEvent:Connect(function(payload)
	payload.canVote = payload.playerAUserId ~= localPlayer.UserId and payload.playerBUserId ~= localPlayer.UserId
	fire("VotingReady", payload)
end)

Remotes.ResultsReady.OnClientEvent:Connect(function(payload)
	fire("ResultsReady", payload)
end)

Remotes.MatchComplete.OnClientEvent:Connect(function(payload)
	fire("MatchComplete", payload)
end)

return GameController
