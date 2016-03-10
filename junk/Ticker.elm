module Ticker where

import Html exposing (Html, input)
import Html.Attributes exposing (value)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = String

init : String -> Model
init ticker = ticker

-- UPDATE
update : String -> Model -> Model
update newTicker model = newTicker

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  input [
      value model
    , on "input" targetValue ( Signal.message address )
    ] []
