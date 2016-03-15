module SelectInput (Model, init, update, view) where

import Html exposing (Html, option, select, text)
import Html.Events exposing (targetValue, on)
import Html.Attributes exposing (selected, value)

import Signal exposing (Address)

-- MODEL
type alias Model = {
    value : String
  , optionValues : List Option
  }

type alias Option = {text: String, value: String}

init : String -> List Option -> Model
init value optionValues = {
    value = value
  , optionValues = optionValues
  }

-- UPDATE
update : String -> Model -> Model
update newValue model = { model | value = newValue }

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  let
    optionsWDefault = options model.value
  in
    select [ on "change" targetValue (Signal.message address) ]
      ( List.map optionsWDefault model.optionValues )

options : String -> Option -> Html
options  d o =
  if d == o.text then
    option [ value o.value , selected True] [ text o.text ]
  else
    option [ value o.value ] [ text o.text ]

--optionValues = ["Yahoo","Google","CBOE","SPDJ"]
