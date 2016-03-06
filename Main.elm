import Effects exposing (Never)
import RequestForm exposing (init, update, view)

import StartApp

import Task

--put all components together
--'pull' requests from Quandl



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
