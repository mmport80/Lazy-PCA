import Effects exposing (Never)
import RequestForm exposing (init, update, view, testMailBox)

import StartApp

import Task

import Mouse exposing (..)

--once have data, draw d3 chart
--

app =
  StartApp.start
    { init = init "Yahoo" "INDEX_VIX" False
    , update = update
    , view = view
    , inputs = []
    }

main =
  app.html

port tasks : Signal (Task.Task Never ())
port tasks = app.tasks

port requestUser : Signal (List RequestForm.Row)
port requestUser = testMailBox.signal
