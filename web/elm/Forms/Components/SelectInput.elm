module Forms.Components.SelectInput where

import Html exposing (Html, option, select, text)
import Html.Events exposing (targetValue, on)
import Html.Attributes exposing (selected, value, disabled)

import Signal exposing (Address)

-- MODEL
type alias Model = {
    value : String
  , optionValues : List Option
  , disabled : Bool
  }

type alias Option = { value: String, text: String }

init : String -> List Option -> Bool -> Model
init value optionValues disabled = Model value optionValues disabled

-- UPDATE
type Action = Enable | Update String | Disable

update : Action -> Model -> Model
update action model =
  case action of
    Update input ->
      { model | value = input }
    Enable ->
      { model | disabled = False }
    Disable ->
      { model | disabled = True }

-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  let
    optionsWDefault = options model.value
  in
    select [
        on "change" targetValue (Signal.message address << Update )
      , disabled model.disabled
      ]
      ( List.map optionsWDefault model.optionValues )

options : String -> Option -> Html
options  d o =
  if d == o.value then
    option [ value o.value , selected True] [ text o.text ]
  else
    option [ value o.value ] [ text o.text ]
