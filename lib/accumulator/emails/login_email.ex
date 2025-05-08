defmodule Accumulator.Emails.LoginEmail do
  use AccumulatorWeb, :html

  def generate_template(connection_info) do
    admin_email = Application.get_env(:accumulator, :admin_email)

    %{
      from: "phoenix@resend.dev",
      to: admin_email,
      subject: "phoenix.aayushsahu.com: login detected",
      html:
        body(connection_info)
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
    }
  end

  defp body(assigns) do
    ~H"""
    <div>
      Login detected!
      <p>Info:</p>
      <p>IP: {@ip_address}</p>
      <p>Location: {@location}</p>
      <p>Device: {@device_info}</p>
    </div>
    """
  end
end
