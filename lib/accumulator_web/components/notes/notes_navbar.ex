defmodule AccumulatorWeb.Components.Notes.NotesNavbar do
  use AccumulatorWeb, :html

  alias AccumulatorWeb.CoreComponents
  import Phoenix.Component

  attr :current_user, :map, required: true
  attr :workspaces, :list, default: []
  attr :selected_workspace, :map, default: nil

  def notes_navbar(assigns) do
    ~H"""
    <nav class="relative z-50">
      <button
        phx-click={
          JS.toggle_attribute({"style", "display: flex;", "display: none;"},
            to: "#navbar"
          )
        }
        type="button"
        class="fixed top-0 p-2 ml-3 text-sm text-gray-500 rounded-lg focus:outline-none z-10"
        aria-controls="navbar"
        aria-expanded="false"
      >
        <svg class="w-6 h-6" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
            clip-rule="evenodd"
          >
          </path>
        </svg>
      </button>

      <div
        class="bg-[#26282a] w-content h-screen fixed flex-col overflow-y-auto justify-between"
        style="display: none;"
        id="navbar"
      >
        <div class="p-4 mt-5">
          <ul class="mb-6">
            <CoreComponents.navbar_link to={~p"/"} label="phoenix.aayushsahu.com" />
            <CoreComponents.navbar_link to={~p"/dashboard"} label="dashboard" />
            <CoreComponents.navbar_link to={~p"/spotify"} label="spotify" />
            <CoreComponents.navbar_link to={~p"/redirect"} label="redirect" />
            <CoreComponents.navbar_link :if={@current_user} to={~p"/bin"} label="bin" />
            <CoreComponents.navbar_link :if={@current_user} to={~p"/notes"} label="notes" />
            <CoreComponents.navbar_link
              :if={!@current_user}
              to={~p"/notes/public/default"}
              label="notes"
            />
            <CoreComponents.navbar_link :if={@current_user} to={~p"/sessions"} label="session" />
            <CoreComponents.navbar_link
              :if={@current_user}
              to={~p"/livedashboard"}
              label="livedashboard"
            />
            <CoreComponents.navbar_link :if={@current_user} to={~p"/plants"} label="plants" />
          </ul>

          <%= if @workspaces && length(@workspaces) > 0 do %>
            <div class="border-t border-gray-700 pt-4 mb-4">
              <h3 class="text-gray-400 font-semibold mb-2">Workspaces</h3>
              <ul>
                <li :for={workspace <- @workspaces} class="my-1" id={"workspace-#{workspace.id}"}>
                  <.link
                    navigate={~p"/notes/#{workspace.id}"}
                    class={"block p-2 rounded text-sm #{if @selected_workspace && workspace.id == @selected_workspace.id, do: "bg-[#373739] text-white", else: "text-gray-400 hover:bg-[#373739]"}"}
                  >
                    {workspace.title}
                    <%= if workspace.is_public do %>
                      <span class="inline-block ml-1">
                        <Heroicons.globe_europe_africa class="h-3 w-3 inline" />
                      </span>
                    <% end %>
                  </.link>
                </li>
              </ul>
            </div>
          <% end %>
        </div>

        <div class="text-right mr-4 mt-auto mb-4">
          <%= if @current_user do %>
            <div>{@current_user.email}</div>
            <.link
              href="/logout"
              method="delete"
              class="text-white font-semibold hover:text-[#6CFACD]"
            >
              Log out
            </.link>
          <% else %>
            <.link href="/login" class="text-white font-semibold hover:text-[#6CFACD]">
              Log in
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
