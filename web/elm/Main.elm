import StartApp

import Router exposing (init, update, view)
import LoginForm exposing (Action(Response), loginRequestMailBox)
import RegisterForm exposing (Action(Response), registerRequestMailBox)
import AnalysisForm exposing (Row, sendToPlotMailBox)

import Effects exposing (Never)
import Task

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--standardish startapp architecture setup

app =
  StartApp.start
    { init = Router.init
    , update = update
    , view = view
    --actions get forwards to correct update function
    , inputs = [ incomingLoginActions, incomingRegisterActions ]
    }

main = app.html

port tasks : Signal (Task.Task Never ())
port tasks = app.tasks

--*****************************************************
--LOGIN
--outgoing login requests to server
port loginRequest : Signal LoginForm.LoginRequest
port loginRequest = loginRequestMailBox.signal

--incoming login responses
port loginResponse : Signal LoginForm.ResponseMessage

incomingLoginActions : Signal (Router.Action)
incomingLoginActions = Signal.map Router.Login (Signal.map LoginForm.Response loginResponse)

--*****************************************************
--Register
--outgoing login requests to server
port registerRequest : Signal RegisterForm.RegisterRequest
port registerRequest = registerRequestMailBox.signal

--incoming login responses
port registerResponse : Signal RegisterForm.ResponseMessage

incomingRegisterActions : Signal (Router.Action)
incomingRegisterActions = Signal.map Router.Register (Signal.map RegisterForm.Response registerResponse)

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--send data to scatter plot

port sendToScatterPlot : Signal (List (String,Float))
port sendToScatterPlot = sendToPlotMailBox.signal
