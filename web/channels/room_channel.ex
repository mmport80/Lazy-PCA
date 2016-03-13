defmodule Backend.RoomChannel do

  alias Backend.User
  alias Backend.Repo

  import Ecto.Query

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  use Phoenix.Channel

  def join("rooms:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("rooms:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end


  defmodule Response do
    defstruct response_text: "", token: ""
  end


  def login_by_username_and_pass(socket, username, given_pass) do
    #repo = Keyword.fetch!(opts, :repo)
    user = Repo.get_by(Backend.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        token = Phoenix.Token.sign(socket, "user", user.id)
        response = %Response{response_text: "OK", token: token}
      user ->
        response = %Response{response_text: "Password Not OK", token: ""}
      true ->
        #?? take up time between tries?
        dummy_checkpw()
        response = %Response{response_text: "User Not Found", token: ""}
    end
  end

  def handle_in("new_msg", %{"body" => params}, socket) do

    #break into action and payload components
    %{"action" => action, "data" => data} = params

    case action do
      "login" ->
        %{"name" => name, "username" => username, "password" => password} = data
        response = login_by_username_and_pass(socket, username, password)
      "register" ->
        #register user
        %{"name" => name, "username" => username, "password" => password} = data
        changeset = User.registration_changeset(%User{},data)
        #*reasons for problem
        case Repo.insert(changeset) do
          {:ok, user} ->
            #regd means logged in
            #no user data to send, fresh account
            response = login_by_username_and_pass(socket, username, password)
          {:error, changeset} ->
            #*-name already taken
            #*-inputs blank or too small --client side
            response = %Response{response_text: "Username already taken", token: ""}
        end

    end



    #login user
    #
    #send back the token
    #send back response
    #send down all the data
    #
    #go into user room "user:john"
    #receive updates

    #logout user
    #flush all data - set to initial state
    #clientside
    #


    #response
    broadcast! socket, "new_msg", %{body: response}

    #usersx = Repo.all User, name: "johno"

    #IO.inspect usersx

    #update db
    #Repo.insert( %Backend.User{name: name, username: username, password: password} )


    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

end
