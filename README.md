# phoenix.aayushsahu.com (aka Accumulator)

Accumulator is a personal productivity and data tracking application built with Elixir/Phoenix. It serves as a unified platform for various personal utilities and data collection services.

## Features

### Dashboard
- Track website/blog visitor statistics in real-time
- Show current page viewers using Phoenix Presence
- Sort and organize blog analytics data
- Monitor page view counts across [my website](https://aayushsahu.com)

### Notes System
- Create and organize notes in workspaces
- Public/private sharing capabilities
- Markdown support
- Search functionality
- Date-based organization

### Paste Bin
- Create private text snippets/pastes
- Set expiration times
- File attachment support
- Automatic cleanup of expired pastes

### Spotify Integration
- Display currently playing track
- Show top tracks and artists
- Auto-refreshes data on scheduled intervals

### Plant Management
- Track houseplants watering schedules
- Get notifications for plants that need watering
- Store plant details and care instructions

### Authentication
- Secure user authentication system
- Protected routes for private data

## Architecture

- Built on Elixir and Phoenix LiveView
- PostgreSQL for data persistence
- Phoenix PubSub for real-time updates
- Phoenix Presence for tracking active users
- Scheduled jobs using periodic workers
- Distributed Elixir clustering with libcluster

## Local Setup

Requires: Elixir, PostgreSQL.

This application uses PostgreSQL. You can either install it manually or through Docker. If the port is different, you need to make changes to the `config/dev.exs` file.

To start your Phoenix server:

- Clone the repo
- Create a `.env` file with necessary environment variables (see `.env.example` if available)
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

This application is configured for deployment on Fly.io using the included `fly.toml` and `Dockerfile`.

## System Architecture

The application uses Phoenix PubSub and Presence for real-time features:

1. **Data Collection**: Various endpoints collect data (website visits, Spotify plays, etc.)
2. **Storage**: Data is stored in PostgreSQL
3. **Real-time Updates**: When data changes, PubSub messages notify relevant components
4. **LiveView**: Phoenix LiveView ensures UI is always in sync with the latest data
5. **Scheduled Updates**: Background jobs regularly refresh external data (Spotify, etc.)

### Dashboard Flow

All the data is stored on Postgres. The first render shows dummy data. As soon as a LiveView connection is established, we fetch data from Postgres and current user count (using Presence) and update the client. LiveView also subscribes (through Phoenix PubSub) to a particular topic (with "update:" prefix) to get some updates.

Whenever data is updated (a new user visits my website/blog), we send a PubSub message to that "update:<topic>" topic. The LiveView gets a message on this topic, fetches latest data from Postgres and Presence count, and updates the LiveView.

High overview on how everything fits together:

![Illustration](dashboard-working.png)
