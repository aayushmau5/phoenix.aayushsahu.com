# Accumulator

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

## TODO

Make a blog post on demystifying phoenix(going deep into how everything works, macros, plugs, etc.)

The need to understand how each piece fit together

- [ ] refactor: more spec
- [ ] move dashboard data into a stream
- [ ] handle errors properly and show them on frontend

## How everything needs to fit together

On "main" channel, when we update the view count, send a pubsub message to "update:main-page-view-count" topic, and when we receive this, update viewcount.
We also need to update rt view count, so send message to "update:rt-main-page-view-count", and update.

Similarly for blogs
