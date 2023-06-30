defmodule RedirectTest do
  use ExUnit.Case, async: true

  alias Accumulator.Redirect

  describe "Generate correct URL" do
    test "with query only" do
      params = %{"p" => "yt", "q" => "meow"}

      assert Redirect.get_url(params) ==
               {:ok, "https://www.youtube.com/results?search_query=meow"}
    end

    test "with query and valid optional args" do
      params = %{"p" => "yt", "q" => "meow", "s" => "ud"}

      assert Redirect.get_url(params) ==
               {:ok, "https://www.youtube.com/results?search_query=meow&sp=CAI%253D"}
    end

    test "with query and invalid optional args" do
      params = %{"p" => "yt", "q" => "meow", "s" => "invalid"}

      assert Redirect.get_url(params) ==
               {:ok, "https://www.youtube.com/results?search_query=meow"}
    end

    test "with space separated query" do
      params = %{"p" => "yt", "q" => "meow meow"}

      assert Redirect.get_url(params) ==
               {:ok, "https://www.youtube.com/results?search_query=meow%20meow"}
    end

    test "with gmail query" do
      params = %{"p" => "gm", "q" => "slice email"}

      assert Redirect.get_url(params) ==
               {:ok, "https://mail.google.com/mail/u/0/#search/slice%20email"}
    end

    test "required params not present" do
      params = %{"p" => "yt"}
      assert Redirect.get_url(params) == {:error, "Required params not present"}
    end

    test "passing non-accepted params(ignores it)" do
      params = %{"p" => "hn", "q" => "meow", "t" => "random"}

      assert Redirect.get_url(params) ==
               {:ok, "https://hn.algolia.com/?dateRange=all&page=0&prefix=false&query=meow"}
    end
  end

  describe "Mappings" do
    test "Mapping exists" do
      assert Redirect.get_mapping("gm") == %{
               "url" => "https://mail.google.com/mail/u/0/#search/",
               "accepted_params" => ["q"],
               "required_params" => ["q"],
               "options" => %{
                 "q" => %{
                   "accepts" => :any,
                   "default" => "{q}"
                 }
               }
             }
    end

    test "Mapping doesn't exists" do
      assert Redirect.get_mapping("invalid") == nil
    end
  end
end
