class OfflineResponses {
  static String get welcome => '''🎓 **سلام! من دستیار هوشمند پروژه "اصول کامپایلر" شما هستم**

من با تحلیل کامل سورس‌کد این پروژه آموزش دیده‌ام و می‌توانم به سوالات شما در مورد زبان **MiniLang** و نحوه کار این کامپایلر پاسخ دهم.

✨ **از من بپرسید:**
• 📊 درباره سینتکس زبان (حلقه‌ها، توابع، آرایه‌ها و...)
• ⚙️ مراحل مختلف کامپایل (Lexer, Parser, Interpreter)
• 🚀 تکنیک‌های بهینه‌سازی پیاده‌سازی شده
• 🧠 نحوه کار تحلیلگر معنایی و جدول نماد‌ها
• 💻 نوشتن و تحلیل کد به زبان MiniLang

**چطور می‌توانم کمکتان کنم؟** 💬''';

  static String get greeting => '''👋 **سلام! خوش آمدید!**

من دستیار هوشمند اصول کامپایلر شما هستم. چطور می‌توانم کمکتان کنم؟ 😊

✨ **می‌توانم در این موارد به شما کمک کنم:**
• 📊 تحلیل سینتکس زبان MiniLang
• 🌳 طراحی Parse Tree و AST
• ⚙️ توضیح مراحل کامپایل در این پروژه
• 🚀 بهینه‌سازی‌های انجام شده (مثل Constant Folding)
• 🧠 مدیریت Symbol Table و Type Checking

**سوال خود را بپرسید!** 💬

💡 **پیشنهادات:**
• "زبان MiniLang از چه نوع داده‌هایی پشتیبانی می‌کند؟"
• "چطور یک آرایه تعریف کنم؟"
• "محدودیت توابع لامبدا چیست؟"
• "بهینه‌ساز کد در این پروژه چه کارهایی انجام می‌دهد؟"''';

  static String get compilerIntro => '''📚 **کامپایلر MiniLang**

کامپایلر این پروژه کد نوشته شده به زبان MiniLang را به یک خروجی قابل فهم تبدیل می‌کند. این فرآیند در چند مرحله اصلی انجام می‌شود:

**1. 📖 Lexical Analysis (تحلیل واژگانی)**
   • کد منبع به توکن‌ها (Tokens) شکسته می‌شود.
   • کلمات کلیدی، شناسه‌ها، عملگرها و... شناسایی می‌شوند.
   • فایل `lexer.dart` مسئول این کار است.

**2. 🌳 Syntax Analysis (تحلیل نحوی)**
   • توکن‌ها به یک ساختار درختی به نام Abstract Syntax Tree (AST) تبدیل می‌شوند.
   • این درخت، ساختار گرامری کد را نمایش می‌دهد.
   • فایل `parser.dart` این مرحله را پیاده‌سازی می‌کند.

**3. 🧠 Semantic Analysis (تحلیل معنایی)**
   • درستی معنایی کد بررسی می‌شود.
   • مواردی مثل تطابق نوع داده‌ها (Type Checking)، تعریف شدن متغیره‌ها و مدیریت scope با استفاده از Symbol Table چک می‌شود.
   • فایل `semantic_analyzer.dart` این وظیفه را بر عهده دارد.

**4. 🚀 Optimization (بهینه‌سازی)**
   • کد AST برای افزایش کارایی بهبود داده می‌شود.
   • تکنیک‌هایی مانند **Constant Folding** و **Dead Code Elimination** در این پروژه پیاده‌سازی شده‌اند.
   • فایل `minilang_optimizer.dart` این منطق را شامل می‌شود.

**5. 🏃 Interpretation (تفسیر و اجرا)**
   • AST نهایی (بهینه شده) خط به خط اجرا شده و خروجی تولید می‌شود.
   • فایل `interpreter.dart` نقش مفسر را ایفا می‌کند.

سوال خاصی در مورد هر مرحله دارید؟ 🤔''';

  static String get defaultResponse => '''🤔 **متاسفانه سوال شما را متوجه نشدم.**

لطفاً سوال خود را واضح‌تر بپرسید یا از موضوعات زیر انتخاب کنید:

📚 **موضوعات اصلی:**
• 📊 انواع داده و متغیرها در MiniLang
• 🔄 تعریف حلقه‌ها (while, for, do-while)
• 📦 کار با آرایه‌ها
• 🔧 توابع و بازگشت
• 🔀 دستور switch
• 🚀 بهینه‌سازی‌های کامپایلر
• 🧠 تحلیل معنایی و خطایابی
• 🛠 تکنیک‌های دیباگ

**مثال‌های سوال:**
• "زبان MiniLang از چه نوع داده‌هایی پشتیبانی می‌کند؟"
• "چطور یک آرایه تعریف کنم؟"
• "محدودیت توابع لامبدا چیست؟"
• "بهینه‌ساز کد چه کارهایی انجام می‌دهد؟"
• "چطور خطاها را پیدا و رفع کنم؟"
• "تفاوت const و var چیست؟"

سوال خود را بپرسید! 😊💬''';

  static String getSmartResponse(String query) {
    String lowerCaseQuery = query.toLowerCase();

    if (_containsAny(lowerCaseQuery, ['نوع', 'داده', 'type', 'data', 'int', 'float', 'string', 'boolean', 'انواع', 'دادهای'])) {
      return _projectSpecificResponses['data_types']!;
    }

    if (_containsAny(lowerCaseQuery, ['آرایه', 'array', 'ارایه', 'لیست', 'list'])) {
      return _projectSpecificResponses['array_definition']!;
    }

    if (_containsAny(lowerCaseQuery, ['تابع', 'function', 'lambda', 'لامبدا', 'محدودیت'])) {
      return _projectSpecificResponses['lambda_limits']!;
    }

    if (_containsAny(lowerCaseQuery, ['main', 'شروع', 'اجرا', 'entry'])) {
      return _projectSpecificResponses['entry_point']!;
    }

    if (_containsAny(lowerCaseQuery, ['کامنت', 'comment', 'توضیح'])) {
      return _projectSpecificResponses['comments']!;
    }

    if (_containsAny(lowerCaseQuery, ['عملگر', 'operator', '+=', '++', '--'])) {
      return _projectSpecificResponses['operators']!;
    }

    if (_containsAny(lowerCaseQuery, ['حلقه', 'loop', 'while', 'for', 'do'])) {
      return _projectSpecificResponses['loops']!;
    }

    if (_containsAny(lowerCaseQuery, ['switch', 'case', 'سوییچ'])) {
      return _projectSpecificResponses['switch_statement']!;
    }

    if (_containsAny(lowerCaseQuery, ['scope', 'محدوده', 'دید', 'global', 'local'])) {
      return _projectSpecificResponses['scope_variables']!;
    }

    if (_containsAny(lowerCaseQuery, ['بازگشت', 'recursion', 'recursive', 'عمق'])) {
      return _projectSpecificResponses['recursion_depth']!;
    }

    if (_containsAny(lowerCaseQuery, ['سیستم', 'type system', 'typing', 'تبدیل'])) {
      return _projectSpecificResponses['type_system']!;
    }

    if (_containsAny(lowerCaseQuery, ['const', 'var', 'تفاوت', 'ثابت', 'متغیر'])) {
      return _projectSpecificResponses['const_vs_var']!;
    }

    if (_containsAny(lowerCaseQuery, ['escape', 'فرار', '\\n', '\\t', 'کاراکتر'])) {
      return _projectSpecificResponses['escape_sequences']!;
    }

    if (_containsAny(lowerCaseQuery, ['بهینه', 'optimize', 'performance', 'عملکرد'])) {
      return _projectSpecificResponses['performance_tips']!;
    }

    if (_containsAny(lowerCaseQuery, ['دیباگ', 'debug', 'خطا', 'error', 'مشکل'])) {
      return _projectSpecificResponses['debugging_tips']!;
    }

    if (_containsAny(lowerCaseQuery, ['بهترین', 'best', 'practice', 'شیوه'])) {
      return _projectSpecificResponses['best_practices']!;
    }

    if (_containsAny(lowerCaseQuery, ['compiler', 'کامپایلر'])) {
      return compilerIntro;
    }

    if (_containsAny(lowerCaseQuery, ['lexer', 'lexical', 'واژگانی'])) {
      return '''📖 **تحلیل واژگانی (Lexical Analysis)**

این اولین مرحله کامپایل است که کد منبع را به توکن‌ها تبدیل می‌کند.

**وظایف Lexer:**
• خواندن کاراکترهای کد منبع
• شناسایی توکن‌ها بر اساس الگوها
• حذف فضاهای خالی و کامنت‌ها
• گزارش خطاهای واژگانی

**مثال:**
```minilang
int age = 25;
```

**خروجی Lexer:**
```
[INT, "int"]
[IDENTIFIER, "age"]
[ASSIGN, "="]
[NUMBER, "25"]
[SEMICOLON, ";"]
```''';
    }

    if (_containsAny(lowerCaseQuery, ['parser', 'syntax', 'نحوی'])) {
      return '''🌳 **تحلیل نحوی (Syntax Analysis)**

مرحله دوم که توکن‌ها را به AST تبدیل می‌کند.

**وظایف Parser:**
• بررسی صحت گرامری
• ساخت Abstract Syntax Tree
• مدیریت اولویت عملگرها
• گزارش خطاهای نحوی

**مثال AST برای `int x = 5 + 10;`:**
```
VariableDeclaration (int x)
       |
BinaryExpression (+)
   /         \
NumberLiteral(5)  NumberLiteral(10)
```''';
    }

    if (_containsAny(lowerCaseQuery, ['semantic', 'معنایی'])) {
      return '''🧠 **تحلیل معنایی (Semantic Analysis)**

مرحله سوم که درستی معنایی کد را بررسی می‌کند.

**وظایف:**
• Type Checking - بررسی نوع داده‌ها
• Symbol Table Management
• Scope Resolution
• بررسی آرگومان‌های توابع
• بررسی دستورات return

**خطاهای معنایی:**
• استفاده از متغیر تعریف نشده
• عدم تطابق نوع داده‌ها
• استفاده نادرست از break/continue
• تابع بدون return (برای توابع غیر void)''';
    }

    if (_containsAny(lowerCaseQuery, ['optimizer', 'optimization', 'بهینه'])) {
      return '''🚀 **بهینه‌سازی کد (Code Optimization)**

**تکنیک‌های پیاده‌سازی شده:**

**1. Constant Folding:**
```minilang
// قبل
int x = 5 + 10 * 2;
// بعد
int x = 25;
```

**2. Dead Code Elimination:**
```minilang
// قبل
if (false) {
    print("هرگز اجرا نمی‌شود");
}
// بعد: حذف می‌شود
```

**3. Algebraic Simplification:**
```minilang
x * 1  =>  x
x + 0  =>  x
x * 0  =>  0
```''';
    }

    if (_containsAny(lowerCaseQuery, ['interpreter', 'اجرا', 'run'])) {
      return '''🏃 **مفسر و اجرای کد (Interpreter)**

آخرین مرحله که AST را خط به خط اجرا می‌کند.

**فرآیند:**
1. ثبت توابع
2. اجرای دستورات سراسری
3. فراخوانی تابع main() (اگر وجود داشته باشد)

**ویژگی‌ها:**
• Symbol Table برای متغیرها
• مدیریت حافظه
• محدودیت‌های امنیتی
• Execution Log کامل''';
    }

    return defaultResponse;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  static String getResponse(String query) {

    return getSmartResponse(query);
  }

  static String? getTopicResponse(String topic) {
    String normalizedTopic = topic.toLowerCase().replaceAll(' ', '_');
    if (_projectSpecificResponses.containsKey(normalizedTopic)) {
      return _projectSpecificResponses[normalizedTopic];
    }
    for (var key in _projectSpecificResponses.keys) {
      if (key.contains(normalizedTopic)) {
        return _projectSpecificResponses[key];
      }
    }
    return null;
  }

  static String? getCodeExample(String key) {
    String normalizedKey = key.toLowerCase().replaceAll(' ', '_');

    final Map<String, String> exampleKeys = {
      'arrays': 'array_definition',
      'functions': 'functions_advanced',
      'loops': 'loops',
      'hello_world': 'data_types',
    };

    String finalKey = exampleKeys[normalizedKey] ?? normalizedKey;

    if (_projectSpecificResponses.containsKey(finalKey)) {
      final responseText = _projectSpecificResponses[finalKey]!;
      final codeBlockRegex = RegExp(r'```minilang\s*([\s\S]*?)\s*```');
      final match = codeBlockRegex.firstMatch(responseText);
      return match?.group(1)?.trim();
    }
    return null;
  }

  static final Map<String, String> _projectSpecificResponses = {
    'data_types': '''📊 **انواع داده در MiniLang**

زبان MiniLang از انواع داده پایه زیر پشتیبانی می‌کند:

• **int**: برای ذخیره اعداد صحیح (مانند `10`, `-5`, `1000`)
  ```minilang
  int age = 25;
  int count = -10;
  ```

• **float**: برای ذخیره اعداد اعشاری (مانند `3.14`, `-2.5`)
  ```minilang
  float pi = 3.14159;
  float temperature = -15.5;
  ```

• **string**: برای ذخیره متن (مانند `"hello"`)
  ```minilang
  string name = "علی";
  string message = "سلام دنیا!";
  ```

• **boolean**: برای مقادیر منطقی (`true` یا `false`)
  ```minilang
  boolean isActive = true;
  boolean hasPermission = false;
  ```

• **var**: تشخیص خودکار نوع
  ```minilang
  var message = "Hello"; // string
  var count = 100;     // int
  var price = 19.99;   // float
  ```

• **const**: برای مقادیر ثابت
  ```minilang
  const float PI = 3.14159;
  const int MAX_SIZE = 1000;
  ```

**تبدیل خودکار نوع:**
```minilang
int x = 5;
string text = "Number: " + x; // x به "5" تبدیل می‌شود
print(text); // خروجی: Number: 5
```

**مقادیر پیش‌فرض:**
• int → 0
• float → 0.0
• boolean → false
• string → ""
• var → null''',

    'array_definition': '''📦 **تعریف و استفاده از آرایه‌ها در MiniLang**

در MiniLang، آرایه‌ها مجموعه‌ای از عناصر هم‌نوع با **اندازه ثابت** هستند.

**✅ نحوه صحیح تعریف:**
```minilang
// یک آرایه 5 عنصری از نوع int
int numbers[5];
// یک آرایه 10 عنصری از نوع string
string names[10];
// یک آرایه 3 عنصری از نوع float
float prices[3];
```

**📝 مقداردهی و دسترسی:**
```minilang
int numbers[5];
numbers[0] = 100;
numbers[1] = 200;
numbers[2] = 300;
numbers[3] = 400;
numbers[4] = 500;
print(numbers[0]); // 100
print(numbers[2]); // 300
```

**🔄 پیمایش آرایه با حلقه:**
```minilang
int data[5];
data[0] = 10;
data[1] = 20;
data[2] = 30;
data[3] = 40;
data[4] = 50;

for (int i = 0; i < 5; i = i + 1) {
    print(data[i]);
}
```

**⚠️ محدودیت‌ها:**
• اندازه آرایه باید عدد صحیح مثبت باشد
• اندازه حداکثر: 10000 عنصر
• مقداردهی اولیه به صورت `int arr[] = {1, 2, 3}` پشتیبانی **نمی‌شود**
• نمی‌توان اندازه آرایه را پس از تعریف تغییر داد

**💡 نکات مهم:**
• همیشه مراقب محدوده اندیس‌ها باشید (0 تا size-1)
• مقدار پیش‌فرض عناصر بستگی به نوع دارد (int→0, float→0.0, string→"", boolean→false)''',

    'lambda_limits': '''🔄 **توابع لامبدا (Lambda) و محدودیت‌های آن در MiniLang**

توابع لامبدا، توابع کوچک و بی‌نامی هستند که برای عملیات ساده استفاده می‌شوند.

**📝 سینتکس:**
```minilang
(نوع پارامتر1, نوع پارامتر2) => عبارت
```

**✅ مثال‌های صحیح:**
```minilang
void main() {
    // ضرب دو عدد
    var multiply = (int a, int b) => a * b;
    print(multiply(4, 5)); // 20
    
    // به توان دو رساندن
    var square = (int x) => x * x;
    print(square(7)); // 49
    
    // مقایسه دو عدد
    var isGreater = (int a, int b) => a > b;
    print(isGreater(10, 5)); // true
    
    // الحاق رشته
    var greet = (string name) => "Hello " + name;
    print(greet("Ali")); // Hello Ali
}
```

**⚠️ محدودیت اصلی:**
بدنه توابع لامبدا فقط می‌توانند شامل **یک عبارت (expression)** باشد.

**✅ راه حل برای منطق پیچیده:**
برای عملیات پیچیده‌تر، از توابع معمولی استفاده کنید:
```minilang
int complexCalc(int x) {
    int temp = x * 2;
    if (temp > 100) {
        return temp - 50;
    } else {
        return temp + 50;
    }
}

void main() {
    print(complexCalc(60)); // 70
}
```

**🎯 کاربردهای مناسب Lambda:**
• محاسبات ریاضی ساده
• مقایسه‌های ساده
• الحاق رشته‌ها
• تبدیلات ساده

**💡 نکته:** Lambda در MiniLang فقط یک expression برمی‌گرداند، نه statement.''',

    'entry_point': '''▶️ **نقطه شروع اجرای برنامه در MiniLang**

مانند بسیاری از زبان‌های برنامه‌نویسی، نقطه شروع اجرای هر برنامه در MiniLang، تابع `main()` است.

**🚀 نحوه کار مفسر:**
1. ابتدا تمام توابع تعریف شده ثبت می‌شوند
2. دستورات سطح سراسری (global) اجرا می‌شوند
3. اگر تابع `main()` وجود داشته باشد، فراخوانی می‌شود

**✅ مثال استاندارد:**
```minilang
void sayHello() {
    print("Hello from function!");
}

int add(int a, int b) {
    return a + b;
}

void main() {
    print("Program started!");
    sayHello();
    int result = add(5, 10);
    print(result);
}
```

**📋 سناریوهای مختلف:**

**سناریو 1: فقط main() وجود دارد**
```minilang
void main() {
    print("Hello World!");
}
```

**سناریو 2: کد سراسری + main()**
```minilang
// این کد قبل از main اجرا می‌شود
int x = 100;
print(x);

void main() {
    print("In main");
}
```

**سناریو 3: بدون main()**
```minilang
// تمام کدها در سطح global اجرا می‌شوند
int x = 50;
print(x);
int y = x + 10;
print(y);
```

**⚠️ شرط مهم:**
تابع `main()` باید **بدون پارامتر** باشد:
```minilang
// صحیح
void main() { }
// غلط
// void main(int argc) { }
```

**🎯 بهترین روش:**
همیشه از تابع `main()` برای شروع برنامه استفاده کنید:
```minilang
// تابع کمکی
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

// نقطه شروع
void main() {
    print(factorial(5));
}
```''',

    'comments': '''📝 **نحوه نوشتن توضیحات (Comments) در MiniLang**

برای افزودن توضیحات به کد خود در MiniLang می‌توانید از دو روش استاندارد استفاده کنید.

**1️⃣ کامنت تک‌خطی (Single-line Comment):**
با استفاده از `//` می‌توانید یک خط کامل را به توضیحات تبدیل کنید.

```minilang
// این یک متغیر برای ذخیره سن است
int x = 10;
// محاسبه مساحت دایره
float radius = 5.0;
float area = 3.14 * radius * radius; // فرمول مساحت
```

**2️⃣ کامنت چندخطی (Multi-line Comment):**
با استفاده از `/*` و `*/` می‌توانید چندین خط را به توضیحات تبدیل کنید.

```minilang
/*
  این تابع دو عدد را جمع می‌کند
  @param a: عدد اول
  @param b: عدد دوم
  @return: حاصل جمع
*/
int add(int a, int b) {
    return a + b;
}

/*
  این یک تابع بازگشتی برای محاسبه فاکتوریل است.
  محدودیت عمق بازگشت 1000 است.
*/
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}
```

**💡 نکات مهم:**
• کامنت‌ها توسط Lexer نادیده گرفته می‌شوند
• کامنت‌ها در فرآیند کامپایل تاثیری ندارند
• می‌توانید کامنت‌های چندخطی را تو در تو ننویسید

**🎯 بهترین شیوه‌ها:**
```minilang
// این تابع مجموع عناصر یک آرایه را محاسبه می‌کند
int calculateSum(int arr[5]) {
    int sum = 0; // متغیر برای ذخیره مجموع
    // پیمایش آرایه
    for (int i = 0; i < 5; i = i + 1) {
        sum = sum + arr[i];
    }
    return sum; // برگرداندن نتیجه
}
```''',

    'operators': '''⚙️ **عملگرهای پشتیبانی شده در MiniLang**

**➕ عملگرهای حسابی (Arithmetic):**
```minilang
int a = 10;
int b = 3;

print(a + b);  // 13
print(a - b);  // 7
print(a * b);  // 30
print(a / b);  // 3 (تقسیم صحیح)
print(a % b);  // 1 (باقیمانده)
```

**🔢 عملگرهای مقایسه‌ای (Comparison):**
```minilang
int x = 10;
int y = 20;

print(x == y); // false
print(x != y); // true
print(x > y);  // false
print(x < y);  // true
print(x >= 10);// true
print(x <= 5); // false
```

**🧠 عملگرهای منطقی (Logical):**
```minilang
boolean a = true;
boolean b = false;

print(a && b); // false (AND)
print(a || b); // true  (OR)
print(!a);     // false (NOT)
print(!b);     // true
```

**⚠️ عملگرهای پشتیبانی نشده:**

**❌ عملگرهای ترکیبی:**
```minilang
// غلط: x += 5;
// صحیح:
x = x + 5;
x = x - 3;
x = x * 2;
x = x / 4;
```

**❌ افزایش و کاهش واحد:**
```minilang
// غلط: x++;
// صحیح:
x = x + 1;
// غلط: x--;
// صحیح:
x = x - 1;
```

**🔗 الحاق رشته‌ها:**
```minilang
string first = "Hello";
string last = "World";
string full = first + " " + last;
print(full); // Hello World

int age = 25;
string message = "Age: " + age;
print(message); // Age: 25
```

**🎯 اولویت عملگرها (بالا به پایین):**
```
1. پرانتز ()
2. عملگرهای یکانی (-, !)
3. ضرب، تقسیم، باقیمانده (*, /, %)
4. جمع، تفریق (+, -)
5. عملگرهای مقایسه (<, >, <=, >=)
6. عملگرهای تساوی (==, !=)
7. و منطقی (&&)
8. یا منطقی (||)
```

**💡 مثال اولویت:**
```minilang
int result = 2 + 3 * 4; // 14
int result2 = (2 + 3) * 4; // 20
```''',

    'loops': '''🔄 **حلقه‌ها در MiniLang**

**1️⃣ حلقه while:**
```minilang
// چاپ اعداد 1 تا 5
int i = 1;
while (i <= 5) {
    print(i);
    i = i + 1;
}
```

**2️⃣ حلقه do-while:**
```minilang
// چاپ اعداد 1 تا 5 (حداقل یکبار اجرا می‌شود)
int i = 1;
do {
    print(i);
    i = i + 1;
} while (i <= 5);
```

**3️⃣ حلقه for:**
```minilang
// چاپ اعداد 0 تا 4
for (int i = 0; i < 5; i = i + 1) {
    print(i);
}
```

**🎯 کنترل جریان حلقه:**

**break - خروج از حلقه:**
```minilang
// چاپ اعداد 1 تا 4
for (int i = 1; i <= 10; i = i + 1) {
    if (i == 5) {
        break; // خروج از حلقه
    }
    print(i);
}
```

**continue - رد شدن از تکرار فعلی:**
```minilang
// چاپ اعداد 1, 2, 4, 5
for (int i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
        continue; // رد شدن از 3
    }
    print(i);
}
```

**📐 حلقه‌های تو در تو:**
```minilang
// جدول ضرب 3x3
for (int i = 1; i <= 3; i = i + 1) {
    for (int j = 1; j <= 3; j = j + 1) {
        print(i * j);
    }
}
```

**⚠️ محدودیت‌های ایمنی:**
• حداکثر تکرار: 100,000 (جلوگیری از حلقه بی‌نهایت)
• سیستم هشدار برای حلقه‌های مشکوک
• timeout برای اجرای طولانی''',

    'switch_statement': '''🔀 **دستور switch در MiniLang**

دستور switch برای انتخاب بین چند گزینه بر اساس مقدار یک متغیر استفاده می‌شود.

**📝 سینتکس:**
```minilang
switch (expression) {
    case value1:
        statements
        break;
    case value2:
        statements
        break;
    default:
        statements
}
```

**✅ مثال عملی:**
```minilang
void main() {
    int day = 3;
    
    switch (day) {
        case 1:
            print("یکشنبه");
            break;
        case 2:
            print("دوشنبه");
            break;
        case 3:
            print("سه‌شنبه");
            break;
        case 4:
            print("چهارشنبه");
            break;
        case 5:
            print("جمعه");
            break;
        default:
            print("روز نامشخص");
    }
}
```

**🔢 استفاده با اعداد:**
```minilang
void main() {
    int score = 85;
    int grade = score / 10;
    
    switch (grade) {
        case 10:
        case 9:
            print("عالی");
            break;
        case 8:
            print("خیلی خوب");
            break;
        case 7:
            print("خوب");
            break;
        case 6:
            print("قبول");
            break;
        default:
            print("مردود");
    }
}
```

**📤 استفاده با رشته‌ها:**
```minilang
void main() {
    string command = "start";
    
    switch (command) {
        case "start":
            print("شروع برنامه");
            break;
        case "stop":
            print("توقف برنامه");
            break;
        case "restart":
            print("شروع مجدد");
            break;
        default:
            print("دستور نامعتبر");
    }
}
```

**⚠️ نکات مهم:**
• حتماً از `break` استفاده کنید تا از case بعدی جلوگیری شود
• می‌توانید چند case را پشت سر هم قرار دهید
• بخش `default` اختیاری است اما توصیه می‌شود
• switch با int، float، string و boolean کار می‌کند''',

    'scope_variables': '''🔭 **محدوده دید متغیرها (Variable Scope) در MiniLang**

Scope تعیین می‌کند که یک متغیر در کدام قسمت‌های برنامه قابل دسترسی است.

**🌍 1. Global Scope (سطح سراسری):**
متغیرهایی که خارج از توابع تعریف می‌شوند.

```minilang
// متغیرهای سراسری
int globalVar = 100;
string name = "Ali";

void printGlobal() {
    // دسترسی به متغیرهای سراسری
    print(globalVar);
    print(name);
}

void main() {
    printGlobal();
    print(globalVar);
}
```

**🏠 2. Local Scope (سطح محلی):**
متغیرهایی که داخل توابع تعریف می‌شوند.

```minilang
void myFunction() {
    // متغیر محلی
    int localVar = 50;
    print(localVar);
}

void main() {
    myFunction();
    // print(localVar); // خطا: localVar اینجا تعریف نشده
}
```

**📦 3. Block Scope (سطح بلوک):**
متغیرهایی که داخل بلوک‌های if، while، for تعریف می‌شوند.

```minilang
void main() {
    int x = 10;
    
    if (x > 5) {
        // متغیر در سطح بلوک
        int y = 20;
        print(x); // دسترسی به x
        print(y); // دسترسی به y
    }
    
    // print(y); // خطا: y اینجا تعریف نشده
}
```

**🔄 4. اولویت Scope:**
متغیر محلی اولویت بیشتری نسبت به متغیر سراسری دارد.

```minilang
int x = 100; // سراسری

void test() {
    int x = 50; // محلی
    print(x); // 50
}

void main() {
    print(x); // 100
    test();
    print(x); // 100
}
```

**📋 5. Scope در حلقه‌ها:**
```minilang
void main() {
    for (int i = 0; i < 5; i = i + 1) {
        // i فقط در این حلقه قابل دسترسی است
        int temp = i * 2;
        print(temp);
    }
    // print(i); // خطا
    // print(temp); // خطا
}
```

**⚠️ قوانین مهم:**
• متغیرهای محلی فقط در تابع خودشان قابل دسترسی هستند
• متغیرهای بلوک فقط در بلوک خودشان قابل دسترسی هستند
• متغیرهای سراسری در همه جا قابل دسترسی هستند
• نمی‌توان دو متغیر با نام یکسان در یک scope تعریف کرد

**💡 بهترین شیوه‌ها:**
• از متغیرهای محلی استفاده کنید تا حد امکان
• از متغیرهای سراسری فقط زمانی استفاده کنید که واقعاً نیاز است
• نام‌های واضح و مشخص برای متغیرها انتخاب کنید''',

    'recursion_depth': '''🔄 **محدودیت عمق بازگشت (Recursion Depth) در MiniLang**

برای جلوگیری از Stack Overflow، MiniLang محدودیت عمق بازگشت دارد.

**⚙️ پیکربندی:**
```dart
maxRecursionDepth: 1000
```

**✅ مثال صحیح (بازگشت محدود):**
```minilang
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

void main() {
    print(factorial(5)); // 120
    print(factorial(10)); // 3628800
}
```

**⚠️ مثال خطا (بازگشت بی‌نهایت):**
```minilang
int badRecursion(int n) {
    return badRecursion(n + 1);
}

void main() {
    badRecursion(1); // خطا: Maximum recursion depth exceeded
}
```

**📊 نمونه‌های بازگشت:**

**1️⃣ فیبوناچی:**
```minilang
int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

void main() {
    for (int i = 0; i < 10; i = i + 1) {
        print(fibonacci(i));
    }
}
```

**2️⃣ GCD (بزرگترین مقسوم علیه مشترک):**
```minilang
int gcd(int a, int b) {
    if (b == 0) {
        return a;
    }
    return gcd(b, a % b);
}

void main() {
    print(gcd(48, 18)); // 6
    print(gcd(100, 35)); // 5
}
```

**🎯 تبدیل بازگشت به حلقه:**
اگر با محدودیت عمق مواجه شدید، می‌توانید الگوریتم را با حلقه پیاده کنید:

```minilang
int factorialIterative(int n) {
    int result = 1;
    for (int i = 2; i <= n; i = i + 1) {
        result = result * i;
    }
    return result;
}

void main() {
    print(factorialIterative(20)); // بسیار سریع‌تر از بازگشتی
}
```

**💡 نکات بهینه‌سازی:**
• همیشه شرط پایان (base case) را بررسی کنید
• برای مقادیر بزرگ از حلقه استفاده کنید
• از memoization برای بهبود عملکرد استفاده کنید (اگر ممکن است)''',

    'type_system': '''🏷️ **سیستم نوع داده (Type System) در MiniLang**

MiniLang یک زبان با **Static Typing** است که نوع متغیرها در زمان کامپایل مشخص می‌شود.

**📋 انواع Type:**

**1️⃣ Primitive Types:**
```minilang
int age = 25;
float price = 19.99;
string name = "Ali";
boolean isActive = true;
```

**2️⃣ Type Inference با var:**
```minilang
var message = "Hello"; // string
var count = 100;     // int
var temperature = 36.5; // float
var flag = true;     // boolean
```

**3️⃣ Array Types:**
```minilang
int numbers[10];
string names[5];
float prices[3];
```

**4️⃣ Function Types:**
```minilang
// (int, int) -> int
int add(int a, int b) {
    return a + b;
}

// (string) -> void
void printMessage(string msg) {
    print(msg);
}
```

**🔄 Type Checking:**

Semantic Analyzer بررسی می‌کند:
```minilang
// خطا: نوع نامعتبر
int x = 10;
x = "hello";

// خطا: عملگر نامعتبر
int y = 5 + "10";

// خطا: آرگومان نامعتبر
int add(int a, int b) {
    return a + b;
}
add(5, "hello");
```

**✅ Type Compatibility:**

**مجاز:**
```minilang
int x = 5;
float y = x; // تبدیل ضمنی

var z = 10;
int w = z; // z یک int است
```

**غیرمجاز:**
```minilang
string s = 100;
boolean b = "true";
int i = 3.14; // نیاز به cast دارد
```

**🔗 Type Coercion (تبدیل خودکار):**

**String Concatenation:**
```minilang
string name = "Age: ";
int age = 25;
string result = name + age;
print(result); // Age: 25
```

**Numeric Operations:**
```minilang
int x = 10;
float y = 3.14;
float result = x + y; // 13.14
```''',

    'const_vs_var': '''🔒 **تفاوت const و var در MiniLang**

**📌 const (ثابت):**
برای تعریف مقادیری که تغییر نمی‌کنند.

```minilang
const float PI = 3.14159;
const int MAX_SIZE = 1000;
const string APP_NAME = "MiniLang";
```

**🔄 var (متغیر):**
برای تعریف متغیرهایی که نوع آن‌ها خودکار تشخیص داده می‌شود.

```minilang
var message = "Hello";
var count = 100;
var price = 19.99;
var isActive = true;
```

**📊 مقایسه:**

| ویژگی | const | var |
|-------|-------|-----|
| نوع | صریح | استنباطی |
| تغییر مقدار | خیر | بله |
| مقداردهی اولیه | الزامی | اختیاری |
| استفاده | ثابت‌ها | متغیره‌ها |

**✅ استفاده صحیح const:**
```minilang
const float PI = 3.14159;
const int MAX_USERS = 100;
const string VERSION = "1.0.0";

void main() {
    float radius = 5.0;
    float area = PI * radius * radius;
    print(area);
}
```

**✅ استفاده صحیح var:**
```minilang
void main() {
    var name = "Ali";
    var age = 25;
    var salary = 5000.50;
    
    print(name);
    print(age);
    print(salary);
    
    age = 26; // صحیح
    print(age);
}
```

**⚠️ محدودیت‌ها:**

**const:**
```minilang
const int MAX = 100;
// MAX = 200; // خطا: نمی‌توان const را تغییر داد

void main() {
    print(MAX);
}
```

**var:**
```minilang
void main() {
    var x; // null
    x = 10;
    print(x);
    
    x = "hello"; // صحیح: نوع می‌تواند تغییر کند
    print(x);
}
```

**🎯 چه زمانی از کدام استفاده کنیم؟**

**const:**
• مقادیر ثابت ریاضی (PI، E)
• تنظیمات برنامه
• مقادیری که نباید تغییر کنند

**var:**
• زمانی که نوع واضح است
• برای کوتاه کردن کد
• مقادیر موقت''',

    'escape_sequences': '''📤 **کاراکترهای فرار (Escape Sequences) در MiniLang**

کاراکترهای فرار برای نمایش کاراکترهای خاص در رشته‌ها استفاده می‌شوند.

**📋 کاراکترهای پشتیبانی شده:**

```minilang
void main() {
    // خط جدید
    print("Line 1\nLine 2");
    
    // تب
    print("Hello\tWorld");
    
    // دابل کوتیشن
    print("She said \"Hello\"");
    
    // بک‌اسلش
    print("Path: C:\\Users\\Ali");
    
    // سینگل کوتیشن
    print("Single quote: \'");
}
```

**📖 جدول کامل:**

| Escape | توضیح | مثال |
|--------|-------|------|
| \n | خط جدید | "Line1\nLine2" |
| \t | Tab | "Name\tAge" |
| \" | علامت " | "He said \"Hi\"" |
| \' | علامت ' | "It\'s okay" |
| \\\\ | بک‌اسلش | "C:\\\\Path" |
| \r | Carriage Return | "Text\rNew" |
| \0 | Null character | "End\0" |

**✅ مثال‌های کاربردی:**

**1. جدول:**
```minilang
void main() {
    print("Name\tAge\tCity");
    print("Ali\t25\tTehran");
    print("Sara\t30\tShiraz");
}
```

**2. آدرس فایل:**
```minilang
void main() {
    string path = "C:\\Users\\Ali\\Documents\\file.txt";
    print(path);
}
```

**3. متن چندخطی:**
```minilang
void main() {
    string message = "Line 1\nLine 2\nLine 3";
    print(message);
}
```

**4. نقل قول:**
```minilang
void main() {
    string quote = "He said: \"Hello World!\"";
    print(quote);
}
```

**💡 نکات مهم:**
• همیشه از \\\\ برای بک‌اسلش استفاده کنید
• برای خط جدید از \n استفاده کنید
• escape sequences فقط در رشته‌ها کار می‌کنند
• کاراکترهای ناشناخته هشدار می‌دهند''',

    'performance_tips': '''⚡ **نکات بهینه‌سازی عملکرد در MiniLang**

**1️⃣ استفاده از بهینه‌ساز:**
```minilang
// قبل از بهینه‌سازی
const int MAX = 100;

void main() {
    int x = 5 + 10 * 2;
    print(x);
}
// بعد از بهینه‌سازی: print(25);
```

**2️⃣ از محاسبات ثابت استفاده کنید:**
```minilang
const float PI = 3.14159;
const int BUFFER_SIZE = 1024;

void main() {
    float radius = 5.0;
    float area = PI * radius * radius;
    print(area);
}
```

**3️⃣ حلقه‌های کارآمد:**

**بد:**
```minilang
void main() {
    for (int i = 0; i < 1000; i = i + 1) {
        // محاسبه تکراری
        int temp = 10 * 2 + 5;
        print(temp);
    }
}
```

**خوب:**
```minilang
void main() {
    int temp = 10 * 2 + 5; // محاسبه یکبار
    for (int i = 0; i < 1000; i = i + 1) {
        print(temp);
    }
}
```

**4️⃣ استفاده بهینه از توابع:**

**بد (فیبوناچی بازگشتی):**
```minilang
int fib(int n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}
```

**خوب (فیبوناچی تکراری):**
```minilang
int fib(int n) {
    if (n <= 1) {
        return n;
    }
    int a = 0;
    int b = 1;
    for (int i = 2; i <= n; i = i + 1) {
        int temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}
```

**5️⃣ بهینه‌سازی آرایه‌ها:**

**بد:**
```minilang
void main() {
    int arr[100];
    for (int i = 0; i < 100; i = i + 1) {
        for (int j = 0; j < 100; j = j + 1) {
            arr[i] = arr[i] + 1;
        }
    }
}
```

**خوب:**
```minilang
void main() {
    int arr[100];
    for (int i = 0; i < 100; i = i + 1) {
        int temp = arr[i];
        for (int j = 0; j < 100; j = j + 1) {
            temp = temp + 1;
        }
        arr[i] = temp;
    }
}
```

**💡 چک‌لیست بهینه‌سازی:**
• از const برای مقادیر ثابت استفاده کنید
• محاسبات تکراری را از حلقه خارج کنید
• از الگوریتم‌های تکراری به جای بازگشتی استفاده کنید
• اندازه آرایه‌ها را به حداقل نیاز برسانید
• از Lambda برای عملیات ساده استفاده کنید
• بهینه‌ساز را فعال کنید''',

    'debugging_tips': '''🛠 **تکنیک‌های دیباگ کردن در MiniLang**

**1️⃣ استفاده از print برای دیباگ:**
```minilang
void main() {
    int x = 10;
    print("x = " + x);
    
    int y = x * 2;
    print("y = " + y);
    
    int result = x + y;
    print("result = " + result);
}
```

**2️⃣ بررسی مقادیر در حلقه:**
```minilang
void main() {
    int sum = 0;
    for (int i = 0; i < 5; i = i + 1) {
        sum = sum + i;
        print("i = " + i + ", sum = " + sum);
    }
}
```

**3️⃣ دیباگ توابع:**
```minilang
int factorial(int n) {
    print("factorial called with n = " + n);
    
    if (n <= 1) {
        print("base case reached");
        return 1;
    }
    
    int result = n * factorial(n - 1);
    print("returning " + result);
    return result;
}

void main() {
    print(factorial(5));
}
```

**4️⃣ بررسی شرایط:**
```minilang
void main() {
    int x = 10;
    int y = 20;
    
    if (x > y) {
        print("x is greater");
    } else {
        print("y is greater or equal");
        print("x = " + x + ", y = " + y);
    }
}
```

**5️⃣ دیباگ آرایه‌ها:**
```minilang
void main() {
    int arr[5];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    
    print("Array elements:");
    for (int i = 0; i < 5; i = i + 1) {
        print("arr[" + i + "] = " + arr[i]);
    }
}
```

**6️⃣ استفاده از Execution Log:**
```minilang
// کد
void main() {
    int x = 5;
    int y = 10;
    int z = x + y;
    print(z);
}
// لاگ
// Declare var x = 5
// Declare var y = 10
// Declare var z = 15
// Print: 15
```

**7️⃣ بررسی خطاهای رایج:**

**خطای تقسیم بر صفر:**
```minilang
int safeDivide(int a, int b) {
    if (b == 0) {
        print("ERROR: Division by zero!");
        return 0;
    }
    return a / b;
}
```

**خطای آرایه:**
```minilang
void main() {
    int arr[5];
    int index = 2;
    
    if (index >= 0 && index < 5) {
        arr[index] = 100;
    } else {
        print("ERROR: Index out of bounds!");
    }
}
```

**💡 نکات مهم دیباگ:**
• از print برای نمایش مقادیر استفاده کنید
• مقادیر را در نقاط کلیدی چک کنید
• از Execution Log برای دنبال کردن جریان استفاده کنید
• خطاهای رایج را بررسی کنید
• کد را مرحله به مرحله تست کنید''',

    'best_practices': '''✨ **بهترین شیوه‌های برنامه‌نویسی در MiniLang**

**1️⃣ نام‌گذاری واضح:**

**بد:**
```minilang
int x = 25;
int y = 5000;
string s = "Ali";
```

**خوب:**
```minilang
int studentAge = 25;
int monthlySalary = 5000;
string userName = "Ali";
```

**2️⃣ استفاده از const برای مقادیر ثابت:**

**بد:**
```minilang
void main() {
    float radius = 5.0;
    float area = 3.14159 * radius * radius;
    print(area);
}
```

**خوب:**
```minilang
const float PI = 3.14159;

void main() {
    float radius = 5.0;
    float area = PI * radius * radius;
    print(area);
}
```

**3️⃣ توابع کوچک و مشخص:**

**بد:**
```minilang
void main() {
    // محاسبه جمع
    int a = 10;
    int b = 20;
    int sum = a + b;
    print(sum);
    
    // محاسبه ضرب
    int c = 5;
    int d = 3;
    int product = c * d;
    print(product);
}
```

**خوب:**
```minilang
int add(int x, int y) {
    return x + y;
}

int multiply(int x, int y) {
    return x * y;
}

void main() {
    print(add(10, 20));
    print(multiply(5, 3));
}
```

**4️⃣ بررسی شرایط مرزی:**

**بد:**
```minilang
int divide(int a, int b) {
    return a / b;
}
```

**خوب:**
```minilang
int divide(int a, int b) {
    if (b == 0) {
        print("Error: Division by zero");
        return 0;
    }
    return a / b;
}
```

**5️⃣ استفاده صحیح از آرایه‌ها:**

**بد:**
```minilang
void main() {
    int arr[5];
    arr[10] = 100; // خطا
}
```

**خوب:**
```minilang
void main() {
    int arr[5];
    int index = 2;
    
    if (index >= 0 && index < 5) {
        arr[index] = 100;
    }
}
```

**6️⃣ مدیریت Scope:**

**بد:**
```minilang
// استفاده بیش از حد از متغیرهای سراسری
int temp = 0;
int result = 0;

void calculate() {
    temp = 10;
    result = temp * 2;
}
```

**خوب:**
```minilang
int calculate() {
    int temp = 10;
    int result = temp * 2;
    return result;
}
```

**7️⃣ استفاده از Lambda برای عملیات ساده:**

**بد:**
```minilang
int square(int x) {
    return x * x;
}

void main() {
    print(square(5));
}
```

**خوب:**
```minilang
void main() {
    var square = (int x) => x * x;
    print(square(5));
}
```

**8️⃣ ساختار مناسب برنامه:**
```minilang
// ثابت‌ها
const int MAX_USERS = 100;
const float TAX_RATE = 0.15;

// توابع کمکی
int calculateTax(int amount) {
    return amount * TAX_RATE;
}

void printReceipt(int amount, int tax) {
    print("Amount: " + amount);
    print("Tax: " + tax);
    print("Total: " + (amount + tax));
}

// نقطه شروع
void main() {
    int price = 1000;
    int tax = calculateTax(price);
    printReceipt(price, tax);
}
```

**9️⃣ کامنت‌گذاری مناسب:**
```minilang
// این تابع فاکتوریل را محاسبه می‌کند
int factorial(int n) {
    if (n <= 1) {
        return 1; // شرط پایان
    }
    return n * factorial(n - 1); // بازگشت
}

void main() {
    int result = factorial(5);
    print(result);
}
```

**🔟 مدیریت خطا:**
```minilang
int getArrayElement(int arr[5], int index) {
    if (index < 0 || index >= 5) {
        print("Invalid index");
        return -1; // مقدار پیش‌فرض برای خطا
    }
    return arr[index];
}
```

**💡 چک‌لیست کیفیت کد:**
• نام‌های واضح و معنادار
• توابع کوچک و تک‌منظوره
• بررسی شرایط مرزی
• مدیریت خطا
• استفاده از const
• ساختار منظم کد
• کامنت‌گذاری مناسب
• اجتناب از تکرار کد''',

    'functions_advanced': '''🔧 **توابع پیشرفته در MiniLang**

**1️⃣ توابع با نوع برگشتی:**
```minilang
// جمع دو عدد
int add(int a, int b) {
    return a + b;
}

// تقسیم دو عدد (با بررسی خطا)
float divide(float a, float b) {
    if (b == 0) {
        return 0.0; // مدیریت تقسیم بر صفر
    }
    return a / b;
}

// الحاق دو رشته
string concat(string s1, string s2) {
    return s1 + s2;
}

// بررسی زوج بودن
boolean isEven(int n) {
    return n % 2 == 0;
}
```

**2️⃣ توابع void:**
```minilang
// چاپ یک بنر
void printBanner() {
    print("=================");
    print("  Welcome!");
    print("=================");
}

// جابجایی دو عدد (فقط در scope محلی)
void swap(int a, int b) {
    int temp = a;
    a = b;
    b = temp;
    print("Swapped!");
}
```

**3️⃣ توابع بازگشتی:**
```minilang
// فاکتوریل
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

// فیبوناچی
int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// بزرگترین مقسوم‌علیه مشترک
int gcd(int a, int b) {
    if (b == 0) {
        return a;
    }
    return gcd(b, a % b);
}
```

**4️⃣ توابع با پارامترهای متعدد:**
```minilang
// پیدا کردن بزرگترین عدد از بین سه عدد
int max(int a, int b, int c) {
    int result = a;
    if (b > result) {
        result = b;
    }
    if (c > result) {
        result = c;
    }
    return result;
}

// میانگین چهار عدد
float average(int a, int b, int c, int d) {
    return (a + b + c + d) / 4.0;
}
```

**5️⃣ توابع کمکی (Helper Functions):**
```minilang
// بررسی اول بودن عدد
boolean isPrime(int n) {
    if (n <= 1) {
        return false;
    }
    for (int i = 2; i < n; i = i + 1) {
        if (n % i == 0) {
            return false;
        }
    }
    return true;
}

// چاپ اعداد اول تا یک محدوده
void printPrimes(int limit) {
    for (int i = 2; i <= limit; i = i + 1) {
        if (isPrime(i) == true) {
            print(i);
        }
    }
}
```

**⚠️ محدودیت‌ها:**
• حداکثر عمق بازگشت: 1000
• تابع main() باید بدون پارامتر باشد
• توابع غیر void باید مقداری return کنند''',

    'errors_common': '''❌ **خطاهای رایج و راه‌حل آنها**

**1️⃣ خطاهای واژگانی (Lexical Errors):**
```minilang
// غلط: @ #
int x = 10;
// غلط: "Hello
string msg = "Hello";
```

**2️⃣ خطاهای نحوی (Syntax Errors):**
```minilang
// غلط: int x = 10
// صحیح:
int x = 10;
print(x);

// غلط: if x > 5
// صحیح:
if (x > 5) {
    print(x);
}
```

**3️⃣ خطاهای معنایی (Semantic Errors):**
```minilang
// غلط: print(y)
// صحیح:
int x = 10;
print(x);

// غلط: add(5)
// صحیح:
int y = 20;
int result = add(5, 10);
```

**4️⃣ خطاهای زمان اجرا (Runtime Errors):**
```minilang
// تقسیم بر صفر
int safeDivide(int a, int b) {
    if (b == 0) {
        return 0;
    }
    return a / b;
}

// خارج از محدوده آرایه
int arr[5];
int index = 2;
if (index >= 0 && index < 5) {
    print(arr[index]);
}
```

**5️⃣ خطاهای منطقی (Logic Errors):**
```minilang
// حلقه بی‌نهایت
// صحیح:
int i = 0;
while (i < 10) {
    print(i);
    i = i + 1;
}
```''',
  };

  static List<Map<String, String>> get suggestedQuestions => [
    {'icon': '📊', 'title': 'انواع داده', 'query': 'زبان MiniLang از چه نوع داده‌هایی پشتیبانی می‌کند؟'},
    {'icon': '📦', 'title': 'نحوه تعریف آرایه', 'query': 'چطور در MiniLang یک آرایه تعریف کنم؟'},
    {'icon': '🔄', 'title': 'محدودیت Lambda', 'query': 'محدودیت‌های توابع لامبدا در MiniLang چیست؟'},
    {'icon': '▶️', 'title': 'نقطه شروع برنامه', 'query': 'نقطه شروع اجرای برنامه در MiniLang کجاست؟'},
    {'icon': '🚀', 'title': 'بهینه‌سازی‌های پروژه', 'query': 'بهینه‌ساز کد در این پروژه چه کارهایی انجام می‌دهد؟'},
    {'icon': '🧠', 'title': 'تحلیل معنایی', 'query': 'تحلیلگر معنایی در این پروژه چه خطاهایی را تشخیص می‌دهد؟'},
    {'icon': '📝', 'title': 'نوشتن کامنت', 'query': 'چطور در MiniLang کامنت بنویسم؟'},
    {'icon': '⚙️', 'title': 'عملگرهای خاص', 'query': 'آیا عملگرهایی مثل += در MiniLang پشتیبانی می‌شوند؟'},
    {'icon': '📖', 'title': 'تحلیل واژگانی', 'query': 'تحلیل واژگانی (Lexical Analysis) چیست؟'},
    {'icon': '🌳', 'title': 'تحلیل نحوی', 'query': 'تحلیل نحوی (Syntax Analysis) چیست؟'},
    {'icon': '🔀', 'title': 'دستور switch', 'query': 'چطور از دستور switch استفاده کنم؟'},
    {'icon': '🔭', 'title': 'Scope متغیرها', 'query': 'محدوده دید متغیرها در MiniLang چگونه است؟'},
    {'icon': '🔄', 'title': 'بازگشت و محدودیت', 'query': 'محدودیت عمق بازگشت چقدر است؟'},
    {'icon': '🏷️', 'title': 'سیستم نوع', 'query': 'سیستم نوع داده در MiniLang چگونه کار می‌کند؟'},
    {'icon': '🔒', 'title': 'const vs var', 'query': 'تفاوت const و var چیست؟'},
    {'icon': '📤', 'title': 'کاراکترهای فرار', 'query': 'چطور از escape sequences استفاده کنم؟'},
    {'icon': '⚡', 'title': 'بهینه‌سازی عملکرد', 'query': 'چطور کد خود را بهینه کنم؟'},
    {'icon': '🛠', 'title': 'دیباگ کردن', 'query': 'چطور خطاها را پیدا و رفع کنم؟'},
    {'icon': '✨', 'title': 'بهترین شیوه‌ها', 'query': 'بهترین شیوه‌های برنامه‌نویسی در MiniLang چیست؟'},
    {'icon': '❌', 'title': 'خطاهای رایج', 'query': 'خطاهای رایج در MiniLang چیست؟'},
  ];
}