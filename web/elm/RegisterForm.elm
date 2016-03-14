module RegisterForm where

import Html exposing (a, text, Html, div)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)
import Signal exposing (Address)
import Effects exposing (Effects, Never)

import Json.Decode as Json exposing (at, string)

import TextInputField exposing (view, update)

import List

--********************************************************************************
--********************************************************************************
-- MODEL
--UI state
type alias Model = {
      username : TextInputField.Model
    , fullname : TextInputField.Model
    , password : TextInputField.Model
    , response : String
    , token : String
    }


init : String -> String -> String -> (Model, Effects Action)
init username password fullname =
    (
      { username = TextInputField.init username "Username" "text"
      , fullname = TextInputField.init fullname "Full Name" "text"
      , password = TextInputField.init password "Password" "password"
      , response = ""
      , token = ""
      }
    , Effects.none
    )


--********************************************************************************
--********************************************************************************
-- UPDATE

type Action
    = UpdateUsername String
    | UpdateFullname String
    | UpdatePassword String
    | Request
    | Response ResponseMessage
    | NoOp

type alias ResponseMessage = {response: String, token: String}

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateFullname input ->
      ( { model | fullname = TextInputField.update input model.fullname }
      , Effects.none
      )
    UpdateUsername input ->
      ( { model | username = TextInputField.update input model.username }
      , Effects.none
      )
    UpdatePassword input ->
      ( { model | password = TextInputField.update input model.password }
      , Effects.none
      )
    NoOp ->
      ( model
      , Effects.none
      )
    --update
    --and also send to port
    Request ->
      ( model
      , sendData (RegisterRequest model.username.value model.fullname.value model.password.value)
      )
    Response input ->
      --remove pw & set response
      ( { model |
          password = TextInputField.update "" model.password
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
        TextInputField.view (Signal.forwardTo address UpdateFullname) model.fullname
      , TextInputField.view (Signal.forwardTo address UpdateUsername) model.username
      , TextInputField.view (Signal.forwardTo address UpdatePassword) model.password
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
