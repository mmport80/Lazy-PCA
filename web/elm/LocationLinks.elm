module LocationLinks where

import Html exposing (Html, a, text, div, hr)
import Html.Events exposing (targetValue, onClick)
import Html.Attributes exposing (href)

import Signal exposing (Address)

-- MODEL
type alias Model = String

init : String -> Model
init location = location

-- UPDATE
type Action = Analysis | Login | Register | Logout

update : Action -> Model
update action =
  case action of
    Analysis ->
      "analysis"
    --once logged in go directly to request
    Login ->
      "login"
    Register ->
      "register"
    Logout ->
      "logout"

-- VIEW
view : Signal.Address Action -> Model -> Html
view address model =
  --if in ...
  case model of
    --reg location, show login link
    "register" ->
      div [][
          a [ href "#", onClick address Login ] [ text "Login" ]
        , hr [][]
        ]
    --login location, show reg link
    "login" ->
      div [][
          a [ href "#", onClick address Register ] [ text "Register" ]
        , hr [][]
        ]
    --request location show logout link
    "analysis" ->
      div [][
          a [ href "#", onClick address Logout ] [ text "Logout" ]
        , hr [][]
        ]
    --logout/default location show both register and login
    _ ->
      div [][
          a [ href "#", onClick address Register ] [ text "Register" ]
        , a [ href "#", onClick address Login ] [ text "Login" ]
        , hr [][]
        ]
