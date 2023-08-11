defmodule Accumulator.Auth.Info do
  defstruct [:ip_address, :location, :device_info]

  def connection_info(conn) do
    {ip_address, location} = get_ip_address_and_location_info(conn)
    device_info = get_device_info_from_user_agent(conn)

    %__MODULE__{
      ip_address: ip_address,
      location: location,
      device_info: device_info
    }
  end

  defp get_ip_address_and_location_info(conn) do
    ip_address = conn.remote_ip

    # We lookup only ipv4 address
    if :inet.is_ipv4_address(ip_address) do
      ip_address =
        ip_address
        |> Tuple.to_list()
        |> Enum.join(".")

      location = ip_city_country_info(ip_address)
      {ip_address, location}
    else
      # false representation for ipv6 but it's ok i guess
      ip_address = ip_address |> Tuple.to_list() |> Enum.join(":")
      {ip_address, nil}
    end
  end

  defp get_device_info_from_user_agent(conn) do
    [user_agent] = Plug.Conn.get_req_header(conn, "user-agent")
    get_device_info(user_agent)
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

  defp get_device_info(user_agent) do
    case UAInspector.parse(user_agent) do
      %{browser_family: :unknown} ->
        nil

      %{browser_family: browser_family, device: %{model: model}, os: %{name: name}} ->
        "#{browser_family}:#{model}:#{name}"
    end
  end
end
