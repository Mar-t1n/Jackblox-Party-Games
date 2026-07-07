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

-- Client (host) tells server to start the Quiplash match for their session.
Remotes.StartMatch = getOrCreate("RemoteEvent", "StartMatch", remotesFolder)

-- Server tells everyone in the session a new prompt is live, including which
-- two players are answering it this round (everyone else spectates/waits).
Remotes.PromptReady = getOrCreate("RemoteEvent", "PromptReady", remotesFolder)

-- Client (one of the two assigned players) submits their answer.
Remotes.SubmitAnswer = getOrCreate("RemoteEvent", "SubmitAnswer", remotesFolder)

-- Server broadcasts both answers (Quiplash-style head-to-head) for everyone
-- else in the session to vote on.
Remotes.VotingReady = getOrCreate("RemoteEvent", "VotingReady", remotesFolder)

-- Client submits their vote ("A" or "B") for the current prompt.
Remotes.SubmitVote = getOrCreate("RemoteEvent", "SubmitVote", remotesFolder)

-- Server broadcasts the vote tally for the current prompt.
Remotes.ResultsReady = getOrCreate("RemoteEvent", "ResultsReady", remotesFolder)

-- Server broadcasts the final leaderboard once every prompt has been played.
Remotes.MatchComplete = getOrCreate("RemoteEvent", "MatchComplete", remotesFolder)

return Remotes
