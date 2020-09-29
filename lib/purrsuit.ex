defmodule Purrsuit do
  def long do
    {:spawn_executable, "/usr/bin/tail"}
    |> Port.open([:stderr_to_stdout, :binary, :exit_status, args: ["-f", "../dummy.log"]])
    |> stream_output
  end

  defp stream_output(port) do
    receive do
      {^port, {:data, data}} ->
        IO.puts(data)
        stream_output(port)
      {^port, {:exit_status, 0}} ->
        IO.puts("Command success")
      {^port, {:exit_status, status}} ->
        IO.puts("Command error, status #{status}")
    end
  end
end
