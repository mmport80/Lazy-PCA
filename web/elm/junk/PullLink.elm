module PullLink where

import Html exposing (a, text, Html)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on)

import Signal exposing (Address)

-- MODEL
type alias Model = { yield : Bool }

-- UPDATE
update : Bool -> Model -> Model
update newYield model =
  { model | yield = newYield }

-- VIEW
view : Signal.Address Bool -> Model -> Html
view address model =
  a [ href "babab" ] [ text "Pull" ]
