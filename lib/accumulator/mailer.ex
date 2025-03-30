defmodule Accumulator.Mailer do
  require Logger

  def send_login_email(connection_info) do
    client = Resend.client(api_key: System.get_env("RESEND_API_KEY"))
    email_meta = Accumulator.Emails.LoginEmail.generate_template(connection_info)

    response =
      Resend.Emails.send(client, %{
        from: email_meta.from,
        to: [email_meta.to],
        subject: email_meta.subject,
        html: email_meta.html
      })

    case response do
      {:ok, _mail} ->
        :ok

      {:error, e} ->
        Logger.warning("Failed to send login email: #{e.message}")

      :client_error ->
        Logger.warning("Failed to send login email: Client error")
    end
  end
end
