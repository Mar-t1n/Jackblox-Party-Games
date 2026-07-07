local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes.SessionRemotes)

local SessionService = {}
local activeSessions = {}
local MAX_PLAYERS_DEFAULT = 8

-- Room names are player-entered text shown to other players, so they must go
-- through Roblox's text filter before being stored/broadcast.
local function filterRoomName(rawName, hostPlayer)
	local fallback = hostPlayer.Name .. "'s Lobby"
	if rawName == nil or rawName == "" then
		return fallback
	end

	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(rawName, hostPlayer.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)

	if ok then
		return filtered
	end

	warn("[SessionService] Failed to filter room name, using fallback: " .. tostring(filtered))
	return fallback
end

local function broadcastSessionList()
	Remotes.SessionListUpdated:FireAllClients(SessionService.GetPublicSessionList())
end

-- Lets everyone already in the session see live join/leave updates with
-- real player names, since the public session list only exposes a count.
local function broadcastSessionUpdate(session)
	for _, member in session.players do
		Remotes.SessionUpdated:FireClient(member, SessionService.GetPublicSession(session))
	end
end

function SessionService.CreateSession(hostPlayer, gameType, rawRoomName, options)
	options = options or {}
	local sessionId = HttpService:GenerateGUID(false)

	local maxPlayers = options.maxPlayers
	if type(maxPlayers) ~= "number" then
		maxPlayers = MAX_PLAYERS_DEFAULT
	end
	maxPlayers = math.clamp(math.floor(maxPlayers), 2, 8)

	local session = {
		sessionId = sessionId,
		hostUserId = hostPlayer.UserId,
		hostName = hostPlayer.Name,
		roomName = filterRoomName(rawRoomName, hostPlayer),
		gameType = gameType,
		players = { hostPlayer },
		maxPlayers = maxPlayers,
		isPublic = options.isPublic ~= false,
		status = "Waiting",
		createdAt = os.time(),
	}

	activeSessions[sessionId] = session
	broadcastSessionList()
	return session
end

function SessionService.GetSession(sessionId)
	return activeSessions[sessionId]
end

-- Session data with real player names, safe to send to clients in that session.
function SessionService.GetPublicSession(session)
	local playerNames = {}
	local playerUserIds = {}
	for _, p in session.players do
		table.insert(playerNames, p.Name)
		table.insert(playerUserIds, p.UserId)
	end
	return {
		sessionId = session.sessionId,
		hostUserId = session.hostUserId,
		hostName = session.hostName,
		roomName = session.roomName,
		gameType = session.gameType,
		playerNames = playerNames,
		playerUserIds = playerUserIds,
		maxPlayers = session.maxPlayers,
		status = session.status,
	}
end

function SessionService.JoinSession(player, sessionId)
	local session = activeSessions[sessionId]
	if not session then
		return false, "Session no longer exists"
	end
	if #session.players >= session.maxPlayers then
		return false, "Session is full"
	end
	if session.status ~= "Waiting" then
		return false, "Session already in progress"
	end

	table.insert(session.players, player)
	if #session.players >= session.maxPlayers then
		session.status = "Full"
	end

	broadcastSessionList()
	broadcastSessionUpdate(session)
	return true
end

function SessionService.LeaveSession(player, sessionId)
	local session = activeSessions[sessionId]
	if not session then return end

	for i, p in session.players do
		if p == player then
			table.remove(session.players, i)
			break
		end
	end

	if #session.players == 0 then
		activeSessions[sessionId] = nil
	else
		if session.status == "Full" then
			session.status = "Waiting"
		end
		broadcastSessionUpdate(session)
	end

	broadcastSessionList()
end

function SessionService.GetPublicSessionList()
	local list = {}
	for _, session in activeSessions do
		if not session.isPublic then
			continue
		end
		table.insert(list, {
			sessionId = session.sessionId,
			hostName = session.hostName,
			roomName = session.roomName,
			gameType = session.gameType,
			playerCount = #session.players,
			maxPlayers = session.maxPlayers,
			status = session.status,
		})
	end
	return list
end

Players.PlayerRemoving:Connect(function(player)
	for sessionId, session in activeSessions do
		for _, p in session.players do
			if p == player then
				SessionService.LeaveSession(player, sessionId)
				break
			end
		end
	end
end)

return SessionService