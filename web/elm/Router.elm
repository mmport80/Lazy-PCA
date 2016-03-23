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
    , locationLinks: LocationLinks.Model
    , user: User
    , data : AnalysisForm.PortableModel
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
    --add inputs so that it can be loaded from db
    --initially static defaultUser
    --later call init using plot config from db
    --called when analysis.response comes thru
    --works like a reset
    (analysis, analysisFx) = AnalysisForm.init
    (login, loginFx) = LoginForm.init "" ""
    (register, registerFx) = RegisterForm.init "" "" ""
    locationLinks = LocationLinks.init ""
  in
    ( Model analysis login register locationLinks (User "" "" "") AnalysisForm.defaultPortableModel
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
  , data : AnalysisForm.PortableModel
  }

defaultExportData : ExportData
defaultExportData = ExportData defaultUser AnalysisForm.defaultPortableModel

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
        (newData, fx) = AnalysisForm.update input model.analysisForm
        pModel = AnalysisForm.convertElmModelToPortableFormat newData
        sd = saveData (ExportData model.user pModel)
        model' = { model | analysisForm = newData }
      in
        --how to write one case to catch all 3?
        case input of
          AnalysisForm.UpdateSource i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.UpdateYield i ->
            ( model', Effects.map Analysis fx )
          AnalysisForm.UpdateTicker i ->
            ( model', Effects.map Analysis fx )
          _ ->
            --
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
      in
        case input of
          LoginForm.Response i ->
            ( { model |
                loginForm = newUser
              , locationLinks = forwardOnLogin newUser.response model.locationLinks
              , user = User i.fullname newUser.username.value newUser.token
              }
            , Effects.map Login fx
            )
          _ ->
            ( { model |
                loginForm = newUser
              , locationLinks = forwardOnLogin newUser.response model.locationLinks
              }
            , Effects.map Login fx
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
  --keep track of location in model
  --if not logged in, token is blank
  --  then goto login page
  --if register link is clicked, go to register form
  --if login link is click, go to login form
  --if logout link is clicked, go to login page
  --default is login
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



--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--one send which sends everything?



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
