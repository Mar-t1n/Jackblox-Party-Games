export type GameSession = {
	sessionId: string,
	hostUserId: number,
	hostName: string,
	gameType: string,
	players: {Player},
	maxPlayers: number,
	status: string,
	createdAt: number,
}

return {}