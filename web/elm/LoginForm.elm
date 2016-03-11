module LoginForm where

import Html exposing (a, text, Html, div, button, span)
import Html.Attributes exposing (href)
import Html.Events exposing (targetChecked, on, onClick)

import Http exposing (get, url)

import Task exposing (toMaybe, andThen)

import Effects exposing (Effects, Never)

import Json.Decode as Json exposing (at, string)

import Signal exposing (Address)

import Username exposing (view, update)
import Password exposing (view, update)

import Debug exposing (log)

import List


--********************************************************************************
--********************************************************************************
-- MODEL
type alias Model = {
      username : Username.Model
    , password : Password.Model
    , response : String
    }

init : String -> String -> String -> (Model, Effects Action)
init username password response =
    (
      { username = Username.init username
      , password = Password.init password
      , response = response
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
    | Response String
    | NoOp

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateUsername input ->
      ( { model | username = Username.update input model.username }
      , Effects.none
      )
    UpdatePassword input ->
      ( { model | password = Password.update input model.password }
      , Effects.none
      )
    NoOp ->
      ( model
      , Effects.none
      )
    --update
    --and also send to port
    Request ->
      ( model, sendData model )
    Response input ->
      --remove pw & set response
      ( { model | password = Password.update "" model.password, response = input}
      , Effects.none
      )


--********************************************************************************
--********************************************************************************
-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
    div []
      [
        Username.view (Signal.forwardTo address UpdateUsername) model.username
      , Password.view (Signal.forwardTo address UpdatePassword) model.password
      , a [ href "#", onClick address Request ] [ text "Login" ]
      , text model.response
      ]



--********************************************************************************
--********************************************************************************
-- EFFECTS

--send data to phoenix
--mail box
--port

--Send data to JS

sendData : Model -> Effects Action
sendData data =
  Signal.send loginRequestMailBox.address data
    `Task.andThen` (\_ -> Task.succeed NoOp)
  |> Effects.task

loginRequestMailBox :
  { address : Signal.Address Model
  , signal : Signal Model
  }
loginRequestMailBox = Signal.mailbox { username = "", password = "", response = "" }
