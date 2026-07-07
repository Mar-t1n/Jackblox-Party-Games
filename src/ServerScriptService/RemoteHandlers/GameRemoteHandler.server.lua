local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes.GameRemotes)
local SessionService = require(script.Parent.Parent.Services.SessionService)
local QuiplashService = require(script.Parent.Parent.Services.QuiplashService)

-- Tracks which session (if any) each player is currently in a live match for,
-- so SubmitAnswer/SubmitVote don't need the client to be trusted with the
-- sessionId of someone else's match.
local playerMatchSession = {}

Remotes.StartMatch.OnServerEvent:Connect(function(player, sessionId)
	if type(sessionId) ~= "string" then return end
	local session = SessionService.GetSession(sessionId)
	if not session then return end
	if session.hostUserId ~= player.UserId then return end
	if QuiplashService.IsMatchActive(sessionId) then return end

	session.status = "InProgress"
	for _, member in ipairs(session.players) do
		playerMatchSession[member.UserId] = sessionId
	end

	QuiplashService.StartMatch(session)
end)

Remotes.SubmitAnswer.OnServerEvent:Connect(function(player, text)
	local sessionId = playerMatchSession[player.UserId]
	if not sessionId then return end
	if type(text) ~= "string" then return end
	QuiplashService.SubmitAnswer(sessionId, player, text)
end)

Remotes.SubmitVote.OnServerEvent:Connect(function(player, choice)
	local sessionId = playerMatchSession[player.UserId]
	if not sessionId then return end
	QuiplashService.SubmitVote(sessionId, player, choice)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	playerMatchSession[player.UserId] = nil
end)
