defmodule AccumulatorWeb.PlantLive.FormComponent do
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

        <label class="block font-bold" for={@uploads.files.ref}>Image</label>
        <.live_file_input style="margin-top:10px;" upload={@uploads.files} />
        <div :for={entry <- @uploads.files.entries} class="flex justify-between">
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
            <%= for err <- upload_errors(@uploads.files, entry) do %>
              <p class="text-sm text-red-500">{error_to_string(err)}</p>
            <% end %>
          </div>

          <div>
            <progress class="rounded-md" value={entry.progress} max="100">
              {entry.progress}%
            </progress>
          </div>
        </div>

        <%= for err <- upload_errors(@uploads.files) do %>
          <p class="text-sm text-red-500">{error_to_string(err)}</p>
        <% end %>
        <%= for err <- @form[:image].errors do %>
          <p class="text-sm text-red-500">{translate_error(err)}</p>
        <% end %>

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
  def update(%{plant: plant} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(Plants.Plant.changeset(plant, %{})) end)
     |> allow_upload(:files,
       accept: ["image/*"],
       max_entries: 1,
       # ~30MB
       max_file_size: 30_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params}, socket) do
    changeset =
      Plants.Plant.changeset(socket.assigns.plant, plant_params)

    changeset =
      case Plants.WateringFreq.validate_watering_frequency(plant_params["watering_frequency"]) do
        {:ok, _} -> changeset
        {:error, message} -> Ecto.Changeset.add_error(changeset, :watering_frequency, message)
      end

    changeset =
      if length(socket.assigns.uploads.files.entries) != 0 do
        Ecto.Changeset.cast(changeset, %{image: "placeholder"}, [:image])
        |> Ecto.Changeset.validate_required([:image])
        |> remove_image_error_from_changeset()
      else
        changeset
      end

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"plant" => plant_params}, socket) do
    save_plant(socket, socket.assigns.action, plant_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket = cancel_upload(socket, :files, ref)

    form =
      Ecto.Changeset.cast(socket.assigns.form.source, %{image: ""}, [:image])
      |> Ecto.Changeset.validate_required([:image])
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  defp save_plant(socket, :edit, plant_params) do
    plant_params = handle_upload(plant_params, socket)

    with {:ok, plant} <- Plants.update_plant(socket.assigns.plant, plant_params),
         {:ok, plant} <- Plants.update_next_water_date(plant) do
      notify_parent({:saved, plant})

      {:noreply,
       socket
       |> put_flash(:info, "Plant updated successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_plant(socket, :new, plant_params) do
    plant_params = handle_upload(plant_params, socket)

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

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp handle_upload(plant_params, socket) do
    storage_directory = if files_present?(socket), do: get_storage_dir()

    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
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

    if length(uploaded_files) != 0 do
      image_path = Enum.at(uploaded_files, 0).access_path
      Map.put_new(plant_params, "image", image_path)
    else
      plant_params
    end
  end

  defp files_present?(socket) do
    case uploaded_entries(socket, :files) do
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

  defp remove_image_error_from_changeset(%Ecto.Changeset{errors: errors} = changeset) do
    remaining_errors = Enum.reject(errors, fn {key, _} -> key == :image end)
    %{changeset | errors: remaining_errors, valid?: remaining_errors == []}
  end
end
