defmodule DataServer do
  use GenServer

  @moduledoc """
  Provides UpNext database functions.

  ### DataServer State
  The DataServer has the following state:

    %{ "Lists" => listdata,
       "Instance ID" => unique id for instance or server,
       "Today" => date being used for today,
       "Undo Info" => undo packet
     }


  All upnext data access should be through this module.
  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, name: UpNextServer, timeout: 20000)
  end

  @doc """
  State for the DataServer consists of the following:

    %{ "Lists" => lists, "Instance" => instance,
       "Today" => today, "Next Record" => next_record_num }

    lists : This is the list of all the list records. Each record is a map.
    instanceid : Number generated when the server is started.
    today : Current date that is being used for evaluations.
  """
  def init(:ok) do
    Agent.start_link(fn -> 0 end, name: RecordCounter)
    state = reload_lists()
    {:ok, state}
  end

  def reload_lists do
    lists = Lists.Access.load_lists()
    new_day(lists)
  end

  def new_day(lists) do
    next_record = Agent.get_and_update(RecordCounter, fn n -> {n + 1, n + 1} end)
    instance = :crypto.strong_rand_bytes(16) |> Base.url_encode64()
    today = Timex.now(Timex.Timezone.local())
    lists = lists |> Enum.map(&Lists.Events.Overdue.generate_overdue_data(&1, today))

    %{
      "Lists" => lists,
      "Instance" => instance,
      "Today" => today,
      "Next Record" => next_record
    }
  end

  # Client code follows.

  @doc """
  Returns the full set of lists.
  """
  def get_lists do
    GenServer.call(UpNextServer, :get_lists)
  end

  #  def load_lists_from_file (path) do
  #      GenServer.call(UpNextServer, {:load_from_file, path})
  #  end

  def load_lists_from_file do
    GenServer.call(UpNextServer, :load_from_file, 20000)
  end

  @doc """
  Returns the types of records from the lists.
  """
  def get_list_type(type) do
    GenServer.call(UpNextServer, {:type, type})
  end

  @doc """
  Sets the state of the specified event to 'checked'
  """
  def check(record_id, date, instance) do
    GenServer.call(UpNextServer, {:check, record_id, date, instance})
  end

  @doc """
  Evaluates all event dates based on the date provdied.
  """
  def evaluate_events(eval_date \\ Timex.now(Timex.Timezone.local())) do
    GenServer.call(UpNextServer, {:evaluate, eval_date}, 20000)
  end

  @doc """
  Writes the full set of lists to the list file.
  """
  def write_lists do
    GenServer.call(UpNextServer, :write_lists)
  end

  @doc """
  Returns the instance of the lists database. The instance is generated each time the DataServer starts up. This provides a method for rejecting stale requests from a browser window.
  """
  def get_lists_instance do
    GenServer.call(UpNextServer, :instance)
  end

  def handle_call(:load_from_file, _from, _state) do
    state = reload_lists()
    {:reply, :ok, state}
  end

  @doc """
  Not sure this is used.
  """
  #  def handle_call({:load_from_file, path}, _from, state) do
  #    lists = Lists.Access.load_lists
  #    instance = :crypto.strong_rand_bytes(16) |> Base.url_encode64
  #    today = Timex.Date.now(Timex.Timezone.local())
  #    next_record = Agent.get_and_update(RecordCounter, fn(n) -> {n + 1, n + 1} end)
  #    lists = lists |> Enum.map(&(Lists.Events.Overdue.generate_overdue_data(&1,today)))
  #    state = %{ "Lists" => lists, "Instance" => instance,
  #               "Today" => today, "Next Record" => next_record }
  #  end

  def handle_call(:instance, _from, state) do
    {:reply, state["Instance"], state}
  end

  def handle_call(:get_lists, _from, state) do
    %{"Lists" => lists} = state
    {:reply, lists, state}
  end

  def handle_call({:type, type}, _from, state) do
    %{"Lists" => lists} = state

    typelist =
      lists
      # Remove unwanted type.
      |> Enum.filter(&is_type(&1, type))

    {:reply, {:ok, typelist}, state}
  end

  # Pattern match to get the record of interest.
  def handle_call({:check, record_id, date, instance}, _from, state) do
    %{"Lists" => lists, "Instance" => server_instance} = state

    if server_instance != instance do
      {:reply, :ok, state}
    else
      updated_lists =
        lists
        |> Enum.map(&check_record(&1, record_id, date))

      new_state = Map.merge(state, %{"Lists" => updated_lists})
      {:reply, :ok, new_state}
    end
  end

  # Probably have a case statement that looks at record type. If not an event,
  # then return it. If it's an event, call the evaluate_event funciton.
  def handle_call({:evaluate, eval_date}, _from, state) do
    %{"Lists" => lists} = state

    events =
      lists
      |> Enum.filter(&is_type(&1, "Event"))
      |> Enum.filter(&Lists.Events.Rules.event_matches?(&1, eval_date))

    {:reply, {:ok, events}, state}
  end

  def handle_call(:write_lists, _from, state) do
    %{"Lists" => lists} = state
    Lists.Access.write_lists_to_file(lists)
    {:reply, :ok, state}
  end

  def check_record(record, id, formatted_date) do
    {num_id, _} = Integer.parse(id)
    %{"Meta Data" => meta_data} = record
    %{"Record ID" => record_id} = meta_data

    case record_id == num_id do
      true ->
        {:ok, date} = Timex.parse(formatted_date, "{0D}-{Mshort}-{YYYY}")
        #        date = Timex.date(date)
        record = put_in(record, ["Meta Data", "Checked"], date)
        record = put_in(record, ["Checked"], formatted_date)
        _record = Lists.Events.Overdue.generate_overdue_data(record, date)

      false ->
        record
    end
  end

  def is_type(record, type) do
    %{"Meta Data" => meta_data} = record

    case meta_data do
      %{"Type" => ^type} ->
        true

      _ ->
        false
    end
  end
end
