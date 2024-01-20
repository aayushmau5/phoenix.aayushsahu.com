defmodule AccumulatorWeb.TodoLive do
  use AccumulatorWeb, :live_view

  # Per day:
  #   - task name
  #   - break down?(smaller subtasks)
  #   - reason(why do you wanna do the task)
  #   - dedicated time
  #   - done?(if yes, at what time?)
  #   - remarks(on the task)
  #   - remark of the day(overall)
  # - How do i make it mobile useable?
  # - need to think about the way to store data(and group by month, etc.)

  # Notion like design?
  # Why am I not using notion?(takes up a lot of ram)

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Todos</h1>
    """
  end
end
