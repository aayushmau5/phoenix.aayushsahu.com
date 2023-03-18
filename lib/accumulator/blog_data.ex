defmodule Accumulator.BlogData do
  defstruct ~w(id views likes current_viewing)a

  def update_current_viewing_value(blog_data, value) do
    Map.update(blog_data, :current_viewing, 0, fn _ -> value end)
  end
end
