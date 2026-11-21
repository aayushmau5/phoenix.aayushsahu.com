# Local dev seed: mix run priv/repo/seeds.exs
if Mix.env() == :dev do
  alias Accumulator.{Repo, Auth.User}

  email = "dev@localhost"
  password = "aWWg48bPxXGnbwDNfbw5fCp1"

  unless Repo.get_by(User, email: email) do
    Repo.insert!(%User{email: email, hashed_password: Bcrypt.hash_pwd_salt(password)})
    IO.puts("Created dev user #{email}")
  end
end
