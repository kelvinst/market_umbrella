defmodule MarketWeb.MarketLive do
  use MarketWeb, :live_view

  alias Market.Cashier
  alias Market.Customer
  alias Market.Line

  @impl true
  def mount(_params, _session, socket) do
    market = Market.create()
    Market.subscribe(market)

    {:ok, assign(socket, market: market, customers: %{}, lines: %{}, cashiers: %{})}
  end

  @impl true
  def handle_event("new_customer", _, socket) do
    customer = Market.new_customer(socket.assigns.market, Enum.random(1..10))
    customers = Map.put(socket.assigns.customers, customer.pid, customer)
    {:noreply, assign(socket, :customers, customers)}
  end

  def handle_event("new_line", _, socket) do
    line = Market.new_line(socket.assigns.market)
    lines = Map.put(socket.assigns.lines, line.pid, line)
    {:noreply, assign(socket, :lines, lines)}
  end

  def handle_event("new_cashier", %{"value" => value}, socket) do
    line = '<#{value}>' |> :erlang.list_to_pid() |> Line.get()
    cashier = Line.new_cashier(line)
    cashiers = Map.put(socket.assigns.cashiers, cashier.pid, cashier)
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
end
