import StartApp

import Router exposing (init, update, view, saveToDBMailBox, deleteFromDBMailBox)
import Forms.LoginForm as LoginForm exposing (Action(Response), loginRequestMailBox)
import Forms.RegisterForm as RegisterForm exposing (Action(Response), registerRequestMailBox)
import Forms.AnalysisForm as AnalysisForm exposing (Row, sendToPlotMailBox)

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
    , inputs = [ incomingLoginActions, incomingRegisterActions, incomingNewPlots ]
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
--now with data also   jhjh
--jump to analysis if OK
--load config after jumping
--load config means calling init
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

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--save data
--need a response also - confirming save

--request new plotconfig
--user plotid is -1, that is a flag to not update but insert

port saveToDB : Signal Router.ExportData
port saveToDB = saveToDBMailBox.signal


--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--receive new plot, after requesting
port newPlotResponse : Signal AnalysisForm.PlotConfig 

incomingNewPlots : Signal (Router.Action)
incomingNewPlots = Signal.map Router.Analysis (Signal.map AnalysisForm.ReceiveNewPlot newPlotResponse)

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
--send delete requests

port deleteFromDB : Signal Router.ExportData
port deleteFromDB = deleteFromDBMailBox.signal
