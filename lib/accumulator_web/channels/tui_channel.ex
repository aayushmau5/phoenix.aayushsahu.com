defmodule AccumulatorWeb.TUIChannel do
  use AccumulatorWeb, :channel

  alias Accumulator.{Comments, Contact, Notes, Pastes, Stats, TUI, TUI.Payload}
  alias Accumulator.Notes.Note
  alias Accumulator.Pastes.Paste
  alias Accumulator.PubSub.Messages.Comments.Changed, as: CommentsChanged
  alias Accumulator.PubSub.Messages.Notes.Changed, as: NotesChanged
  alias Accumulator.PubSub.Messages.Paste, as: PasteMsg
  alias EhaPubsubMessages.Presence.{BlogPresence, SitePresence}
  alias EhaPubsubMessages.Stats.{BlogUpdated, SiteUpdated}
  alias EhaPubsubMessages.Topics
  alias PubSubContract.Bus

  @impl true
  def join(_room_id, _payload, socket) do
    if authorized?(socket) do
      subscribe_to_updates()
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Stats

  def handle_in("stats", %{"action" => "get-all"}, socket) do
    data = stats_data()

    response = %TUI{name: "stats", payload: %Payload{action: "get-all", data: data}}
    {:reply, {:ok, response}, socket}
  end

  # Daily Stats

  def handle_in("daily-stats", %{"action" => "get-all"} = payload, socket) do
    options = Map.get(payload, "data", %{})
    slug = daily_stats_slug(options)
    days = daily_stats_days(options)

    data = %{
      slug: slug,
      days: days,
      stats:
        slug
        |> Stats.get_daily_stats_for_last_n_days(days)
        |> Enum.map(&daily_stat_data/1)
    }

    response = %TUI{name: "daily-stats", payload: %Payload{action: "get-all", data: data}}
    {:reply, {:ok, response}, socket}
  end

  # Devices

  def handle_in("devices", %{"action" => "get-all"}, socket) do
    data = Stats.get_user_agent_stats()
    response = %TUI{name: "devices", payload: %Payload{action: "get-all", data: data}}
    {:reply, {:ok, response}, socket}
  end

  # Notes

  def handle_in("notes", %{"action" => "get-workspaces"}, socket) do
    workspaces = Notes.get_all_workspaces() |> Enum.map(&workspace_data/1)
    tui_reply(socket, "notes", "get-workspaces", workspaces)
  end

  def handle_in(
        "notes",
        %{"action" => "get-all", "data" => %{"workspace_id" => workspace_id}},
        socket
      ) do
    with workspace_id when not is_nil(workspace_id) <- integer_id(workspace_id),
         workspace when not is_nil(workspace) <- Notes.get_workspace(workspace_id) do
      data = %{
        workspace: workspace_data(workspace),
        notes: notes_for_workspace(workspace_id)
      }

      tui_reply(socket, "notes", "get-all", data)
    else
      _ -> error_reply(socket, "Workspace not found")
    end
  end

  def handle_in("notes", %{"action" => "get", "data" => %{"id" => id}}, socket) do
    case find_note(id) do
      nil -> error_reply(socket, "Note not found")
      note -> tui_reply(socket, "notes", "get", note_data(note))
    end
  end

  def handle_in("notes", %{"action" => "new", "data" => data}, socket) do
    workspace_id = integer_id(Map.get(data, "workspace_id"))
    text = Map.get(data, "text")

    if is_integer(workspace_id) and is_binary(text) and String.trim(text) != "" do
      params = %{"workspace_id" => workspace_id, "text" => text}

      case %Note{} |> Note.changeset(params) |> Notes.insert() do
        {:ok, note} ->
          Notes.broadcast!(%{type: :new_note, workspace_id: note.workspace_id})
          tui_reply(socket, "notes", "new", note_data(note))

        {:error, changeset} ->
          changeset_error_reply(socket, changeset)
      end
    else
      error_reply(socket, "workspace_id and non-empty text are required")
    end
  end

  def handle_in("notes", %{"action" => "edit", "data" => %{"id" => id} = data}, socket) do
    case find_note(id) do
      nil ->
        error_reply(socket, "Note not found")

      note ->
        params =
          data
          |> Map.take(["text", "workspace_id"])
          |> normalize_workspace_id()

        case Notes.update_note(note.id, params) do
          {:ok, updated_note} ->
            Notes.broadcast!(%{type: :update_note, workspace_id: updated_note.workspace_id})
            tui_reply(socket, "notes", "edit", note_data(updated_note))

          {:error, changeset} ->
            changeset_error_reply(socket, changeset)
        end
    end
  end

  def handle_in("notes", %{"action" => "delete", "data" => %{"id" => id}}, socket) do
    case find_note(id) do
      nil ->
        error_reply(socket, "Note not found")

      note ->
        case Notes.delete_note(note.id) do
          {:ok, _deleted_note} ->
            Notes.broadcast!(%{type: :delete_note, workspace_id: note.workspace_id})
            tui_reply(socket, "notes", "delete", %{id: note.id})

          {:error, changeset} ->
            changeset_error_reply(socket, changeset)
        end
    end
  end

  # Comments

  def handle_in(
        "comments",
        %{"action" => "get-all", "data" => %{"blog_slug" => blog_slug}},
        socket
      )
      when is_binary(blog_slug) do
    comments = Comments.list_comments_with_nested_replies(blog_slug)
    tui_reply(socket, "comments", "get-all", Enum.map(comments, &comment_data/1))
  end

  def handle_in("comments", %{"action" => "reply", "data" => data}, socket) do
    blog_slug = Map.get(data, "blog_slug")
    parent_id = integer_id(Map.get(data, "parent_id"))
    content = Map.get(data, "content")

    case find_comment(parent_id) do
      %{blog_slug: ^blog_slug} when is_binary(content) ->
        attrs = %{
          "author" => Map.get(data, "author", "Aayush"),
          "blog_slug" => blog_slug,
          "content" => content,
          "parent_id" => parent_id
        }

        case Comments.create_comment(attrs) do
          {:ok, comment} -> tui_reply(socket, "comments", "reply", comment_data(comment))
          {:error, changeset} -> changeset_error_reply(socket, changeset)
        end

      _ ->
        error_reply(socket, "Parent comment not found")
    end
  end

  def handle_in("comments", %{"action" => "edit", "data" => %{"id" => id} = data}, socket) do
    case find_comment(id) do
      nil ->
        error_reply(socket, "Comment not found")

      comment ->
        attrs = Map.take(data, ["content", "author"])

        case Comments.update_comment(comment, attrs) do
          {:ok, updated_comment} ->
            tui_reply(socket, "comments", "edit", comment_data(updated_comment))

          {:error, changeset} ->
            changeset_error_reply(socket, changeset)
        end
    end
  end

  def handle_in("comments", %{"action" => "delete", "data" => %{"id" => id}}, socket) do
    case find_comment(id) do
      nil ->
        error_reply(socket, "Comment not found")

      comment ->
        case Comments.delete_comment(comment) do
          {:ok, _deleted_comment} ->
            tui_reply(socket, "comments", "delete", %{id: comment.id})

          {:error, changeset} ->
            changeset_error_reply(socket, changeset)
        end
    end
  end

  # Contact Messages (read-only)

  def handle_in("contact-messages", %{"action" => "get-all"}, socket) do
    messages = Contact.list_messages() |> Enum.map(&contact_message_data/1)
    tui_reply(socket, "contact-messages", "get-all", messages)
  end

  # Bin

  def handle_in("bin", %{"action" => "get-all"} = _payload, socket) do
    pastes = Pastes.get_all_pastes()
    response = %TUI{name: "bin", payload: %Payload{action: "get-all", data: pastes}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "new", "data" => data} = _payload, socket) do
    expire_map = Map.get(data, "expire")

    paste_params = %{
      title: Map.get(data, "title"),
      content: Map.get(data, "content"),
      time_duration: Map.get(expire_map, "time"),
      time_type: Map.get(expire_map, "unit") |> String.downcase()
    }

    paste_changeset =
      %Paste{}
      |> Paste.changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        get_expiration_time(paste_params.time_duration, paste_params.time_type)
      )
      |> Ecto.Changeset.put_embed(:files, [])

    data =
      case Pastes.add_paste(paste_changeset) do
        :ok -> %{status: "OK"}
        {:error, _} -> %{status: "ERROR", message: "Failed to create paste"}
      end

    response = %TUI{name: "bin", payload: %Payload{action: "new", data: data}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "delete", "data" => data} = _payload, socket) do
    bin_id = Map.get(data, "id")

    data =
      case Pastes.delete_paste(bin_id) do
        {:error, _} -> %{status: "ERROR", message: "Failed to delete paste"}
        _ -> %{status: "OK"}
      end

    response = %TUI{name: "bin", payload: %Payload{action: "delete", data: data}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "edit", "data" => data} = _payload, socket) do
    expire_map = Map.get(data, "expire")

    paste_params =
      %{
        title: Map.get(data, "title"),
        content: Map.get(data, "content"),
        time_duration: Map.get(expire_map, "time"),
        time_type: Map.get(expire_map, "unit") |> String.downcase()
      }

    bin_id = Map.get(data, "id")
    paste = Pastes.get_paste(bin_id)

    deleted_files =
      Map.get(data, "files")
      |> Enum.filter(&(Map.get(&1, "removed") == true))
      |> Enum.map(&Map.get(&1, "file"))

    deleted_files =
      Enum.filter(paste.files, fn file ->
        Enum.any?(deleted_files, fn f -> Map.get(f, "id") == file.id end)
      end)

    present_files =
      Map.get(data, "files")
      |> Enum.filter(&(Map.get(&1, "removed") !== true))
      |> Enum.map(&Map.get(&1, "file"))

    files = update_files(paste.files, present_files)

    updated_paste =
      paste
      |> Paste.update_changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        extend_expiration_time(
          paste.expire_at,
          paste_params.time_duration,
          paste_params.time_type
        )
      )
      |> Ecto.Changeset.put_embed(:files, files)
      |> Pastes.update_existing_paste()

    data =
      case updated_paste do
        {:ok, paste} ->
          Pastes.cleanup_files(deleted_files)
          Bus.publish(Accumulator.PubSub, PasteMsg.Updated.new!(paste_id: paste.id))
          paste

        {:error, _} ->
          paste
      end

    response = %TUI{name: "bin", payload: %Payload{action: "edit", data: data}}
    {:reply, {:ok, response}, socket}
  end

  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in(_event, _payload, socket) do
    error_reply(socket, "Unsupported channel request")
  end

  @impl true
  def handle_info(%NotesChanged{type: type, workspace_id: workspace_id}, socket) do
    push(socket, "notes-changed", %{action: type, workspace_id: workspace_id})
    {:noreply, socket}
  end

  def handle_info(%CommentsChanged{type: type, blog_slug: blog_slug, comment_id: comment_id}, socket) do
    push(socket, "comment-#{type}", %{blog_slug: blog_slug, id: comment_id})
    {:noreply, socket}
  end

  def handle_info(%PasteMsg.Created{}, socket) do
    push(socket, "bin-created", %{})
    {:noreply, socket}
  end

  def handle_info(%PasteMsg.Deleted{}, socket) do
    push(socket, "bin-deleted", %{})
    {:noreply, socket}
  end

  def handle_info(%PasteMsg.Updated{paste_id: paste_id}, socket) do
    push(socket, "bin-updated", %{id: paste_id})
    {:noreply, socket}
  end

  def handle_info(%SiteUpdated{visits: visits}, socket) do
    push(socket, "stats-updated", %{scope: "site", views: visits})
    {:noreply, socket}
  end

  def handle_info(
        %BlogUpdated{slug: slug, visits: visits, likes: likes, comments: comments},
        socket
      ) do
    push(socket, "stats-updated", %{
      scope: "blog",
      slug: slug,
      views: visits,
      likes: likes,
      comments: length(comments)
    })

    {:noreply, socket}
  end

  def handle_info(%SitePresence{count: count}, socket) do
    push(socket, "presence-updated", %{scope: "site", count: count})
    {:noreply, socket}
  end

  def handle_info(%BlogPresence{slug: slug, count: count}, socket) do
    push(socket, "presence-updated", %{scope: "blog", slug: slug, count: count})
    {:noreply, socket}
  end

  defp authorized?(socket), do: socket.assigns[:tui_authenticated] == true

  defp subscribe_to_updates do
    Notes.subscribe()
    Comments.subscribe()
    Pastes.subscribe()
    Bus.subscribe(Accumulator.PubSub, PasteMsg.Updated)
    Bus.subscribe(EventHorizon.PubSub, SiteUpdated)
    Bus.subscribe(EventHorizon.PubSub, SitePresence)

    Stats.get_all_blogs_data()
    |> Enum.map(&String.replace_prefix(&1.slug, "blog:", ""))
    |> then(&["battleship" | &1])
    |> Enum.uniq()
    |> Enum.each(fn slug ->
      Bus.subscribe(EventHorizon.PubSub, Topics.blog_stats(slug: slug))
    end)
  end

  defp tui_reply(socket, name, action, data) do
    response = %TUI{name: name, payload: %Payload{action: action, data: data}}
    {:reply, {:ok, response}, socket}
  end

  defp error_reply(socket, message) do
    {:reply, {:error, %{message: message}}, socket}
  end

  defp changeset_error_reply(socket, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
        Enum.reduce(options, message, fn {key, value}, formatted_message ->
          String.replace(formatted_message, "%{#{key}}", to_string(value))
        end)
      end)

    {:reply, {:error, %{errors: errors}}, socket}
  end

  defp integer_id(value) when is_integer(value) and value > 0, do: value

  defp integer_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> id
      _ -> nil
    end
  end

  defp integer_id(_value), do: nil

  defp find_note(id) do
    case integer_id(id) do
      nil -> nil
      note_id -> Notes.get_note(note_id)
    end
  end

  defp find_comment(id) do
    case integer_id(id) do
      nil -> nil
      comment_id -> Comments.get_comment(comment_id)
    end
  end

  defp normalize_workspace_id(%{"workspace_id" => workspace_id} = params) do
    Map.put(params, "workspace_id", integer_id(workspace_id))
  end

  defp normalize_workspace_id(params), do: params

  defp notes_for_workspace(workspace_id) do
    workspace_id
    |> Notes.get_all_notes_for_workspace()
    |> Enum.flat_map(fn [_date, notes] -> notes end)
    |> Enum.map(&note_data/1)
  end

  defp note_data(note) do
    %{
      id: note.id,
      text: note.text,
      workspace_id: note.workspace_id,
      inserted_at: iso8601(note.inserted_at),
      updated_at: iso8601(note.updated_at)
    }
  end

  defp workspace_data(workspace) do
    %{
      id: workspace.id,
      title: workspace.title,
      is_public: workspace.is_public,
      inserted_at: iso8601(workspace.inserted_at),
      updated_at: iso8601(workspace.updated_at)
    }
  end

  defp comment_data(comment) do
    %{
      id: comment.id,
      content: comment.content,
      author: comment.author || "Anonymous",
      blog_slug: comment.blog_slug,
      parent_id: comment.parent_id,
      inserted_at: iso8601(comment.inserted_at),
      updated_at: iso8601(comment.updated_at),
      replies: comment_replies(comment.replies)
    }
  end

  defp comment_replies(%Ecto.Association.NotLoaded{}), do: []
  defp comment_replies(replies), do: Enum.map(replies, &comment_data/1)

  defp contact_message_data(message) do
    %{
      id: message.id,
      email: message.email,
      message: message.message,
      inserted_at: iso8601(message.inserted_at),
      updated_at: iso8601(message.updated_at)
    }
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp iso8601(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  defp stats_data do
    %{
      main: stat_data(Stats.get_main_data()),
      battleship: stat_data(Stats.get_blog_data("battleship")),
      blogs: Enum.map(Stats.get_all_blogs_data(), &blog_stat_data/1)
    }
  end

  defp stat_data(nil), do: nil

  defp stat_data(stat) do
    %{slug: stat.slug, views: stat.views, likes: stat.likes}
  end

  defp blog_stat_data(stat) do
    blog_slug = String.replace_prefix(stat.slug, "blog:", "")

    stat
    |> stat_data()
    |> Map.put(:comments, Comments.count_comments(blog_slug))
  end

  defp daily_stat_data(stat) do
    %{
      slug: stat.slug,
      date: Date.to_iso8601(stat.date),
      views: stat.views,
      likes: stat.likes
    }
  end

  defp daily_stats_slug(%{"slug" => slug}) when is_binary(slug) and slug != "", do: slug
  defp daily_stats_slug(_options), do: "main"

  defp daily_stats_days(%{"days" => days}) when is_integer(days) and days > 0,
    do: min(days, 365)

  defp daily_stats_days(_options), do: 30

  defp get_expiration_time(duration, type) do
    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(DateTime.utc_now(), duration, type) |> DateTime.truncate(:second)
  end

  defp extend_expiration_time(expiration_time, duration, type) do
    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(expiration_time, duration, type) |> DateTime.truncate(:second)
  end

  defp update_files(current_files, present_files) do
    Enum.filter(current_files, fn file ->
      present_file_id?(file.id, present_files)
    end)
  end

  defp present_file_id?(id, present_files) do
    Enum.any?(present_files, fn file -> Map.get(file, "id") == id end)
  end
end
