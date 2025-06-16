# Anthropic Caching and MessageBuilder Tests

This directory contains tests for the MessageBuilder feature and Anthropic caching functionality.

## Test Files

- `anthropic_caching_test.dart` - Comprehensive tests for MessageBuilder and Anthropic caching with real API calls

## Prerequisites

To run these tests, you need:

1. **Anthropic API Key**: Set the `ANTHROPIC_API_KEY` environment variable
2. **Active Internet Connection**: Tests make real API calls
3. **Dart SDK**: Compatible with your project's Dart version

## Running the Tests

### Set Environment Variable

```bash
# Linux/macOS
export ANTHROPIC_API_KEY="your-api-key-here"

# Windows (Command Prompt)
set ANTHROPIC_API_KEY=your-api-key-here

# Windows (PowerShell)
$env:ANTHROPIC_API_KEY="your-api-key-here"
```

### Run Tests

```bash
# Run only caching tests
dart test test/anthropic_caching_test.dart

# Run with verbose output
dart test test/anthropic_caching_test.dart -v

# Run specific test group
dart test test/anthropic_caching_test.dart --name "MessageBuilder Feature Tests"
```

## What the Tests Cover

### MessageBuilder Tests
- ✅ Basic message creation (user, system, assistant)
- ✅ Text chaining functionality
- ✅ Anthropic-specific configuration
- ✅ Extension handling
- ✅ Mixed cached and non-cached content

### Anthropic Caching Tests
- ✅ Cache creation and hits with real API
- ✅ Token usage comparison across requests
- ✅ Different cache TTL settings
- ✅ Content blocks with cache control
- ✅ Streaming with cached messages
- ✅ Mixed content scenarios

## Expected Test Output

When tests run successfully, you'll see:

```
✓ MessageBuilder creates basic message correctly
✓ MessageBuilder creates cached message with extensions  
✓ Anthropic caching works with real API - first request (cache creation)
First request (cache creation):
  Prompt tokens: 145
  Completion tokens: 23
  Response: Quantum computing is a computational paradigm...

✓ Anthropic caching works with real API - second request (cache hit)  
Second request (cache hit):
  Prompt tokens: 95  // Notice reduced tokens due to caching
  Completion tokens: 28
  Response: Quantum entanglement is a phenomenon where...
```

## Notes

- **Test Duration**: Tests typically take 30-60 seconds to complete
- **API Costs**: Tests use minimal tokens (usually <1000 total)
- **Model Used**: Tests use `claude-3-haiku-20240307` for speed and cost efficiency
- **Cache Behavior**: Subsequent requests with same cached content should show reduced prompt tokens

## Troubleshooting

### Common Issues

**API Key Not Set**
```
Exception: ANTHROPIC_API_KEY environment variable is required for this test
```
Solution: Set the environment variable correctly

**Network/API Errors**
```
DioError: SocketException: Failed host lookup
```
Solution: Check internet connection and API key validity

**Rate Limiting**
```
HTTP 429: Rate limit exceeded
```
Solution: Wait a moment and retry, or upgrade your Anthropic API plan

### Debug Mode

For debugging failed tests:

```bash
# Run with detailed logging
dart test test/anthropic_caching_test.dart --verbose --concurrency=1
```

This will show detailed HTTP requests and responses to help diagnose issues. 