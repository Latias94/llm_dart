# OpenAI Provider Tests

This directory contains comprehensive tests for the OpenAI provider, with special focus on the new Responses API functionality.

## Test Organization

### Core OpenAI Tests
- `openai_advanced_test.dart` - Advanced OpenAI provider features

### OpenAI Responses API Tests

#### Configuration & Setup Tests
- `responses_test.dart` - Basic configuration and builder tests
- `responses_stateful_test.dart` - Stateful features and capability detection

#### Comprehensive Feature Tests
- `responses_comprehensive_test.dart` - Complete feature coverage including:
  - Configuration and builder methods
  - Built-in tools (web search, file search, computer use)
  - Response models and serialization
  - Capability detection and type safety

#### Error Handling & Edge Cases
- `responses_error_handling_test.dart` - Error scenarios and edge cases:
  - OpenAIResponsesError handling
  - Configuration validation
  - Response model edge cases
  - Builder edge cases
  - Capability edge cases

#### Functionality Tests
- `responses_functionality_test.dart` - Method interfaces and behavior:
  - Method interface validation
  - Message handling
  - Tool handling
  - Response ID handling
  - Streaming functionality

#### Integration Tests
- `responses_integration_test.dart` - Integration scenarios:
  - Mock response handling
  - Response input items integration
  - Error response integration
  - Complete workflow testing

## Running Tests

### Run All OpenAI Responses API Tests
```bash
dart test test/providers/openai/responses_test_suite.dart
```

### Run Individual Test Files
```bash
# Configuration tests
dart test test/providers/openai/responses_test.dart

# Stateful features
dart test test/providers/openai/responses_stateful_test.dart

# Comprehensive features
dart test test/providers/openai/responses_comprehensive_test.dart

# Error handling
dart test test/providers/openai/responses_error_handling_test.dart

# Functionality
dart test test/providers/openai/responses_functionality_test.dart

# Integration
dart test test/providers/openai/responses_integration_test.dart
```

### Run All Tests (Including OpenAI Responses API)
```bash
dart test test/test_all.dart
```

## Test Coverage

The OpenAI Responses API tests cover:

### ✅ Configuration & Builder
- [x] Basic configuration with `useResponsesAPI()`
- [x] Built-in tools configuration (web search, file search, computer use)
- [x] Previous response ID for conversation chaining
- [x] Builder method chaining and accumulation
- [x] `buildOpenAIResponses()` convenience method
- [x] Configuration validation and edge cases

### ✅ Built-in Tools
- [x] Web search tool creation and serialization
- [x] File search tool with vector stores and parameters
- [x] Computer use tool with display settings
- [x] Tool equality and hashCode handling
- [x] Complex parameter structures
- [x] Tool validation and edge cases

### ✅ Response Models
- [x] `ResponseInputItem` creation and serialization
- [x] `ResponseInputItemsList` with pagination
- [x] Complex content structures (multimodal, tool calls)
- [x] JSON serialization/deserialization
- [x] Model equality and edge cases

### ✅ Capability Detection
- [x] `LLMCapability.openaiResponses` detection
- [x] Type-safe capability checking
- [x] Provider capability consistency
- [x] Responses getter availability

### ✅ Error Handling
- [x] `OpenAIResponsesError` creation and formatting
- [x] Configuration validation errors
- [x] API error response handling
- [x] Edge case error scenarios

### ✅ Method Interfaces
- [x] All `OpenAIResponsesCapability` methods
- [x] `ChatCapability` interface compliance
- [x] Extension method availability
- [x] Parameter validation

### ✅ Message & Tool Handling
- [x] Empty, single, and multiple messages
- [x] Multimodal content support
- [x] Tool parameter validation
- [x] Complex tool structures

### ✅ Response Management
- [x] Response ID handling and validation
- [x] Conversation continuation and forking
- [x] Background processing
- [x] Response lifecycle management

### ✅ Streaming
- [x] Basic streaming setup
- [x] Streaming with tools
- [x] Stream event handling

### ✅ Integration Scenarios
- [x] Mock response parsing
- [x] Complete conversation workflows
- [x] Error response handling
- [x] End-to-end usage patterns

## Test Philosophy

These tests follow several key principles:

1. **Comprehensive Coverage**: Every public API surface is tested
2. **Edge Case Handling**: Unusual inputs and error conditions are covered
3. **Type Safety**: Proper type checking and capability detection
4. **Real-world Scenarios**: Tests reflect actual usage patterns
5. **Mock-based**: Tests don't require actual API keys or network calls
6. **Maintainable**: Clear organization and documentation

## Adding New Tests

When adding new Responses API features:

1. Add configuration tests to `responses_comprehensive_test.dart`
2. Add error scenarios to `responses_error_handling_test.dart`
3. Add method tests to `responses_functionality_test.dart`
4. Add integration scenarios to `responses_integration_test.dart`
5. Update this README with new coverage areas

## Notes

- All tests are designed to run without actual API keys
- Tests focus on interface compliance and data structure handling
- Mock responses are based on actual OpenAI API documentation
- Error handling tests cover both expected and edge case scenarios
