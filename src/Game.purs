module App.Game where

import Data.Maybe
import App.Board as Board
import App.BoardView as BoardView
import App.Round as Round
import Pux.Html as H
import App.Board (Board, Player)
import App.BoardView (class BoardView, getBoard, getCurrentPlayer, getHand, getPitAction, getTurn)
import App.Config (Config)
import App.Config as Config
import App.FixedMatrix72 (Row(..))
import Data.Either (Either(..))
import Data.Tuple (Tuple(..))
import Prelude (show, ($), (<$>), (#), (<>), (+))
import Pux (EffModel, mapEffects, mapState, noEffects)
import Pux.Html (Html)

data State
  = PlayingRound Config Int Round.State
  | RoundOver Config Int Player Board
  | GameOver Config Int Player Board

data Action
  = RoundAction Round.Action
  | NextRound
  -- | NewGame

instance boardViewGame :: BoardView State Action where
  getBoard (PlayingRound _ _ round) = getBoard round
  getBoard (RoundOver _ _ _ board) = board
  getBoard (GameOver _ _ _ board) = board

  getCurrentPlayer (PlayingRound _ _ round) = getCurrentPlayer round
  getCurrentPlayer _ = Nothing

  getHand (PlayingRound _ _ round) = getHand round
  getHand _ = Nothing

  getTurn (PlayingRound _ _ round) = getTurn round
  getTurn _ = Nothing

  getPitAction (PlayingRound _ _ round) ref = RoundAction <$> getPitAction round ref
  getPitAction _ _ = Nothing

init :: State
init = PlayingRound Config.init 1 $ Round.init A Board.init

update :: forall eff. Action -> State -> EffModel State Action (eff)
update (RoundAction action) (PlayingRound config nth round) =
  case Round.update config action round of
    Right result ->
      result
      # mapEffects RoundAction
      # mapState (PlayingRound config nth)
    Left (Tuple player board) -> -- Round over
      RoundOver config nth player board
      # noEffects

update NextRound (RoundOver config nth player board) =
  PlayingRound config (nth + 1) (Round.init player board) -- TODO
  # noEffects

update _ state =
  -- TODO: make this not possible
  state
  # noEffects

view :: State -> Html Action
view (PlayingRound config nth round) =
  H.div []
    [ H.h2 [] [ H.text $ "Playing round " <> show nth ]
    , RoundAction <$> Round.view round
    , Config.view config
    ]

view state@(RoundOver config nth player board) =
  H.div []
    [ H.h2 [] [ H.text $ "Round " <> show nth <> " is over" ]
    , BoardView.view state
    , Config.view config
    ]

view state@(GameOver config nth player board) =
  H.div []
    [ H.h2 [] [ H.text $ show player <> "won the game after " <> show nth <> "rounds" ]
    , BoardView.view state
    , Config.view config
    ]
