// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 📊 Structured Output - JSON Schema and Data Validation
///
/// This example demonstrates how to get structured data from AI:
/// - Defining tool-call schemas for responses (Vercel-style `generateObject`)
/// - Type safety via parsing into Dart classes
/// - Complex nested structures
/// - Error handling for malformed data
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('📊 Structured Output - JSON Schema and Data Validation\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  registerOpenAI();

  // Create AI provider
  final provider = await LLMBuilder()
      .provider(openaiProviderId)
      .apiKey(apiKey)
      .model('gpt-4.1-mini')
      .temperature(0.3) // Lower temperature for more consistent structure
      .maxTokens(1000)
      .build();

  // Demonstrate different structured output scenarios
  await demonstrateBasicStructuredOutput(provider);
  await demonstrateComplexStructures(provider);
  await demonstrateDataValidation(provider);
  await demonstrateErrorHandling(provider);

  print('\n✅ Structured output completed!');
}

/// Demonstrate basic structured output
Future<void> demonstrateBasicStructuredOutput(ChatCapability provider) async {
  print('📋 Basic Structured Output:\n');

  try {
    final personSchema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'name': ParameterProperty(
          propertyType: 'string',
          description: 'Full name',
        ),
        'age': ParameterProperty(
          propertyType: 'integer',
          description: 'Age in years',
        ),
        'email': ParameterProperty(
          propertyType: 'string',
          description: 'Email address',
        ),
        'occupation': ParameterProperty(
          propertyType: 'string',
          description: 'Job title / occupation',
        ),
        'skills': ParameterProperty(
          propertyType: 'array',
          description: 'List of skills',
          items: const ParameterProperty(
            propertyType: 'string',
            description: 'Skill name',
          ),
        ),
      },
      required: ['name', 'age', 'email', 'occupation', 'skills'],
    );

    print('   User: Extract person information from text');

    final result = await generateObject(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.system(
            'Extract the person information from the user text.',
          ),
          PromptMessage.user(
            'John Smith is a 32-year-old software engineer at TechCorp. '
            'He has experience in Python, JavaScript, and cloud computing. '
            'You can reach him at john.smith@email.com',
          ),
        ],
      ),
      schema: personSchema,
      toolName: 'extract_person',
      toolDescription: 'Extract person information from text.',
    );

    print('   🤖 Object: ${jsonEncode(result.object)}');

    final person = Person.fromJson(result.object);
    print('   ✅ Parsed successfully:');
    print('      Name: ${person.name}');
    print('      Age: ${person.age}');
    print('      Email: ${person.email}');
    print('      Occupation: ${person.occupation}');
    print('      Skills: ${person.skills.join(', ')}');

    print('   ✅ Basic structured output successful\n');
  } catch (e) {
    print('   ❌ Basic structured output failed: $e\n');
  }
}

/// Demonstrate complex nested structures
Future<void> demonstrateComplexStructures(ChatCapability provider) async {
  print('🏗️  Complex Nested Structures:\n');

  try {
    final companySchema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'company': ParameterProperty(
          propertyType: 'object',
          description: 'Company information',
          properties: {
            'name': const ParameterProperty(
              propertyType: 'string',
              description: 'Company name',
            ),
            'founded': const ParameterProperty(
              propertyType: 'integer',
              description: 'Year founded',
            ),
            'industry': const ParameterProperty(
              propertyType: 'string',
              description: 'Industry',
            ),
            'headquarters': ParameterProperty(
              propertyType: 'object',
              description: 'Headquarters',
              properties: {
                'city': const ParameterProperty(
                  propertyType: 'string',
                  description: 'City',
                ),
                'country': const ParameterProperty(
                  propertyType: 'string',
                  description: 'Country',
                ),
              },
              required: const ['city', 'country'],
            ),
          },
          required: const ['name', 'founded', 'industry', 'headquarters'],
        ),
        'employees': ParameterProperty(
          propertyType: 'array',
          description: 'Employee list',
          items: ParameterProperty(
            propertyType: 'object',
            description: 'Employee',
            properties: {
              'name': const ParameterProperty(
                propertyType: 'string',
                description: 'Employee name',
              ),
              'position': const ParameterProperty(
                propertyType: 'string',
                description: 'Role / position',
              ),
              'department': const ParameterProperty(
                propertyType: 'string',
                description: 'Department',
              ),
              'salary': const ParameterProperty(
                propertyType: 'number',
                description: 'Salary in USD',
              ),
            },
            required: const ['name', 'position', 'department', 'salary'],
          ),
        ),
        'financial': ParameterProperty(
          propertyType: 'object',
          description: 'Financial metrics',
          properties: {
            'revenue': const ParameterProperty(
              propertyType: 'number',
              description: 'Annual revenue',
            ),
            'profit': const ParameterProperty(
              propertyType: 'number',
              description: 'Annual profit',
            ),
            'currency': const ParameterProperty(
              propertyType: 'string',
              description: 'Currency code (e.g., USD)',
            ),
          },
          required: const ['revenue', 'profit', 'currency'],
        ),
      },
      required: const ['company', 'employees', 'financial'],
    );

    print('   User: Create fictional company data structure');

    final result = await generateObject(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.system(
            'Create a fictional company object from the user request.',
          ),
          PromptMessage.user(
            'Create a fictional tech company:\n'
            '- Company name: InnovateTech\n'
            '- Founded in 2018\n'
            '- Software industry\n'
            '- Headquarters in San Francisco, USA\n'
            '- 3 employees: CEO Alice Johnson (salary 150000 USD), CTO Bob Wilson (salary 130000 USD), Developer Carol Davis (salary 90000 USD)\n'
            '- Revenue: 2.5M, Profit: 500K (USD)\n',
          ),
        ],
      ),
      schema: companySchema,
      toolName: 'create_company',
      toolDescription: 'Return the fictional company object.',
    );

    print('   🤖 Object: ${jsonEncode(result.object)}');

    final company = Company.fromJson(result.object);
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

    print('   ✅ Complex structures demonstration successful\n');
  } catch (e) {
    print('   ❌ Complex structures demonstration failed: $e\n');
  }
}

/// Demonstrate data validation
Future<void> demonstrateDataValidation(ChatCapability provider) async {
  print('✅ Data Validation:\n');

  try {
    final productSchema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'name': const ParameterProperty(
          propertyType: 'string',
          description: 'Product name',
        ),
        'price': const ParameterProperty(
          propertyType: 'number',
          description: 'Price as a positive number',
        ),
        'category': ParameterProperty(
          propertyType: 'string',
          description: 'Product category',
          enumList: const [
            'electronics',
            'clothing',
            'books',
            'home',
            'sports'
          ],
        ),
        'inStock': const ParameterProperty(
          propertyType: 'boolean',
          description: 'Whether the product is in stock',
        ),
        'rating': const ParameterProperty(
          propertyType: 'number',
          description: 'Rating from 0 to 5',
        ),
        'tags': ParameterProperty(
          propertyType: 'array',
          description: 'Optional tag list (best-effort)',
          items: const ParameterProperty(
            propertyType: 'string',
            description: 'Tag',
          ),
        ),
      },
      required: const ['name', 'price', 'category', 'inStock'],
    );

    final testCases = [
      'Laptop computer, \$999, electronics category, in stock, 4.5 stars',
      'Running shoes, \$89.99, sports, available, rated 4.2/5',
      'Invalid product with negative price -\$50', // This should test validation
    ];

    for (int i = 0; i < testCases.length; i++) {
      print('   Test Case ${i + 1}: ${testCases[i]}');

      try {
        final result = await generateObject(
          model: provider,
          promptIr: Prompt(
            messages: [
              PromptMessage.system(
                'Extract product information from the user text.',
              ),
              PromptMessage.user('Extract product info: ${testCases[i]}'),
            ],
          ),
          schema: productSchema,
          toolName: 'extract_product',
          toolDescription: 'Extract product information as a JSON object.',
        );
        final product = Product.fromJson(result.object);

        // Validate the product
        final validationErrors = validateProduct(product);

        if (validationErrors.isEmpty) {
          print('      ✅ Valid product: ${product.name} - \$${product.price}');
        } else {
          print('      ❌ Validation errors: ${validationErrors.join(', ')}');
        }
      } on InvalidRequestError catch (e) {
        print('      ❌ Schema validation failed: ${e.message}');
      } catch (e) {
        print('      ❌ Unexpected error: $e');
      }

      print('');
    }

    print('   ✅ Data validation demonstration successful\n');
  } catch (e) {
    print('   ❌ Data validation demonstration failed: $e\n');
  }
}

/// Demonstrate error handling for malformed data
Future<void> demonstrateErrorHandling(ChatCapability provider) async {
  print('🛡️  Error Handling for Malformed Data:\n');

  try {
    final userSchema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'name': const ParameterProperty(
          propertyType: 'string',
          description: 'User name',
        ),
        'age': const ParameterProperty(
          propertyType: 'integer',
          description: 'Age in years',
        ),
        'email': const ParameterProperty(
          propertyType: 'string',
          description: 'Email address',
        ),
        'preferences': ParameterProperty(
          propertyType: 'array',
          description: 'Array of preference strings',
          items: const ParameterProperty(
            propertyType: 'string',
            description: 'Preference',
          ),
        ),
      },
      required: const ['name', 'age', 'email', 'preferences'],
    );

    print('   User: Create user data with preferences');

    try {
      final result = await generateObject(
        model: provider,
        promptIr: Prompt(
          messages: [
            PromptMessage.system(
              'Extract user info from the prompt. If preferences are present, return them as an array of strings.',
            ),
            PromptMessage.user(
              'Create user data for someone who likes pizza and movies. '
              'IMPORTANT: Return preferences as a single comma-separated string (not an array).',
            ),
          ],
        ),
        schema: userSchema,
        toolName: 'create_user',
        toolDescription: 'Create a user object.',
      );

      print('   ✅ Object: ${jsonEncode(result.object)}');
    } on InvalidRequestError catch (e) {
      print('   ❌ Schema validation failed: ${e.message}');
      print(
          '   💡 Fix: align prompt instructions with the schema (array vs string).');
    }

    print('   ✅ Error handling demonstration successful\n');
  } catch (e) {
    print('   ❌ Error handling demonstration failed: $e\n');
  }
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
