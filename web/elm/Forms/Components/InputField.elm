module Forms.Components.InputField where

import Html exposing (Html, input)
import Html.Attributes exposing (value, placeholder, type', disabled)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
--add disabled option
type alias Model = {
    value : String
  , placeHolder : String
  , inputType : String
  , disabled : Bool
  }

init : String -> String -> String -> Bool -> Model
init input placeHolder inputType disabled =
  Model input placeHolder inputType disabled

-- UPDATE
type Action = Update String | Enable | Disable | Reset


update : Action -> Model -> Model
update action model =
  case action of
    Reset ->
      { model | value = "" }
    --if date then validate first
    Update input ->
      { model | value = input }
    Enable ->
      { model | disabled = False }
    Disable ->
      { model | disabled = True }
    --validation message

-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  input [
      value model.value
    , type' model.inputType
    , on "input" targetValue ( Update >> Signal.message address )
    , disabled model.disabled
    , placeholder model.placeHolder
    ] []
