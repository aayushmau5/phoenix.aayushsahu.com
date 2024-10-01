defmodule AccumulatorWeb.NativeLive.SwiftUI do
  use AccumulatorNative, [:render_component, format: :swiftui]

  def render(assigns, _interface) do
    # interface =>
    # %{
    #   "app_build" => "2",
    #   "app_version" => "0.3.0",
    #   "bundle_id" => "com.dockyard.LiveViewNativeGo",
    #   "i18n" => %{"time_zone" => "Asia/Kolkata"},
    #   "l10n" => %{"locale" => "en_IN"},
    #   "os" => "iOS",
    #   "os_version" => "18.0",
    #   "target" => "ios"
    # }

    ~LVN"""
    <Text>Hello from phoenix.aayushsahu.com</Text>
    """
  end
end
