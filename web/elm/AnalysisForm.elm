module AnalysisForm where

import Html exposing (a, text, Html, div, hr)
import Html.Attributes exposing (href, id)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects, Never)
import Signal exposing (Address)

import Json.Decode as Json exposing (at, string)

import SelectInput exposing (init, view, update, Action, Option)
import InputField exposing (view, update)
import Yield exposing (view, update)

import List
import String

import Date
import Date.Format


--********************************************************************************
--********************************************************************************
-- MODEL
--a row of the data file
--how to approach with files from different sources?
--type alias Row = (String, Float, Float, Float, Float, Float, Float)
type alias Row = (Date.Date, Float)

defaultRow : Row
defaultRow = (,) (Date.fromTime 0) 0

type alias Model = {
      source : SelectInput.Model
    , ticker : InputField.Model
    , yield : Yield.Model
    , newData : List Row
    , frequency : SelectInput.Model
    , startDate : InputField.Model
    , endDate : InputField.Model
    }

init : (Model, Effects Action)
init =
  let
    sourceOptions = [ Option "YAHOO" "Yahoo", Option "GOOG" "Google", Option "CBOE" "Chicago Board of Options Exchange", Option "SPDJ" "S&P Dow Jones" ]
    frequencyOptions = [ Option "1" "Daily", Option "5" "Weekly", Option "21" "Monthly", Option "63" "Quarterly" ]
  in
    (
      { startDate = InputField.init "" "Start Date" "date" True
      , endDate = InputField.init "" "End Date" "date" True
      , ticker = InputField.init "INDEX_VIX" "Ticker" "text" False
      , yield = Yield.init False
      --start with useful default data? instead of useless default data
      , newData =  [ defaultRow ]
      --option names and values
      , source = SelectInput.init "YAHOO" sourceOptions False
      , frequency = SelectInput.init "21" frequencyOptions True
      }
    , Effects.none
    )

--********************************************************************************
--********************************************************************************
-- UPDATE
type Action
    = UpdateSource SelectInput.Action
    | UpdateFrequency SelectInput.Action
    | UpdateTicker InputField.Action
    | UpdateYield Bool
    | UpdateStartDate InputField.Action
    | UpdateEndDate InputField.Action
    | Request
    | NewData ( Maybe ( List (Row) ) )
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
      , sendDataToPlot model model.newData
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
      , sendDataToPlot model model.newData
      )
    UpdateEndDate input ->
      ( { model | endDate = InputField.update input model.endDate }
      , sendDataToPlot model model.newData
      )
    --get data from quandl
    Request ->
      ( {model |
          frequency = SelectInput.update SelectInput.Enable model.frequency
        , startDate = InputField.update InputField.Enable model.startDate
        , endDate = InputField.update InputField.Enable model.endDate
        }
      , getData model )
    NoOp ->
      ( model, Effects.none )
    --Send data to JS
    NewData maybeList ->
      let
        maybeToDate = (Maybe.withDefault (Date.fromTime 0)) >> (Date.Format.format "%Y-%m-%d" )
        data = Maybe.withDefault model.newData maybeList
        onlyDates = data |> List.map (\ (a,_) -> a )
        newStartDate = onlyDates |> List.head |> maybeToDate
        newEndDate = onlyDates |> List.reverse |> List.head |> maybeToDate
      in
        ( --take new data, save it down
          { model |
              newData = data
            , startDate = InputField.update (InputField.Update newEndDate) model.startDate
            , endDate = InputField.update (InputField.Update newStartDate) model.endDate
          }
          , sendDataToPlot model data
        )




--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  div [] [
      div []
        [
          SelectInput.view (Signal.forwardTo address UpdateSource) model.source
        , InputField.view (Signal.forwardTo address UpdateTicker) model.ticker
        , Yield.view (Signal.forwardTo address UpdateYield) model.yield
        , text "Yield"
        , a [ href "#", onClick address Request ] [ text "Pull" ]
        ]
    , hr [] []
    , div [id "plot"] []
    , hr [] []
    , div [] [
        SelectInput.view (Signal.forwardTo address UpdateFrequency) model.frequency
      ]
    , hr [] []
    , div [] [
        text "Start Date"
      , InputField.view (Signal.forwardTo address UpdateStartDate) model.startDate
      , text "End Date"
      , InputField.view (Signal.forwardTo address UpdateEndDate) model.endDate
      ]
  ]


--********************************************************************************
--********************************************************************************
-- EFFECTS

--INCOMING DATA


quandlUrl : Model -> String
quandlUrl model =
  Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source.value++"/"++model.ticker.value++".json")
    [ "auth_token" => "Fp6cFhibc5xvL2pN3dnu" ]

--change name to something like 'decodeList'
decodeData : Json.Decoder (List (Date.Date, Float))
decodeData = Json.at ["dataset", "data"] (Json.list csvRow)

csvRow : Json.Decoder (Date.Date, Float)
csvRow = (Json.tuple7 (,,,,,,)
  Json.string Json.float Json.float Json.float Json.float Json.float Json.float
  )
  |> Json.map (\ (a,_,_,_,_,_,b) -> ( (toDate a), b ) )

--remove?
--don't like new operators that much
(=>) = (,)

getData : Model -> Effects Action
getData model =
  Http.get decodeData (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewData
    |> Effects.task



--OUTGOING DATA

--filter new data appropriately before plotting it
sendDataToPlot : Model -> List Row -> Effects Action
sendDataToPlot model data =
  let
    fInt = toInteger 21 model.frequency.value
    sd = model.startDate.value |> toDate |> Date.toTime
    ed = model.startDate.value |> toDate |> Date.toTime
  in
    data
    --|> List.indexedMap (\ i (a,b) -> (i,a,b))
    --filter by frequency
    --|> List.filter (\ (i,a,b) -> i % fInt == 0 )
    --filter out according to start and end dates
    {--
    |> List.filter (\(_,a,_) ->
        (Date.toTime a) >= sd && (Date.toTime a) <= ed
      )
    --}
    |> List.map (\ (a,b) -> ((Date.Format.format "%Y-%m-%d" a), b) )
    --send data to UI
    |> sendData


sendData : List (String, Float) -> Effects Action
sendData data =
  Signal.send sendToPlotMailBox.address data
    --add error condition
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

sendToPlotMailBox :
  { address : Signal.Address (List (String, Float))
  , signal : Signal (List (String, Float))
  }
sendToPlotMailBox = Signal.mailbox [ ("",0) ]


--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
---Utils

--convert string to int with default value as backup
toInteger : Int -> String -> Int
toInteger d =
  String.toInt
  >> Result.toMaybe
  >> Maybe.withDefault d

--convert string to int with default value as backup
toDate : String -> Date.Date
toDate =
  Date.fromString
  >> Result.withDefault (Date.fromTime 0)

fromDateToInteger : Int -> String -> Int
fromDateToInteger d =
  String.toInt
  >> Result.toMaybe
  >> Maybe.withDefault d
