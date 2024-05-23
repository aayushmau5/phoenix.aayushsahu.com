defmodule Accumulator.Parser do
  import NimbleParsec

  date =
    integer(4)
    |> ignore(string("-"))
    |> integer(2)
    |> ignore(string("-"))
    |> integer(2)

  time =
    integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> optional(string("Z"))

  defparsec(:datetime, date |> ignore(string("T")) |> concat(time), inline: true)

  # TODO: think how this can be used

  # fuck it! markdown parser

  # first '#', '##', '###', '####' tags

  heading =
    utf8_string([not: ?\n], min: 1)

  heading_tags =
    string("#")
    |> times(min: 1, max: 4)
    # space
    |> ignore(times(string(" "), min: 1))
    # string until end of line
    |> concat(heading)

  # the fall guy
  markdown = heading_tags

  defparsec(:markdown, markdown, inline: true)
end
