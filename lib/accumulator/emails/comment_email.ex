defmodule Accumulator.Emails.CommentEmail do
  use AccumulatorWeb, :html

  def generate_template(comment) do
    admin_email = Application.get_env(:accumulator, :admin_email)

    subject =
      if comment.parent_id do
        "💬 New reply on phoenix.aayushsahu.com"
      else
        "💬 New comment on phoenix.aayushsahu.com"
      end

    %{
      from: "phoenix@resend.dev",
      to: admin_email,
      subject: subject,
      html:
        body(%{comment: comment})
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
    }
  end

  defp body(assigns) do
    ~H"""
    <div>
      <h2>{if @comment.parent_id, do: "New Reply", else: "New Comment"}</h2>

      <div style="background-color: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px;">
        <p><strong>Author:</strong> {@comment.author || "Anonymous"}</p>
        <p><strong>Blog Post:</strong> {@comment.blog_slug}</p>
        <p>
          <strong>Posted:</strong> {Calendar.strftime(@comment.inserted_at, "%B %d, %Y at %I:%M %p")}
        </p>

        <div style="margin-top: 15px;">
          <strong>Content:</strong>
          <div style="background-color: white; padding: 10px; margin-top: 5px; border-left: 3px solid #007acc;">
            {@comment.content}
          </div>
        </div>
      </div>

      <div style="margin-top: 20px;">
        <a
          href="https://phoenix.aayushsahu.com/comments"
          style="background-color: #007acc; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;"
        >
          Open Dashboard
        </a>
      </div>

      <div :if={@comment.parent_id} style="margin-top: 15px; color: #666;">
        <small>This is a reply to an existing comment thread.</small>
      </div>
    </div>
    """
  end
end
