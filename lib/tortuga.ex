defmodule Tortuga do
  use GenServer
  require Logger

  # Path to the UI program
  @cmd "C:\\Users\\frank\\source\\repos\\ElixirUI\\ElixirUI\\bin\\Debug\\net5.0-windows\\ElixirUI.exe"
  # The heartbeat timer. This is needed to trigger updates.
  @timer 250

  @moduledoc """
  Documentation for `Tortuga`.
  """
	def timer_elapsed() do
		Process.send_after(__MODULE__, :heartbeat, @timer)
	end

  def init(_args \\ []) do
    port = Port.open({:spawn, @cmd}, [:binary, :exit_status])
		timer_elapsed()

    {:ok, %{latest_output: nil, exit_status: nil, port: port} }
  end

  # This callback handles data incoming from the command's STDOUT
  def handle_info({_port, {:data, text_line}}, state) do
    latest_output = text_line |> String.trim

    Logger.info "From GUI: #{latest_output}"

		new_state = %{state | latest_output: latest_output}
    {:noreply, new_state}
  end

  # This callback tells us when the process exits
  def handle_info({_port, {:exit_status, _status}}, state) do
    {:stop, :csharp_gui_process_exited, state}
  end

	def handle_info(:heartbeat, state = %{port: port}) do
    Port.info(port)
    |> handle_heartbeat()
		{:noreply, state}
	end

  # no-op catch-all callback for unhandled messages
	def handle_info(_msg, state), do: {:noreply, state}

  defp handle_heartbeat(nil), do: {:heartbeat_stopped}
  defp handle_heartbeat(_) do
		write("heartbeat")
		timer_elapsed()
  end

	def handle_cast({:write, value}, state = %{port: port}) do
		Port.command(port, value)
		{:noreply, state}
	end

  @doc """
  Starts the port control server
  """
  def start(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Writes a message to the port
  """
  def write(value), do: GenServer.cast(__MODULE__, {:write, value})
end
