defmodule Accumulator.Markdown do
  @moduledoc """
  A Markdown to HTML parser
  """

  def to_html(markdown) do
    markdown
  end

  def parse(markdown_string) do
    tokenize(markdown_string)
  end

  def tokenize(markdown_string) do
    markdown_string |> String.split("\n") |> Enum.map(&replace_symbol/1)
  end

  def replace_symbol(string) do
    case string do
      "" -> {:new_line, ""}
      value -> String.trim(value) |> handle_symbol()
    end
  end

  def handle_symbol(value) do
    cond do
      String.starts_with?(value, "#") -> {:heading, value}
      String.starts_with?(value, "`") -> {:code, value}
      String.starts_with?(value, "```") -> {:code_block, value}
      # or hr
      String.starts_with?(value, "-") -> {:li, value}
      String.starts_with?(value, "_") -> {:italics, value}
      String.starts_with?(value, "*") -> {:bold, value}
      String.starts_with?(value, "~") -> {:bold, value}
    end

    if String.starts_with?(value, "#") do
      String
    end
  end

  # Headings
  # links
  # images
  # \n

  # What kind of datastructure? ease of creation and walking
  # if inside code block, ignore stuff
  # [{:h1, "text"}, {:new_line, ""}, {:line, "....."}, {:li, "something"}, ..., {:check_box, "",},]
  # {:ul, ["", "", ""]}
  # {:code, ""}
  # {:codeblock, "", extra_ops}
  # {:hr, ""}
  # {:italics, ""}
  # {:bold, ""}
  # {:strike, ""}

  # flow for concurrency

  # how to conver into ast?
  # How to convert into html? (pluggable)
  # parsing html? <soething>
end
