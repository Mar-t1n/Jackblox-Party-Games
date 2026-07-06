local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes.SessionRemotes)
local SessionService = require(script.Parent.Parent.Services.SessionService)

-- Only game type we ship today; keeps client-supplied strings from becoming
-- arbitrary session categories.
local SUPPORTED_GAME_TYPES = { Quiplash = true }

Remotes.GetSessions.OnServerInvoke = function(player)
	return SessionService.GetPublicSessionList()
end

Remotes.CreateSession.OnServerEvent:Connect(function(player, gameType, roomName)
	if type(gameType) ~= "string" or not SUPPORTED_GAME_TYPES[gameType] then
		gameType = "Quiplash"
	end
	if type(roomName) ~= "string" then
		roomName = ""
	end
	roomName = string.sub(roomName, 1, 32)

	local session = SessionService.CreateSession(player, gameType, roomName)
	Remotes.SessionJoined:FireClient(player, SessionService.GetPublicSession(session))
end)

Remotes.JoinSession.OnServerEvent:Connect(function(player, sessionId)
	if type(sessionId) ~= "string" then return end

	local ok, err = SessionService.JoinSession(player, sessionId)
	if ok then
		Remotes.SessionJoined:FireClient(player, SessionService.GetPublicSession(SessionService.GetSession(sessionId)))
	else
		Remotes.SessionActionFailed:FireClient(player, err)
	end
end)

Remotes.LeaveSession.OnServerEvent:Connect(function(player, sessionId)
	if type(sessionId) ~= "string" then return end
	SessionService.LeaveSession(player, sessionId)
end)
