defmodule Accumulator.Emails.PlantEmail do
  use AccumulatorWeb, :html

  def generate_template(plants) do
    admin_email = Application.get_env(:accumulator, :admin_email)

    %{
      from: "phoenix@resend.dev",
      to: admin_email,
      subject: "🪴 Your plants need some care!",
      html:
        body(%{plants: plants})
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
    }
  end

  defp body(assigns) do
    ~H"""
    <div>
      These plants need to be watered today.
      <div :for={p <- @plants}>
        <img src={"https://phoenix.aayushsahu.com#{p.image}"} />
        <p>Name: {p.name}</p>
        <p>Watered On: {p.watered_on}</p>
        <p>Watering Frequency: {p.watering_frequency}</p>
        <p>Care tips: {p.care}</p>
        <a href={"https://phoenix.aayushsahu.com/plants/#{p.id}"}>Link</a>
        <div></div>
      </div>
    </div>
    """
  end
end
