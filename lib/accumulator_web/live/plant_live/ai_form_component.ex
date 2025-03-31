defmodule AccumulatorWeb.PlantLive.AIFormComponent do
  use AccumulatorWeb, :live_component

  alias Accumulator.Plants

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        :if={@type == :image_upload}
        for={@image_form}
        id="image-form"
        phx-target={@myself}
        phx-change="image-validate"
        phx-submit="image-save"
      >
        <label class="block font-bold" for={@uploads.image.ref}>Image</label>
        <.live_file_input style="margin-top:10px;" upload={@uploads.image} />
        <div :for={entry <- @uploads.image.entries} class="flex justify-between">
          <div>
            <div>{entry.client_name}</div>
            <div class="text-sm opacity-30">{entry.client_type}</div>
            <button
              type="button"
              phx-target={@myself}
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              class="block text-sm"
            >
              Cancel
            </button>
            <%= for err <- upload_errors(@uploads.image, entry) do %>
              <p class="text-sm text-red-500">{error_to_string(err)}</p>
            <% end %>
          </div>

          <div>
            <progress class="rounded-md" value={entry.progress} max="100">
              {entry.progress}%
            </progress>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Uploading...">
            Upload Image
          </.button>
        </:actions>
      </.simple_form>

      <div :if={@type == :processing} class="text-center">Processing Image...</div>

      <div :if={@type == :error} class="text-center text-red-500">{@ai_error}</div>

      <img :if={@type == :form} src={@image_url} class="h-64 w-auto mx-auto" />

      <.simple_form
        :if={@type == :form}
        for={@form}
        id="plant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input type="textarea" field={@form[:info]} label="Info" />
        <.input type="textarea" field={@form[:care]} label="Care" />
        <.input field={@form[:watering_frequency]} label="Watering Frequency" />
        <.input type="date" field={@form[:watered_on]} label="Watered On" />
        <.input field={@form[:potting_notes]} label="Potting Notes" />

        <:actions>
          <.button
            phx-disable-with="Saving..."
            disabled={length(@form.errors) !== 0}
            class="disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Save Plant
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{ai_result: result} = _assigns, socket) do
    socket =
      case result do
        {:ok, params} ->
          changeset = Plants.Plant.changeset(socket.assigns.plant, params)
          assign(socket, type: :form, form: to_form(changeset, action: :validate))

        {:error, error} ->
          assign(socket, type: :error, ai_error: error)
      end

    {:ok, socket}
  end

  def update(%{plant: plant} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:image_form, to_form(%{"image" => ""}))
     |> assign(:form, to_form(Plants.Plant.changeset(plant, %{})))
     |> assign(:type, :image_upload)
     |> assign(:image_url, nil)
     |> assign(:ai_error, nil)
     |> allow_upload(:image,
       accept: ["image/*"],
       max_entries: 1,
       max_file_size: 30_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params}, socket) do
    plant_params = Map.put_new(plant_params, "image", socket.assigns.image_url)
    changeset = Plants.Plant.changeset(socket.assigns.plant, plant_params)

    changeset =
      case Plants.WateringFreq.validate_watering_frequency(plant_params["watering_frequency"]) do
        {:ok, _} -> changeset
        {:error, message} -> Ecto.Changeset.add_error(changeset, :watering_frequency, message)
      end

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"plant" => plant_params}, socket) do
    plant_params = Map.put_new(plant_params, "image", socket.assigns.image_url)

    with {:ok, plant} <- Plants.create_plant(plant_params),
         {:ok, plant} <- Plants.update_next_water_date(plant) do
      notify_parent({:saved, plant})

      {:noreply,
       socket
       |> put_flash(:info, "Plant created successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("image-validate", _params, socket), do: {:noreply, socket}

  def handle_event("image-save", _params, socket) do
    image = handle_upload(socket)

    pid = self()
    component_id = socket.assigns.id

    Task.start(fn ->
      encoded_image = File.read!(image.storage_path) |> Base.encode64()
      result = Plants.AI.run(encoded_image)
      send(pid, {:ai_processing_result, component_id, result})
    end)

    {:noreply, assign(socket, type: :processing, image_url: image.access_path)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket = cancel_upload(socket, :image, ref)
    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp handle_upload(socket) do
    storage_directory = if files_present?(socket), do: get_storage_dir()

    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        %{client_name: file_name, client_type: file_type} = entry
        santized_filename = Zarex.sanitize(file_name)

        dest = Path.join([storage_directory, santized_filename])
        File.cp!(path, dest)

        {:ok,
         %{
           name: santized_filename,
           type: file_type,
           storage_path: dest,
           access_path:
             "/uploads/#{Path.join(Path.basename(storage_directory), santized_filename)}"
         }}
      end)

    Enum.at(uploaded_files, 0)
  end

  defp files_present?(socket) do
    case uploaded_entries(socket, :image) do
      {[], []} -> false
      _ -> true
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp get_storage_dir() do
    storage_directory = Path.join([Application.fetch_env!(:accumulator, :upload_dir), "plants"])

    if File.exists?(storage_directory),
      do: storage_directory,
      else: create_storage_dir(storage_directory)
  end

  defp create_storage_dir(dir) do
    :ok = File.mkdir(dir)
    dir
  end
end
