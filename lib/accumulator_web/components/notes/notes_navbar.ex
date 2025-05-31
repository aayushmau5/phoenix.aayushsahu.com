defmodule AccumulatorWeb.Components.Notes.NotesNavbar do
  use AccumulatorWeb, :html

  import Phoenix.Component

  attr :current_user, :map, required: true
  attr :workspaces, :list, default: []
  attr :selected_workspace, :map, default: nil

  def notes_navbar(assigns) do
    ~H"""
    <nav class="relative z-50">
      <button
        phx-click={
          JS.toggle(
            to: "#navbar",
            in:
              {"transition ease-out duration-300", "opacity-0 -translate-x-full",
               "opacity-100 translate-x-0"},
            out:
              {"transition ease-in duration-200", "opacity-100 translate-x-0",
               "opacity-0 -translate-x-full"}
          )
          |> JS.toggle(
            to: "#navbar-overlay",
            in: {"transition ease-out duration-300", "opacity-0", "opacity-100"},
            out: {"transition ease-in duration-200", "opacity-100", "opacity-0"}
          )
        }
        id="navbar-toggle"
        type="button"
        class="fixed top-0 p-2 ml-3 text-sm text-gray-400 hover:text-white rounded-lg z-10 duration-200"
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
        id="navbar-overlay"
        class="fixed inset-0 bg-black bg-opacity-50 z-40 hidden"
        phx-click={
          JS.toggle(
            to: "#navbar",
            in:
              {"transition ease-out duration-300", "opacity-0 -translate-x-full",
               "opacity-100 translate-x-0"},
            out:
              {"transition ease-in duration-200", "opacity-100 translate-x-0",
               "opacity-0 -translate-x-full"}
          )
          |> JS.toggle(
            to: "#navbar-overlay",
            in: {"transition ease-out duration-300", "opacity-0", "opacity-100"},
            out: {"transition ease-in duration-200", "opacity-100", "opacity-0"}
          )
        }
        aria-hidden="true"
      >
      </div>

      <div
        id="navbar"
        class="bg-[#26282a] w-72 md:w-64 h-screen fixed top-0 left-0 flex flex-col overflow-y-auto justify-between z-50 hidden opacity-0 transform"
        phx-click-away={
          JS.toggle(
            to: "#navbar",
            in:
              {"transition ease-out duration-300", "opacity-0 -translate-x-full",
               "opacity-100 translate-x-0"},
            out:
              {"transition ease-in duration-200", "opacity-100 translate-x-0",
               "opacity-0 -translate-x-full"}
          )
          |> JS.toggle(
            to: "#navbar-overlay",
            in: {"transition ease-out duration-300", "opacity-0", "opacity-100"},
            out: {"transition ease-in duration-200", "opacity-100", "opacity-0"}
          )
        }
        role="navigation"
        aria-labelledby="navbar-toggle"
      >
        <div class="p-4 mt-5">
          <div class="mb-2 px-2 flex items-center">
            <button
              type="button"
              class="ml-auto p-1 text-gray-400 hover:text-white rounded-lg focus:ring-2 focus:ring-gray-600 focus:outline-none"
              aria-label="Close menu"
              phx-click={
                JS.toggle(
                  to: "#navbar",
                  in:
                    {"transition ease-out duration-300", "opacity-0 -translate-x-full",
                     "opacity-100 translate-x-0"},
                  out:
                    {"transition ease-in duration-200", "opacity-100 translate-x-0",
                     "opacity-0 -translate-x-full"}
                )
                |> JS.toggle(
                  to: "#navbar-overlay",
                  in: {"transition ease-out duration-300", "opacity-0", "opacity-100"},
                  out: {"transition ease-in duration-200", "opacity-100", "opacity-0"}
                )
              }
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <ul class="mb-6 space-y-1">
            <.navbar_link to={~p"/"}>
              🌳 home
            </.navbar_link>
            <.navbar_link to={~p"/dashboard"}>
              📈 dashboard
            </.navbar_link>
            <.navbar_link to={~p"/spotify"}>
              🎵 spotify
            </.navbar_link>
            <.navbar_link to={~p"/redirect"}>
              🔗 redirect
            </.navbar_link>
            <.navbar_link :if={@current_user} to={~p"/bin"}>
              🚮 bin
            </.navbar_link>
            <.navbar_link :if={@current_user} to={~p"/notes"}>
              📓 notes
            </.navbar_link>
            <.navbar_link :if={!@current_user} to={~p"/notes/public/default"}>
              📓 notes
            </.navbar_link>
            <.navbar_link :if={@current_user} to={~p"/sessions"}>
              🌐 session
            </.navbar_link>
            <.navbar_link :if={@current_user} to={~p"/livedashboard"}>
              💻 livedashboard
            </.navbar_link>
            <.navbar_link :if={@current_user} to={~p"/plants"}>
              🪴 plants
            </.navbar_link>
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

        <div class="p-4 mt-auto mb-4 border-t border-gray-700">
          <%= if @current_user do %>
            <div class="text-sm text-gray-300 truncate mb-2">{@current_user.email}</div>
            <.link
              href="/logout"
              method="delete"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-gray-700 hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 transition-colors duration-200 w-full justify-center"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
                />
              </svg>
              Log out
            </.link>
          <% else %>
            <.link
              href="/login"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-gray-700 hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 transition-colors duration-200 w-full justify-center"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"
                />
              </svg>
              Log in
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
