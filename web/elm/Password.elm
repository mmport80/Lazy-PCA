module Password where

import Html exposing (Html, input)
import Html.Attributes exposing (value, type', placeholder)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = String

init : String -> Model
init password = password

-- UPDATE
update : String -> Model -> Model
update password model = password

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  input [
      value model
    , on "input" targetValue ( Signal.message address )
    , type' "password"
    , placeholder "Password"
    ] []
