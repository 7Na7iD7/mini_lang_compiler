import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearningScreenAdvanced extends StatefulWidget {
  const LearningScreenAdvanced({super.key});

  @override
  State<LearningScreenAdvanced> createState() => _LearningScreenAdvancedState();
}

class _LearningScreenAdvancedState extends State<LearningScreenAdvanced> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLearningCard(
                    index: 0,
                    title: 'عملگرهای مقایسه‌ای',
                    icon: Icons.compare_arrows_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'عملگرهای مقایسه‌ای برای مقایسه دو مقدار و بازگشت نتیجه boolean استفاده می‌شوند.',
                    codeExample: '''int a = 10;
int b = 20;

print(a > b);
print(a < b);
print(a >= 10);
print(a <= 10);
print(a == b);
print(a != b);''',
                    explanation: 'عملگرهای >، <، >=، <=، ==، != برای مقایسه اعداد استفاده می‌شوند و نتیجه true یا false برمی‌گردانند.',
                    output: 'false\ntrue\ntrue\ntrue\nfalse\ntrue',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 1,
                    title: 'انتساب مقدار',
                    icon: Icons.add_circle_outline_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'در MiniLang برای تغییر مقدار متغیر باید از عملیات کامل استفاده کنید.',
                    codeExample: '''int x = 10;

x = x + 5;
print(x);

x = x - 3;
print(x);

x = x * 2;
print(x);

x = x / 4;
print(x);''',
                    explanation: 'برای تغییر مقدار متغیر باید از فرم کامل استفاده کنید: x = x + value',
                    output: '15\n12\n24\n6',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 2,
                    title: 'کار با رشته‌ها (String)',
                    icon: Icons.text_fields_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'رشته‌ها برای ذخیره متن استفاده می‌شوند. می‌توان رشته‌ها را با + به هم وصل کرد.',
                    codeExample: '''string firstName = "علی";
string lastName = "احمدی";
string fullName = firstName + " " + lastName;

print(fullName);
print("سلام " + firstName);

int age = 25;
print("سن: " + age);''',
                    explanation: 'عملگر + برای رشته‌ها به معنای الحاق (concatenation) است. اعداد به طور خودکار به رشته تبدیل می‌شوند.',
                    output: 'علی احمدی\nسلام علی\nسن: 25',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 3,
                    title: 'Escape Characters',
                    icon: Icons.backspace_rounded,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'کاراکترهای فرار برای نمایش کاراکترهای خاص در رشته‌ها استفاده می‌شوند.',
                    codeExample: '''string text1 = "سطر اول\\nسطر دوم";
print(text1);

string text2 = "نام:\\t\\tعلی";
print(text2);

string text3 = "\\"متن داخل گیومه\\"";
print(text3);''',
                    explanation: '\\n برای خط جدید، \\t برای تب، \\\\ برای بک‌اسلش و \\" برای گیومه استفاده می‌شود.',
                    output: 'سطر اول\nسطر دوم\nنام:\t\tعلی\n"متن داخل گیومه"',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 4,
                    title: 'حلقه‌های تو در تو (Nested Loops)',
                    icon: Icons.grid_4x4_rounded,
                    gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
                    description: 'می‌توان حلقه‌ها را داخل یکدیگر قرار داد برای کار با ساختارهای دوبعدی.',
                    codeExample: '''for (int i = 1; i <= 3; i = i + 1) {
    for (int j = 1; j <= 3; j = j + 1) {
        print(i * j);
    }
}''',
                    explanation: 'حلقه بیرونی 3 بار اجرا می‌شود و برای هر بار، حلقه داخلی 3 بار اجرا می‌شود. در مجموع 9 عدد چاپ می‌شود.',
                    output: '1\n2\n3\n2\n4\n6\n3\n6\n9',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 5,
                    title: 'دستورات شرطی تو در تو',
                    icon: Icons.account_tree_rounded,
                    gradient: const [Color(0xFF30cfd0), Color(0xFF330867)],
                    description: 'می‌توان دستورات if را داخل یکدیگر قرار داد برای بررسی شرایط پیچیده‌تر.',
                    codeExample: '''int age = 20;
boolean hasLicense = true;

if (age >= 18) {
    if (hasLicense == true) {
        print("می‌توانید رانندگی کنید");
    } else {
        print("گواهینامه لازم است");
    }
} else {
    print("سن کافی نیست");
}''',
                    explanation: 'ابتدا سن بررسی می‌شود، سپس در صورت بزرگ‌تر بودن از 18، وجود گواهینامه بررسی می‌شود.',
                    output: 'می‌توانید رانندگی کنید',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 6,
                    title: 'پیمایش آرایه با حلقه',
                    icon: Icons.list_alt_rounded,
                    gradient: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
                    description: 'با استفاده از حلقه for می‌توان تمام عناصر یک آرایه را پیمایش کرد.',
                    codeExample: '''int scores[5];
scores[0] = 85;
scores[1] = 92;
scores[2] = 78;
scores[3] = 95;
scores[4] = 88;

for (int i = 0; i < 5; i = i + 1) {
    print(scores[i]);
}''',
                    explanation: 'حلقه از اندیس 0 تا 4 می‌رود و هر عنصر آرایه را چاپ می‌کند.',
                    output: '85\n92\n78\n95\n88',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 7,
                    title: 'محاسبه مجموع آرایه',
                    icon: Icons.calculate_outlined,
                    gradient: const [Color(0xFFff9a9e), Color(0xFFfecfef)],
                    description: 'یک الگوی رایج برای محاسبه مجموع عناصر آرایه با استفاده از حلقه.',
                    codeExample: '''int numbers[5];
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;
numbers[3] = 40;
numbers[4] = 50;

int sum = 0;
for (int i = 0; i < 5; i = i + 1) {
    sum = sum + numbers[i];
}

print(sum);''',
                    explanation: 'متغیر sum ابتدا صفر است و در هر تکرار، مقدار عنصر فعلی به آن اضافه می‌شود.',
                    output: '150',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 8,
                    title: 'توابع با پارامترهای متعدد',
                    icon: Icons.functions_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'توابع می‌توانند چند پارامتر دریافت کنند و با آنها محاسبات پیچیده‌تر انجام دهند.',
                    codeExample: '''int max(int a, int b, int c) {
    int result = a;
    if (b > result) {
        result = b;
    }
    if (c > result) {
        result = c;
    }
    return result;
}

void main() {
    int largest = max(15, 42, 28);
    print(largest);
}''',
                    explanation: 'این تابع سه عدد دریافت می‌کند و بزرگترین آنها را برمی‌گرداند.',
                    output: '42',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 9,
                    title: 'توابع void (بدون مقدار برگشتی)',
                    icon: Icons.call_made_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'توابع void کاری انجام می‌دهند اما مقداری برنمی‌گردانند.',
                    codeExample: '''void printGreeting(string name) {
    print("سلام " + name);
    print("خوش آمدید!");
}

void main() {
    printGreeting("علی");
    printGreeting("سارا");
}''',
                    explanation: 'تابع printGreeting پیامی چاپ می‌کند اما return ندارد. از void برای توابعی که فقط عملیات انجام می‌دهند استفاده می‌شود.',
                    output: 'سلام علی\nخوش آمدید!\nسلام سارا\nخوش آمدید!',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 10,
                    title: 'توابع با شرط',
                    icon: Icons.device_hub_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'توابع می‌توانند شامل دستورات شرطی برای منطق پیچیده‌تر باشند.',
                    codeExample: '''string grade(int score) {
    if (score >= 90) {
        return "عالی";
    } else if (score >= 70) {
        return "خوب";
    } else if (score >= 50) {
        return "قبولی";
    } else {
        return "مردودی";
    }
}

void main() {
    print(grade(95));
    print(grade(75));
    print(grade(45));
}''',
                    explanation: 'تابع grade بر اساس نمره، یک رشته برمی‌گرداند. از چند return در شاخه‌های مختلف استفاده شده است.',
                    output: 'عالی\nخوب\nمردودی',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 11,
                    title: 'فاکتوریل با حلقه',
                    icon: Icons.repeat_one_rounded,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'محاسبه فاکتوریل با استفاده از حلقه به جای بازگشت.',
                    codeExample: '''int factorial(int n) {
    int result = 1;
    for (int i = 1; i <= n; i = i + 1) {
        result = result * i;
    }
    return result;
}

void main() {
    print(factorial(5));
    print(factorial(6));
}''',
                    explanation: 'این روش غیربازگشتی است و از حلقه استفاده می‌کند. factorial(5) = 1 × 2 × 3 × 4 × 5',
                    output: '120\n720',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 12,
                    title: 'الگوی جستجو در آرایه',
                    icon: Icons.search_rounded,
                    gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
                    description: 'جستجوی خطی برای یافتن یک مقدار در آرایه.',
                    codeExample: '''int search(int arr[5], int target) {
    for (int i = 0; i < 5; i = i + 1) {
        if (arr[i] == target) {
            return i;
        }
    }
    return -1;
}

void main() {
    int data[5];
    data[0] = 10;
    data[1] = 25;
    data[2] = 30;
    data[3] = 45;
    data[4] = 50;
    
    print(search(data, 30));
    print(search(data, 99));
}''',
                    explanation: 'تابع search آرایه را پیمایش می‌کند. اگر مقدار پیدا شد، اندیس آن را برمی‌گرداند، وگرنه -1 برمی‌گرداند.',
                    output: '2\n-1',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 13,
                    title: 'حداکثر و حداقل آرایه',
                    icon: Icons.show_chart_rounded,
                    gradient: const [Color(0xFF30cfd0), Color(0xFF330867)],
                    description: 'الگویی برای یافتن بزرگترین و کوچکترین عنصر آرایه.',
                    codeExample: '''int findMax(int arr[5]) {
    int max = arr[0];
    for (int i = 1; i < 5; i = i + 1) {
        if (arr[i] > max) {
            max = arr[i];
        }
    }
    return max;
}

void main() {
    int nums[5];
    nums[0] = 45;
    nums[1] = 12;
    nums[2] = 89;
    nums[3] = 34;
    nums[4] = 67;
    
    print(findMax(nums));
}''',
                    explanation: 'فرض اولیه این است که اولین عنصر بزرگترین است، سپس با حلقه بقیه عناصر بررسی می‌شوند.',
                    output: '89',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 14,
                    title: 'توابع کمکی (Helper Functions)',
                    icon: Icons.handyman_rounded,
                    gradient: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
                    description: 'توابع کوچک که به توابع اصلی کمک می‌کنند و کد را ساده‌تر می‌کنند.',
                    codeExample: '''boolean isEven(int n) {
    return n % 2 == 0;
}

void printIfEven(int n) {
    if (isEven(n) == true) {
        print(n);
    }
}

void main() {
    printIfEven(10);
    printIfEven(15);
    printIfEven(22);
}''',
                    explanation: 'تابع isEven بررسی می‌کند عدد زوج است یا خیر. تابع printIfEven از آن استفاده می‌کند.',
                    output: '10\n22',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 15,
                    title: 'محاسبه میانگین',
                    icon: Icons.analytics_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'محاسبه میانگین اعداد یک آرایه.',
                    codeExample: '''float average(int arr[5]) {
    int sum = 0;
    for (int i = 0; i < 5; i = i + 1) {
        sum = sum + arr[i];
    }
    return sum / 5;
}

void main() {
    int scores[5];
    scores[0] = 85;
    scores[1] = 90;
    scores[2] = 78;
    scores[3] = 92;
    scores[4] = 88;
    
    print(average(scores));
}''',
                    explanation: 'ابتدا مجموع محاسبه می‌شود، سپس بر تعداد عناصر تقسیم می‌شود. نتیجه از نوع float است.',
                    output: '86.6',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 16,
                    title: 'توابع boolean (منطقی)',
                    icon: Icons.check_circle_outline_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'توابعی که true یا false برمی‌گردانند برای بررسی شرایط.',
                    codeExample: '''boolean isPrime(int n) {
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

void main() {
    print(isPrime(7));
    print(isPrime(10));
    print(isPrime(13));
}''',
                    explanation: 'تابع isPrime بررسی می‌کند عدد اول است یا نه. اگر مقسوم‌علیهی داشته باشد، false برمی‌گرداند.',
                    output: 'true\nfalse\ntrue',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 17,
                    title: 'کار با اعداد اعشاری (Float)',
                    icon: Icons.calculate,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'استفاده از نوع float برای محاسبات دقیق‌تر.',
                    codeExample: '''float calculateCircleArea(float radius) {
    float pi = 3.14159;
    return pi * radius * radius;
}

void main() {
    float r = 5.0;
    float area = calculateCircleArea(r);
    print(area);
}''',
                    explanation: 'برای محاسبات ریاضی که نیاز به دقت بیشتر دارند، از float استفاده می‌شود.',
                    output: '78.53975',
                  ),
                  const SizedBox(height: 32),
                  _buildBestPracticesSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مفاهیم پیشرفته',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'الگوها و تکنیک‌های حرفه‌ای',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningCard({
    required int index,
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required String description,
    required String codeExample,
    required String explanation,
    required String output,
  }) {
    final isExpanded = _expandedIndex == index;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              gradient.first.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: gradient.first,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCodeBlock(codeExample),
                    const SizedBox(height: 12),
                    Text(
                      'توضیح:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: gradient.first,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOutputBlock(output, gradient.first),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFAED581),
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: Colors.white70,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('کد کپی شد'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOutputBlock(String output, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'خروجی:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            output,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPracticesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'بهترین شیوه‌های برنامه‌نویسی',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBestPracticeItem(
              'نام‌گذاری معنادار',
              'از نام‌های توصیفی برای متغیرها و توابع استفاده کنید',
              Icons.label_rounded,
            ),
            _buildBestPracticeItem(
              'توابع کوچک',
              'هر تابع باید یک کار مشخص انجام دهد',
              Icons.functions_rounded,
            ),
            _buildBestPracticeItem(
              'اجتناب از تکرار',
              'کدهای تکراری را در توابع جداگانه قرار دهید',
              Icons.content_copy_rounded,
            ),
            _buildBestPracticeItem(
              'مدیریت خطا',
              'شرایط خطا را بررسی کنید (مثل تقسیم بر صفر)',
              Icons.error_outline_rounded,
            ),
            _buildBestPracticeItem(
              'کامنت‌گذاری',
              'کدهای پیچیده را با توضیح همراه کنید',
              Icons.comment_rounded,
            ),
            _buildBestPracticeItem(
              'تست کردن',
              'کد خود را با ورودی‌های مختلف امتحان کنید',
              Icons.science_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPracticeItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}