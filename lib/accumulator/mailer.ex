defmodule Accumulator.Mailer do
  require Logger

  @resend_url "https://api.resend.com/emails"

  def send_login_email(connection_info) do
    email_meta = Accumulator.Emails.LoginEmail.generate_template(connection_info)

    %{
      from: email_meta.from,
      to: [email_meta.to],
      subject: email_meta.subject,
      html: email_meta.html
    }
    |> send_email()
    |> handle_response("login")
  end

  def send_plant_email(plants) do
    email_meta = Accumulator.Emails.PlantEmail.generate_template(plants)

    %{
      from: email_meta.from,
      to: email_meta.to,
      subject: email_meta.subject,
      html: email_meta.html
    }
    |> send_email()
    |> handle_response("plant")
  end

  def send_comment_email(comment) do
    email_meta = Accumulator.Emails.CommentEmail.generate_template(comment)

    %{
      from: email_meta.from,
      to: email_meta.to,
      subject: email_meta.subject,
      html: email_meta.html
    }
    |> send_email()
    |> handle_response("comment")
  end

  defp send_email(body) do
    Req.post(@resend_url,
      json: body,
      auth: {:bearer, System.get_env("RESEND_API_KEY")},
      retry: false
    )
  end

  defp handle_response({:ok, %Req.Response{status: status}}, _kind) when status in 200..299,
    do: :ok

  defp handle_response({:ok, %Req.Response{status: status, body: body}}, kind) do
    Logger.warning("Failed to send #{kind} email: HTTP #{status} #{inspect(body)}")
  end

  defp handle_response({:error, exception}, kind) do
    Logger.warning("Failed to send #{kind} email: #{Exception.message(exception)}")
  end
end
