# Elixir |> BEAM() == ❤

This project was created for a given presentation, so there is some context you might be missing, I will update it here when the slides are available publicly

## The Basics

Starting off with the basics, here is a hello world:

```elixir
IO.puts("Hello CapiConf")
```

So in this case `"Hello CapiConf"` is the data, and `IO.puts` is the behavior, that takes that data as a parameter and prints it to the STDIO.

Now let's make it a bit more complex, doing it multiple times and faking some processing (also known as sleeping a bit):

```elixir
for i <- 1..10 do
  Process.sleep(500)
  IO.puts("Hello CapiConf #{i}")
end
```

Cool, as you saw, it took a while now to print it all.

But what if we want it to take less time? Simple, do them on separate processes using `spawn`:

```elixir
for i <- 1..10 do
  spawn(fn ->
    Process.sleep(500)
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

The `spawn` function starts off a new process to run them concurrently and in an async manner.

But hey, did you see how it actually printed them sequentially? Well, that's not always the case:

```elixir
for i <- 1..10 do
  spawn(fn ->
    400..500 |> Enum.random() |> Process.sleep()
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

This way you can see how all of the processes execute at the same time, as opposed to not using the spawn, for example:

```elixir
for i <- 1..10 do
  400..500 |> Enum.random() |> Process.sleep()
  IO.puts("Hello CapiConf #{i}")
end
```

## The Processes

One interesting thing is that it does not matter to other processes if a given process fail. Check this:

```elixir
for i <- 1..10 do
  spawn(fn ->
    400..500 |> Enum.random() |> Process.sleep()
    if Integer.mod(i, 2) != 0, do: raise "That's odd, #{i}"
    IO.puts("Hello CapiConf #{i}")
  end)
end
```

As you saw, the odd numbers failed, but the even still work flawlessly.

Now let's see a bit more complex process stuff, let's start by creating a process that lives forever:

```elixir
defmodule Highlander do
  def rise do
    spawn(__MODULE__, :live, [1])
  end

  def live(years) do
    IO.puts("Alive for #{years} years")
    Process.sleep(1000)
    live(years + 1)
  end
end

highlander = Highlander.rise()
```

Nice, he lives forever this way, but now let's cut his head off:

```elixir
Process.exit(highlander, :kill)
```

Cool, that one will not bother us anymore.

Let's see how processes interact to each other now:

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
send(nux, :continue)
send(nux, :continue)
send(nux, :continue)
send(nux, :continue)
send(nux, :die)
```

You see, it's just a matter of using the `send` and `receive` functions to communicate to each other.

All process interaction is made through this messages, `send` adds the message to that process mailbox, and `receive` reads from the mailbox sequentially. If the mailbox is empty, `receive` will put the process on standby (timeout configurable).

## The Market


