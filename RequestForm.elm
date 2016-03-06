module RequestForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe)

import Effects exposing (Effects, Never)

import Json.Decode as Json

import Signal exposing (Address)

import Source exposing (view, update)
import Ticker exposing (view, update)
import Yield exposing (view, update)

import Debug exposing (log)

-- MODEL
type alias Model = {
      source : Source.Model
    , ticker : Ticker.Model
    , yield : Yield.Model
    , quandlUrl : String
    }

init : String -> String -> Bool -> (Model, Effects Action)
init source ticker yield =
    (
      { source = Source.init source
      , ticker = Ticker.init ticker
      , yield = Yield.init yield
      , quandlUrl = ""
      }
    , Effects.none
    )


-- UPDATE
type Action
    = UpdateSource String
    | UpdateTicker String
    | UpdateYield Bool
    | Request
    | NewData (Maybe String)

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
      ( model, getRandomGif model)
    NewData maybeUrl ->
      (
      { model | quandlUrl = (Maybe.withDefault model.quandlUrl maybeUrl) }
      , Effects.none
      )


-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  div []
    [
      Source.view (Signal.forwardTo address UpdateSource) model.source
    , Ticker.view (Signal.forwardTo address UpdateTicker) model.ticker
    , Yield.view (Signal.forwardTo address UpdateYield) model.yield
    , a [ href "#", onClick address Request ] [ text "Pull" ]
    , text model.quandlUrl
    ]


-- EFFECTS
(=>) = (,)

quandlUrl : Model -> String
quandlUrl model =
  let
    l = log "Log" model.quandlUrl
  in
    Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source++"/"++model.ticker++".json")
      [ "auth_token" => "Fp6cFhibc5xvL2pN3dnu" ]

decodeUrl : Json.Decoder String
decodeUrl =
  Json.at ["dataset", "frequency"] Json.string

getRandomGif : Model -> Effects Action
getRandomGif model =
  Http.get decodeUrl (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewData
    |> Effects.task
