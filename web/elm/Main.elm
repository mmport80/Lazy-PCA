import Effects exposing (Never)
--import RequestForm exposing (init, update, view, testMailBox)
import Router exposing (init, update, view)

import LoginForm exposing (Action(Response), loginRequestMailBox)
import RegisterForm exposing (Action(Response), registerRequestMailBox)
import RequestForm exposing (Row, testMailBox)

import StartApp
import Task

port quandlRequest : Signal (List RequestForm.Row)
port quandlRequest = testMailBox.signal

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
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
