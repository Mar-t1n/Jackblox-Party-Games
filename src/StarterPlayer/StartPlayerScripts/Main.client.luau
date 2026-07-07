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
	OnStartMatch = function(session)
		GameController.StartMatch(session.sessionId)
	end,
})

local roundUI = GameScreens.Build(UIKit, GameController, {
	OnBackToLobby = function()
		UIKit.SwitchTo(lobby.LobbiesBrowser)
	end,
})

menu.PlayButton.MouseButton1Click:Connect(function()
	UIKit.SwitchTo(menu.ModeSelect)
end)

menu.QuiplashButton.MouseButton1Click:Connect(function()
	UIKit.SwitchTo(lobby.LobbiesBrowser)
end)

UIKit.SwitchTo(menu.MainMenu)
