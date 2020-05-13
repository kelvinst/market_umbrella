defmodule MarketWeb.MarketLive do
  use MarketWeb, :live_view

  alias Market.Cashier
  alias Market.Customer
  alias Market.Line

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, market: nil, customers: %{}, lines: %{}, cashiers: %{})}
  end

  @impl true
  def handle_event("new_market", %{"multiplier" => multiplier}, socket) do
    multiplier =
      case Integer.parse(multiplier) do
        {x, _} -> x
        :error -> 1
      end

    market = Market.create(multiplier)
    Market.subscribe(market)

    {:noreply, assign(socket, market: market, customers: %{}, lines: %{}, cashiers: %{})}
  end

  def handle_event("new_customer", params, socket) do
    customers =
      for _ <- 1..customers(params), into: socket.assigns.customers do
        customer = Market.new_customer(socket.assigns.market, Enum.random(items(params)))
        {customer.pid, customer}
      end

    {:noreply, assign(socket, :customers, customers)}
  end

  def handle_event("new_line", _, socket) do
    line = Market.new_line(socket.assigns.market)
    lines = Map.put(socket.assigns.lines, line.pid, line)
    {:noreply, assign(socket, :lines, lines)}
  end

  def handle_event("new_cashier", %{"reductions" => reductions, "line" => line}, socket) do
    reductions =
      case Integer.parse(reductions) do
        {x, _} -> x
        :error -> 999
      end

    cashiers = create_cashier(line, socket.assigns.cashiers, reductions)
    {:noreply, assign(socket, :cashiers, cashiers)}
  end

  @impl true
  def handle_info({%Customer{} = customer, :updated}, socket) do
    customers = Map.put(socket.assigns.customers, customer.pid, customer)
    {:noreply, assign(socket, :customers, customers)}
  end

  def handle_info({%Line{} = line, :updated}, socket) do
    lines = Map.put(socket.assigns.lines, line.pid, line)
    {:noreply, assign(socket, :lines, lines)}
  end

  def handle_info({%Cashier{} = cashier, :updated}, socket) do
    cashiers = Map.put(socket.assigns.cashiers, cashier.pid, cashier)
    {:noreply, assign(socket, :cashiers, cashiers)}
  end

  defp customers(%{} = map), do: map |> Map.to_list() |> customers(1)
  defp customers([], acc), do: acc
  defp customers([{"shiftKey", true} | rest], acc), do: customers(rest, acc + 2)
  defp customers([{"altKey", true} | rest], acc), do: customers(rest, acc + 3)
  defp customers([{"ctrlKey", true} | rest], acc), do: customers(rest, acc + 5)
  defp customers([{"metaKey", true} | rest], acc), do: customers(rest, acc + 7)
  defp customers([_ | rest], acc), do: customers(rest, acc)

  defp items(%{"value" => "large"}), do: 20..39
  defp items(%{"value" => "medium"}), do: 10..19
  defp items(%{"value" => "small"}), do: 1..9

  defp create_cashier(line, cashiers, reductions) do
    line = '<#{line}>' |> :erlang.list_to_pid() |> Line.get()
    cashier = Line.new_cashier(line, reductions)
    Map.put(cashiers, cashier.pid, cashier)
  end
end
