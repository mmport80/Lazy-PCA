module LoginForm where

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
    , password : TextInputField.Model
    , response : String
    , token : String
    }


init : String -> String -> (Model, Effects Action)
init username password =
    (
      { username = TextInputField.init username "Username" "text"
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
    | UpdatePassword String
    | Request
    | Response ResponseMessage
    | NoOp

type alias ResponseMessage = {response: String, token: String}

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
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
      ( model, sendData {username = model.username.value, password = model.password.value} )
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
        TextInputField.view (Signal.forwardTo address UpdateUsername) model.username
      , TextInputField.view (Signal.forwardTo address UpdatePassword) model.password
      , a [ href "#", onClick address Request ] [ text "Login" ]
      , text model.response
      ]


--********************************************************************************
--********************************************************************************
-- EFFECTS
type alias LoginRequest = {
      username : String
    , password : String
    }

sendData : LoginRequest -> Effects Action
sendData data =
  Signal.send loginRequestMailBox.address data
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

loginRequestMailBox :
  { address : Signal.Address LoginRequest
  , signal : Signal LoginRequest
  }
loginRequestMailBox = Signal.mailbox (LoginRequest "" "")
