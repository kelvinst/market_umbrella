defmodule Syntax do

  

  defp types do
    %{
      integer: 1,
      float: 1.2,
      list: [1, 2, 3],
      atom: :hello,
      charlist: 'world',
      string: "binary"
    }
  end

  def sum(a, b) do
    a + b
  end

  def print(str, 1) do 
    IO.puts(str)
  end

  def print(str, x) when x > 1 do 
    IO.puts("#{str}s")
  end
end

## Calling the functions



Syntax.sum(1, 2) # => 3
Syntax.print("apple", 1) # apple => :ok
Syntax.print("orange", 2) # oranges => :ok

