import Effects exposing (Never)
import RequestForm exposing (init, update, view) --, testMailBox

import StartApp

import Task

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

port requestUser : Signal String
port requestUser = Signal.constant("1")
