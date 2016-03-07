module RequestForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe)

import Effects exposing (Effects, Never)

import Json.Decode as Json exposing (at, string)

import Signal exposing (Address)

import Source exposing (view, update)
import Ticker exposing (view, update)
import Yield exposing (view, update)

import Debug exposing (log)

import List


-- MODEL
type alias Model = {
      source : Source.Model
    , ticker : Ticker.Model
    , yield : Yield.Model
    , newData : List Row
    }

init : String -> String -> Bool -> (Model, Effects Action)
init source ticker yield =
    (
      { source = Source.init source
      , ticker = Ticker.init ticker
      , yield = Yield.init yield
      , newData = [("",0,0,0,0,0,0)]
      }
    , Effects.none
    )


-- UPDATE
type Action
    = UpdateSource String
    | UpdateTicker String
    | UpdateYield Bool
    | Request
    | NewData ( Maybe (List Row) )

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateSource input ->
      ( { model | source = Source.update input model.source }
      , Effects.none
      )
    UpdateTicker input ->
      ( { model | ticker = Ticker.update input model.ticker }
      , Effects.none
      )
    UpdateYield input ->
      ( { model | yield = Yield.update input model.yield }
      , Effects.none
      )
    Request ->
      ( model, getData model )
    NewData maybeList ->
      ( { model | newData = (Maybe.withDefault model.newData maybeList) }
      , Effects.none
      )


-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  let l =
    Debug.log "array" model.newData
  in
    div []
      [
        Source.view (Signal.forwardTo address UpdateSource) model.source
      , Ticker.view (Signal.forwardTo address UpdateTicker) model.ticker
      , Yield.view (Signal.forwardTo address UpdateYield) model.yield
      , text "Yield"
      , a [ href "#", onClick address Request ] [ text "Pull" ]
      ]


-- EFFECTS
type alias Row = (String, Float, Float, Float, Float, Float, Float)

row : Json.Decoder Row
row = Json.tuple7 (,,,,,,)
  Json.string Json.float Json.float Json.float Json.float Json.float Json.float

(=>) = (,)

quandlUrl : Model -> String
quandlUrl model =
  Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source++"/"++model.ticker++".json")
    [ "auth_token" => "Fp6cFhibc5xvL2pN3dnu" ]

--change name to something like 'decodeList'
decodeData : Json.Decoder (List Row)
decodeData = Json.at ["dataset", "data"] (Json.list row)

getData : Model -> Effects Action
getData model =
  Http.get decodeData (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewData
    |> Effects.task
