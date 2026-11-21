defmodule Accumulator.Auth.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias Accumulator.Auth.UserToken

  @rand_size 32

  @session_validity_in_days 365
  @touch_interval_in_hours 24

  schema "users_tokens" do
    field(:token, :binary)
    field(:context, :string)
    field(:last_used_at, :naive_datetime)
    field(:ip_address, :string)
    field(:location, :string)
    field(:device_info, :string)
    belongs_to(:user, Accumulator.Auth.User)

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    now = NaiveDateTime.utc_now(:second)

    {token,
     %UserToken{token: token, context: "session", user_id: user.id, last_used_at: now}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it was
  used within the last @session_validity_in_days.
  """
  def verify_session_token_query(token) do
    query =
      from(token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.last_used_at > ago(@session_validity_in_days, "day"),
        select: user
      )

    {:ok, query}
  end

  @doc """
  Returns a query that marks a session token as used now.

  It only matches tokens not touched within @touch_interval_in_hours,
  so an active session costs at most one write per interval.
  """
  def touch_session_token_query(token) do
    from(t in token_and_context_query(token, "session"),
      where: t.last_used_at < ago(@touch_interval_in_hours, "hour"),
      update: [set: [last_used_at: fragment("(now() at time zone 'utc')")]]
    )
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from(UserToken, where: [token: ^token, context: ^context])
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    from(t in UserToken, where: t.user_id == ^user.id)
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from(t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts)
  end
end
