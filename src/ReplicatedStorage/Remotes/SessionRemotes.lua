local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local remotesFolder = getOrCreate("Folder", "RemoteEvents", ReplicatedStorage)

local Remotes = {}

-- Client asks server for the current list of sessions (one-time fetch)
Remotes.GetSessions = getOrCreate("RemoteFunction", "GetSessions", remotesFolder)

-- Server pushes updated session list to all clients whenever it changes
Remotes.SessionListUpdated = getOrCreate("RemoteEvent", "SessionListUpdated", remotesFolder)

-- Client tells server it wants to create a session
Remotes.CreateSession = getOrCreate("RemoteEvent", "CreateSession", remotesFolder)

-- Client tells server it wants to join a specific session
Remotes.JoinSession = getOrCreate("RemoteEvent", "JoinSession", remotesFolder)

-- Client tells server it's leaving its current session
Remotes.LeaveSession = getOrCreate("RemoteEvent", "LeaveSession", remotesFolder)

-- Server tells a specific client it successfully created/joined a session
Remotes.SessionJoined = getOrCreate("RemoteEvent", "SessionJoined", remotesFolder)

-- Server pushes a live player-list update to everyone currently in a session
Remotes.SessionUpdated = getOrCreate("RemoteEvent", "SessionUpdated", remotesFolder)

-- Server tells a specific client that their last session action (join/create) failed
Remotes.SessionActionFailed = getOrCreate("RemoteEvent", "SessionActionFailed", remotesFolder)

return Remotes