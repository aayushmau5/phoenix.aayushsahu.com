defmodule Accumulator.MarkdownTest do
  use ExUnit.Case, async: true

  alias Accumulator.Markdown

  describe "parser" do
    test "markdown" do
      md = ~S"""
      # hello world


      this is something else

      - something
      - in the
      - way

      [helllo]()

      - [ ] world
      - [x] world

      ## goodbye world

      `# hello`

      """

      assert_match(
        [
          {:h1, "hello world"},
          {:new_line, ""},
          {:new_line, ""},
          {:para, "this is something else"}
        ],
        md
      )
    end
  end

  defp assert_match(left, right) do
    assert match?({:ok, ^left, "", _, _, _}, Markdown.parse(right))
  end
end
