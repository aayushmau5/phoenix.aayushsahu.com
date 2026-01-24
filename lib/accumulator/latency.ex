defmodule Accumulator.Latency do
  @bsh_prefix "aayush-battleship"
  @timeout 500

  def measure_bsh() do
    case find_node(@bsh_prefix) do
      nil ->
        {:error, :not_connected}

      node ->
        start_time = System.monotonic_time(:microsecond)

        try do
          :erpc.call(node, :erlang, :monotonic_time, [:native], @timeout)
        catch
          :exit, reason -> {:error, reason}
        else
          _result ->
            end_time = System.monotonic_time(:microsecond)
            rtt_ms = (end_time - start_time) / 1000.0
            {:ok, Float.round(rtt_ms, 2)}
        end
    end
  end

  defp find_node(prefix) do
    Node.list()
    |> Enum.find(fn node ->
      node |> Atom.to_string() |> String.starts_with?(prefix)
    end)
  end
end
