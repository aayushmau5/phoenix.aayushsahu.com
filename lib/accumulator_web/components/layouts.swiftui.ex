defmodule AccumulatorWeb.Layouts.SwiftUI do
  use AccumulatorNative, [:layout, format: :swiftui]

  embed_templates "layouts_swiftui/*"
end
