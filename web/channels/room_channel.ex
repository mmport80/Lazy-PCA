defmodule Backend.RoomChannel do

  alias Backend.User
  alias Backend.Repo

  import Ecto.Query

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  use Phoenix.Channel

  #public room
  #can create rooms to group users in
  #everyone comes through here, which means if we 'broadcast!' intead of pushing below
  #we can send site wide messages to everybody
  def join("rooms:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("rooms:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  #Response struct to send back to client
  #token is the auth required to pull down data
  defmodule Response do
    defstruct response_text: "", token: "", action: ""
  end

  #all incoming connections go here
  def handle_in("new_msg", %{"body" => params}, socket) do
    #break into action and payload components
    %{"action" => action, "data" => data} = params

    #I have been doing too much Elm recently...
    case action do
      "login" ->
        %{"username" => username, "password" => password} = data

        #check password against user
        %{response_text: response, token: token} = login_by_username_and_pass(socket, username, password)
        response = %Response{response_text: response, token: token, action: action}
      "register" ->
        #register user
        %{"name" => name, "username" => username, "password" => password} = data

        #changesets are fine-grained validation objects based on what's specified in the User model
        changeset = User.registration_changeset(%User{},data)

        #*reasons for problem
        response =
          case Repo.insert(changeset) do
            {:ok, user} ->
              #regd means logged in here
              #no user data to send, fresh account
              %{response_text: response, token: token} = login_by_username_and_pass(socket, username, password)
              %Response{response_text: response, token: token, action: action}
            {:error, changeset } ->
              #*-name already taken
              #*-inputs blank or too small --implement client side check
              %Response{response_text: "Username already taken", token: "", action: action}
          end
    end

    #response back down socket
    #use broadcast! for 'room-wide' messages
    push socket, "new_msg", %{body: response}

    {:noreply, socket}
  end


  #login logic
  def login_by_username_and_pass(socket, username, given_pass) do
    user = Repo.get_by(Backend.User, username: username)

    cond do
      #does user match the password and hashed pw?
      user && checkpw(given_pass, user.password_hash) ->
        token = Phoenix.Token.sign(socket, "user", user.id)
        %{response_text: "OK", token: token}
      #no need to be so granular
      user ->
        %{response_text: "Password Not OK", token: ""}
      true ->
        #?? take up time between tries?
        dummy_checkpw()
        %{response_text: "User Not Found", token: ""}
    end
  end

  #superfluous right now
  #handles all broadcast events
  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

end
