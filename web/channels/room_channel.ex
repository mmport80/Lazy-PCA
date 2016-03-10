

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



  def login_by_username_and_pass(username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Backend.User, username: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        "OK"
      user ->
        "not OK"
      true ->
        dummy_checkpw()
        "not found"
    end
  end

  def create(username, password) do
     case login_by_username_and_pass(username, password, repo: Repo) do
       "OK" ->
         IO.puts "Logd in"
       _ ->
         IO.puts "Not Logd in"
     end
   end

  def handle_in("new_msg", %{"body" => user_params}, socket) do
    %{"name" => name, "username" => username, "password" => password} = user_params

    broadcast! socket, "new_msg", %{body: name}

    #register user
    changeset = User.registration_changeset(%User{},user_params)
    case Repo.insert(changeset) do
        {:ok, user} ->
          IO.puts "regd"
        {:error, changeset} ->
          IO.puts "not regd"
    end

    #login user
    #
    #send back the token
    #send down all the data
    #go into user room "user:john"
    #receive updates
    create(username, password)

    user_id = 1
    token = Phoenix.Token.sign(socket, "user", user_id)
    IO.puts "verify"
    IO.inspect Phoenix.Token.verify(socket, "user", token)

    #logout user
    #flush all data - set to initial state
    #clientside
    #





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
