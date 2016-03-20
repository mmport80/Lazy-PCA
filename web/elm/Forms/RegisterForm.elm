module Forms.RegisterForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Signal exposing (Address)
import Effects exposing (Effects, Never)

import Json.Decode as Json exposing (at, string)

import Forms.Components.InputField as InputField exposing (view, update)

import List

--********************************************************************************
--********************************************************************************
-- MODEL
--UI state
type alias Model = {
      username : InputField.Model
    , fullname : InputField.Model
    , password : InputField.Model
    , response : String
    , token : String
    }


init : String -> String -> String -> (Model, Effects Action)
init username password fullname =
    (
      { username = InputField.init username "Username" "text" False
      , fullname = InputField.init fullname "Full Name" "text" False
      , password = InputField.init password "Password" "password" False
      , response = ""
      , token = ""
      }
    , Effects.none
    )


--********************************************************************************
--********************************************************************************
-- UPDATE

type Action
    = UpdateUsername InputField.Action
    | UpdateFullname InputField.Action
    | UpdatePassword InputField.Action
    | Request
    | Response ResponseMessage
    | NoOp

type alias ResponseMessage = {response: String, token: String}

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateFullname input ->
      ( { model | fullname = InputField.update input model.fullname }
      , Effects.none
      )
    UpdateUsername input ->
      ( { model | username = InputField.update input model.username }
      , Effects.none
      )
    UpdatePassword input ->
      ( { model | password = InputField.update input model.password }
      , Effects.none
      )
    NoOp ->
      ( model
      , Effects.none
      )
    --update
    --and also send to port
    Request ->
      (
        { model |
          response = "Please Wait..." }
      , sendData (RegisterRequest model.username.value model.fullname.value model.password.value)
      )
    Response input ->
      --remove pw & set response
      ( { model |
          password = InputField.update InputField.Reset model.password
        , response = input.response
        , token = input.token
        }
      , Effects.none
      )


--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
    div []
      [
        InputField.view (Signal.forwardTo address UpdateFullname) model.fullname
      , InputField.view (Signal.forwardTo address UpdateUsername) model.username
      , InputField.view (Signal.forwardTo address UpdatePassword) model.password
      , a [ href "#", onClick address Request ] [ text "Register" ]
      , text model.response
      ]


--********************************************************************************
--********************************************************************************
-- EFFECTS
type alias RegisterRequest = {
      username : String
    , fullname : String
    , password : String
    }

sendData : RegisterRequest -> Effects Action
sendData data =
  Signal.send registerRequestMailBox.address data
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

registerRequestMailBox :
  { address : Signal.Address RegisterRequest
  , signal : Signal RegisterRequest
  }
registerRequestMailBox = Signal.mailbox (RegisterRequest "" "" "")
