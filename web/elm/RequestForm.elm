module RequestForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href, id)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects, Never)
import Signal exposing (Address)

import Json.Decode as Json exposing (at, string)

import Source exposing (view, update)
import TextInputField exposing (view, update)
import Yield exposing (view, update)

import List


--********************************************************************************
--********************************************************************************
-- MODEL
--a row of the data file
--how to approach with files from different sources?
type alias Row = (String, Float, Float, Float, Float, Float, Float)

type alias Model = {
      source : Source.Model
    , ticker : TextInputField.Model
    , yield : Yield.Model
    , newData : List Row
    }

init : String -> String -> Bool -> (Model, Effects Action)
init source ticker yield =
    (
      { source = Source.init source
      , ticker = TextInputField.init ticker "Ticker" "text"
      , yield = Yield.init yield
      --start with useful default data? instead of useless default data
      , newData = [("",0,0,0,0,0,0)]
      }
    , Effects.none
    )

--********************************************************************************
--********************************************************************************
-- UPDATE
type Action
    = UpdateSource String
    | UpdateTicker String
    | UpdateYield Bool
    | Request
    | NewData ( Maybe (List Row) )
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateSource input ->
      ( { model | source = Source.update input model.source }
      , Effects.none
      )
    UpdateTicker input ->
      ( { model | ticker = TextInputField.update input model.ticker }
      , Effects.none
      )
    UpdateYield input ->
      ( { model | yield = Yield.update input model.yield }
      , Effects.none
      )
    Request ->
      ( model, getData model )
    NoOp ->
      ( model, Effects.none )
    --update
    --and also send to port
    NewData maybeList ->
      let
        data = (Maybe.withDefault model.newData maybeList)
      in
        (
          { model | newData = data }
          , sendData data
        )


--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  div[][
      div []
        [
          Source.view (Signal.forwardTo address UpdateSource) model.source
        , TextInputField.view (Signal.forwardTo address UpdateTicker) model.ticker
        , Yield.view (Signal.forwardTo address UpdateYield) model.yield
        , text "Yield"
        , a [ href "#", onClick address Request ] [ text "Pull" ]
        ]
  ]


--********************************************************************************
--********************************************************************************
-- EFFECTS

--only take what's needed?
--i.e. date and closing price
--convert date into Date type
row : Json.Decoder Row
row = Json.tuple7 (,,,,,,)
  Json.string Json.float Json.float Json.float Json.float Json.float Json.float

--remove?
--don't like new operators that much
(=>) = (,)

quandlUrl : Model -> String
quandlUrl model =
  Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source++"/"++model.ticker.value++".json")
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


--Send data to JS
sendData : List Row -> Effects Action
sendData data =
  Signal.send testMailBox.address data
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

testMailBox :
  { address : Signal.Address (List Row)
  , signal : Signal (List Row)
  }
testMailBox = Signal.mailbox [("",0,0,0,0,0,0)]
