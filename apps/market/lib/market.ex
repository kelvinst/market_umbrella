defmodule Market do
  @moduledoc """
  Market keeps the contexts that define your domain
  and business logic.
  """

  use GenServer

  alias Market.Customer
  alias Market.Line
  alias Market.Cashier

  defstruct [cashiers: [], lines: [], customers: []]

  def create do
    GenServer.start_link(__MODULE__, nil)
  end

  def new_customer(market, items_to_take) do
    {:ok, customer} = Customer.create(market, items_to_take)
    GenServer.cast(market, {:add_customer, customer})
    customer
  end

  def new_line(market) do
    {:ok, line} = Line.create(market)
    GenServer.cast(market, {:add_line, line})
    line
  end

  def new_cashier(market, line) do
    {:ok, cashier} = Cashier.create(market, line)
    GenServer.cast(market, {:add_cashier, cashier})
    cashier
  end

  def best_line(market) do
    GenServer.call(market, :best_line)
  end

  # Callbacks
  
  @impl true
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:add_customer, customer}, state) do
    {:noreply, Map.update(state, :customers, [], &[customer | &1])}
  end
  
  def handle_cast({:add_line, line}, state) do
    {:noreply, Map.update(state, :lines, [], &[line | &1])}
  end

  def handle_cast({:add_cashier, cashier}, state) do
    {:noreply, Map.update(state, :cashiers, [], &[cashier | &1])}
  end

  @impl true
  def handle_call(:best_line, state) do
    best_line = 
      state.lines
      |> Enum.map(&Task.async(Line, :customer_count, [&1])
      |> Enum.map(&Task.await/1)
      |> Enum.min()

    {:reply, best_line, state}
  end
end
