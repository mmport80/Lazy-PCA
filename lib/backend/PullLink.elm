module Source (Model, init, update, view) where

import Html exposing (Html, option, select, text)
import Html.Events exposing (targetValue, on)

import Signal exposing (Address)

-- MODEL
type alias Model = {
      source : Source.Model
    , ticker : Ticker.Model
    , yield : Yield.Model
    , newData : List Row
    }

init : String -> Model
init source = source



-- UPDATE
type Action = Request

update : Action -> Model
update request = newSource

  Request ->
    ( model, getData model )
  NewData maybeList ->
    let
      data = (Maybe.withDefault model.newData maybeList)
    in
      (
        { model | newData = data }
        , sendData data
      )

-- VIEW
view : Signal.Address String -> Model -> Html
view address model =
  a [ href "#", onClick address Request ] [ text "Pull" ]
