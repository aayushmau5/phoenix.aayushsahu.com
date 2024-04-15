defmodule AccumulatorWeb.NotesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Note}

  @impl true
  def mount(_params, _session, socket) do
    form =
      %Note{}
      |> Ecto.Changeset.change()
      |> to_form()

    socket =
      if connected?(socket) do
        notes = Notes.get_by_ascending_order()
        stream(socket, :notes, notes)
      else
        stream(socket, :notes, [])
      end

    {:ok,
     socket
     |> assign(form: form)
     |> assign(search: to_form(%{"search" => ""}))}
  end

  @impl true
  def handle_event("validate", %{"note" => note_params} = _params, socket) do
    note_changeset = %Note{} |> Note.changeset(note_params)

    form =
      note_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"note" => note_params} = _params, socket) do
    socket =
      case Notes.insert(note_params) do
        {:ok, note} ->
          form = %Note{} |> Note.changeset() |> to_form()

          socket
          |> assign(form: form)
          |> stream_insert(:notes, note)

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search-change", _params, socket) do
    # Do nothing with the search bar change rn
    {:noreply, socket}
  end

  @impl true
  def handle_event("search-submit", %{"search" => search} = _params, socket) do
    # TODO: implement search functionality
    IO.inspect(search, label: "Search")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-2">
        <.simple_form for={@search} phx-change="search-change" phx-submit="search-submit">
          <.input field={@search[:search]} class="bg-transparent" />
        </.simple_form>
      </div>
      <div class="bg-black bg-opacity-20 p-2 rounded-md" id="notes" phx-update="stream">
        <div
          :for={{dom_id, note} <- @streams.notes}
          class="bg-[#1f1f1f] my-2 p-2 rounded-md"
          id={dom_id}
        >
          <div><%= note.text %></div>
        </div>
      </div>
      <div>
        <.simple_form for={@form} phx-change="validate" phx-submit="save">
          <.input field={@form[:text]} />
          <%!-- <.input field={@form[:files]} label="File" /> --%>
          <:actions>
            <.button>Save</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
