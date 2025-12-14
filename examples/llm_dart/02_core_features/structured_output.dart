// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:llm_dart/llm_dart.dart';

/// 📊 Structured Output - JSON Schema and Data Validation
///
/// This example demonstrates how to get structured data from AI:
/// - Defining JSON schemas for responses
/// - Data validation and type safety
/// - Complex nested structures
/// - Error handling for malformed data
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('📊 Structured Output - JSON Schema and Data Validation\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  // Create AI model
  final model = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4.1-mini')
      .temperature(0.3) // Lower temperature for more consistent structure
      .maxTokens(1000)
      .buildLanguageModel();

  // Demonstrate different structured output scenarios
  await demonstrateBasicStructuredOutput(model);
  await demonstrateComplexStructures(model);
  await demonstrateDataValidation(model);
  await demonstrateErrorHandling(model);

  print('\n✅ Structured output completed!');
}

/// Demonstrate basic structured output
Future<void> demonstrateBasicStructuredOutput(LanguageModel model) async {
  print('📋 Basic Structured Output:\n');

  try {
    final prompts = [
      ChatPromptBuilder.system().text('''
Extract person information and return as JSON. Use this exact format:
{
  "name": "full name",
  "age": number,
  "email": "email address",
  "occupation": "job title",
  "skills": ["skill1", "skill2"]
}
Return only the JSON data, no other text.
''').build(),
      ChatPromptBuilder.user().text('''
Extract information about this person:
"John Smith is a 32-year-old software engineer at TechCorp.
He has experience in Python, JavaScript, and cloud computing.
You can reach him at john.smith@email.com"
''').build(),
    ];

    print('   User: Extract person information from text');

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
    );
    final jsonText = response.text ?? '';

    print('   🤖 AI Response: $jsonText');

    // Parse and validate JSON
    try {
      final cleanedJson = attemptJsonFix(jsonText);
      final personData = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final person = Person.fromJson(personData);

      print('   ✅ Parsed successfully:');
      print('      Name: ${person.name}');
      print('      Age: ${person.age}');
      print('      Email: ${person.email}');
      print('      Occupation: ${person.occupation}');
      print('      Skills: ${person.skills.join(', ')}');
    } catch (e) {
      print('   ❌ JSON parsing failed: $e');
    }

    print('   ✅ Basic structured output successful\n');
  } catch (e) {
    print('   ❌ Basic structured output failed: $e\n');
  }
}

/// Demonstrate complex nested structures
Future<void> demonstrateComplexStructures(LanguageModel model) async {
  print('🏗️  Complex Nested Structures:\n');

  try {
    final companySchema = {
      "type": "object",
      "properties": {
        "company": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "founded": {"type": "integer"},
            "industry": {"type": "string"},
            "headquarters": {
              "type": "object",
              "properties": {
                "city": {"type": "string"},
                "country": {"type": "string"}
              }
            }
          }
        },
        "employees": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "position": {"type": "string"},
              "department": {"type": "string"},
              "salary": {"type": "number"}
            }
          }
        },
        "financial": {
          "type": "object",
          "properties": {
            "revenue": {"type": "number"},
            "profit": {"type": "number"},
            "currency": {"type": "string"}
          }
        }
      }
    };

    final prompts = [
      ChatPromptBuilder.system().text('''
Extract company information and return as JSON following this schema:
${jsonEncode(companySchema)}
Only return valid JSON.
''').build(),
      ChatPromptBuilder.user().text('''
Create a fictional tech company with the following details:
- Company name: InnovateTech
- Founded in 2018
- Software industry
- Headquarters in San Francisco, USA
- 3 employees: CEO Alice Johnson (\$150,000), CTO Bob Wilson (\$130,000), Developer Carol Davis (\$90,000)
- Revenue: \$2.5M, Profit: \$500K (USD)
''').build(),
    ];

    print('   User: Create fictional company data structure');

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
    );
    final jsonText = response.text ?? '';

    print('   🤖 AI Response: $jsonText');

    try {
      final companyData = jsonDecode(jsonText) as Map<String, dynamic>;
      final company = Company.fromJson(companyData);

      print('   ✅ Parsed complex structure:');
      print(
          '      Company: ${company.company.name} (${company.company.founded})');
      print(
          '      Location: ${company.company.headquarters.city}, ${company.company.headquarters.country}');
      print('      Employees: ${company.employees.length}');
      print(
          '      Revenue: ${company.financial.currency} ${company.financial.revenue}');

      for (final employee in company.employees) {
        print(
            '        • ${employee.name} - ${employee.position} (\$${employee.salary})');
      }
    } catch (e) {
      print('   ❌ Complex structure parsing failed: $e');
    }

    print('   ✅ Complex structures demonstration successful\n');
  } catch (e) {
    print('   ❌ Complex structures demonstration failed: $e\n');
  }
}

/// Demonstrate data validation
Future<void> demonstrateDataValidation(LanguageModel model) async {
  print('✅ Data Validation:\n');

  try {
    final productSchema = {
      "type": "object",
      "properties": {
        "name": {"type": "string", "minLength": 1},
        "price": {"type": "number", "minimum": 0},
        "category": {
          "type": "string",
          "enum": ["electronics", "clothing", "books", "home", "sports"]
        },
        "inStock": {"type": "boolean"},
        "rating": {"type": "number", "minimum": 0, "maximum": 5},
        "tags": {
          "type": "array",
          "items": {"type": "string"},
          "maxItems": 5
        }
      },
      "required": ["name", "price", "category", "inStock"]
    };

    final testCases = [
      'Laptop computer, \$999, electronics category, in stock, 4.5 stars',
      'Running shoes, \$89.99, sports, available, rated 4.2/5',
      'Invalid product with negative price -\$50', // This should test validation
    ];

    for (int i = 0; i < testCases.length; i++) {
      print('   Test Case ${i + 1}: ${testCases[i]}');

      final prompts = [
        ChatPromptBuilder.system().text('''
Extract product information as JSON following this schema:
${jsonEncode(productSchema)}
Ensure all validation rules are followed. Only return valid JSON.
''').build(),
        ChatPromptBuilder.user()
            .text('Extract product info: ${testCases[i]}')
            .build(),
      ];

      final response = await generateTextWithModel(
        model,
        promptMessages: prompts,
      );
      final jsonText = response.text ?? '';

      try {
        final productData = jsonDecode(jsonText) as Map<String, dynamic>;
        final product = Product.fromJson(productData);

        // Validate the product
        final validationErrors = validateProduct(product);

        if (validationErrors.isEmpty) {
          print('      ✅ Valid product: ${product.name} - \$${product.price}');
        } else {
          print('      ❌ Validation errors: ${validationErrors.join(', ')}');
        }
      } catch (e) {
        print('      ❌ JSON parsing failed: $e');
      }

      print('');
    }

    print('   ✅ Data validation demonstration successful\n');
  } catch (e) {
    print('   ❌ Data validation demonstration failed: $e\n');
  }
}

/// Demonstrate error handling for malformed data
Future<void> demonstrateErrorHandling(LanguageModel model) async {
  print('🛡️  Error Handling for Malformed Data:\n');

  try {
    final prompts = [
      ChatPromptBuilder.system().text('''
Return a JSON object with user information. 
Include: name, age, email, preferences (array of strings).
Only return valid JSON.
''').build(),
      ChatPromptBuilder.user()
          .text('Create user data for someone who likes pizza and movies')
          .build(),
    ];

    print('   User: Create user data with preferences');

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
    );
    final jsonText = response.text ?? '';

    print('   🤖 Raw response: $jsonText');

    // Attempt to parse with error handling
    final result = parseJsonSafely(jsonText);

    if (result.success) {
      print('   ✅ Successfully parsed JSON:');
      print('      Data: ${result.data}');
    } else {
      print('   ❌ JSON parsing failed: ${result.error}');
      print('   🔧 Attempting to fix...');

      // Try to fix common JSON issues
      final fixedJson = attemptJsonFix(jsonText);
      final fixedResult = parseJsonSafely(fixedJson);

      if (fixedResult.success) {
        print('   ✅ Fixed and parsed successfully: ${fixedResult.data}');
      } else {
        print('   ❌ Could not fix JSON: ${fixedResult.error}');
      }
    }

    print('   ✅ Error handling demonstration successful\n');
  } catch (e) {
    print('   ❌ Error handling demonstration failed: $e\n');
  }
}

/// Parse JSON safely with error handling
ParseResult parseJsonSafely(String jsonText) {
  try {
    final data = jsonDecode(jsonText);
    return ParseResult(success: true, data: data);
  } catch (e) {
    return ParseResult(success: false, error: e.toString());
  }
}

/// Attempt to fix common JSON issues
String attemptJsonFix(String jsonText) {
  var fixed = jsonText.trim();

  // Remove markdown code blocks
  fixed = fixed.replaceAll(RegExp(r'```json\s*'), '');
  fixed = fixed.replaceAll(RegExp(r'```\s*$'), '');
  fixed = fixed.replaceAll(RegExp(r'```'), '');

  // Remove extra text before/after JSON
  final jsonStart = fixed.indexOf('{');
  final jsonEnd = fixed.lastIndexOf('}');

  if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
    fixed = fixed.substring(jsonStart, jsonEnd + 1);
  }

  return fixed;
}

/// Validate product data
List<String> validateProduct(Product product) {
  final errors = <String>[];

  if (product.name.isEmpty) {
    errors.add('Name cannot be empty');
  }

  if (product.price < 0) {
    errors.add('Price cannot be negative');
  }

  if (product.rating < 0 || product.rating > 5) {
    errors.add('Rating must be between 0 and 5');
  }

  final validCategories = [
    'electronics',
    'clothing',
    'books',
    'home',
    'sports'
  ];
  if (!validCategories.contains(product.category)) {
    errors.add('Invalid category');
  }

  return errors;
}

/// Data classes for structured output

class Person {
  final String name;
  final int age;
  final String email;
  final String occupation;
  final List<String> skills;

  Person({
    required this.name,
    required this.age,
    required this.email,
    required this.occupation,
    required this.skills,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class Company {
  final CompanyInfo company;
  final List<Employee> employees;
  final Financial financial;

  Company({
    required this.company,
    required this.employees,
    required this.financial,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      company: CompanyInfo.fromJson(json['company'] as Map<String, dynamic>),
      employees: (json['employees'] as List<dynamic>)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList(),
      financial: Financial.fromJson(json['financial'] as Map<String, dynamic>),
    );
  }
}

class CompanyInfo {
  final String name;
  final int founded;
  final String industry;
  final Headquarters headquarters;

  CompanyInfo({
    required this.name,
    required this.founded,
    required this.industry,
    required this.headquarters,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name'] as String? ?? '',
      founded: json['founded'] as int? ?? 0,
      industry: json['industry'] as String? ?? '',
      headquarters: json['headquarters'] != null
          ? Headquarters.fromJson(json['headquarters'] as Map<String, dynamic>)
          : Headquarters(city: '', country: ''),
    );
  }
}

class Headquarters {
  final String city;
  final String country;

  Headquarters({required this.city, required this.country});

  factory Headquarters.fromJson(Map<String, dynamic> json) {
    return Headquarters(
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }
}

class Employee {
  final String name;
  final String position;
  final String department;
  final double salary;

  Employee({
    required this.name,
    required this.position,
    required this.department,
    required this.salary,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      department: json['department'] as String? ?? '',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Financial {
  final double revenue;
  final double profit;
  final String currency;

  Financial({
    required this.revenue,
    required this.profit,
    required this.currency,
  });

  factory Financial.fromJson(Map<String, dynamic> json) {
    return Financial(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

class Product {
  final String name;
  final double price;
  final String category;
  final bool inStock;
  final double rating;
  final List<String> tags;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
    required this.rating,
    required this.tags,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      inStock: json['inStock'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ParseResult {
  final bool success;
  final dynamic data;
  final String? error;

  ParseResult({required this.success, this.data, this.error});
}

/// 🎯 Key Structured Output Concepts Summary:
///
/// Schema Definition:
/// - JSON Schema for validation
/// - Required vs optional fields
/// - Data types and constraints
/// - Nested objects and arrays
///
/// Best Practices:
/// 1. Use lower temperature for consistent structure
/// 2. Provide clear schema in system prompt
/// 3. Implement robust JSON parsing
/// 4. Validate data after parsing
/// 5. Handle malformed responses gracefully
///
/// Error Handling:
/// - JSON parsing errors
/// - Schema validation failures
/// - Data type mismatches
/// - Missing required fields
///
/// Advanced Techniques:
/// - Automatic JSON fixing
/// - Progressive validation
/// - Schema evolution
/// - Type-safe data classes
///
/// Next Steps:
/// - error_handling.dart: Production error management
/// - ../03_advanced_features/: Advanced AI capabilities
/// - ../04_providers/: Provider-specific features
