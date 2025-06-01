defmodule Accumulator.Examples.ProfanityFilterExample do
  @moduledoc """
  Example usage of the Profanity Filter with Perspective API.
  
  This module demonstrates how to use the profanity filter in various scenarios.
  Run examples with: `mix run -e "Accumulator.Examples.ProfanityFilterExample.run_examples()"`
  """

  alias Accumulator.ProfanityFilter
  require Logger

  def run_examples do
    IO.puts("=== Profanity Filter Examples ===\n")

    # Clean content examples
    IO.puts("1. Testing clean content:")
    test_clean_content()

    IO.puts("\n2. Testing English profanity:")
    test_english_profanity()

    IO.puts("\n3. Testing Hindi/Hinglish profanity:")
    test_hindi_profanity()

    IO.puts("\n4. Testing edge cases:")
    test_edge_cases()

    IO.puts("\n5. Testing boolean helper:")
    test_boolean_helper()

    IO.puts("\n=== Examples Complete ===")
  end

  defp test_clean_content do
    clean_examples = [
      "This is a great article!",
      "I love this content, very informative.",
      "Nice work on the implementation.",
      "बहुत अच्छा है यह article",
      "Great job! Keep it up 👍"
    ]

    Enum.each(clean_examples, fn text ->
      case ProfanityFilter.check_profanity(text) do
        {:ok, _} -> 
          IO.puts("  ✅ CLEAN: \"#{text}\"")
        {:error, reason} -> 
          IO.puts("  ❌ REJECTED: \"#{text}\" - #{reason}")
      end
    end)
  end

  defp test_english_profanity do
    profane_examples = [
      "This is fucking terrible",
      "You're such an idiot",
      "What the hell is this shit",
      "Damn, this sucks"
    ]

    Enum.each(profane_examples, fn text ->
      case ProfanityFilter.check_profanity(text) do
        {:ok, _} -> 
          IO.puts("  ⚠️  ALLOWED: \"#{text}\" (might be below threshold)")
        {:error, :contains_profanity} -> 
          IO.puts("  ❌ BLOCKED: \"#{text}\"")
        {:error, reason} -> 
          IO.puts("  ❌ ERROR: \"#{text}\" - #{reason}")
      end
    end)
  end

  defp test_hindi_profanity do
    hindi_examples = [
      "Tu chutiya hai yaar",
      "Madarchod kya kar raha hai",
      "BC kya baat hai",
      "Ye gandu insaan hai"
    ]

    Enum.each(hindi_examples, fn text ->
      case ProfanityFilter.check_profanity(text) do
        {:ok, _} -> 
          IO.puts("  ⚠️  ALLOWED: \"#{text}\" (might be below threshold)")
        {:error, :contains_profanity} -> 
          IO.puts("  ❌ BLOCKED: \"#{text}\"")
        {:error, reason} -> 
          IO.puts("  ❌ ERROR: \"#{text}\" - #{reason}")
      end
    end)
  end

  defp test_edge_cases do
    edge_cases = [
      "",  # Empty string
      "A",  # Single character
      String.duplicate("Clean text. ", 50),  # Long text
      "Hello! 😊 How are you?",  # Emojis and punctuation
      "This contains the word 'class' but should be fine",  # Potential false positive
      "I live in Scunthorpe"  # Classic false positive test
    ]

    Enum.each(edge_cases, fn text ->
      display_text = if String.length(text) > 50, do: "#{String.slice(text, 0, 50)}...", else: text
      
      case ProfanityFilter.check_profanity(text) do
        {:ok, _} -> 
          IO.puts("  ✅ CLEAN: \"#{display_text}\"")
        {:error, reason} -> 
          IO.puts("  ❌ REJECTED: \"#{display_text}\" - #{reason}")
      end
    end)
  end

  defp test_boolean_helper do
    test_cases = [
      {"Clean comment", false},
      {"This is shit", true},
      {"Great work!", false},
      {"Tu gandu hai", true}
    ]

    Enum.each(test_cases, fn {text, expected} ->
      result = ProfanityFilter.contains_profanity?(text)
      status = if result == expected, do: "✅", else: "❌"
      IO.puts("  #{status} \"#{text}\" -> #{result} (expected: #{expected})")
    end)
  end

  def test_comment_creation do
    IO.puts("=== Testing Comment Creation ===\n")

    alias Accumulator.Comments.Comment

    test_comments = [
      %{content: "This is a great article!", author: "John", blog_slug: "test"},
      %{content: "This is fucking terrible", author: "Angry User", blog_slug: "test"},
      %{content: "Tu chutiya hai", author: "Hindi User", blog_slug: "test"},
      %{content: "Nice work on this project", author: "Happy User", blog_slug: "test"}
    ]

    Enum.each(test_comments, fn attrs ->
      changeset = Comment.changeset(%Comment{}, attrs)
      
      if changeset.valid? do
        IO.puts("  ✅ VALID: \"#{attrs.content}\" by #{attrs.author}")
      else
        errors = Enum.map(changeset.errors, fn {field, {message, _}} -> "#{field}: #{message}" end)
        IO.puts("  ❌ INVALID: \"#{attrs.content}\" - #{Enum.join(errors, ", ")}")
      end
    end)
  end

  def benchmark_performance do
    IO.puts("=== Performance Benchmark ===\n")

    test_texts = [
      "This is a clean comment",
      "This is fucking terrible",
      "Tu chutiya hai yaar",
      "Great article, loved reading it!"
    ]

    Enum.each(test_texts, fn text ->
      {time_microseconds, result} = :timer.tc(fn ->
        ProfanityFilter.check_profanity(text)
      end)

      time_ms = time_microseconds / 1000
      result_str = case result do
        {:ok, _} -> "CLEAN"
        {:error, :contains_profanity} -> "PROFANE"
        {:error, reason} -> "ERROR: #{reason}"
      end

      IO.puts("  \"#{text}\" -> #{result_str} (#{Float.round(time_ms, 2)}ms)")
    end)
  end

  def test_api_availability do
    IO.puts("=== API Availability Test ===\n")

    api_key = Application.get_env(:accumulator, :perspective_api_key) || System.get_env("PERSPECTIVE_API_KEY")

    if api_key && api_key != "" do
      IO.puts("  ✅ API Key configured")
      
      # Test a simple request
      case ProfanityFilter.check_profanity("test message") do
        {:ok, _} -> IO.puts("  ✅ API responding normally")
        {:error, :contains_profanity} -> IO.puts("  ✅ API responding normally (flagged test content)")
        {:error, reason} -> IO.puts("  ❌ API error: #{inspect(reason)}")
      end
    else
      IO.puts("  ⚠️  No API Key configured - using fallback mode")
      IO.puts("  Set PERSPECTIVE_API_KEY environment variable to enable full functionality")
    end
  end
end