module Forms.AnalysisForm where

import Html exposing (a, text, Html, div, hr)
import Html.Attributes exposing (href, id)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects, Never)
import Signal exposing (Address)

import Json.Decode as Json exposing (at, string)

import Forms.Components.SelectInput as SelectInput exposing (init, view, update, Action, Option)
import Forms.Components.InputField as InputField exposing (view, update)
import Forms.Components.Yield as Yield exposing (view, update)

import List
import String

import Date
import Date.Format
import Time exposing (every, millisecond)

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
    , progressMsg : String
    , plots : List PlotConfig
    }

init : List PlotConfig -> (Model, Effects Action)
init plots =
  let
    sourceOptions = [ Option "YAHOO" "Yahoo", Option "GOOG" "Google", Option "CBOE" "Chicago Board of Options Exchange", Option "SPDJ" "S&P Dow Jones" ]
    frequencyOptions = [ Option "1" "Daily", Option "5" "Weekly", Option "21" "Monthly", Option "63" "Quarterly" ]
  in
    (
      { startDate = InputField.init "" "Start Date" "date" True
      , endDate = InputField.init "" "End Date" "date" True
      , ticker = InputField.init "INDEX_VIX" "Ticker" "text" False
      , yield = Yield.init False
      --start with useful default data? instead of useless data
      , newData =  [ defaultRow ]
      , source = SelectInput.init "YAHOO" sourceOptions False
      , frequency = SelectInput.init "21" frequencyOptions True
      , progressMsg = ""
      , plots = plots
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
      let
        model' = { model | frequency = SelectInput.update input model.frequency }
      in
        ( model'
        , sendDataToPlot model'
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
      let
        model' = { model | startDate = InputField.update input model.startDate }
      in
        ( model'
        , sendDataToPlot model'
        )
    UpdateEndDate input ->
      let
        model' = { model | endDate = InputField.update input model.endDate }
      in
        ( model'
        , sendDataToPlot model'
        )
    --get data from quandl
    Request ->
      ( {model |
          frequency = SelectInput.update SelectInput.Enable model.frequency
        , startDate = InputField.update InputField.Enable model.startDate
        , endDate = InputField.update InputField.Enable model.endDate
        , progressMsg = "Please Wait..."
        }
      , getData model )
    --remove this
    NoOp ->
      ( model, Effects.none )
    --Send data to JS
    NewData maybeList ->
      let
        maybeToDate = (Maybe.withDefault (Date.fromTime 0)) >> (Date.Format.format "%Y-%m-%d" )
        data = Maybe.withDefault model.newData maybeList

        progressMsg =
          if maybeList == Nothing then
            "Could not find data"
          else
            ""

        onlyDates = data |> List.map (\ (a,_) -> a )
        newEndDate = onlyDates |> List.head |> maybeToDate
        newStartDate = onlyDates |> List.reverse |> List.head |> maybeToDate
        model' = { model |
            newData = data
          , startDate = InputField.update (InputField.Update newStartDate) model.startDate
          , endDate = InputField.update (InputField.Update newEndDate) model.endDate
          , progressMsg = progressMsg
          }
      in
        (
          model'
        , sendDataToPlot model'
        )


--on change send data to plot
--send data to server

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
        , text model.progressMsg
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
    --saved plots
    , div [] (List.foldl ( \p a -> (text p.source) :: a ) [] model.plots )--["1","2","3","4","5","6"])

    ]



--********************************************************************************
--********************************************************************************
-- EFFECTS

--INCOMING DATA
quandlUrl : Model -> String
quandlUrl model =
  Http.url ("https://www.quandl.com/api/v3/datasets/"++model.source.value++"/"++model.ticker.value++".json")
    [ "auth_token" => "Fp6cFhibc5xvL2pN3dnu" ]

--remove?
--don't like new operators that much
(=>) = (,)

--change name to something like 'decodeList'
decodeData : Json.Decoder (List (Date.Date, Float))
decodeData = Json.at ["dataset", "data"] (Json.list csvRow)

csvRow : Json.Decoder (Date.Date, Float)
csvRow = (Json.tuple7 (,,,,,,)
  Json.string Json.float Json.float Json.float Json.float Json.float Json.float
  )
  |> Json.map (\ (a,_,_,_,_,_,b) -> ( (toDate (Date.fromTime 0) a), b ) )

getData : Model -> Effects Action
getData model =
  Http.get decodeData (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewData
    |> Effects.task

--OUTGOING DATA

--filter new data appropriately before plotting it
sendDataToPlot : Model -> Effects Action
sendDataToPlot model =
  let
    fInt = toInteger 21 model.frequency.value
    sd = model.startDate.value |> toDate (Date.fromTime 0) |> Date.toTime
    ed = model.endDate.value |> toDate (Date.fromTime 0) |> Date.toTime
  in
    model.newData
    |> List.indexedMap (\ i (a,b) -> (i,a,b))
    --filter by frequency
    |> List.filter (\ (i,a,b) -> i % fInt == 0 )
    --filter out according to start and end dates
    |> List.filter (\(_,a,_) ->
        (Date.toTime a >= sd) && (Date.toTime a <= ed)
      )
    |> List.map (\ (_,a,b) -> ((dateToISOFormat a), b) )
    --send data to UI
    |> sendData

dateToISOFormat : Date.Date -> String
dateToISOFormat = Date.Format.format "%Y-%m-%d"

sendData : List (String, Float) -> Effects Action
sendData data =
  Signal.send sendToPlotMailBox.address data
    --add error condition
    --remove no op
    --and flag errors
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
toDate : Date.Date -> String -> Date.Date
toDate d =
  Date.fromString
  >> Result.withDefault d

fromDateToInteger : Int -> String -> Int
fromDateToInteger d =
  String.toInt
  >> Result.toMaybe
  >> Maybe.withDefault d

type alias PlotConfig = {
      endDate : String
    , startDate : String
    , ticker : String
    , y : Bool
    , source : String
    , frequency : Int
    , id : Int
    }

defaultPlotConfig : PlotConfig
defaultPlotConfig = PlotConfig "" "" "" False "" 21 -1

type alias PortableModel = {
      endDate : String
    , startDate : String
    , ticker : String
    , y : Bool
    , source : String
    , frequency : String
    , newData : List (String, Float)
    }

defaultPortableModel : PortableModel
defaultPortableModel = PortableModel "" "" "" False "" "" [("",0)]

convertElmModelToPortableFormat : Model -> PortableModel
convertElmModelToPortableFormat model =
  { endDate = model.endDate.value
  , startDate = model.startDate.value
  , ticker = model.ticker.value
  , y = model.yield
  , source = model.source.value
  , frequency = model.frequency.value
  , newData =  model.newData |> List.map (\ (a,b) -> (dateToISOFormat a,b) )
  }
