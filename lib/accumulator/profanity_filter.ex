defmodule Accumulator.ProfanityFilter do
  @moduledoc """
  Module for filtering profanity using Google's Perspective API.
  Supports both English and Hindi/Hinglish content moderation.
  """

  require Logger

  @perspective_api_url "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze"
  @toxicity_threshold 0.7
  @profanity_threshold 0.6

  # Fallback word list for when API is unavailable
  @fallback_profanity [
    "fuck",
    "shit",
    "bitch",
    "asshole",
    "bastard",
    "madarchod",
    "behenchod",
    "chutiya",
    "gandu",
    "randi",
    "mc",
    "bc",
    "wtf",
    "stfu"
  ]

  @doc """
  Checks if the given text contains profanity using Perspective API.
  Returns `{:ok, text}` if clean, `{:error, :contains_profanity}` if profane.
  Falls back to local filtering if API is unavailable.
  """
  def check_profanity(text) when is_binary(text) and byte_size(text) > 0 do
    case analyze_with_perspective(text) do
      {:ok, scores} ->
        if is_profane?(scores) do
          {:error, :contains_profanity}
        else
          {:ok, text}
        end

      {:error, reason} ->
        Logger.warning("Perspective API error: #{inspect(reason)}, falling back to local filter")
        check_with_fallback(text)
    end
  end

  def check_profanity(""), do: {:ok, ""}
  def check_profanity(_), do: {:error, :invalid_input}

  @doc """
  Returns true if the text contains profanity, false otherwise.
  """
  def contains_profanity?(text) do
    case check_profanity(text) do
      {:ok, _} -> false
      {:error, :contains_profanity} -> true
      {:error, _} -> false
    end
  end

  # Private functions

  defp analyze_with_perspective(text) do
    api_key = get_api_key()

    if is_nil(api_key) or api_key == "" do
      {:error, :no_api_key}
    else
      make_perspective_request(text, api_key)
    end
  end

  defp make_perspective_request(text, api_key) do
    body = %{
      requestedAttributes: %{
        TOXICITY: %{},
        SEVERE_TOXICITY: %{},
        PROFANITY: %{},
        IDENTITY_ATTACK: %{}
      },
      languages: ["en", "hi"],
      comment: %{text: text}
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    url = "#{@perspective_api_url}?key=#{api_key}"

    case Req.post(url, json: body, headers: headers, retry: false, receive_timeout: 5000) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, extract_scores(response)}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Perspective API returned status #{status}: #{inspect(body)}")
        {:error, {:api_error, status}}

      {:error, reason} ->
        Logger.warning("Perspective API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_scores(response) do
    attribute_scores = Map.get(response, "attributeScores", %{})

    %{
      toxicity: get_score(attribute_scores, "TOXICITY"),
      severe_toxicity: get_score(attribute_scores, "SEVERE_TOXICITY"),
      profanity: get_score(attribute_scores, "PROFANITY"),
      identity_attack: get_score(attribute_scores, "IDENTITY_ATTACK")
    }
  end

  defp get_score(attribute_scores, attribute) do
    attribute_scores
    |> Map.get(attribute, %{})
    |> Map.get("summaryScore", %{})
    |> Map.get("value", 0.0)
  end

  defp is_profane?(scores) do
    scores.toxicity > @toxicity_threshold or
      scores.severe_toxicity > @toxicity_threshold or
      scores.profanity > @profanity_threshold or
      scores.identity_attack > @toxicity_threshold
  end

  defp check_with_fallback(text) do
    normalized_text =
      text
      |> String.downcase()
      |> String.replace(~r/[^\w\s]/, " ")

    contains_fallback_profanity =
      @fallback_profanity
      |> Enum.any?(fn word ->
        String.contains?(normalized_text, word)
      end)

    if contains_fallback_profanity do
      {:error, :contains_profanity}
    else
      {:ok, text}
    end
  end

  defp get_api_key do
    Application.get_env(:accumulator, :perspective_api_key) ||
      System.get_env("PERSPECTIVE_API_KEY")
  end
end
