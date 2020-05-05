defmodule Market.Customer do
  use GenServer

  alias Market.Line

  defstruct [:market, items_to_take: 0, items_took: 0, items_processed: 0]

  def create(market, items_to_take) when items_to_take > 0 do
    GenServer.start_link(__MODULE__, [market, items_to_take])
  end

  # Callbacks
  
  @impl true
  def init([market, items_to_take]) do
    schedule_shopping() 
    {:ok, %__MODULE__{market: market, items_to_take: items_to_take}}
  end

  @impl true
  def handle_info(:shop, %__MODULE__{items_to_take: x, items_took: x} = c) do
    Line.add_customer(Market.best_line(), self())
    {:noreply, state}
  end

  def handle_info(:shop, %__MODULE__{items_to_take: x} = c) do
    schedule_shopping()
    {:noreply, Map.update(c, :items_took, 0, &(&1 + 1)}
  end

  defp schedule_shopping do
    Process.send_after(self(), :shop, 1000)
  end
end
