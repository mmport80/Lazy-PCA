module Yield where

import Html exposing (Html, input)
import Html.Attributes exposing (type')
import Html.Events exposing (targetChecked, on)

import Signal exposing (Address)

-- MODEL
type alias Model = Bool

init : Bool -> Model
init yield = yield

-- UPDATE
update : Bool -> Model -> Model
update newYield model = newYield

-- VIEW
view : Signal.Address Bool -> Model -> Html
view address model =
  input
    [ type' "checkbox"
    , on "change" targetChecked (Signal.message address)
    ]
    []
