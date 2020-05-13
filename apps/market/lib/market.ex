defmodule Market do
  @moduledoc """
  Market keeps the contexts that define your domain
  and business logic.
  """

  use GenServer

  alias Market.Customer
  alias Market.Line

  defstruct [:pid, multiplier: 1, lines: [], customers: []]

  def create(multiplier) do
    {:ok, pid} = GenServer.start_link(__MODULE__, multiplier)
    get(pid)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def best_line(%Market{} = market) do
    GenServer.call(market.pid, :best_line)
  end

  def new_customer(%Market{} = market, items_to_take) do
    customer = Customer.create(market, items_to_take)
    GenServer.cast(market.pid, {:add_customer, customer})
    customer
  end

  def new_line(%Market{} = market) do
    line = Line.create(market)
    GenServer.cast(market.pid, {:add_line, line})
    line
  end

  def subscribe(%Market{pid: pid}) do
    Phoenix.PubSub.subscribe(Market.PubSub, "market:#{pid}")
  end

  def broadcast(%Market{pid: pid}, resource, event) do
    Phoenix.PubSub.broadcast(Market.PubSub, "market:#{pid}", {resource, event})
  end

  # Callbacks

  @impl true
  def init(multiplier) do
    {:ok, %__MODULE__{pid: self(), multiplier: multiplier}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:best_line, _from, state) do
    {best_line, _count} =
      state.lines
      |> Enum.map(fn line ->
        {line, Task.async(Line, :customer_count, [line])}
      end)
      |> Enum.map(fn {line, task} ->
        {line, Task.await(task)}
      end)
      |> Enum.min_by(&elem(&1, 1), fn -> {nil, nil} end)

    {:reply, best_line, state}
  end

  @impl true
  def handle_cast({:add_customer, customer}, state) do
    {:noreply, Map.update(state, :customers, [], &[customer | &1])}
  end

  def handle_cast({:add_line, line}, state) do
    {:noreply, Map.update(state, :lines, [], &[line | &1])}
  end
end
