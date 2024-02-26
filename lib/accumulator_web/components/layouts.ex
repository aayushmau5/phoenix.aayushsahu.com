defmodule AccumulatorWeb.Layouts do
  use AccumulatorWeb, :html
  use LiveViewNative.Layouts

  embed_templates "layouts/*.html"
end
