defmodule AccumulatorWeb.PhotoController do
  use AccumulatorWeb, :controller

  alias Accumulator.Photos

  def index(conn, _params) do
    render(conn, :index, photos: Photos.list_photos())
  end
end
