--[[
	SessionController - the client's only touchpoint with the session
	RemoteEvents/RemoteFunction. UI modules should never touch
	ReplicatedStorage.Remotes directly; they go through this controller so the
	networking layer can change without UI rewrites.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Remotes.SessionRemotes)

local SessionController = {}

-- Signal-style event list so multiple UI screens can subscribe independently.
local listeners = {
	SessionListUpdated = {},
	SessionJoined = {},
	SessionUpdated = {},
	SessionActionFailed = {},
}

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

function SessionController.OnSessionListUpdated(callback)
	return subscribe("SessionListUpdated", callback)
end

function SessionController.OnSessionJoined(callback)
	return subscribe("SessionJoined", callback)
end

function SessionController.OnSessionUpdated(callback)
	return subscribe("SessionUpdated", callback)
end

function SessionController.OnSessionActionFailed(callback)
	return subscribe("SessionActionFailed", callback)
end

-- One-time fetch, useful when a screen opens and needs the current list
-- immediately rather than waiting for the next broadcast.
function SessionController.FetchSessions()
	local ok, result = pcall(function()
		return Remotes.GetSessions:InvokeServer()
	end)
	if ok then
		return result
	end
	warn("[SessionController] GetSessions failed: " .. tostring(result))
	return {}
end

function SessionController.CreateSession(gameType, roomName, options)
	Remotes.CreateSession:FireServer(gameType, roomName, options)
end

function SessionController.JoinSession(sessionId)
	Remotes.JoinSession:FireServer(sessionId)
end

function SessionController.LeaveSession(sessionId)
	Remotes.LeaveSession:FireServer(sessionId)
end

Remotes.SessionListUpdated.OnClientEvent:Connect(function(sessionList)
	fire("SessionListUpdated", sessionList)
end)

Remotes.SessionJoined.OnClientEvent:Connect(function(session)
	fire("SessionJoined", session)
end)

Remotes.SessionUpdated.OnClientEvent:Connect(function(session)
	fire("SessionUpdated", session)
end)

Remotes.SessionActionFailed.OnClientEvent:Connect(function(errorMessage)
	fire("SessionActionFailed", errorMessage)
end)

return SessionController
