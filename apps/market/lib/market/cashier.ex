defmodule Market.Cashier do
  use GenServer

  alias Market.Cashier
  alias Market.Line
  alias Market.Customer

  defstruct [:pid, line: nil, customer: nil]

  def create(%Line{} = line) do
    {:ok, pid} = GenServer.start_link(__MODULE__, line)
    get(pid)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  # Callbacks

  @impl true
  def init(line) do
    schedule_work()
    {:ok, %__MODULE__{pid: self(), line: line}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:work, %Cashier{customer: nil} = state) do
    case Line.next_customer(state.line) do
      nil ->
        schedule_work()
        {:noreply, state}

      customer ->
        new_state = %{state | customer: customer}
        schedule_work()
        Market.broadcast(new_state.line.market, new_state, :updated)
        {:noreply, new_state}
    end
  end

  def handle_info(:work, %Cashier{} = state) do
    case Customer.process_item(state.customer) do
      :continue -> 
        schedule_work()
        {:noreply, state}

      :done -> 
        new_state = %{state | customer: nil}
        schedule_work()
        Market.broadcast(new_state.line.market, new_state, :updated)
        {:noreply, new_state}
    end
  end

  defp schedule_work do
    Process.send_after(self(), :work, 500)
  end
end
