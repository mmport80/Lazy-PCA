module InputField where

import Html exposing (Html, input)
import Html.Attributes exposing (value, placeholder, type')
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
--add disabled option
type alias Model = {
    value : String
  , placeHolder : String
  , inputType : String
  }

init : String -> String -> String -> Model
init input placeHolder inputType =
  Model input placeHolder inputType

-- UPDATE
update : String -> Model -> Model
update input model = {model | value = input}

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  input [
      value model.value
    , type' model.inputType
    , on "input" targetValue ( Signal.message address )
    , placeholder model.placeHolder
    ] []
