# Profanity Filter Setup Guide

## Quick Setup

### 1. Get Perspective API Key

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the "Perspective Comment Analyzer API"
4. Go to "APIs & Services" > "Credentials"
5. Click "Create Credentials" > "API Key"
6. Copy your API key

### 2. Set Environment Variable

Add to your `.env` file:
```
PERSPECTIVE_API_KEY=your_api_key_here
```

Or export in your shell:
```bash
export PERSPECTIVE_API_KEY="your_api_key_here"
```

### 3. Test the Setup

Run in IEx:
```elixir
iex -S mix

# Test clean content
Accumulator.ProfanityFilter.check_profanity("This is a great article!")
# Should return: {:ok, "This is a great article!"}

# Test profane content
Accumulator.ProfanityFilter.check_profanity("This is shit")
# Should return: {:error, :contains_profanity}
```

### 4. Run Examples

```bash
mix run -e "Accumulator.Examples.ProfanityFilterExample.run_examples()"
```

### 5. Run Tests

```bash
mix test test/accumulator/profanity_filter_test.exs
```

### 6. Test Comment Creation

```bash
mix run -e "Accumulator.Examples.ProfanityFilterExample.test_comment_creation()"
```

## Verification Checklist

- [ ] API key is set in environment
- [ ] Clean comments are accepted
- [ ] Profane comments are rejected
- [ ] Fallback works when API is unavailable
- [ ] Tests pass
- [ ] Comment validation works in channels

## Troubleshooting

### API Key Issues
- Ensure key is valid and not restricted
- Check Google Cloud Console for quota limits
- Verify API is enabled

### Fallback Mode
If API fails, the system falls back to basic word filtering and logs warnings.

### Rate Limits
Free tier: 1,000 requests/day, 1 QPS
Monitor usage in Google Cloud Console.

## Ready to Use!

Your profanity filter is now active and will automatically filter comments in both English and Hindi/Hinglish.