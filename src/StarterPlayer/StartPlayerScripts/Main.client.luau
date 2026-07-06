--[[
	Entry point LocalScript. Builds the menu shell, then wires the
	cross-screen navigation and hands "start match" / "back to lobby" /
	"play again" decisions to the controllers. Individual screen modules only
	know about the one controller they need (LobbyScreens -> SessionController,
	GameScreens -> GameController); this script is the only place that needs
	to see all of them at once.
]]

local StarterPlayerScripts = script.Parent

local UIKit = require(StarterPlayerScripts.UI.UIKit)
local MenuScreens = require(StarterPlayerScripts.UI.MenuScreens)
local LobbyScreens = require(StarterPlayerScripts.UI.LobbyScreens)
local GameScreens = require(StarterPlayerScripts.UI.GameScreens)

local SessionController = require(StarterPlayerScripts.Controllers.SessionController)
local GameController = require(StarterPlayerScripts.Controllers.GameController)

UIKit.Init()

local menu = MenuScreens.Build(UIKit)

local lobby = LobbyScreens.Build(UIKit, SessionController, {
	ModeSelect = menu.ModeSelect,
	OnStartMatch = function()
		-- TODO: once the server-authoritative round exists, this should tell
		-- the server to start the match for everyone in the session instead
		-- of only kicking off a local mock round for the host.
		GameController.StartMockRound()
	end,
})

local roundUI = GameScreens.Build(UIKit, GameController, {
	OnBackToLobby = function()
		GameController.EndRound()
		UIKit.SwitchTo(lobby.LobbiesBrowser)
	end,
	OnPlayAgain = function()
		GameController.StartMockRound()
	end,
})

menu.PlayButton.MouseButton1Click:Connect(function()
	UIKit.SwitchTo(menu.ModeSelect)
end)

menu.LobbiesButton.MouseButton1Click:Connect(function()
	UIKit.SwitchTo(lobby.LobbiesBrowser)
end)

UIKit.SwitchTo(menu.MainMenu)
