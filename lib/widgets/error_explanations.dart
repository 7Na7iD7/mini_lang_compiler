enum ErrorCategory { lexer, parser, semantic, runtime }

class ErrorExplanation {
  final String title;
  final String problem;
  final String solution;
  final String wrongExample;
  final String correctExample;
  final ErrorCategory category;
  final List<String> tips;
  final String? quickFix;
  final List<String>? relatedTopics;
  final String? phaseSource;

  ErrorExplanation({
    required this.title,
    required this.problem,
    required this.solution,
    required this.wrongExample,
    required this.correctExample,
    required this.category,
    this.tips = const [],
    this.quickFix,
    this.relatedTopics,
    this.phaseSource,
  });
}

class ErrorExplainer {
  static ErrorExplanation? explainError(String errorMessage, {String? phaseSource}) {
    final lower = errorMessage.toLowerCase();

    // Lexer Errors
    if (lower.contains('unterminated string')) {
      return ErrorExplanation(
        title: 'Missing Quote in String',
        problem: 'You started a string with " but forgot to close it with another "',
        solution: 'Add a closing quote at the end of your string',
        wrongExample: 'string name = "Hello;',
        correctExample: 'string name = "Hello";',
        category: ErrorCategory.lexer,
        tips: [
          'Every " must have a matching "',
          'Strings must be on one line',
          'Use escape sequences for special characters',
        ],
        quickFix: 'Add closing quote "',
        relatedTopics: ['Strings', 'Escape Characters'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('unexpected character')) {
      return ErrorExplanation(
        title: 'Invalid Character',
        problem: 'You used a symbol that the language doesn\'t understand',
        solution: 'Remove or replace the invalid character',
        wrongExample: 'int x = 5 @ 3;',
        correctExample: 'int x = 5 * 3;',
        category: ErrorCategory.lexer,
        tips: [
          'Check for typos',
          'Use only valid operators: + - * / % == != < > <= >=',
          'Avoid special symbols like @, #, \$',
        ],
        quickFix: 'Replace with valid operator',
        relatedTopics: ['Operators', 'Syntax'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('unterminated character')) {
      return ErrorExplanation(
        title: 'Missing Quote in Character',
        problem: 'You started a character with \' but forgot to close it',
        solution: 'Add a closing single quote',
        wrongExample: 'char c = \'a;',
        correctExample: 'char c = \'a\';',
        category: ErrorCategory.lexer,
        tips: [
          'Characters use single quotes \'',
          'Strings use double quotes "',
          'A character can only hold one letter',
        ],
        quickFix: 'Add closing single quote \'',
        relatedTopics: ['Characters', 'Data Types'],
        phaseSource: phaseSource,
      );
    }

    // Parser Errors

    if (lower.contains('expected') && lower.contains('but found')) {
      return ErrorExplanation(
        title: 'Missing or Wrong Symbol',
        problem: 'The compiler expected a specific symbol but found something else',
        solution: 'Check your syntax - you might be missing a semicolon, parenthesis, or bracket',
        wrongExample: '''int x = 5
print(x);''',
        correctExample: '''int x = 5;
print(x);''',
        category: ErrorCategory.parser,
        tips: [
          'Every statement needs a semicolon ;',
          'Check matching ( ) { } [ ]',
          'Function calls need parentheses',
          'Use proper indentation to spot errors easily',
        ],
        quickFix: 'Add missing semicolon or bracket',
        relatedTopics: ['Syntax', 'Statements'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('variable or function name')) {
      return ErrorExplanation(
        title: 'Missing Name',
        problem: 'You declared a variable or function but didn\'t give it a name',
        solution: 'Add a valid name after the type',
        wrongExample: 'int = 5;',
        correctExample: 'int x = 5;',
        category: ErrorCategory.parser,
        tips: [
          'Names must start with a letter or _',
          'Names can contain letters, numbers, and _',
          'Don\'t use keywords as names',
          'Use descriptive names like "counter" not "x"',
        ],
        quickFix: 'Add variable/function name',
        relatedTopics: ['Variables', 'Naming Conventions'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('break') && lower.contains('loop')) {
      return ErrorExplanation(
        title: 'Break Outside Loop',
        problem: 'You used "break" outside of a loop or switch statement',
        solution: 'Move the break statement inside a loop (for, while, do-while) or switch',
        wrongExample: '''int x = 5;
break;''',
        correctExample: '''while (x > 0) {
  x = x - 1;
  break;
}''',
        category: ErrorCategory.parser,
        tips: [
          'break exits from the current loop',
          'Only use break inside loops or switch',
          'break stops the loop immediately',
        ],
        quickFix: 'Move break inside loop/switch',
        relatedTopics: ['Loops', 'Control Flow', 'Switch'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('continue') && lower.contains('loop')) {
      return ErrorExplanation(
        title: 'Continue Outside Loop',
        problem: 'You used "continue" outside of a loop',
        solution: 'Move the continue statement inside a loop (for, while, do-while)',
        wrongExample: '''int x = 5;
continue;''',
        correctExample: '''for (int i = 0; i < 10; i = i + 1) {
  if (i == 5) {
    continue;
  }
  print(i);
}''',
        category: ErrorCategory.parser,
        tips: [
          'continue skips to the next iteration',
          'Only use continue inside loops',
          'continue doesn\'t exit the loop, just skips current iteration',
        ],
        quickFix: 'Move continue inside loop',
        relatedTopics: ['Loops', 'Control Flow'],
        phaseSource: phaseSource,
      );
    }

    // Semantic Errors
    if (lower.contains('not declared') || lower.contains('undefined')) {
      return ErrorExplanation(
        title: 'Variable Not Declared',
        problem: 'You\'re trying to use a variable that doesn\'t exist',
        solution: 'Declare the variable before using it, or check for typos',
        wrongExample: '''print(x);''',
        correctExample: '''int x = 5;
print(x);''',
        category: ErrorCategory.semantic,
        tips: [
          'Declare variables before using them',
          'Check spelling carefully',
          'Variable names are case-sensitive',
          'Make sure the variable is in scope',
        ],
        quickFix: 'Declare variable first',
        relatedTopics: ['Variables', 'Scope', 'Declaration'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('type mismatch') || lower.contains('cannot assign')) {
      return ErrorExplanation(
        title: 'Wrong Type',
        problem: 'You\'re trying to put the wrong type of value into a variable',
        solution: 'Make sure the value matches the variable type',
        wrongExample: '''int x = "hello";''',
        correctExample: '''string x = "hello";
// or
int x = 5;''',
        category: ErrorCategory.semantic,
        tips: [
          'int = whole numbers (1, 2, 3)',
          'string = text ("hello")',
          'boolean = true/false',
          'float = decimals (3.14)',
          'Use var to let compiler infer type',
        ],
        quickFix: 'Change type or value',
        relatedTopics: ['Data Types', 'Type System'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('already defined') || lower.contains('redefined')) {
      return ErrorExplanation(
        title: 'Duplicate Name',
        problem: 'You declared a variable or function with a name that\'s already used',
        solution: 'Use a different name, or remove one of the declarations',
        wrongExample: '''int x = 5;
int x = 10;''',
        correctExample: '''int x = 5;
x = 10;  // assignment, not declaration''',
        category: ErrorCategory.semantic,
        tips: [
          'Each name can only be declared once in the same scope',
          'Use different names for different variables',
          'To change a value, use assignment (=) not declaration',
          'Consider using more descriptive names',
        ],
        quickFix: 'Rename or remove duplicate',
        relatedTopics: ['Variables', 'Scope', 'Declaration'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('not a function')) {
      return ErrorExplanation(
        title: 'Calling Non-Function',
        problem: 'You\'re trying to call something that isn\'t a function',
        solution: 'Check that you\'re calling an actual function, not a variable',
        wrongExample: '''int x = 5;
x();''',
        correctExample: '''int x = 5;
print(x);''',
        category: ErrorCategory.semantic,
        tips: [
          'Only functions can be called with ()',
          'Variables are used without ()',
          'Check if you meant to use a function name',
        ],
        quickFix: 'Remove () or use correct function',
        relatedTopics: ['Functions', 'Function Calls'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('expects') && lower.contains('argument')) {
      return ErrorExplanation(
        title: 'Wrong Number of Arguments',
        problem: 'You\'re passing the wrong number of arguments to a function',
        solution: 'Match the number of arguments to what the function expects',
        wrongExample: '''int add(int a, int b) {
  return a + b;
}
add(5);  // missing one argument''',
        correctExample: '''int add(int a, int b) {
  return a + b;
}
add(5, 3);  // correct''',
        category: ErrorCategory.semantic,
        tips: [
          'Count the parameters in the function declaration',
          'Pass the same number of arguments',
          'Arguments must match parameter order',
        ],
        quickFix: 'Add or remove arguments',
        relatedTopics: ['Functions', 'Parameters'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('condition') && lower.contains('boolean')) {
      return ErrorExplanation(
        title: 'Non-Boolean Condition',
        problem: 'Your if/while condition must be true or false',
        solution: 'Use a comparison or boolean expression',
        wrongExample: '''if (5) {
  print("yes");
}''',
        correctExample: '''if (5 > 3) {
  print("yes");
}''',
        category: ErrorCategory.semantic,
        tips: [
          'Use comparisons: ==, !=, <, >, <=, >=',
          'Use boolean values: true, false',
          'Use logical operators: &&, ||, !',
          'Numbers are not automatically converted to boolean',
        ],
        quickFix: 'Add comparison operator',
        relatedTopics: ['Conditionals', 'Boolean Logic', 'Operators'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('not an array')) {
      return ErrorExplanation(
        title: 'Not an Array',
        problem: 'You\'re trying to access an array index on something that isn\'t an array',
        solution: 'Make sure you declared the variable as an array',
        wrongExample: '''int x = 5;
print(x[0]);''',
        correctExample: '''int x[5];
x[0] = 5;
print(x[0]);''',
        category: ErrorCategory.semantic,
        tips: [
          'Arrays are declared with [size]',
          'Access elements with [index]',
          'Array size must be specified at declaration',
        ],
        quickFix: 'Declare as array or remove []',
        relatedTopics: ['Arrays', 'Indexing'],
        phaseSource: phaseSource,
      );
    }

    // Runtime Errors
    if (lower.contains('division by zero')) {
      return ErrorExplanation(
        title: 'Division by Zero',
        problem: 'You\'re trying to divide a number by zero, which is mathematically undefined',
        solution: 'Check that your divisor is not zero before dividing',
        wrongExample: '''int x = 10 / 0;''',
        correctExample: '''int divisor = 5;
if (divisor != 0) {
  int x = 10 / divisor;
  print(x);
} else {
  print("Cannot divide by zero");
}''',
        category: ErrorCategory.runtime,
        tips: [
          'Always check divisor != 0',
          'Zero division causes runtime errors',
          'Add validation before division operations',
        ],
        quickFix: 'Add zero check before division',
        relatedTopics: ['Math Operations', 'Error Handling'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('array index') && lower.contains('out of bounds')) {
      return ErrorExplanation(
        title: 'Array Index Out of Range',
        problem: 'You\'re trying to access an array position that doesn\'t exist',
        solution: 'Make sure your index is between 0 and array size - 1',
        wrongExample: '''int arr[5];
arr[10] = 5;  // array only has 5 elements''',
        correctExample: '''int arr[5];
arr[4] = 5;  // last valid index is 4''',
        category: ErrorCategory.runtime,
        tips: [
          'Array indices start at 0',
          'If array has size 5, valid indices are 0-4',
          'Check i < array_size before accessing',
          'Use loops carefully with arrays',
        ],
        quickFix: 'Check array bounds',
        relatedTopics: ['Arrays', 'Indexing', 'Loops'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('infinite loop') || (lower.contains('exceeded') && lower.contains('iterations'))) {
      return ErrorExplanation(
        title: 'Infinite Loop Detected',
        problem: 'Your loop is running too many times - probably forever',
        solution: 'Make sure your loop condition eventually becomes false',
        wrongExample: '''int i = 0;
while (i < 10) {
  print(i);
  // forgot to increment i
}''',
        correctExample: '''int i = 0;
while (i < 10) {
  print(i);
  i = i + 1;  // increment i
}''',
        category: ErrorCategory.runtime,
        tips: [
          'Always change the loop variable',
          'Make sure the condition will become false',
          'Test with small numbers first',
          'Add a safety counter if needed',
        ],
        quickFix: 'Add loop variable increment',
        relatedTopics: ['Loops', 'While Loops', 'Debugging'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('recursion depth')) {
      return ErrorExplanation(
        title: 'Too Much Recursion',
        problem: 'Your function is calling itself too many times',
        solution: 'Add a base case to stop the recursion',
        wrongExample: '''int factorial(int n) {
  return n * factorial(n - 1);
  // no base case!
}''',
        correctExample: '''int factorial(int n) {
  if (n <= 1) {
    return 1;  // base case
  }
  return n * factorial(n - 1);
}''',
        category: ErrorCategory.runtime,
        tips: [
          'Always have a base case',
          'Make sure you\'re getting closer to the base case',
          'Test with small inputs first',
          'Consider using loops instead of recursion',
        ],
        quickFix: 'Add base case condition',
        relatedTopics: ['Recursion', 'Functions', 'Base Case'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('return') && lower.contains('void')) {
      return ErrorExplanation(
        title: 'Returning Value from Void Function',
        problem: 'You\'re trying to return a value from a function marked as void',
        solution: 'Either change the return type or remove the return value',
        wrongExample: '''void printNumber(int x) {
  return x;  // void shouldn't return
}''',
        correctExample: '''// Option 1: Change return type
int getNumber(int x) {
  return x;
}

// Option 2: Don't return value
void printNumber(int x) {
  print(x);
}''',
        category: ErrorCategory.semantic,
        tips: [
          'void = returns nothing',
          'If function returns something, don\'t use void',
          'Use void for actions, not calculations',
        ],
        quickFix: 'Remove return value or change type',
        relatedTopics: ['Functions', 'Return Types', 'Void'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('may not return')) {
      return ErrorExplanation(
        title: 'Missing Return Statement',
        problem: 'Your function might not return a value in all cases',
        solution: 'Make sure every path through the function returns a value',
        wrongExample: '''int abs(int x) {
  if (x >= 0) {
    return x;
  }
  // what if x < 0?
}''',
        correctExample: '''int abs(int x) {
  if (x >= 0) {
    return x;
  }
  return -x;  // handle all cases
}''',
        category: ErrorCategory.semantic,
        tips: [
          'Cover all possible conditions',
          'Every branch should return',
          'Add else clause for completeness',
        ],
        quickFix: 'Add return for all paths',
        relatedTopics: ['Functions', 'Return Statements', 'Conditionals'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('lambda') && lower.contains('statement')) {
      return ErrorExplanation(
        title: 'Lambda Contains Multiple Statements',
        problem: 'Lambda functions can only contain a single expression',
        solution: 'Use a regular function for multiple statements',
        wrongExample: '''var complex = (int x) => {
  int temp = x * 2;
  return temp + 5;
};''',
        correctExample: '''// Option 1: Use single expression
var simple = (int x) => x * 2 + 5;

// Option 2: Use regular function
int complex(int x) {
  int temp = x * 2;
  return temp + 5;
}''',
        category: ErrorCategory.semantic,
        tips: [
          'Lambda = single expression only',
          'No statements like if, while in lambda',
          'Use regular functions for complex logic',
          'Lambda is for simple, one-line operations',
        ],
        quickFix: 'Convert to regular function',
        relatedTopics: ['Lambda', 'Functions', 'Expressions'],
        phaseSource: phaseSource,
      );
    }

    if (lower.contains('switch') && lower.contains('break')) {
      return ErrorExplanation(
        title: 'Missing Break in Switch',
        problem: 'Each case in switch needs a break statement',
        solution: 'Add break after each case block',
        wrongExample: '''switch (x) {
  case 1:
    print("one");
  case 2:
    print("two");
}''',
        correctExample: '''switch (x) {
  case 1:
    print("one");
    break;
  case 2:
    print("two");
    break;
}''',
        category: ErrorCategory.semantic,
        tips: [
          'Always add break in switch cases',
          'break prevents fall-through',
          'Use default for unmatched cases',
        ],
        quickFix: 'Add break statement',
        relatedTopics: ['Switch', 'Control Flow', 'Break'],
        phaseSource: phaseSource,
      );
    }

    return null;
  }
}