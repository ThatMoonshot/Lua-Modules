---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		Array.map(match.games, CustomMatchSummary._createGame),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow?
function CustomMatchSummary._createGame(game, gameIndex)
	if game.status == STATUS_NOT_PLAYED then
		return
	end
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1hero', NUM_HEROES_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2hero', NUM_HEROES_PICK),
	}

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.Characters{
				flipped = false,
				characters = characterData[1],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team1side or ''),
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = Logic.nilIfEmpty(game.length) or ('Game ' .. gameIndex)},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.Characters{
				flipped = true,
				characters = characterData[2],
				bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team2side or ''),
			},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
