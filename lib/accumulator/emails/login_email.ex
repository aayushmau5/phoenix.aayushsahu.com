defmodule Accumulator.Emails.LoginEmail do
  import Swoosh.Email

  def generate_template() do
    admin_email = Application.get_env(:accumulator, :admin_email)

    new()
    |> to({"Hi", admin_email})
    |> from({"Phoenix", "phoenix@resend.dev"})
    |> subject("phoenix.aayushsahu.com login detected")
    |> html_body(body())
  end

  defp body() do
    ~s"""
    <div>
      Login detected!
    </div>
    """
  end
end
