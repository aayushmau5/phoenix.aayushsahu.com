defmodule Accumulator.Auth do
  @moduledoc """
  The Auth context.
  """

  import Ecto.Query, warn: false
  alias Accumulator.Repo

  alias Accumulator.Auth.{User, UserToken}

  ## Database getters

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  ## Session

  def get_all_sessions() do
    Repo.all(UserToken)
  end

  def delete_session_by_id(id) do
    query = from(t in UserToken, where: t.id == ^id)
    Repo.delete_all(query)
  end

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user, connection_info) do
    {token, user_token} = UserToken.build_session_token(user)

    user_token =
      user_token
      |> Map.put(:ip_address, connection_info.ip_address)
      |> Map.put(:location, connection_info.location)
      |> Map.put(:device_info, connection_info.device_info)

    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end
end
