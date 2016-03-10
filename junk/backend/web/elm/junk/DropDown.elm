module DropDown where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onKeyPress)


-- MODEL
--change model as ui changes

--Config Model__
--source
--ticker
--Yield
--frequency
--startDate
--endDate

--Results
--data, anything else...
--ticker

type alias Model = String


-- UPDATE

type Action = Increment | Decrement

update : Action -> Model -> Model
update action model =
  case action of
    Increment ->
      model ++ "1"
    Decrement ->
      model ++ "1"


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =

    div []
      [ select [ ] (List.map customerItem dataProviders)
      , input [ value "INDEX_VIX" ] []
      , text "Yield"
      , input [ type' "checkbox" ] []
      , a [ href "xoxo" ] [ text "Pull" ]
      --, button [ onClick address Decrement ] [(text "Submit")]
      --, div [ countStyle ] [ text (toString model) ]
      --, button [ onClick address Increment ] [ text "+" ]
      ]


customerItem custname =
  option [ ] [ text custname ]

dataProviders = ["Yahoo","Google","CBOE","SPDJ"]


countStyle : Attribute
countStyle =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "inline-block")
    , ("width", "50px")
    , ("text-align", "center")
    ]
