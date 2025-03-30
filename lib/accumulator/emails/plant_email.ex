defmodule Accumulator.Emails.PlantEmail do
  use AccumulatorWeb, :html

  def generate_template(plants) do
    admin_email = Application.get_env(:accumulator, :admin_email)

    %{
      from: "phoenix@resend.dev",
      to: admin_email,
      subject: "🪴 Your plants need some care!",
      html:
        body(plants)
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
    }
  end

  defp body(assigns) do
    ~H"""
    <div>
      TODO
    </div>
    """
  end
end
