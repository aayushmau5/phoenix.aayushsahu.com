# Profanity Filter with Google Perspective API

This Phoenix application includes an advanced profanity filter for comments that uses Google's Perspective API to detect inappropriate language in both English and Hindi/Hinglish.

## Features

- **AI-Powered Detection**: Uses Google's Perspective API for sophisticated content moderation
- **Multi-language Support**: Supports English and Hindi/Hinglish content
- **Fallback Protection**: Local word list fallback when API is unavailable
- **Smart Scoring**: Uses multiple toxicity metrics (toxicity, profanity, identity attacks)
- **Graceful Degradation**: Continues to work even if API fails

## Setup

### 1. Get Perspective API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Perspective Comment Analyzer API
4. Create credentials (API key)
5. Copy your API key

### 2. Environment Configuration

Add your API key to your environment:

```bash
export PERSPECTIVE_API_KEY="your_api_key_here"
```

Or add it to your `.env` file:

```
PERSPECTIVE_API_KEY=your_api_key_here
```

### 3. Configuration

The API key is automatically configured in `config/config.exs`:

```elixir
config :accumulator,
  perspective_api_key: System.get_env("PERSPECTIVE_API_KEY")
```

## How It Works

### API Integration

1. **Primary Check**: When a comment is submitted, the content is sent to Perspective API
2. **Multi-Metric Analysis**: The API returns scores for:
   - Toxicity (threshold: 0.7)
   - Severe Toxicity (threshold: 0.7)
   - Profanity (threshold: 0.6)
   - Identity Attack (threshold: 0.7)
3. **Decision Making**: If any score exceeds its threshold, the comment is rejected

### Fallback System

If the Perspective API fails:
- Falls back to local word list filtering
- Logs the API error for debugging
- Continues to provide basic protection

### Error Handling

- **API Unavailable**: Falls back to local filtering
- **Invalid API Key**: Falls back to local filtering
- **Rate Limiting**: Falls back to local filtering
- **Timeout**: Falls back to local filtering (5-second timeout)

## Usage Examples

```elixir
# Clean content
ProfanityFilter.check_profanity("This is a great article!")
# => {:ok, "This is a great article!"}

# Profane content (English)
ProfanityFilter.check_profanity("This is fucking terrible")
# => {:error, :contains_profanity}

# Profane content (Hindi/Hinglish)
ProfanityFilter.check_profanity("Tu chutiya hai")
# => {:error, :contains_profanity}

# Simple boolean check
ProfanityFilter.contains_profanity?("Nice work!")
# => false
```

## Integration

The profanity filter is integrated into the comment system at the validation level:

- **Model Validation**: Added to `Comment.changeset/2`
- **Automatic Rejection**: Comments with profanity are rejected with error message
- **Channel Integration**: Works seamlessly with Phoenix Channel comment system

## API Costs

- **Free Tier**: 1,000 requests per day
- **Paid Tier**: $1 per 1,000 requests after free tier
- **Rate Limits**: 1 QPS (queries per second) for free tier

## Monitoring

The system logs warnings when:
- API requests fail
- Falling back to local filtering
- API returns unexpected responses

Check your logs for entries like:
```
[warning] Perspective API error: :timeout, falling back to local filter
```

## Thresholds

Current toxicity thresholds can be adjusted in the module:

```elixir
@toxicity_threshold 0.7      # For toxicity, severe toxicity, identity attacks
@profanity_threshold 0.6     # For profanity detection
```

Lower values = more strict filtering
Higher values = more permissive filtering

## Fallback Word List

When API is unavailable, the system uses a basic word list covering common profanity in:
- English: fuck, shit, bitch, asshole, etc.
- Hindi/Hinglish: madarchod, behenchod, chutiya, gandu, etc.
- Abbreviations: wtf, stfu, etc.

## Testing

Run the test suite:

```bash
mix test test/accumulator/profanity_filter_test.exs
```

Tests cover:
- Clean content validation
- Profane content detection
- API error handling
- Fallback functionality
- Edge cases and multilingual content

## Maintenance

### Updating Thresholds

Modify the threshold constants in `lib/accumulator/profanity_filter.ex`:

```elixir
@toxicity_threshold 0.7
@profanity_threshold 0.6
```

### Updating Fallback Words

Modify the fallback word list in the same file:

```elixir
@fallback_profanity [
  # Add or remove words as needed
]
```

### Monitoring Usage

Check your Google Cloud Console for:
- API usage statistics
- Error rates
- Cost tracking

## Troubleshooting

### Common Issues

1. **"No API key" errors**: Ensure `PERSPECTIVE_API_KEY` environment variable is set
2. **API quota exceeded**: Check your Google Cloud Console for usage limits
3. **All comments being rejected**: Check if thresholds are too low
4. **API always failing**: Verify API key is valid and service is enabled

### Debug Mode

To see detailed API responses, check application logs when making requests.