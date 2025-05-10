defmodule AccumulatorWeb.PageController do
  use AccumulatorWeb, :controller

  alias Accumulator.Redirect

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> put_layout(html: {AccumulatorWeb.Layouts, :home})
    |> render(:home)
  end

  def redirect(conn, params) do
    if Map.get(params, "p") == nil do
      render(conn, :redirect, %{error: nil, page_title: "Redirect"})
    else
      case Redirect.get_url(params) do
        {:ok, url} ->
          Phoenix.Controller.redirect(conn, external: url)

        {:error, message} ->
          render(conn, :redirect, %{error: message, page_title: "Redirect"})
      end
    end
  end
end
