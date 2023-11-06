defmodule Accumulator.Auth.Info do
  defstruct [:ip_address, :location, :device_info]

  def connection_info(conn) do
    {ip_address, location} = get_ip_address_and_location_info(conn)
    user_agent = get_user_agent(conn)

    %__MODULE__{
      ip_address: ip_address,
      location: location,
      device_info: user_agent
    }
  end

  defp get_ip_address_and_location_info(conn) do
    ip_address = get_ip_address(conn)

    location = ip_city_country_info(ip_address)
    {ip_address, location}
  end

  defp get_ip_address(conn) do
    # Fly.io provides client ip address in a separate header called "fly-client-ip"
    # Alternatively: we can also use the first element of "x-forwarded-for" header
    ip_address = Plug.Conn.get_req_header(conn, "fly-client-ip")

    if ip_address != [] do
      Enum.at(ip_address, 0)
    else
      conn.remote_ip
      |> Tuple.to_list()
      |> Enum.join(".")
    end
  end

  defp get_user_agent(conn) do
    [user_agent] = Plug.Conn.get_req_header(conn, "user-agent")
    user_agent
  end

  defp ip_city_country_info(address) when is_binary(address) do
    case Req.get("http://ip-api.com/json/#{address}?fields=49179") do
      {:ok, %{status: 200, body: %{"status" => "success"} = body}} ->
        "#{Map.get(body, "city")}:#{Map.get(body, "country")}"

      {:ok, _resp} ->
        nil

      {:error, _} ->
        nil
    end
  end
end
