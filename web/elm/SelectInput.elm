module SelectInput (Model, init, update, view) where

import Html exposing (Html, option, select, text)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = {
    value : String
  , optionValues : List String
  }

init : String -> List String -> Model
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
  select [ on "change" targetValue (Signal.message address) ]
    (List.map options model.optionValues)

options : String -> Html
options s =
  option [] [ text s ]

--optionValues = ["Yahoo","Google","CBOE","SPDJ"]
