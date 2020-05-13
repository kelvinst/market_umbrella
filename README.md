# Elixir |> BEAM() == ❤

This project was created for a given presentation, so there is some context to it, please read the [presentation](./priv/presentations/en.pdf') and get back here when you get on the "Practice" slide.

## Practice

### Data

Here is some data for you:

```elixir
1
1.2
[1, 2, 3]
:atom
"string"
```

You can investigate a bit about the data using the function `i`:

```elixir
i("Hello CapiConf")
```

### Functions

You already saw a function, the `i` one, but here is another one:

```elixir
h()
```

It prints some helpful info, so enjoy yourself at home!

Now let's make a hello world:

```elixir
IO.puts("Hello CapiConf")
```

So in this case `"Hello CapiConf"` is the data, and `IO.puts` is the function, that takes that data as a parameter and prints it to the STDIO.

If you want, you can investigate function using the macro `h`, like this:

```elixir
h(IO.puts)
```

It will print the help page for that function.

### Processes

So finally, here is a process:

```elixir
spawn(IO, :puts, ["Hello CapiConf"])
```

So `spawn` is a function that starts a process that will run the given function with the given parameters.

Now go back to the [presentation](./priv/presentations/en.pdf'), and get back here when you get to "More Practice"

## More Practice

### Everything is a process

In fact, even `iex` is a process, that is waiting for you to send him something to execute.

### Concurrent and lightweight

Now let's make it a bit more complex, doing it multiple times and faking some processing (also known as sleeping a bit):

```elixir
for i <- 1..10 do
  400..500 |> Enum.random() |> Process.sleep()
  IO.puts("Hello CapiConf #{i}")
end
```

So basically a sequential counter with some random processing time from 400 to 500 milliseconds. But what happens if I spawn a process for each iteration?

```elixir
for i <- 1..10 do
  spawn(fn ->
    400..500 |> Enum.random() |> Process.sleep()
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

As you see, the counter is not sequential anymore, cause processes run concurrently. 

Also, you might see some performance improvements, let's see how that goes with lots of processes:

```elixir
for i <- 1..10000 do
  spawn(fn ->
    400..500 |> Enum.random() |> Process.sleep()
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

So as you see, processes start and finish pretty quickly too. Took a while to finish mostly because of IO, I guarantee.

Time to live forever now, let's start a process that do not die:

```elixir
defmodule Highlander do
  def rise do
    spawn(__MODULE__, :live, [0])
  end

  def live(years) do
    IO.puts("Alive for #{years} years")
    live(years + 1)
  end
end

highlander = Highlander.rise()
```

Nice, he lives forever this way, unless you cut off his head:

```elixir
Process.exit(highlander, :kill)
```

Cool, that one will not bother us anymore. Note how we could still kill the process that was supposed to lock the CPU, as it was basically an infinite recursion.

### Message passing

Now let's create another process that wants to talk a bit:

```elixir
defmodule WarBoy do
  def rise do
    spawn(__MODULE__, :drive, [0])
  end

  def drive(index) do
    receive do
      :continue -> 
        [
          "I live, I die! I live again!",
          "Oh what a day. What a lovely day!",
          "If I'm gonna die, I'm gonna die historic on the fury road!",
        ]
        |> Enum.at(Integer.mod(index, 3))
        |> IO.puts()

        drive(index + 1)

      :die ->
        IO.puts("Witness meeeee!!")
    end
  end
end

nux = WarBoy.rise()
```

So we started the process and saved his `PID` on `nux` variable. Let's interact with him

```elixir
send(nux, :continue)
```

And let him die:

```elixir
send(nux, :die)
```

You see, it's just a matter of using the `send` and `receive` functions to communicate to each other.

`send` adds the message to that process mailbox, and `receive` reads from the mailbox sequentially. If the mailbox is empty, `receive` will put the process on standby (timeout configurable).

### Strongly isolated and share nothing

One interesting thing is that it does not matter to other processes if a given process fail. Check this:

```elixir
for i <- 1..10 do
  spawn(fn ->
    if Integer.mod(i, 2) != 0, do: raise "That's odd, #{i}"
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

As you saw, the odd numbers failed, but the even still work flawlessly. They are strongly isolated.

Now let's watch some friends eat together:

```elixir
defmodule Friend do
  def start(name, food) do
    spawn(__MODULE__, :live, [name, food])
  end

  def live(name, food) do
    receive do
      :eat -> 
        case food do
          [food | rest] ->
            IO.puts("#{name} ate #{food}")
            live(name, rest)
          [] ->
            IO.puts("Where is the food that was here?")
            live(name, food)
        end
      {:done, pid} -> 
        send(pid, food)
    end
  end

  def eat(friend) do
    send(friend, :eat)
  end

  def done(friend) do
    send(friend, {:done, self()})

    receive do
      quantity -> quantity
    end
  end
end

food = ["pasta", "meatballs", "pizza", "panna cotta"]
joey = Friend.start("Joey", food)
rachel = Friend.start("Rachel", food)
```

We gave the same `food` for both friends, let's see what happens when eating:

```elixir
Friend.eat(joey)
Friend.eat(joey)
Friend.eat(joey)
Friend.eat(joey)
Friend.eat(joey)
Friend.eat(rachel)

Friend.done(joey)
Friend.done(rachel)
```

So basically JOEY DOES NOT SHARE FOOOOOD! Actually, PROCESSES DO NOT SHARE ANYTHING!

## Demo

Just run `mix phx.server` on this repo root folder and acess http://localhost:4000, OR, you could try it live [in here](https://incomparable-light-flycatcher.gigalixirapp.com), it might get unavailable after some time though.

Some details about this project:

- You can use the modifier keys (CTRL, SHIFT, ALT, WIN/CMD) to create more than one customer (each key adds a different number of customers)
- It is an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html#umbrella-projects)
- The domain implementation is on the subproject [`apps/market`](./apps/market/)
- The files under [`lib`](./apps/market/lib) have the implementation of each type of process
- I used OTP's [GenServer](https://hexdocs.pm/elixir/GenServer.html) to handle the processes communication easily (it is basically a design pattern for long living processes that communicate a lot)
- The web implementation is on the folder [`apps/market_web`](./apps/market_web/)
- It uses the framework [phoenix](https://hexdocs.pm/phoenix/overview.html) for routing
- Used the command [`mix phx.new --no-ecto --live --umbrella`](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html) to generate the initial project
- It uses [phoenix live view](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) to render the main view totally on the server and do live updates over websockets without the JS hassle you normally go to
- Realtime updates from the domain processes are sent to the live view through [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)
- The main view logic is basically on the files under [`lib/market_web/live`](./apps/market_web/lib/market_web/live/)
