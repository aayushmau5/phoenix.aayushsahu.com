defmodule AccumulatorWeb.SpotifyComponents do
  @moduledoc """
  Components for Spotify data.
  """
  use Phoenix.Component

  attr :now_playing, :any, required: true

  def now_playing(%{now_playing: nil} = assigns) do
    ~H"""
    <div>
      Loading...
    </div>
    """
  end

  def now_playing(%{now_playing: {:not_playing, _}} = assigns) do
    assigns = assign(assigns, :message, assigns.now_playing |> elem(1))

    ~H"""
    <div>
      <%= @message %>
    </div>
    """
  end

  def now_playing(%{now_playing: {:error, _}} = assigns) do
    ~H"""
    <div>
      Failed to fetch currently playing song
    </div>
    """
  end

  def now_playing(assigns) do
    assigns = assign(assigns, :track, assigns.now_playing |> elem(1))

    ~H"""
    <a
      href={@track["url"]}
      target="_blank"
      rel="noreferrer"
      class="flex gap-4 items-center p-4 rounded-md bg-opacity-30 bg-black hover:bg-opacity-40"
    >
      <div class="w-max">
        <.spotify_logo height="40px" width="auto" />
      </div>
      <div>
        <p class=""><%= @track["name"] %></p>
        <p class="text-sm text-gray-400 my-1"><%= @track["artists"] %></p>
        <p class="text-sm text-gray-400"><%= @track["album_name"] %></p>
      </div>
    </a>
    """
  end

  attr :tracks, :list

  def top_tracks(%{tracks: nil} = assigns) do
    ~H"""
    <div>
      Loading...
    </div>
    """
  end

  def top_tracks(%{tracks: {:error, _}} = assigns) do
    ~H"""
    <div>
      Failed to fetch top tracks
    </div>
    """
  end

  def top_tracks(assigns) do
    assigns = assign(assigns, :tracks, assigns.tracks |> elem(1))

    ~H"""
    <div class="flex flex-wrap gap-4 justify-between items-center">
      <%= for track <- @tracks do %>
        <a
          href={track["url"]}
          target="_blank"
          rel="noreferrer"
          class="w-52 flex items-center justify-center hover:bg-black hover:bg-opacity-30 rounded-md"
        >
          <div class="p-3 w-max">
            <img class="h-48 w-auto" src={track["album_image_url"]} />
            <p class="mt-2"><%= track["name"] %></p>
            <p class="text-sm text-gray-400 my-1"><%= track["artists"] %></p>
            <p class="text-sm text-gray-400"><%= track["album_name"] %></p>
          </div>
        </a>
      <% end %>
    </div>
    """
  end

  attr :artists, :list

  def top_artists(%{artists: nil} = assigns) do
    ~H"""
    <div>
      Loading...
    </div>
    """
  end

  def top_artists(%{artists: {:error, _}} = assigns) do
    ~H"""
    <div>
      Failed to fetch top artists
    </div>
    """
  end

  def top_artists(assigns) do
    assigns = assign(assigns, :artists, assigns.artists |> elem(1))

    ~H"""
    <div class="flex flex-wrap gap-4 justify-between items-center">
      <%= for artist <- @artists do %>
        <a
          href={artist["url"]}
          target="_blank"
          rel="noreferrer"
          class="w-52 flex items-center justify-center hover:bg-black hover:bg-opacity-30 rounded-md"
        >
          <div class="p-3 w-max">
            <img class="h-48 w-auto" src={artist["image_url"]} />
            <p class="mt-2"><%= artist["name"] %></p>
          </div>
        </a>
      <% end %>
    </div>
    """
  end

  attr :width, :string, default: "20px"
  attr :height, :string, default: "20px"

  def spotify_logo(assigns) do
    ~H"""
    <svg viewBox="0 0 2931 2931" width={@width} height={@height}>
      <style>
        .st0{fill:#2ebd59}
      </style>
      <path
        class="st0"
        d="M1465.5 0C656.1 0 0 656.1 0 1465.5S656.1 2931 1465.5 2931 2931 2274.9 2931 1465.5C2931 656.2 2274.9.1 1465.5 0zm672.1 2113.6c-26.3 43.2-82.6 56.7-125.6 30.4-344.1-210.3-777.3-257.8-1287.4-141.3-49.2 11.3-98.2-19.5-109.4-68.7-11.3-49.2 19.4-98.2 68.7-109.4C1242.1 1697.1 1721 1752 2107.3 1988c43 26.5 56.7 82.6 30.3 125.6zm179.3-398.9c-33.1 53.8-103.5 70.6-157.2 37.6-393.8-242.1-994.4-312.2-1460.3-170.8-60.4 18.3-124.2-15.8-142.6-76.1-18.2-60.4 15.9-124.1 76.2-142.5 532.2-161.5 1193.9-83.3 1646.2 194.7 53.8 33.1 70.8 103.4 37.7 157.1zm15.4-415.6c-472.4-280.5-1251.6-306.3-1702.6-169.5-72.4 22-149-18.9-170.9-91.3-21.9-72.4 18.9-149 91.4-171 517.7-157.1 1378.2-126.8 1922 196 65.1 38.7 86.5 122.8 47.9 187.8-38.5 65.2-122.8 86.7-187.8 48z"
      />
    </svg>
    """
  end
end
