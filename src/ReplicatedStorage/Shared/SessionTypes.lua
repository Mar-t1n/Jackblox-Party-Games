export type GameSession = {
	sessionId: string,
	hostUserId: number,
	hostName: string,
	roomName: string,
	gameType: string,
	players: {Player},
	maxPlayers: number,
	status: string,
	createdAt: number,
}

-- Sanitized session view sent to clients (no Player instances, real names only).
export type PublicSession = {
	sessionId: string,
	hostUserId: number,
	hostName: string,
	roomName: string,
	gameType: string,
	playerNames: {string},
	maxPlayers: number,
	status: string,
}

-- Row shape used for the public "browse rooms" list.
export type SessionListEntry = {
	sessionId: string,
	hostName: string,
	roomName: string,
	gameType: string,
	playerCount: number,
	maxPlayers: number,
	status: string,
}

return {}