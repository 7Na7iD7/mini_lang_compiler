class CompilerExamples {
  static String getExample(String exampleKey) {
    switch (exampleKey) {
      case 'simple':
        return _simpleExample;
      case 'fibonacci':
        return _fibonacciExample;
      case 'array':
        return _arrayExample;
      case 'var_demo':
        return _varDemoExample;
      case 'loop':
        return _loopExample;
      case 'increment':
        return _incrementExample;
      case 'do_while':
        return _doWhileExample;
      case 'break_continue':
        return _breakContinueExample;
      case 'switch_case':
        return _switchCaseExample;
      case 'lambda':
        return _lambdaExample;
      case 'advanced_lambda':
        return _advancedLambdaExample;
      case 'recursive':
        return _recursiveExample;
      case 'combined':
        return _combinedExample;
      case 'math_simple':
        return _mathSimpleExample;
      case 'math_advanced':
        return _mathAdvancedExample;
      case 'string_operations':
        return _stringOperationsExample;
      case 'calculator':
        return _calculatorExample;
      case 'pattern_printing':
        return _patternPrintingExample;
      case 'number_games':
        return _numberGamesExample;
      default:
        return _defaultExample;
    }
  }

  static List<String> get availableExamples => [
    'simple',
    'fibonacci',
    'array',
    'var_demo',
    'loop',
    'increment',
    'do_while',
    'break_continue',
    'switch_case',
    'lambda',
    'advanced_lambda',
    'recursive',
    'combined',
    'math_simple',
    'math_advanced',
    'string_operations',
    'calculator',
    'pattern_printing',
    'number_games',
  ];

  static String getExampleDisplayName(String exampleKey) {
    switch (exampleKey) {
      case 'simple':
        return 'Simple Function';
      case 'fibonacci':
        return 'Fibonacci Sequence';
      case 'array':
        return 'Array Operations';
      case 'var_demo':
        return 'Variable Demo';
      case 'loop':
        return 'Loop Examples';
      case 'increment':
        return 'Increment/Decrement';
      case 'do_while':
        return 'Do-While Loop';
      case 'break_continue':
        return 'Break & Continue';
      case 'switch_case':
        return 'Switch-Case';
      case 'lambda':
        return 'Lambda Functions';
      case 'advanced_lambda':
        return 'Advanced Lambda';
      case 'recursive':
        return 'Recursive Functions';
      case 'combined':
        return 'Combined Features';
      case 'math_simple':
        return 'Simple Math';
      case 'math_advanced':
        return 'Advanced Math';
      case 'string_operations':
        return 'String Operations';
      case 'calculator':
        return 'Calculator';
      case 'pattern_printing':
        return 'Pattern Printing';
      case 'number_games':
        return 'Number Games';
      default:
        return 'Default Example';
    }
  }

  static const String _defaultExample = '''void greet(string name) {
    print("Hello!");
    print(name);
}

var userName = "Developer";
greet(userName);''';

  static const String _simpleExample = '''void greet(string name) {
    print("Hello!");
    print(name);
}

var userName = "Developer";
greet(userName);

int luckyNumber = 42;
print(luckyNumber);''';

  static const String _fibonacciExample = '''int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

void main() {
    var i = 0;
    for (i = 0; i < 10; i = i + 1) {
        print(fibonacci(i));
    }
}''';

  static const String _arrayExample = '''int numbers[5];
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;
numbers[3] = 40;
numbers[4] = 50;

var i = 0;
for (i = 0; i < 5; i = i + 1) {
    print(numbers[i]);
}''';

  static const String _varDemoExample = '''var message = "Hello Dart-like!";
print(message);

var number = 42;
print(number);

var result = number * 2;
print(result);''';

  static const String _loopExample = '''var i = 1;
for (i = 1; i <= 5; i = i + 1) {
    print(i);
}

int j = 0;
for (j = 0; j <= 10; j = j + 2) {
    print(j);
}''';

  static const String _incrementExample = '''var counter = 0;
counter++;
print(counter);

counter++;
print(counter);

counter--;
print(counter);''';

  static const String _doWhileExample = '''void main() {
    int i = 0;
    do {
        print(i);
        i = i + 1;
    } while (i < 5);
    
    print("Done!");
}''';

  static const String _breakContinueExample = '''void main() {
    print("Break Example:");
    int i = 0;
    while (i < 10) {
        if (i == 5) {
            break;
        }
        print(i);
        i = i + 1;
    }
    
    print("Continue Example:");
    int j = 0;
    while (j < 10) {
        j = j + 1;
        if (j % 2 == 0) {
            continue;
        }
        print(j);
    }
}''';

  static const String _switchCaseExample = '''void main() {
    int day = 3;
    
    switch (day) {
        case 1:
            print("Monday");
            break;
        case 2:
            print("Tuesday");
            break;
        case 3:
            print("Wednesday");
            break;
        case 4:
            print("Thursday");
            break;
        case 5:
            print("Friday");
            break;
        default:
            print("Weekend");
    }
}''';

  static const String _lambdaExample = '''void main() {
    var add = (int a, int b) => a + b;
    var result = add(5, 3);
    print(result);
    
    var square = (int x) => x * x;
    var squared = square(4);
    print(squared);
    
    var isEven = (int n) => n % 2 == 0;
    print(isEven(4));
    print(isEven(7));
}''';

  static const String _advancedLambdaExample = '''void main() {
    var multiply = (int x, int y) => x * y;
    var divide = (int x, int y) => x / y;
    
    var result1 = multiply(10, 5);
    print(result1);
    
    var result2 = divide(10, 5);
    print(result2);
    
    var add = (int a, int b) => a + b;
    var sum = add(15, 25);
    print(sum);
}''';

  static const String _recursiveExample = '''int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int power(int base, int exp) {
    if (exp == 0) {
        return 1;
    }
    return base * power(base, exp - 1);
}

void main() {
    print(factorial(5));
    print(power(2, 10));
}''';

  static const String _combinedExample = '''int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

void main() {
    print("=== Feature Demo ===");
    
    print("1. Factorial:");
    print(factorial(5));
    
    print("2. Lambda:");
    var doubleFunc = (int x) => x * 2;
    var result = doubleFunc(21);
    print(result);
    
    print("3. Switch:");
    int day = 3;
    switch (day) {
        case 1:
            print("Monday");
            break;
        case 2:
            print("Tuesday");
            break;
        case 3:
            print("Wednesday");
            break;
        default:
            print("Other");
    }
    
    print("4. Do-While:");
    int counter = 0;
    do {
        print(counter);
        counter = counter + 1;
    } while (counter < 3);
    
    print("5. Continue:");
    int i = 0;
    while (i < 5) {
        i = i + 1;
        if (i == 3) {
            continue;
        }
        print(i);
    }
    
    print("=== All Done! ===");
}''';

  // Simple Math (Beginner-Friendly)
  static const String _mathSimpleExample = '''void main() {
    print("=== Simple Math ===");
    
    int a = 10;
    int b = 5;
    
    print("Addition:");
    print(a + b);
    
    print("Subtraction:");
    print(a - b);
    
    print("Multiplication:");
    print(a * b);
    
    print("Division:");
    print(a / b);
    
    print("Modulo:");
    print(a % b);
    
    print("=== Comparisons ===");
    print(a > b);
    print(a < b);
    print(a == b);
    
    print("=== Even or Odd ===");
    int num = 7;
    if (num % 2 == 0) {
        print("Even");
    } else {
        print("Odd");
    }
}''';

  // Advanced Math (Intermediate)
  static const String _mathAdvancedExample = '''int gcd(int a, int b) {
    if (b == 0) {
        return a;
    }
    return gcd(b, a % b);
}

int lcm(int a, int b) {
    return (a * b) / gcd(a, b);
}

boolean isPrime(int n) {
    if (n <= 1) {
        return false;
    }
    if (n <= 3) {
        return true;
    }
    if (n % 2 == 0) {
        return false;
    }
    
    int i = 3;
    while (i * i <= n) {
        if (n % i == 0) {
            return false;
        }
        i = i + 2;
    }
    return true;
}

int sumDigits(int n) {
    int sum = 0;
    while (n > 0) {
        sum = sum + (n % 10);
        n = n / 10;
    }
    return sum;
}

void main() {
    print("=== GCD & LCM ===");
    print(gcd(48, 18));
    print(lcm(12, 18));
    
    print("=== Prime Numbers ===");
    print(isPrime(17));
    print(isPrime(18));
    print(isPrime(19));
    
    print("=== Sum of Digits ===");
    print(sumDigits(12345));
}''';

  // String Operations
  static const String _stringOperationsExample = '''void main() {
    print("=== String Basics ===");
    
    string firstName = "John";
    string lastName = "Doe";
    string fullName = firstName + " " + lastName;
    print(fullName);
    
    print("=== String with Numbers ===");
    string prefix = "User";
    int userId = 123;
    string message = prefix + " " + userId;
    print(message);
    
    print("=== Greetings ===");
    string[] names;
    names[0] = "Alice";
    names[1] = "Bob";
    names[2] = "Charlie";
    
    int i = 0;
    while (i < 3) {
        string greeting = "Hello, " + names[i] + "!";
        print(greeting);
        i = i + 1;
    }
    
    print("=== Formatting ===");
    int score = 95;
    string result = "Your score: " + score + "/100";
    print(result);
}''';

  // Calculator
  static const String _calculatorExample = '''int add(int a, int b) {
    return a + b;
}

int subtract(int a, int b) {
    return a - b;
}

int multiply(int a, int b) {
    return a * b;
}

int divide(int a, int b) {
    if (b == 0) {
        print("Error: Division by zero!");
        return 0;
    }
    return a / b;
}

void printResult(string operation, int result) {
    string output = operation + " = " + result;
    print(output);
}

void main() {
    print("=== Simple Calculator ===");
    
    int x = 20;
    int y = 5;
    
    printResult("20 + 5", add(x, y));
    printResult("20 - 5", subtract(x, y));
    printResult("20 * 5", multiply(x, y));
    printResult("20 / 5", divide(x, y));
    
    print("=== Using Lambda ===");
    var mod = (int a, int b) => a % b;
    printResult("20 % 5", mod(x, y));
    
    print("=== Calculator Test ===");
    int result = add(multiply(3, 4), divide(20, 2));
    print(result);
}''';

  // Pattern Printing
  static const String _patternPrintingExample = '''void printStars(int count) {
    int i = 0;
    while (i < count) {
        print("*");
        i = i + 1;
    }
}

void printNumbers(int count) {
    int i = 1;
    while (i <= count) {
        print(i);
        i = i + 1;
    }
}

void printSquare(int size) {
    print("=== Square Pattern ===");
    int i = 0;
    while (i < size) {
        printStars(size);
        i = i + 1;
    }
}

void printTriangle(int height) {
    print("=== Triangle Pattern ===");
    int i = 1;
    while (i <= height) {
        printStars(i);
        i = i + 1;
    }
}

void printCountdown(int from) {
    print("=== Countdown ===");
    int i = from;
    while (i >= 0) {
        print(i);
        i = i - 1;
    }
    print("Blast off!");
}

void main() {
    printSquare(3);
    print("---");
    printTriangle(4);
    print("---");
    printCountdown(5);
    print("---");
    printNumbers(10);
}''';

  // Number Games
  static const String _numberGamesExample = '''int findMax(int a, int b, int c) {
    int max = a;
    if (b > max) {
        max = b;
    }
    if (c > max) {
        max = c;
    }
    return max;
}

int findMin(int a, int b, int c) {
    int min = a;
    if (b < min) {
        min = b;
    }
    if (c < min) {
        min = c;
    }
    return min;
}

int sumRange(int start, int end) {
    int sum = 0;
    int i = start;
    while (i <= end) {
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}

int countEven(int limit) {
    int count = 0;
    int i = 1;
    while (i <= limit) {
        if (i % 2 == 0) {
            count = count + 1;
        }
        i = i + 1;
    }
    return count;
}

void main() {
    print("=== Find Max/Min ===");
    print(findMax(15, 42, 27));
    print(findMin(15, 42, 27));
    
    print("=== Sum Range ===");
    print(sumRange(1, 10));
    print(sumRange(1, 100));
    
    print("=== Count Even Numbers ===");
    print(countEven(10));
    print(countEven(20));
    
    print("=== Multiples of 3 ===");
    int i = 3;
    int count = 0;
    while (count < 5) {
        print(i);
        i = i + 3;
        count = count + 1;
    }
}''';
}