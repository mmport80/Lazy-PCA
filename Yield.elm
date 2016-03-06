module Yield where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (targetChecked, on)

import Signal exposing (Address)

import Debug exposing (..)

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
