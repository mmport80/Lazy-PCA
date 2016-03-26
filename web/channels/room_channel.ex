defmodule Backend.RoomChannel do

  alias Backend.User
  alias Backend.Plot
  alias Backend.Repo
  alias Ecto.Date

  import Ecto.Query

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  use Phoenix.Channel

  intercept ["new_msg", "save_data"]

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

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  def handle_in("save_data", %{"body" => params}, socket) do
    #get user data
    #IO.inspect params

    %{"plot" => plot, "user" => user} = params

    IO.inspect plot

    case Phoenix.Token.verify(socket, "user", user["token"] ) do
      #check that id is owned by user
      {:ok, user_id } ->
        #get user
        #make sure user owns plot
        #p = save_plot user data
        #return ok

        #changeset which checks whether orig and new plot have same user_id

        user = Repo.get_by(Backend.User, id: user_id )

        orig_Plot = Repo.get_by(Backend.Plot, id: plot["id"] )

        #orig owner id matches logged in user
        if orig_Plot.user_id == user_id do
          {:ok, sd} = Ecto.Date.cast(plot["startDate"])
          {:ok, ed} = Ecto.Date.cast(plot["endDate"])

          p = %{source: plot["source"], ticker: plot["ticker"], frequency: plot["frequency"], startDate: sd, endDate: ed, y: plot["y"], deleted: false, user_id: user.id}
          changeset = Plot.changeset(%Plot{},p)
          #update plot
          case Repo.update ( Ecto.Changeset.change Repo.get!(Plot, plot["id"]), p ) do
            {:ok, o} ->
              r = "oke"
            _ ->
              r = "error"
          end
        else
          r = "error"
        end
      _ ->
        #don't save
        #return error
        r = "error"
    end

    push socket, "save_data", %{body: r}
    {:noreply, socket}
  end

  def handle_out("save_data", payload, socket) do
    push socket, "save_data", payload
    {:noreply, socket}
  end

  #insert plot is always default
  def insert_new_plot(user) do
    {:ok, sd} = Ecto.Date.cast("1990-01-02")
    today = Date.utc()
    Repo.insert (user |> defaultPlot)
  end

  def defaultPlot(user) do
    {:ok, sd} = Ecto.Date.cast("1990-01-02")
    today = Date.utc()
    %Plot{source: "YAHOO", ticker: "INDEX_VIX", frequency: 21, startDate: sd, endDate: today, y: false, deleted: false, user_id: user.id}
  end

  def defaultUser() do
    %User{fullname: "", username: "",password: "", id: -1}
  end

#°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
#°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  #Response struct to send back to client
  #token is the auth required to pull down data
  defmodule Response do
    defstruct response_text: "", token: "", action: "", fullname: "", plots: []
  end

  #all incoming connections go here
  def handle_in("new_msg", %{"body" => params}, socket) do
    #break into action and payload components
    %{"action" => action, "data" => data} = params
    #I have been doing too much Elm...
    case action do
      "login" ->
        %{"username" => username, "password" => password} = data
        response = login_by_username_and_pass( socket, username, password )
      "register" ->
        %{"fullname" => fullname, "username" => username, "password" => password} = data
        #changesets are fine-grained validation objects based on what's specified in the User model
        changeset = User.registration_changeset(%User{},data)
        #*reasons for problem
        response =
          case Repo.insert(changeset) do
            {:ok, user} ->
              #insert new plot, login
              {:ok, p} = insert_new_plot(user)
              login_by_username_and_pass(socket, username, password)
            {:error, changeset } ->
              #*-name already taken
              #*-inputs blank or too small --implement client side check
              %Response{response_text: "Try another username", action: action, fullname: fullname}
          end
      #'null' reponse
      true ->
        response = %Response{}
    end
    #response back down socket
    #use broadcast! for 'room-wide' messages
    push socket, "new_msg", %{body: response}
    {:noreply, socket}
  end

  #handles login auth
  def login_by_username_and_pass( socket, username, password ) do
    user = Repo.get_by(Backend.User, username: username)
    cond do
      #does user match the password and hashed pw?
      user && checkpw(password, user.password_hash) ->
        plots = Plot
          |> where( [a], a.user_id == ^user.id )
          |> order_by( [c], desc: c.updated_at )
          |> Backend.Repo.all
          #convert back into json-isable format
          |> Enum.map(
            fn(p) ->
              %{ source: p.source, ticker: p.ticker, frequency: p.frequency, startDate: p.startDate, endDate: p.endDate, y: p.y, deleted: p.deleted, user_id: p.user_id, id: p.id }
            end)

        token = Phoenix.Token.sign(socket, "user", user.id)
        #ok is magic word which brings user to login
        %Response{response_text: "OK", token: token, action: "login", fullname: user.fullname, plots: plots}
      true ->
        dummy_checkpw()
        %Response{response_text: "Wrong password user combination", action: "login"}
    end
  end

  #superfluous right now
  #handles all broadcast events
  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

end
