defmodule Purrsuit.Application do
  alias Purrsuit.Listener

  use Application

  def start(_type, _args) do
    "echo $(hostname)@$(hostname -I | awk '{print $1}')"
    |> String.to_charlist
    |> :os.cmd()
    |> List.to_string
    |> String.trim
    |> String.to_atom
    |> Node.start

    Node.set_cookie(:purrsuit)

    children = [ Listener ]
    opts = [strategy: :one_for_one, name: Purrsuit.Supervisor]

    pid = Supervisor.start_link(children, opts)

    Purrsuit.Listener.start

    pid
  end
end
