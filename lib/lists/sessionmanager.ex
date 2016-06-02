defmodule Lists.SessionManager do
  use GenServer
  import Plug.Conn
  @moduledoc """
  ## Session Manager
  The session manager keeps the following state:

  %{"Sessions" =>
      %{session_id => session_map,
        session_id => session_map,
        ...}}

  All upnext data access should be through this module.
  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: SessionServer])
  end

  @doc """
  Checks to see if a session has been established. If no session is retrieved
  from the cookies, then a new session is started.
  If a session id is retrieved, it's looked up in the session table to see if it's valid. If not, a new session is started. If session is valid, nothing more to do here.
  """
  def get_session_parameter conn, key do
    GenServer.call(SessionServer, {:get_session_parameter, conn, key})
  end

  def set_session_parameter conn, key, value do
    GenServer.call(SessionServer, {:set_session_parameter, conn, key, value})
  end

  def check_session conn do
    GenServer.call(SessionServer, {:check_session, conn})
  end

  def touch_session conn do
    GenServer.call(SessionServer, {:touch_session, conn})
  end

  def get_sessions do
    GenServer.call(SessionServer, :get_sessions)
  end

  def get_session_by_id(session_id) do
    GenServer.call(SessionServer, {:get_session_by_id, session_id})
  end

  def get_session_by_connection(conn) do
    session_id = get_session(conn, :session_id)
    GenServer.call(SessionServer, {:get_session_by_id, session_id})
  end

  def handle_call({:get_session_parameter, conn, parameter_name}, _from, state) do
    session_id = get_session(conn, :session_id)
    value = get_in(state, ["Sessions", session_id, parameter_name])
    {:reply, {:ok, value}, state}
  end

  def handle_call({:set_session_parameter, conn, key, value}, _from, state) do
    session_id = get_session(conn, :session_id)
    new_state = put_in(state, ["Sessions", session_id, key], value)
    {:reply, :ok, new_state}
  end

  def handle_call(:get_sessions, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_session_by_id, session_id}, _from, state) do
    %{"Sessions" => session_maps} = state
    %{^session_id => session_map} = session_maps
    {:reply, session_map, state}
  end

  def handle_call({:touch_session, conn}, _from, state) do
    session_id = get_session(conn, :session_id)
    new_state = add_session_parameter(state, session_id, "Last Accessed",Timex.DateTime.now(Timex.Timezone.local()))
    {:reply, conn, new_state}
  end

  def handle_call({:check_session, conn}, _from, state) do
    session_id = get_session(conn, :session_id)
    %{"Sessions" => session_map} = state
    session_exists = Map.has_key?(session_map,session_id)
    cond do
      session_id == nil ->
        new_session_id = :crypto.strong_rand_bytes(16) |> Base.url_encode64 |> binary_part(0, 16)
        new_state = add_new_session(state, new_session_id)
        new_conn = conn
          |> put_session(:session_id, new_session_id)
        {:reply, new_conn, new_state}
      session_exists ->
        {:reply, conn, state}
      true ->
        new_state = add_new_session(state,session_id)
        {:reply, conn, new_state}
    end
  end

  def add_new_session(state, session_id) do
    %{"Sessions" => session_maps} = state
    new_session_map = %{session_id => %{}}
    new_sessions_maps = Map.merge(session_maps, new_session_map)
    new_state = %{"Sessions" => new_sessions_maps}
    add_session_parameter(new_state, session_id, "Date Created",Timex.DateTime.now(Timex.Timezone.local()))
  end

  def add_session_parameter(state, session_id, key, value) do
    %{"Sessions" => session_maps} = state
    %{^session_id => session_map} = session_maps
    new_session_map = %{session_id => Map.put(session_map, key, value)}
    new_sessions_maps = Map.merge(session_maps, new_session_map)
    %{"Sessions" => new_sessions_maps}
  end

  def init (:ok) do
    state = %{ "Sessions" => %{} }
    {:ok, state}
  end

end
