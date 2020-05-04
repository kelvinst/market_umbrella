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

## The Market

