defmodule Mix.Tasks.System.Start do
  # Mix.Task behaviour is not in PLT since Mix is not a runtime dep, so we disable the warning
  @dialyzer :no_undefined_callbacks

  use Mix.Task

  def loop do
    receive do
      {:nodeup, node} ->
        unless Node.self == node do
          IO.puts((node |> Atom.to_string) <> " connected")
        end
        loop()
      {:nodedown, node} ->
        IO.puts((node |> Atom.to_string) <> " disconnected")
        loop()
      {:data, node, msg} ->
        IO.write((node |> Atom.to_string) <> " :: " <> msg)
        loop()
      _ -> loop()
    end
  end

  def run(_args) do
    :net_kernel.monitor_nodes(true)

    ip = "echo $(hostname -I | awk '{print $1}')"
    |> String.to_charlist
    |> :os.cmd()
    |> List.to_string
    |> String.trim

    "node" <> (:rand.uniform(1000) |> Integer.to_string) <> "@" <> ip
    |> String.to_atom
    |> Node.start

    Node.set_cookie(:purrsuit)

    {:ok, data} = File.read("/etc/purrsuit/nodes.conf")

    data
    |> String.split("\n")
    |> Enum.map(&(String.trim/1))
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&(String.to_atom/1))
    |> Enum.each(fn node ->
      Node.connect(node)
      Node.spawn(node, Purrsuit.Listener, :listen, [self()])
    end)

    loop()
  end
end
