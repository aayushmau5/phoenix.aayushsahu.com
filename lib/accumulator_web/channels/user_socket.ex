defmodule AccumulatorWeb.UserSocket do
  use Phoenix.Socket

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "user-join", AccumulatorWeb.UserJoinChannel
  channel "blog:*", AccumulatorWeb.BlogChannel
  channel "comments:*", AccumulatorWeb.CommentChannel
  channel "contact", AccumulatorWeb.ContactChannel

  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(_params, socket, connect_info) do
    ip = get_client_ip(connect_info) |> dbg()
    {:ok, assign(socket, :client_ip, ip)}
  end

  defp get_client_ip(connect_info) do
    x_headers = Map.get(connect_info, :x_headers, [])

    case List.keyfind(x_headers, "x-forwarded-for", 0) do
      {_, forwarded_for} ->
        forwarded_for |> String.split(",") |> List.first() |> String.trim()

      nil ->
        case connect_info[:peer_data] do
          %{address: addr} -> :inet.ntoa(addr) |> to_string()
          _ -> "unknown"
        end
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.AccumulatorWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket) do
    "user_socket:#{Time.utc_now() |> Time.to_string()}"
  end
end
