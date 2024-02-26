defmodule AccumulatorWeb.TodoLive do
  use AccumulatorWeb, :live_view

  @impl true
  def render(%{format: :swiftui} = assigns) do
    ~SWIFTUI"""
    <VStack>
      <Text>
        Hello native!
      </Text>
    </VStack>
    """
  end

  @impl true
  def render(%{} = assigns) do
    ~H"""
    <div class="flex w-full h-screen items-center">
      <span class="w-full text-center">
        Check the app for full experience!
      </span>
    </div>
    """
  end
end
