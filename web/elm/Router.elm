module Router where

import Forms.LoginForm as LoginForm exposing (init, update, view, loginRequestMailBox, Action)
import Forms.RegisterForm as RegisterForm exposing (init, update, view, registerRequestMailBox, Action)
import Forms.AnalysisForm as AnalysisForm exposing (init, update, view, sendToPlotMailBox, Action, dateToISOFormat)

import LocationLinks exposing (init, update, view, Action)

import Html exposing (a, text, Html, div, button, span)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Effects exposing (Effects)
import Signal exposing (Address)

import List

--********************************************************************************
--********************************************************************************
-- MODEL

type alias Model =
    {
      analysisForm : AnalysisForm.Model
    , loginForm : LoginForm.Model
    , registerForm : RegisterForm.Model
    , locationLinks : LocationLinks.Model
    , user : User
    , plots : List AnalysisForm.PlotConfig
    }

type alias User = {
    fullname: String
  , username: String
  , token: String
  }

defaultUser : User
defaultUser = User "" "" ""

init : (Model, Effects Action)
init =
  let
    (analysis, analysisFx) = AnalysisForm.init plots
    (login, loginFx) = LoginForm.init "" ""
    (register, registerFx) = RegisterForm.init "" "" ""
    locationLinks = LocationLinks.init ""
    plots = [ AnalysisForm.defaultPlotConfig ]
  in
    ( Model analysis login register locationLinks (User "" "" "") plots
    , Effects.batch
        [ Effects.map Login loginFx
        , Effects.map Analysis analysisFx
        , Effects.map Register registerFx
        ]
    )

--********************************************************************************
--********************************************************************************
-- UPDATE
--act like a router, sending to different forms based on actions

type alias ExportData = {
    user : User
  , plot : AnalysisForm.PlotConfig
  }

defaultExportData : ExportData
defaultExportData = ExportData defaultUser AnalysisForm.defaultPlotConfig

type Action
    = Login LoginForm.Action
    | Analysis AnalysisForm.Action
    | Register RegisterForm.Action
    | ChangeLocation LocationLinks.Action
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Analysis input ->
      let
        (analysisForm, fx) = AnalysisForm.update input model.analysisForm
        --extract plot config from current analysis form
        plot = AnalysisForm.convertElmModelToPlotConfig analysisForm
        --add current plot to top
        plots = plot
          ::
          --filter out current plot from lower down in the array
          ( model.plots |> List.filter (\p -> p.id /= plot.id) )
        --only save user & plot config
        sd = saveData (ExportData model.user plot)
        --requestNewPlot
        np = saveData (ExportData model.user AnalysisForm.defaultPlotConfig)

        analysisForm' = { analysisForm | plots = plots }

        model' = { model | analysisForm = analysisForm', plots = plots }
      in
        --how to write one case to catch all 3?
        --don't save when setting up initial request
        --save when we get data backup
        --or when frequency or dates have been changed
        case input of
          AnalysisForm.UpdateSource i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.UpdateYield i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.UpdateTicker i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.Request ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.Hover i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.Bold ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.RequestNewPlot ->
            ( model', Effects.batch [np, Effects.map Analysis fx] )
          AnalysisForm.Delete plot ->
            ( { model | plots = plots |> List.filter (\p -> p.id /= plot.id) }
            , Effects.batch
              [ deleteData (ExportData model.user plot)
              , Effects.map Analysis fx
              ]
            )
          _ ->
            ( model', Effects.batch [sd, Effects.map Analysis fx] )
    Register input ->
      let
        (newUser, fx) = RegisterForm.update input model.registerForm
      in
        ( { model |
            registerForm = newUser
          , locationLinks = forwardOnLogin newUser.response model.locationLinks
          , user = User newUser.username.value newUser.fullname.value newUser.token
          }
        , Effects.map Register fx
        )
    Login input ->
      let
        (newUser, fx) = LoginForm.update input model.loginForm
        locationLinks = forwardOnLogin newUser.response model.locationLinks
        fxMap = Effects.map Login fx

      in
        case input of
          LoginForm.Response i ->
            let
              (analysis, analysisFx) = AnalysisForm.init i.plots
              analysisFxMap = Effects.map Analysis analysisFx
              model' =
                { model |
                  loginForm = newUser
                , locationLinks = locationLinks
                , user = User i.fullname newUser.username.value newUser.token
                , plots = i.plots
                , analysisForm = analysis
                }
            in
              ( model',Effects.batch [fxMap, analysisFxMap] ) --analysisFxMap
          _ ->
            ( { model |
                loginForm = newUser
              , locationLinks = locationLinks
              }
            , fxMap
            )
    ChangeLocation input ->
      let
        newLocation = LocationLinks.update input
      in
        case newLocation of
          --reset to original state
          "logout" ->
            init
          _ ->
            ( { model |
              locationLinks = newLocation
              }
            , Effects.none
            )
    --superfluous
    NoOp ->
      ( model, Effects.none )

forwardOnLogin : String -> String -> LocationLinks.Model
forwardOnLogin response currentLocation =
  case response of
    "OK" ->
      LocationLinks.update LocationLinks.Analysis
    _ ->
      currentLocation



--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  case model.locationLinks of
    --if page is...
    "analysis" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.locationLinks
        , AnalysisForm.view (Signal.forwardTo address Analysis) model.analysisForm
        ]
    "register" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.locationLinks
        , RegisterForm.view (Signal.forwardTo address Register) model.registerForm
        ]
    "login" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.locationLinks
        , LoginForm.view (Signal.forwardTo address Login) model.loginForm
        ]
    _ ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.locationLinks
        ]

--********************************************************************************
--********************************************************************************
-- EFFECTS
--one send mailbox which sends everything?

saveData : ExportData -> Effects Action
saveData model =
  Signal.send saveToDBMailBox.address model
    --add error condition
    --remove no op
    --and flag errors
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

saveToDBMailBox :
  { address : Signal.Address ExportData
  , signal : Signal ExportData
  }
saveToDBMailBox = Signal.mailbox defaultExportData


--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

deleteData : ExportData -> Effects Action
deleteData model =
  Signal.send deleteFromDBMailBox.address model
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

deleteFromDBMailBox :
  { address : Signal.Address ExportData
  , signal : Signal ExportData
  }
deleteFromDBMailBox = Signal.mailbox defaultExportData
