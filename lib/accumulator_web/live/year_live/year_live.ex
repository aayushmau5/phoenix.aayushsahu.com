defmodule AccumulatorWeb.YearLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Year
  alias Accumulator.Year.Log

  on_mount {AccumulatorWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    year = 2026
    today = DateTime.now!("Asia/Kolkata") |> DateTime.to_date()

    days_in_year = if Date.leap_year?(Date.new!(year, 1, 1)), do: 366, else: 365

    days_elapsed =
      if today.year == year do
        diff = Date.diff(today, Date.new!(year, 1, 1))
        if diff > 0, do: diff, else: 0
      else
        if today.year > year do
          days_in_year
        else
          0
        end
      end

    days_remaining = days_in_year - days_elapsed
    percentage_left = Float.round(days_remaining / days_in_year * 100, 0) |> trunc()

    start_of_year = Date.new!(year, 1, 1)
    logged_dates = Year.logged_dates(year)

    socket =
      socket
      |> assign(:page_title, "2026")
      |> assign(:year, year)
      |> assign(:start_of_year, start_of_year)
      |> assign(:days_in_year, days_in_year)
      |> assign(:days_elapsed, days_elapsed)
      |> assign(:days_remaining, days_remaining)
      |> assign(:percentage_left, percentage_left)
      |> assign(:logged_dates, logged_dates)
      |> assign(:selected_log, nil)
      |> assign(:show_modal, false)
      |> assign(:form, to_form(Year.change_log(%Log{}, %{})))

    {:ok, socket}
  end

  defp day_has_log?(logged_dates, start_of_year, day) do
    date = Date.add(start_of_year, day - 1)
    MapSet.member?(logged_dates, date)
  end

  defp day_to_date(start_of_year, day) do
    Date.add(start_of_year, day - 1)
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d")
  end

  defp dot_class(day, days_elapsed, logged_dates, start_of_year) do
    cond do
      day > days_elapsed ->
        "bg-white cursor-default"

      day_has_log?(logged_dates, start_of_year, day) ->
        "bg-[#5db37f] cursor-pointer hover:bg-[#5db37f]/80"

      true ->
        "bg-[#116a34] cursor-pointer hover:bg-[#1a8d47]"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="font-mono">
      <div class="flex flex-wrap gap-2">
        <div
          :for={day <- 1..@days_in_year}
          class={[
            "p-2 rounded-full relative group transition-colors",
            dot_class(day, @days_elapsed, @logged_dates, @start_of_year)
          ]}
          phx-click={day <= @days_elapsed && "select_day"}
          phx-value-day={day}
        >
          <div
            :if={day <= @days_elapsed}
            class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-zinc-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-10"
          >
            {format_date(day_to_date(@start_of_year, day))}
          </div>
        </div>
      </div>
      <div class="mt-20">
        <span class="tracking-wide">{@year}</span>
        <span class="tracking-tight">{@percentage_left}% left</span>
      </div>
      <button
        :if={@current_user}
        phx-click={show_modal("log-modal")}
      >
        Add log
      </button>

      <div :if={@selected_log} class="mt-8 p-4 bg-zinc-900">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-[#5db37f]">
            {format_date(@selected_log.logged_on)}
          </h3>
          <button
            phx-click="clear_selection"
            class="text-zinc-500 hover:text-white transition-colors"
          >
            <Heroicons.x_mark class="w-5 h-5" />
          </button>
        </div>
        <p class="text-zinc-300 whitespace-pre-wrap font-sans">{@selected_log.text || "No log entry"}</p>
      </div>

      <.modal id="log-modal" show={@show_modal} on_cancel={JS.push("close_modal")}>
        <h2 class="text-xl font-bold mb-6">Add Log</h2>
        <.simple_form
          for={@form}
          id="log-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input type="date" field={@form[:logged_on]} label="Date" phx-hook="LocalDate" />
          <.input type="textarea" field={@form[:text]} label="Log" rows="6" />
          <:actions>
            <.button phx-disable-with="Saving...">
              Save Log
            </.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"log" => log_params}, socket) do
    changeset =
      %Log{}
      |> Year.change_log(log_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"log" => log_params}, socket) do
    case Year.create_log(log_params) do
      {:ok, _log} ->
        {:noreply,
         socket
         |> put_flash(:info, "Log saved successfully!")
         |> assign(:logged_dates, Year.logged_dates(socket.assigns.year))
         |> assign(:form, to_form(Year.change_log(%Log{}, %{})))
         |> push_event("close_modal", %{to: "#log-modal"})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:form, to_form(Year.change_log(%Log{}, %{})))}
  end

  @impl true
  def handle_event("select_day", %{"day" => day_str}, socket) do
    day = String.to_integer(day_str)
    date = day_to_date(socket.assigns.start_of_year, day)
    log = Year.get_log_by_date(date)

    {:noreply, assign(socket, :selected_log, log)}
  end

  @impl true
  def handle_event("clear_selection", _, socket) do
    {:noreply, assign(socket, :selected_log, nil)}
  end
end
