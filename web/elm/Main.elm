import Effects exposing (Never)
--import RequestForm exposing (init, update, view, testMailBox)
import LoginForm exposing (init, update, view, loginRequestMailBox, Action(Response))

import StartApp
import Task




--hook up login with db js
--send and receive responses
--send login deets
--receive response + token
--add token to login model
--use username and token to pull down data

--registration
--send details
--get back response + token

--top level model, switches to different views
--updating model as we go


{--
app =
  StartApp.start
    { init = init "Yahoo" "INDEX_VIX" False
    , update = update
    , view = view
    , inputs = []
    }

main = app.html

port tasks : Signal (Task.Task Never ())
port tasks = app.tasks

port requestUser : Signal (List RequestForm.Row)
port requestUser = testMailBox.signal

--}

--^^^^^^^^^^^^^^^^^^^°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

--start app architecture boilerplate
app =
  StartApp.start
    { init = init "" "" ""
    , update = update
    , view = view
    --actions get forwards to correct update function
    , inputs = [ incomingActions ]
    }

main = app.html

port tasks : Signal (Task.Task Never ())
port tasks = app.tasks


--outgoing login requests to server
port loginRequest : Signal LoginForm.Model
port loginRequest = loginRequestMailBox.signal


--incoming login responses
port loginResponse : Signal String

incomingActions : Signal (Action)
incomingActions = Signal.map Response loginResponse
