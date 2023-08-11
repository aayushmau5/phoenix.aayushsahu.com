defmodule Accumulator.Mailer do
  use Swoosh.Mailer, otp_app: :accumulator
  require Logger

  def send_login_email(connection_info) do
    email = Accumulator.Emails.LoginEmail.generate_template(connection_info)

    case __MODULE__.deliver(email) do
      {:ok, _mail} ->
        :ok

      {:error, :client_error} ->
        Logger.warning("Failed to send login email: Client error")

      {:error, %{message: message}} ->
        Logger.warning("Failed to send login email: #{message}")
    end
  end
end
