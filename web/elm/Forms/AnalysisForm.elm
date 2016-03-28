module Forms.AnalysisForm where

import Html exposing (a, text, Html, div, hr, span, br)
import Html.Attributes exposing (href, id, class, classList)
import Html.Events exposing (targetChecked, on, onClick, onMouseOver)

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

--********************************************************************************
--********************************************************************************
-- MODEL
--a row of the data file
type alias Row = (Date.Date, Float)

defaultRow : Row
defaultRow = (,) (Date.fromTime 0) 0

--description of form
type alias Model = {
    source : SelectInput.Model
  , ticker : InputField.Model
  , yield : Yield.Model
  , newData : List Row
  , frequency : SelectInput.Model
  , startDate : InputField.Model
  , verifiedStartDate : String
  , endDate : InputField.Model
  , verifiedEndDate : String
  , progressMsg : String
  , plot_id : Int
  , plots : List PlotConfig
  , hoverId : Int
  }

--select field values
sourceOptions : List Option
sourceOptions = [ Option "YAHOO" "Yahoo", Option "GOOG" "Google", Option "CBOE" "Chicago Board of Options Exchange", Option "SPDJ" "S&P Dow Jones" ]

frequencyOptions : List Option
frequencyOptions = [ Option "1" "Daily", Option "5" "Weekly", Option "21" "Monthly", Option "63" "Quarterly" ]

--initilise form
init : List PlotConfig -> (Model, Effects Action)
init plots =
  let
    initPlot = Maybe.withDefault defaultPlotConfig (List.head plots)
  in
    (
      { startDate = InputField.init initPlot.startDate "Start" "date" True
      , endDate = InputField.init initPlot.endDate "End" "date" True
      , ticker = InputField.init initPlot.ticker "Ticker" "text" False
      , yield = Yield.init initPlot.y
      , newData =  [ defaultRow ]
      , source = SelectInput.init initPlot.source sourceOptions False
      , frequency = SelectInput.init (toString initPlot.frequency) frequencyOptions True
      , progressMsg = ""
      , plot_id = initPlot.id
      , plots = plots
      , hoverId = 0
      }
    , Effects.none
    )

--********************************************************************************
--********************************************************************************
-- UPDATE
--all the actions available for this form
type Action
    = UpdateSource SelectInput.Action
    | UpdateFrequency SelectInput.Action
    | UpdateTicker InputField.Action
    | UpdateYield Bool
    | UpdateStartDate InputField.Action
    | UpdateEndDate InputField.Action
    --request data from quandl
    | Request
    --once we receive data then, send it to the scatter plot
    | NewData ( Maybe ( List (Row) ) )
    --get rid of this, superfluous
    | NoOp
    --load plot when from saved configurations
    | LoadNewPlot PlotConfig
    | Hover Int
    | ReceiveNewPlot PlotConfig
    | RequestNewPlot
    | Delete PlotConfig

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    --update plot configs as they are updated in the ui
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
    --only update dates if they are actually dates
    UpdateStartDate input ->
      let
        model' = { model | startDate = InputField.update input model.startDate }
      in
        ( model'
        , sendDataToPlot model'
        )
    UpdateEndDate input ->
      let
        endDate = InputField.update input model.endDate
        model' = { model | endDate = endDate }
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
        , progressMsg = "Downloading Data..."
        }
      , getData model )
    --remove this
    NoOp ->
      ( model, Effects.none )
    LoadNewPlot p ->
      let
        model' = { model |
          startDate = InputField.init p.startDate "Start Date" "date" False
        , endDate = InputField.init p.endDate "End Date" "date" False
        , ticker = InputField.init p.ticker "Ticker" "text" False
        , yield = Yield.init p.y
        , source = SelectInput.init p.source sourceOptions False
        , frequency = SelectInput.init (toString p.frequency) frequencyOptions False
        , plot_id = p.id
        , progressMsg = "Downloading Data..."
        }
      in
        (model', getData model')
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
        ( model'
        , sendDataToPlot model'
        )
    Hover id ->
      ( { model |
          hoverId = id
          }
        , Effects.none )
    --send new plot request
    RequestNewPlot ->
      --plot's requested in Router
      ( model, Effects.none )
    --add new plot to top of array
    --v similar to load new plot
    ReceiveNewPlot p ->
      let
        model' = { model |
          startDate = InputField.init p.startDate "Start Date" "date" False
        , endDate = InputField.init p.endDate "End Date" "date" False
        , ticker = InputField.init p.ticker "Ticker" "text" False
        , yield = Yield.init p.y
        , source = SelectInput.init p.source sourceOptions False
        , frequency = SelectInput.init (toString p.frequency) frequencyOptions False
        , plot_id = p.id
        , progressMsg = "Downloading Data..."
        , plots = p :: model.plots
        }
      in
        (model', getData model')
    Delete p ->
      --done at 'router' level
      ( model
      , Effects.none
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
          a [ href "#", onClick address RequestNewPlot ] [ text "New" ]
        ]
    , hr [] []
    , div []
        [
          SelectInput.view (Signal.forwardTo address UpdateSource) model.source
        , InputField.view (Signal.forwardTo address UpdateTicker) model.ticker
        , Yield.view (Signal.forwardTo address UpdateYield) model.yield
        , text "Yield"
        , a [ href "#", onClick address Request ] [ text "Pull" ]
        ]
    , hr [] []
    , div [] [ text model.progressMsg ]
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
    , hr [] []
    --saved plots
    , div [ class "table" ] ( generateSavedPlotConfigTable address model )
    ]

--make this a standalone component?
generateSavedPlotConfigTable : Signal.Address Action -> Model -> List Html
generateSavedPlotConfigTable address model =
  let
    cell = class "cell"
    onHover id = onMouseOver address (Hover id)
    load p = onClick address (LoadNewPlot p)
    underline id =
      if id == model.hoverId then
        classList [("underline", True),("cell",True)]
      else
        classList [("normal", True),("cell",True)]
    default p = [underline p.id, onHover p.id, load p]
  in
    [ div [ class "header" ]
        [   div [ cell ] [ text "Source"]
          , div [ cell ] [ text "Ticker"]
          , div [ cell ] [ text "Sampling"]
          , div [ cell ] [ text "Period" ]
          , div [ cell ] [ text "DELETE" ]
          ]
    ]
    ++
    List.map
      ( \p ->
        div [
            classList [
                ("rowGroup", True)
              ]
            ]
            --group everything but delete together
            --have only one LoadNewPlot reference
            [ div [ classList [("row", True),("hover",True)] ] [
                div (default p) [ text (String.left 1 p.source) ]
              , div (default p) [ text p.ticker ]
              , div (default p)
                [ text
                  (--convert value to text
                  List.filter ( \o -> o.value == toString(p.frequency) ) frequencyOptions
                  |> List.head
                  |> Maybe.withDefault (Option "21" "Monthly")
                  |> (\o -> String.left 1 o.text)
                  )
                ]
              , div (default p)
                  [ text ((String.left 4 p.startDate) ++ " - " ++ (String.left 4 p.endDate)) ]
              --delete plot from DB
              --remove from plots list
              --remove from db
              , if p.id == model.hoverId then
                  div [ cell, class "delete", onHover p.id, onClick address (Delete p) ] [ text "X" ]
                else
                  div [ cell, class "delete", onHover p.id ] []
            ]
          ]

        )
      ( List.filter ( \p -> p.id /= model.plot_id ) model.plots )




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
defaultPlotConfig = PlotConfig "1950-01-03" "2016-03-24" "INDEX_GSPC" False "Yahoo" 21 -1

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

dateValidate : String -> String -> String
dateValidate orig input =
  case Date.fromString input of
    --update
    Ok _ ->
      input
    --don't update
    Err _ ->
      orig

convertElmModelToPlotConfig : Model -> PlotConfig
convertElmModelToPlotConfig model =
  { endDate = model.endDate.value
  , startDate = model.startDate.value
  , ticker = model.ticker.value
  , y = model.yield
  , source = model.source.value
  , frequency = toInteger 21 model.frequency.value
  , id =  model.plot_id
  }
