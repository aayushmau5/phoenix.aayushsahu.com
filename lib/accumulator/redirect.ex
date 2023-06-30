defmodule Accumulator.Redirect do
  @redirect_mapping %{
    "yt" => %{
      "url" => "https://www.youtube.com/results?",
      "accepted_params" => ["q", "s"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "search_query={q}"
        },
        "s" => %{
          "accepts" => ["ud"],
          "ud" => "sp=CAI%253D"
        }
      }
    },
    "g" => %{
      "url" => "https://www.google.com/search?",
      "accepted_params" => ["q"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "q={q}"
        }
      }
    },
    "gi" => %{
      "url" => "https://www.google.com/search?",
      "accepted_params" => ["q"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "q={q}&tbm=isch"
        }
      }
    },
    "ddg" => %{
      "url" => "https://duckduckgo.com/?",
      "accepted_params" => ["q"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "q={q}"
        }
      }
    },
    "hn" => %{
      "url" => "https://hn.algolia.com/?",
      "accepted_params" => ["q", "t", "s"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "dateRange=all&page=0&prefix=false&query={q}"
        },
        "t" => %{
          "accepts" => ["story", "comment"],
          "story" => "type=story",
          "comment" => "type=comment"
        },
        "s" => %{
          "accepts" => ["popular", "date"],
          "popular" => "sort=byPopularity",
          "date" => "sort=byDate"
        }
      }
    },
    "npm" => %{
      "url" => "https://www.npmjs.com/search?",
      "accepted_params" => ["q", "s"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "q={q}"
        },
        "s" => %{
          "accepts" => ["popular"],
          "popular" => "ranking=popularity"
        }
      }
    },
    "hex" => %{
      "url" => "https://hex.pm/packages?",
      "accepted_params" => ["q", "s"],
      "required_params" => ["q"],
      "options" => %{
        "q" => %{
          "accepts" => :any,
          "default" => "search={q}"
        },
        "s" => %{
          "accepts" => ["downloads", "recent"],
          "downloads" => "sort=total_downloads",
          "recent" => "sort=recent_downloads"
        }
      }
    },
    "gm" => %{
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
  }

  def get_url(params) do
    %{"p" => page} = params

    case get_mapping(page) do
      nil -> {:error, "No mappings found"}
      mapping -> generate_url(params, mapping)
    end
  end

  defp generate_url(params, mapping) do
    case required_params_present?(params, mapping) do
      true ->
        url_params =
          generate_url_params(params, mapping) |> Enum.reject(&(&1 == nil)) |> Enum.join("&")

        {:ok, mapping["url"] <> url_params}

      false ->
        {:error, "Required params not present"}
    end
  end

  defp generate_url_params(params, mapping) do
    options = mapping["options"]

    for accepted_param <- mapping["accepted_params"],
        {^accepted_param, value} <- params do
      option = Map.get(options, accepted_param)
      value = String.downcase(value) |> URI.encode()

      case option["accepts"] do
        :any ->
          Regex.replace(~r/{([a-z]+)?}/, option["default"], fn v, m ->
            if m == accepted_param, do: value, else: v
          end)

        accepts ->
          if Enum.any?(accepts, &(value == &1)), do: option[value]
      end
    end
  end

  defp required_params_present?(params, mapping),
    do: Map.get(mapping, "required_params") |> Enum.all?(&Map.has_key?(params, &1))

  def get_mapping(site), do: Map.get(all_site_mappings(), site)
  def all_site_mappings, do: @redirect_mapping
end
