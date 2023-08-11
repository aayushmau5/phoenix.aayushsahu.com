defmodule Accumulator.Emails.LoginEmail do
  use AccumulatorWeb, :html

  def generate_template(connection_info) do
    admin_email = Application.get_env(:accumulator, :admin_email)

    Swoosh.Email.new(
      to: admin_email,
      from: {"Phoenix", "phoenix@resend.dev"},
      subject: "phoenix.aayushsahu.com: login detected",
      html_body:
        body(connection_info)
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
    )
  end

  defp body(assigns) do
    ~H"""
    <div>
      Login detected!
      <p>Info:</p>
      <p>IP: <%= @ip_address %></p>
      <p>Location: <%= @location %></p>
      <p>Device: <%= @device_info %></p>
    </div>
    """
  end
end
