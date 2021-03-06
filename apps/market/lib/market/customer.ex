defmodule Market.Customer do
  use GenServer

  alias Market.Customer
  alias Market.Line

  defstruct [
    :pid,
    :market,
    state: "shopping",
    items_to_take: 0,
    items_took: 0,
    items_processed: 0,
    created_at: nil,
    entered_line_at: nil,
    finished_at: nil
  ]

  def create(market, items_to_take) when items_to_take > 0 do
    {:ok, pid} = GenServer.start_link(__MODULE__, [market, items_to_take])
    get(pid)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def process_item(%Customer{} = customer) do
    GenServer.call(customer.pid, :process_item)
  end

  # Callbacks

  @impl true
  def init([market, items_to_take]) do
    state = %__MODULE__{
      pid: self(),
      market: market,
      items_to_take: items_to_take,
      created_at: now()
    }

    schedule_shopping(market.multiplier)

    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:process_item, _from, %Customer{items_took: x, items_processed: x} = state) do
    new_state = %{state | state: "done", finished_at: now()}
    Market.broadcast(state.market, new_state, :updated)
    {:reply, :done, new_state}
  end

  def handle_call(:process_item, _from, %Customer{} = state) do
    new_state = Map.update(state, :items_processed, 0, &(&1 + 1))
    Market.broadcast(state.market, new_state, :updated)
    {:reply, :continue, new_state}
  end

  @impl true
  def handle_info(:shop, %__MODULE__{items_to_take: x, items_took: x} = state) do
    line = Market.best_line(state.market)

    new_state =
      if line do
        Line.add_customer(line, state)
        %{state | state: "processing", entered_line_at: now()}
      else
        schedule_shopping(state.market.multiplier)
        %{state | state: "done_shopping"}
      end

    Market.broadcast(state.market, new_state, :updated)

    {:noreply, new_state}
  end

  def handle_info(:shop, %__MODULE__{} = state) do
    schedule_shopping(state.market.multiplier)
    Market.broadcast(state.market, state, :updated)
    {:noreply, Map.update(state, :items_took, 0, &(&1 + 1))}
  end

  defp schedule_shopping(multiplier) do
    Process.send_after(self(), :shop, floor(200 / multiplier))
  end

  defp now, do: DateTime.to_unix(DateTime.utc_now(), :millisecond)
end
