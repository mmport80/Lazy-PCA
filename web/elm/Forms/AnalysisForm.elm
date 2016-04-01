module Forms.AnalysisForm where

import Html exposing (a, text, Html, div, hr, span, br, h2, p)
import Html.Attributes exposing (href, id, class, classList)
import Html.Events exposing (targetChecked, on, onClick, onMouseOver, onMouseOut)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects, Never)
import Signal exposing (Address)

import Json.Decode as Json exposing (at, string)

import Forms.Components.SelectInput as SelectInput exposing (init, view, update, Action, Option)
import Forms.Components.InputField as InputField exposing (view, update)
import Forms.Components.Checkbox as Checkbox exposing (view, update)

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
  , yield : Checkbox.Model
  , newData : List Row
  , frequency : SelectInput.Model
  , startDate : InputField.Model
  , endDate : InputField.Model
  , progressMsg : String
  , plot_id : Int
  , plots : List PlotConfig
  , hoverId : Int
  , bold : Bool
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
    p = Maybe.withDefault defaultPlotConfig (List.head plots)
    model = {
        startDate = InputField.init p.startDate "Start Date" "date" False "*" "1900-01-01" p.endDate
      , endDate = InputField.init p.endDate "End Date" "date" False "*" p.startDate "2100-01-01"
      , ticker = InputField.init p.ticker "Ticker" "text" False "*" "" ""
      , yield = Checkbox.init p.y
      , source = SelectInput.init p.source sourceOptions False
      , frequency = SelectInput.init (toString p.frequency) frequencyOptions False
      , plot_id = p.id
      , progressMsg = "Downloading Data..."
      , plots = plots
      , hoverId = 0
      , bold = False
      , newData = [defaultRow]
      }
  in
    ( model
    , getData model
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
    --once we receive data, then send it to the scatter plot
    | NewData ( Maybe ( List (Row) ) )
    | NewDataAndDates ( Maybe ( List (Row) ) )
    --get rid of this, superfluous
    | NoOp
    --load plot when from saved configurations
    | LoadNewPlot PlotConfig
    | Hover Int
    | ReceiveNewPlot PlotConfig
    | RequestNewPlot
    | Delete PlotConfig
    | Bold

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    --update plot configs as they are updated in the ui
    UpdateSource input ->
      ( { model | source = SelectInput.update input model.source }
      , Effects.none
      )
    UpdateTicker input ->
      ( { model | ticker = InputField.update input model.ticker }
      , Effects.none
      )
    UpdateYield input ->
      ( { model | yield = Checkbox.update input model.yield }
      , Effects.none
      )
    UpdateFrequency input ->
      let
        model' = { model |
          frequency = SelectInput.update input model.frequency
          }
      in
        ( model'
        , sendDataToPlot model'
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
    --'pull' link
    Request ->
      ( {model |
          frequency = SelectInput.update SelectInput.Enable model.frequency
        , startDate = InputField.update InputField.Enable model.startDate
        , endDate = InputField.update InputField.Enable model.endDate
        , progressMsg = "Downloading Data..."
        }
      , getDataAndDates model )
    --remove this
    NoOp ->
      ( model, Effects.none )
    --Receive data and then end data onto JS
    NewData maybeList ->
      let
        model' = updateData model maybeList
      in
        ( model', sendDataToPlot model' )
    --Receive data and then end data onto JS
    NewDataAndDates maybeList ->
      let
        model' = updateData model maybeList
          |> updateDate
      in
        ( model', sendDataToPlot model' )
    Hover id ->
      ( { model |
          hoverId = id
          }
        , Effects.none )
    --load from saved plots
    LoadNewPlot p ->
      let
        model' = loadPlotConfig model p
      in
        (model', getData model')
    --send new plot request, requested in Router
    RequestNewPlot ->
      ( model, Effects.none )
    --receive plot from server
    --add new plot to top of array
    --v similar to load new plot
    --should make function from this
    ReceiveNewPlot p ->
      let
        model' = loadPlotConfig model p
      in
        (model', getDataAndDates model')
    Delete plot ->
      let
        plots = model.plots |> List.filter (\p -> p.id /= plot.id)
        model' = { model | plots = plots }
      in
        --done at 'router' level
        ( model', Effects.none )
    Bold ->
      let
        bold =
          if (model.bold == True) then
            False
          else
            True
      in
        (
        {model | bold = bold}
        , Effects.none
        )

updateData : Model -> ( Maybe ( List (Row) ) ) -> Model
updateData model maybeList =
  let
    data = Maybe.withDefault model.newData maybeList
    progressMsg =
      if maybeList == Nothing then
        "Could not find data"
      else
        ""
  in
    { model |
        newData = data
      , progressMsg = progressMsg
      }

updateDate : Model -> Model
updateDate model =
  let
    maybeToDate = (Maybe.withDefault (Date.fromTime 0)) >> (Date.Format.format "%Y-%m-%d" )
    onlyDates = model.newData |> List.map (\ (a,_) -> a )
    newEndDate = onlyDates |> List.head |> maybeToDate
    newStartDate = onlyDates |> List.reverse |> List.head |> maybeToDate
  in
    { model |
        startDate = InputField.update (InputField.Update newStartDate) model.startDate
      , endDate = InputField.update (InputField.Update newEndDate) model.endDate
      }

--load plot config into form
loadPlotConfig : Model -> PlotConfig -> Model
loadPlotConfig model p =
  let
    --previously displayed plot
    pp = convertElmModelToPlotConfig model
  in
    { model |
      startDate = InputField.init p.startDate "Start Date" "date" False "*" "1900-01-01" p.endDate
    , endDate = InputField.init p.endDate "End Date" "date" False "*" p.startDate "2100-01-01"
    , ticker = InputField.init p.ticker "Ticker" "text" False "*" "" ""
    , yield = Checkbox.init p.y
    , source = SelectInput.init p.source sourceOptions False
    , frequency = SelectInput.init (toString p.frequency) frequencyOptions False
    , plot_id = p.id
    , progressMsg = "Downloading Data..."
    --add to existing plots
    , plots = p :: pp ::
        ( model.plots
          |> List.filter (\p' -> p'.id /= p.id && p'.id /= pp.id)
        )
    }



--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  div [] [
      div [] [
          text "Pull required data down from "
        , a [href "https://www.quandl.com/"] [text "Quandl"]
        , text " by specifying sources and tickers"
        ]
    , br [] []
    , div []
        [
          span [ class "redBorder" ]
            [ SelectInput.view (Signal.forwardTo address UpdateSource) model.source ]
        , InputField.view (Signal.forwardTo address UpdateTicker) model.ticker
        , Checkbox.view (Signal.forwardTo address UpdateYield) model.yield
        , text "Yield"
        ]
    , div [] [
      p [][
        a [ class "bold", href "#", onClick address Request ] [ text "Pull" ]
        ]
      ]
    , hr [] []
    , div [id "plot"] [
        div [] [
          text model.progressMsg
          ]
      ]
    , hr [] []
    , h2 [] [
      text "Set the horizon"
      ]
    , div [] [
        SelectInput.view (Signal.forwardTo address UpdateFrequency) model.frequency
      ]
    , hr [] []
    , h2 [] [
      text "Filter by date"
      ]
    , div [ class "rowGroup" ] [
        div [ class "row" ] [
            div [ class "cell2" ] [ text "Start"]
          , div [ class "cell2" ] [
              InputField.view (Signal.forwardTo address UpdateStartDate) model.startDate
              ]
          ]
      ]
    , div [ class "rowGroup" ] [
        div [ class "row" ] [
            div [ class "cell2" ] [ text "End"]
          , div [ class "cell2" ] [
              InputField.view (Signal.forwardTo address UpdateEndDate) model.endDate
              ]
          ]
      ]
    , hr [] []
    --saved plots
    , h2 [] [ text "Saved Plots" ]
    , p []
        [
          a [ href "#", onClick address RequestNewPlot ] [ text "New" ]
        ]
    , div [ class "table" ] ( generateSavedPlotConfigTable address model )
    ]

--make this table a standalone component?
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
    bold =
      if model.bold then
        class "bold"
      else
        class "normal"
    default p = [underline p.id, onHover p.id, onMouseOut address (Hover -1), load p]
  in
    [ div [ class "header" ]
        [   div [ cell ] [ text ""]
          , div [ cell ] [ text ""]
          , div [ cell ] [ text ""]
          , div [ cell ] [ text "" ]
          , div [ cell ] [ text "" ]
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
                  div [ cell, class "delete", onHover p.id, onMouseOut address (Hover -1) ]
                    [ span[ bold, onClick address (Delete p), onMouseOver address Bold, onMouseOut address Bold ] [text "X"] ]
                else
                  div [ cell, class "delete", onHover p.id ] [ text " " ]
            ]
          ]
        )
      ( List.filter ( \p -> p.id /= model.plot_id ) model.plots )


--********************************************************************************
--********************************************************************************
--********************************************************************************
-- EFFECTS

getData : Model -> Effects Action
getData model =
  Http.get decodeData (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewData
    |> Effects.task


getDataAndDates : Model -> Effects Action
getDataAndDates model =
  Http.get decodeData (quandlUrl model)
    |> Task.toMaybe
    |> Task.map NewDataAndDates
    |> Effects.task

--don't like new operators that much
(=>) : a -> b -> ( a, b )
(=>) = (,)

--INCOMING DATA
quandlUrl : Model -> String
quandlUrl model =
  Http.url ("https://www.quandl.com/api/v1/datasets/"++model.source.value++"/"++model.ticker.value++".json")
    [ "column" => (sourceToColumn model.source.value)
    , "auth_token" => "Fp6cFhibc5xvL2pN3dnu"
    ]

--JSON decoding
sourceToColumn : String -> String
sourceToColumn s =
  case s of
    "GOOG" -> "4"
    "YAHOO" -> "6"
    "CBOE" -> "1"
    _ -> "1" --spdj

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--JSON decode

--change name to something like 'decodeList'
decodeData : Json.Decoder (List (Date.Date, Float))
decodeData = Json.at ["data"] (Json.list dataRow)

dataRow : Json.Decoder (Date.Date, Float)
dataRow =
  ( Json.tuple2 (,) Json.string Json.float )
    |> Json.map (\ (a,b) -> ( (toDate (Date.fromTime 0) a), b ) )

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--OUTGOING DATA
--filter new data appropriately before plotting it
sendDataToPlot : Model -> Effects Action
sendDataToPlot model =
  let
    fInt = toInteger 21 model.frequency.value
    sd = model.startDate.value |> toDate (Date.fromTime 0) |> Date.toTime
    ed = model.endDate.value |> toDate (Date.fromTime 0) |> Date.toTime
    --if yield is true then convert yields to dsfcts
    dataToExport =
      if model.yield == True then
        List.map (\(a,b) -> ( a, e^(-b/100) ) ) model.newData
      else
        model.newData
  in
    dataToExport
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
--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
---Utils

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--conversions
toInteger : Int -> String -> Int
toInteger d =
  String.toInt
  >> Result.toMaybe
  >> Maybe.withDefault d

dateToISOFormat : Date.Date -> String
dateToISOFormat = Date.Format.format "%Y-%m-%d"

--convert string to int with default value as backup
toDate : Date.Date -> String -> Date.Date
toDate d =
  Date.fromString
  >> Result.withDefault d

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

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--export format
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
