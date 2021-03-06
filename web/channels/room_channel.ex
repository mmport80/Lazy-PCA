defmodule Backend.RoomChannel do

  alias Backend.User
  alias Backend.Plot
  alias Backend.Repo

  alias Ecto.Date
  import Ecto.Query

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  use Phoenix.Channel

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  #incoming plotconfig from elm
  @type plotConfig :: %{ source: char_list, ticker: char_list, frequency: integer, startDate: char_list, endDate: char_list, y: boolean, id: integer }
  #json format to send to Elm, can remove deleted field
  @type p :: %{ source: char_list, ticker: char_list, frequency: integer, startDate: char_list, endDate: char_list, y: boolean, deleted: boolean, user_id: integer, id: integer }

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  intercept ["new_msg", "save_data", "delete_data"]

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  #public room
  #can create rooms to group users in
  #everyone comes through here, which means if we 'broadcast!' intead of pushing below
  #we can send site wide messages to everybody
  @spec join(String.t, map, Phoenix.Socket.t) :: {:ok, Phoenix.Socket.t}
  def join("rooms:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("rooms:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  #Response struct to send back to client
  #token is the auth required to pull down data
  defmodule Response do
    alias Backend.RoomChannel
    @type t :: %{response_text: char_list, token: char_list, action: char_list, fullname: char_list, plots: list(RoomChannel.p), errors: list(char_list)}
    defstruct response_text: "", token: "", action: "", fullname: "", plots: [], errors: []
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #incoming data


  @type user_details :: %{ username: char_list, password: char_list, fullname: char_list }
  @type save_or_delete_request :: %{ user: user_details, plot: plotConfig }

  @type login_details :: %{ username: char_list, password: char_list }
  @type reg_details :: %{ username: char_list, password: char_list, fullname: char_list }
  @type l_r_request :: %{ action: char_list, data: login_details | reg_details }

  @type request :: %{ body: save_or_delete_request | l_r_request }

  @spec handle_in(String.t, request, Phoenix.Socket.t) :: {:noreply, Phoenix.Socket.t}
  def handle_in("delete_data", %{"body" => params}, socket) do
    %{"plot" => plot, "user" => user} = params
    rr =
      #find user_id from token
      case Phoenix.Token.verify(socket, "user", user["token"] ) do
        {:ok, user_id } ->
          #user = Repo.get_by(Backend.User, id: user_id )
          orig_Plot = Repo.get_by(Backend.Plot, id: plot["id"])
          #check whether user owns plot
          if orig_Plot.user_id == user_id do
            [p] = Repo.all(from(p in Plot, where: p.id == ^plot["id"]))
            case Repo.delete p do
              #Deleted with success
              {:ok, _} ->
                %Response{ response_text: "ok" }
              #Something went wrong
              {:error, _ } ->
                %Response{ response_text: "error" }
            end
          else
            %Response{ response_text: "error" }
          end
        _ ->
          #auth unsuccessful, return error
          %Response{ response_text: "error" }
      end
    #reply
    push socket, "delete_data", %{body: rr}
    {:noreply, socket}
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  def handle_in("save_data", %{"body" => params}, socket) do
    %{"plot" => plot, "user" => user} = params
    rr =
      #find user_id from token
      case Phoenix.Token.verify(socket, "user", user["token"] ) do
        {:ok, user_id } ->
          user = Repo.get_by(Backend.User, id: user_id )
          cond do
            #-----insert new plot
            #if sent plot with -1 plot_id, then insert rather than update
            plot["id"] == -1 ->
              #insert default plot
              {:ok, p} = insert_new_plot(user)
              %Response{ action: "new", plots: [ p |> convertPlotToJsonFormat ] }
            #-----save existing plot
            True ->
              %Response{ response_text: save_existing_plot(user, plot) }
            end
        _ ->
          #don't save, return error
          %Response{ response_text: "error" }
      end
    push socket, "save_data", %{body: rr}
    {:noreply, socket}
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

  #login / reg / user auth actions
  def handle_in("new_msg", %{"body" => params}, socket) do
    #break into action and payload components
    %{"action" => action, "data" => data} = params
    #I have been doing too much Elm...
    response =
      case action do
        "login" ->
          %{"username" => username, "password" => password} = data
          login_by_username_and_pass( socket, username, password )
        "register" ->
          %{"fullname" => fullname, "username" => username, "password" => password} = data
          #changesets are fine-grained validation objects based on what's specified in the User model
          changeset = User.registration_changeset(%User{},data)
          #*reasons for problem
          case Repo.insert(changeset) do
            {:ok, user} ->
              #insert new plot, login
              {:ok, p} = insert_new_plot(user)
              login_by_username_and_pass(socket, username, password)
            {:error, changeset } ->
              #remove, not necessary
              e = Ecto.Changeset.traverse_errors(changeset, fn
                {msg, opts} -> String.replace(msg, "%{count}", to_string(opts[:count]))
                msg -> msg
              end)

              #Elm deals with every case apart from user name already being taken
              %Response{response_text: "User name already taken", action: action, fullname: fullname}
          end
        #'null' reponse
        true ->
          %Response{}
      end
    #response back down socket
    #use broadcast! for 'room-wide' messages
    push socket, "new_msg", %{body: response}
    {:noreply, socket}
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #called by handle_in save_data
  #save plots which already exist in db

  #coming from elm
  @spec save_existing_plot(%User{}, plotConfig) :: String.t
  def save_existing_plot(user, plot) do
    orig_Plot = Repo.get_by(Backend.Plot, id: plot["id"] )
    #make sure owner owns plot
    #orig plot owner id matches logged in user
    if orig_Plot.user_id == user.id do
      {:ok, sd} = Ecto.Date.cast(plot["startDate"])
      {:ok, ed} = Ecto.Date.cast(plot["endDate"])
      p = %{source: plot["source"], ticker: plot["ticker"], frequency: plot["frequency"], startDate: sd, endDate: ed, y: plot["y"], deleted: false, user_id: user.id}

      #update plot, force update in order to save order of opened plots
      case Repo.update (Ecto.Changeset.change Repo.get!(Plot, plot["id"]), p), force: true do
        {:ok, _} ->
          "oke"
        _ ->
          "error"
      end
    else
      "error"
    end
  end

  #insert plot always inserts default plot
  @spec insert_new_plot(%User{}) :: {:ok, %Plot{}} | {:error, Ecto.Changeset.t}
  def insert_new_plot(user) do
    Repo.insert (user |> defaultPlot)
  end

  @spec defaultPlot(%User{}) :: %Plot{}
  def defaultPlot(user) do
    {:ok, sd} = Ecto.Date.cast("1990-01-02")
    today = Date.utc()
    %Plot{source: "YAHOO", ticker: "INDEX_VIX", frequency: 21, startDate: sd, endDate: today, y: false, deleted: false, user_id: user.id}
  end

  @spec defaultUser() :: %User{}
  def defaultUser() do
    %User{fullname: "", username: "",password: "", id: -1}
  end

#°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
#°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #called by handle_in new_msg, i.e. logging / registering
  #handles login auth
  @spec login_by_username_and_pass(Phoenix.Socket.t, char_list, char_list) :: %Response{}
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
          |> Enum.map( &convertPlotToJsonFormat/1 )

        token = Phoenix.Token.sign(socket, "user", user.id)
        #ok is magic word which brings user to login
        %Response{response_text: "OK", token: token, action: "login", fullname: user.fullname, plots: plots}
      true ->
        dummy_checkpw()
        %Response{response_text: "Wrong password user combination", action: "login"}
    end
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #Utils

  @spec convertPlotToJsonFormat(%Plot{}) :: p
  def convertPlotToJsonFormat(p) do
    %{ source: p.source, ticker: p.ticker, frequency: p.frequency, startDate: p.startDate, endDate: p.endDate, y: p.y, deleted: p.deleted, user_id: p.user_id, id: p.id }
  end

  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
  #handles all broadcast events
  #not applicable right now, but necessary to include in any case - expected in all channels

  @spec handle_out(String.t, map, Phoenix.Socket.t) :: {:noreply, Phoenix.Socket.t}
  def handle_out("delete_data", payload, socket) do
    push socket, "delete_data", payload
    {:noreply, socket}
  end

  def handle_out("save_data", payload, socket) do
    push socket, "save_data", payload
    {:noreply, socket}
  end

  def handle_out("new_msg", payload, socket) do
    push socket, "new_msg", payload
    {:noreply, socket}
  end

end
