defmodule Market.Line do
  use GenServer

  alias Market.Line
  alias Market.Cashier
  alias Market.Customer

  defstruct [:pid, :market, customers: [], cashiers: []]

  def create(market) do
    {:ok, pid} = GenServer.start_link(__MODULE__, market)
    get(pid)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def customer_count(%Line{} = line) do
    GenServer.call(line.pid, :customer_count)
  end

  def next_customer(%Line{} = line) do
    GenServer.call(line.pid, :next_customer)
  end

  def add_customer(%Line{} = line, %Customer{} = customer) do
    GenServer.cast(line.pid, {:add_customer, customer})
  end

  def new_cashier(%Line{} = line) do
    cashier = Cashier.create(line)
    GenServer.cast(line.pid, {:add_cashier, cashier})
    cashier
  end

  # Callbacks

  @impl true
  def init(market) do
    {:ok, %__MODULE__{pid: self(), market: market}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:customer_count, _from, state) do
    {:reply, length(state.customers), state}
  end

  def handle_call(:next_customer, _from, state) do
    case state.customers do
      [next_customer | rest] ->
        new_state = %{state | customers: rest}
        Market.broadcast(new_state.market, new_state, :updated)
        {:reply, next_customer, new_state}

      [] -> 
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_cast({:add_customer, customer}, state) do
    new_state = Map.update(state, :customers, [], &(&1 ++ [customer]))
    Market.broadcast(new_state.market, new_state, :updated)
    {:noreply, new_state}
  end

  def handle_cast({:add_cashier, cashier}, state) do
    new_state = Map.update(state, :cashiers, [], &[cashier | &1])
    Market.broadcast(new_state.market, new_state, :updated)
    {:noreply, new_state}
  end
end
