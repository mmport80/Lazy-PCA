module Source (Model, init, update, view) where

import Html exposing (Html, option, select, text)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = String

init : String -> Model
init source = source

-- UPDATE
update : String -> Model -> Model
update newSource model = newSource

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  select [ on "change" targetValue (Signal.message address) ]
    (List.map options dataProviders)

options : String -> Html
options s =
  option [] [ text s ]

dataProviders = ["Yahoo","Google","CBOE","SPDJ"]
