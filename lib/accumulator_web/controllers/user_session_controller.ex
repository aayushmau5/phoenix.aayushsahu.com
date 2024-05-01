defmodule AccumulatorWeb.UserSessionController do
  use AccumulatorWeb, :controller

  alias Accumulator.Auth
  alias AccumulatorWeb.UserAuth

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"password" => password} = user_params
    email = Application.get_env(:accumulator, :admin_email)

    if user = Auth.get_user_by_email_and_password(email, password) do
      connection_info = Accumulator.Auth.Info.connection_info(conn)

      Task.Supervisor.async_nolink(Accumulator.TaskRunner, fn ->
        Accumulator.Mailer.send_login_email(connection_info)
        raise("hello world")
      end)

      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params, connection_info)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
