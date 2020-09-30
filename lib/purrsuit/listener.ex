defmodule Purrsuit.Listener do
  use GenServer

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start do
    GenServer.cast(__MODULE__, :start)
  end

  def listen(pid) do
    GenServer.call(__MODULE__, {:listen, pid})
  end

  # Server

  def init(_opts) do
    { :ok, %MapSet{} }
  end

  def handle_cast(:start, listeners) do
    {:ok, data} = File.read("/etc/purrsuit/watch.conf")
    data
    |> String.split("\n")
    |> Enum.map(&(String.trim/1))
    |> Enum.reject(&(&1 == ""))
    |> Enum.each(fn watch ->
      Task.start_link(fn ->
        {:spawn_executable, "./wrap.sh"}
        |> Port.open([:stderr_to_stdout, :binary, :exit_status, args: ["/usr/bin/tail -f " <> watch]])
        |> stream_output
      end)
    end)

    {:noreply, listeners}
  end

  def handle_cast({:data, data}, listeners) do
    listeners
    |> Enum.each(fn pid ->
      send(pid, {:data, Node.self, data})
    end)
    {:noreply, listeners}
  end

  def handle_call({:listen, pid}, _ref, listeners) do
    Process.monitor(pid)
    {:reply, pid, listeners |> MapSet.put(pid) }
  end

  def handle_info({:DOWN, _ref, :process, pid, _}, listeners) do
    {:noreply, listeners |> MapSet.delete(pid)}
  end

  defp stream_output(port) do
    receive do
      {^port, {:data, data}} ->
        GenServer.cast(__MODULE__, {:data, data})
        stream_output(port)
      {^port, {:exit_status, 0}} ->
        IO.puts("Command success")
      {^port, {:exit_status, status}} ->
        IO.puts("Command error, status #{status}")
    end
  end
end
