defmodule Market.Cashier do
  use GenServer

  alias Market.Cashier
  alias Market.Line
  alias Market.Customer

  defstruct [:pid, reductions: 999, current_reduction: 999, line: nil, customer: nil]

  def create(%Line{} = line, reductions) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [line, reductions])
    get(pid)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  # Callbacks

  @impl true
  def init([line, reductions]) do
    schedule_work(line.market.multiplier)
    {:ok, %__MODULE__{pid: self(), line: line, reductions: reductions, current_reduction: reductions}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:work, %Cashier{customer: nil} = state) do
    {:noreply, next_customer(state, fn -> state end, fn -> state end)}
  end

  def handle_info(:work, %Cashier{current_reduction: 0} = state) do
    new_state = next_customer(state, fn ->
      %{state | current_reduction: state.reductions}
    end, fn ->
      Line.add_customer(state.line, state.customer)
      %{state | current_reduction: state.reductions}
    end)

    {:noreply, new_state}
  end

  def handle_info(:work, %Cashier{} = state) do
    case Customer.process_item(state.customer) do
      :continue ->
        schedule_work(state.line.market.multiplier)
        new_state = %{state | current_reduction: state.current_reduction - 1}
        {:noreply, new_state}

      :done ->
        {:noreply, clear_customer(state)}
    end
  end

  defp next_customer(state, no_customer_fun, customer_fun) do
    case Line.next_customer(state.line) do
      nil ->
        state = no_customer_fun.()
        schedule_work(state.line.market.multiplier)
        state

      customer ->
        state = customer_fun.()
        new_state = %{state | customer: customer}
        schedule_work(state.line.market.multiplier)
        Market.broadcast(new_state.line.market, new_state, :updated)
        new_state
    end
  end

  defp clear_customer(state) do
    new_state = %{state | customer: nil}
    schedule_work(state.line.market.multiplier)
    Market.broadcast(new_state.line.market, new_state, :updated)
    new_state
  end

  defp schedule_work(multiplier) do
    Process.send_after(self(), :work, floor(200 / multiplier))
  end
end
