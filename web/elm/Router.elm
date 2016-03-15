module Router where

import LoginForm exposing (init, update, view, loginRequestMailBox, Action)
import RegisterForm exposing (init, update, view, registerRequestMailBox, Action)
import AnalysisForm exposing (init, update, view, quandlMailBox, Action)

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
      data : AnalysisForm.Model
    , userLogin : LoginForm.Model
    , userRegister : RegisterForm.Model
    , location: LocationLinks.Model
    }

init : (Model, Effects Action)
init =
  let
    (analysis, analysisFx) = AnalysisForm.init "Yahoo" "INDEX_VIX" False ["Yahoo","Google","CBOE","SPDJ"]
    (login, loginFx) = LoginForm.init "" ""
    (register, registerFx) = RegisterForm.init "" "" ""
    locationLinks = LocationLinks.init ""
  in
    ( Model analysis login register locationLinks
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
--
type Action
    = Login LoginForm.Action
    | Analysis AnalysisForm.Action
    | Register RegisterForm.Action
    | ChangeLocation LocationLinks.Action

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    Analysis input ->
      let
        (newData, fx) = AnalysisForm.update input model.data
      in
        ( { model | data = newData }
        , Effects.map Analysis fx
        )
    --action to capture response from outside world
    --take action update state
    --then send on another action to update whichever form...
    Register input ->
      let
        (newUser, fx) = RegisterForm.update input model.userRegister
      in
        ( { model |
              userRegister = newUser
            , location =
              --forward page?
              case newUser.response of
                "OK" ->
                  LocationLinks.update LocationLinks.Analysis
                _ ->
                  model.location
          }
        , Effects.map Register fx
        )
    Login input ->
      let
        (newUser, fx) = LoginForm.update input model.userLogin
      in
        ( { model |
            userLogin = newUser
          --forward page?
          , location = forwardOnLogin newUser.response model.location
          }
        , Effects.map Login fx
        )
    --reset to original state
    ChangeLocation input ->
      let
        newLocation = LocationLinks.update input
      in
        --forward?
        case newLocation of
          "logout" ->
            init
          _ ->
            ( { model |
              location = newLocation
              }
            , Effects.none
            )

--forwardOnLogin : String -> String

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
  case model.location of
    --if page is...
    "analysis" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.location
        , AnalysisForm.view (Signal.forwardTo address Analysis) model.data
        ]
    "register" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.location
        , RegisterForm.view (Signal.forwardTo address Register) model.userRegister
        ]
    "login" ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.location
        , LoginForm.view (Signal.forwardTo address Login) model.userLogin
        ]
    _ ->
      div [][
          LocationLinks.view (Signal.forwardTo address ChangeLocation) model.location
        ]




--********************************************************************************
--********************************************************************************
-- EFFECTS
