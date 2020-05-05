defmodule Market.Line do
  use GenServer

  defstruct [:market, customers: []]

  def create(market) do
    GenServer.start_link(__MODULE__, market)
  end

  def customer_count(line) do
    GenServer.call(line, :customer_count)
  end

  # Callbacks

  @impl true
  def init(market) do
    {:ok, %__MODULE__{market: market}}
  end

  @impl true
  def handle_call(:customer_count, state) do
    {:reply, length(state.customers), state}
  end
end
