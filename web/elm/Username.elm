module Username where

import Html exposing (Html, input)
import Html.Attributes exposing (value, placeholder)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = String

init : String -> Model
init user = user

-- UPDATE
update : String -> Model -> Model
update username model = username

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  input [
      value model
    , on "input" targetValue ( Signal.message address )
    , placeholder "Username"
    ] []
