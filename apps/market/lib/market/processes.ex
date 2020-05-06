defimpl String.Chars, for: PID do
  def to_string(pid) do
    pid
    |> inspect
    |> String.replace(~r/#PID<([\d\.]+)>/, "\\1")
  end
end

defimpl Phoenix.HTML.Safe, for: PID do
  def to_iodata(pid) do
    to_string(pid)
  end
end
