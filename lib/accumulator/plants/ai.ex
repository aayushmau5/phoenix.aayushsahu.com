defmodule Accumulator.Plants.AI do
  require Logger

  @llm_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash"

  def run(base64_image) do
    response = make_request(base64_image)

    case response do
      {:ok, %Req.Response{status: 200, body: body}} ->
        %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}} | _]} = body
        parsed_content = clean_and_parse(text)
        {:ok, parsed_content}

      {:ok, %Req.Response{body: body}} ->
        %{"error" => %{"message" => message}} = body
        Logger.error(message)
        {:error, message}

      {:error, error} ->
        Logger.error(Exception.message(error))
        {:error, error}
    end
  end

  defp make_request(base64_image) do
    Req.post(
      "#{@llm_url}:generateContent",
      params: [key: get_api_key()],
      json: %{
        contents: [
          %{
            parts: [
              %{text: prompt()},
              %{
                inline_data: %{
                  data: base64_image,
                  mime_type: "image/jpeg"
                }
              }
            ]
          }
        ]
      }
    )
  end

  defp prompt() do
    """
    A description of the given plant.
    As a genius expert, your task is to understand the content and provide the parsed objects in json that match the following json_schema:\n
    {"name": string, "info": string, "care": string, "watering_frequency": one of ["weekly", "biweekly", "daily", "<num> days", "<num> weeks", "when upper soil is dry"]}

    ## Fields:
    - name: Common name of the plant
    - info: Some common information about the plant such as it's features(ex. "air purifier")
    - care: Some care tips of the plant(ex. "indirect sunlight")
    - watering_frequency: At what frequency the plant should be watered(ex. "3 days" meaning every 3 days. One special case: "when upper soil is dry")

    Make sure to return an instance of the JSON, not the schema itself.
    """
  end

  defp get_api_key() do
    System.get_env("GEMINI_API_KEY")
  end

  defp clean_and_parse(response) do
    Regex.replace(~r/^```json\n|\n```$/, response, "")
    |> JSON.decode!()
  end
end
