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
}