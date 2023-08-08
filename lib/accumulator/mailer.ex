defmodule Accumulator.Mailer do
  use Swoosh.Mailer, otp_app: :accumulator
  require Logger

  def send_login_email() do
    email = Accumulator.Emails.LoginEmail.generate_template()

    case __MODULE__.deliver(email) do
      {:ok, mail} ->
        IO.inspect(mail)
        :ok

      {:error, :client_error} ->
        Logger.error("Failed to send login email: Client error")

      {:error, %{message: message}} ->
        Logger.error("Failed to send login email: #{message}")
    end
  end
end
