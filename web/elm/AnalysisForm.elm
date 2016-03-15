module AnalysisForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href, id)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects, Never)
import Signal exposing (Address)

import Json.Decode as Json exposing (at, string)

import SelectInput exposing (view, update)
import InputField exposing (view, update)
import Yield exposing (view, update)

import List


--********************************************************************************
--********************************************************************************
-- MODEL
--a row of the data file
--how to approach with files from different sources?
type alias Row = (String, Float, Float, Float, Float, Float, Float)

type alias Model = {
      source : SelectInput.Model
    , ticker : InputField.Model
    , yield : Yield.Model
    , newData : List Row
    , frequency : SelectInput.Model
    , startDate : InputField.Model
    , endDate : InputField.Model
    }

init : String -> String -> Bool -> List String -> (Model, Effects Action)
init source ticker yield optionValues =
    (
      { source = SelectInput.init source optionValues
      , ticker = InputField.init ticker "Ticker" "text"
      , yield = Yield.init yield
      --start with useful default data? instead of useless default data
      , newData = [("",0,0,0,0,0,0)]
      , frequency = SelectInput.init "Monthly" ["Daily","Weekly","Monthly","Quarterly"]
      , startDate = InputField.init "" "Start Date" "date"
      , endDate = InputField.init "" "End Date" "date"
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
    | UpdateFrequency String
    | UpdateStartDate String
    | UpdateEndDate String
    | Request
    | NewData ( Maybe (List Row) )
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateSource input ->
      ( { model | source = SelectInput.update input model.source }
      , Effects.none
      )
    UpdateFrequency input ->
        ( { model | frequency = SelectInput.update input model.frequency }
        , Effects.none
        )
    UpdateTicker input ->
      ( { model | ticker = InputField.update input model.ticker }
      , Effects.none
      )
    UpdateYield input ->
      ( { model | yield = Yield.update input model.yield }
      , Effects.none
      )
    UpdateStartDate input ->
      ( { model | startDate = InputField.update input model.startDate }
      , Effects.none
      )
    UpdateEndDate input ->
      ( { model | endDate = InputField.update input model.endDate }
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
          SelectInput.view (Signal.forwardTo address UpdateSource) model.source
        , InputField.view (Signal.forwardTo address UpdateTicker) model.ticker
        , Yield.view (Signal.forwardTo address UpdateYield) model.yield
        , text "Yield"
        , a [ href "#", onClick address Request ] [ text "Pull" ]
        ]
    , div [id "plot"] []
    , div [] [
        SelectInput.view (Signal.forwardTo address UpdateFrequency) model.frequency
      ]
    , div [] [
          InputField.view (Signal.forwardTo address UpdateStartDate) model.startDate
        , InputField.view (Signal.forwardTo address UpdateEndDate) model.endDate
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
  Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source.value++"/"++model.ticker.value++".json")
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
  Signal.send quandlMailBox.address data
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

quandlMailBox :
  { address : Signal.Address (List Row)
  , signal : Signal (List Row)
  }
quandlMailBox = Signal.mailbox [("",0,0,0,0,0,0)]
