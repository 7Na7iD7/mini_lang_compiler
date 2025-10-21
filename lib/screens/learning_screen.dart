import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
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
                    title: 'متغیرها و انواع داده',
                    icon: Icons.storage_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'متغیرها برای ذخیره مقادیر استفاده می‌شوند. MiniLang از انواع داده مختلفی پشتیبانی می‌کند.',
                    codeExample: '''int age = 25;
float price = 19.99;
string name = "علی";
boolean isActive = true;
var autoType = 100;

print(name);
print(age);''',
                    explanation: 'در این مثال، پنج متغیر با انواع مختلف تعریف شده‌اند. کلمه کلیدی "var" به کامپایلر اجازه می‌دهد نوع را خودکار تشخیص دهد.',
                    output: 'علی\n25',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 1,
                    title: 'عملگرهای ریاضی',
                    icon: Icons.calculate_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'عملگرهای ریاضی برای انجام محاسبات استفاده می‌شوند.',
                    codeExample: '''int a = 10;
int b = 3;

print(a + b);
print(a - b);
print(a * b);
print(a / b);
print(a % b);''',
                    explanation: 'عملگرهای +، -، *، / و % به ترتیب برای جمع، تفریق، ضرب، تقسیم و باقیمانده تقسیم استفاده می‌شوند.',
                    output: '13\n7\n30\n3.333333333333333\n1',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 2,
                    title: 'دستورات شرطی (if-else)',
                    icon: Icons.alt_route_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'دستورات شرطی برای اجرای کدهای مختلف بر اساس شرایط استفاده می‌شوند.',
                    codeExample: '''int score = 85;

if (score >= 90) {
    print("عالی");
} else if (score >= 70) {
    print("خوب");
} else {
    print("نیاز به تلاش بیشتر");
}''',
                    explanation: 'در این مثال، بر اساس مقدار نمره، پیام متفاوتی چاپ می‌شود. چون نمره 85 است، "خوب" چاپ می‌شود.',
                    output: 'خوب',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 3,
                    title: 'حلقه while',
                    icon: Icons.loop_rounded,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'حلقه while تا زمانی که شرط برقرار است، کد را تکرار می‌کند.',
                    codeExample: '''int counter = 1;

while (counter <= 5) {
    print(counter);
    counter = counter + 1;
}''',
                    explanation: 'این حلقه اعداد 1 تا 5 را چاپ می‌کند. در هر تکرار، مقدار counter یک واحد افزایش می‌یابد.',
                    output: '1\n2\n3\n4\n5',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 4,
                    title: 'حلقه for',
                    icon: Icons.repeat_rounded,
                    gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
                    description: 'حلقه for برای تکرار با تعداد مشخص استفاده می‌شود.',
                    codeExample: '''for (int i = 0; i < 5; i = i + 1) {
    print(i * 2);
}''',
                    explanation: 'این حلقه پنج بار اجرا می‌شود و در هر بار، دو برابر مقدار i را چاپ می‌کند.',
                    output: '0\n2\n4\n6\n8',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 5,
                    title: 'حلقه do-while',
                    icon: Icons.rotate_right_rounded,
                    gradient: const [Color(0xFF30cfd0), Color(0xFF330867)],
                    description: 'حلقه do-while حداقل یک بار اجرا می‌شود، سپس شرط را بررسی می‌کند.',
                    codeExample: '''int num = 1;

do {
    print(num);
    num = num + 1;
} while (num <= 3);''',
                    explanation: 'این حلقه ابتدا کد داخل بلوک را اجرا می‌کند، سپس شرط را بررسی می‌کند.',
                    output: '1\n2\n3',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 6,
                    title: 'دستور switch',
                    icon: Icons.device_hub_rounded,
                    gradient: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
                    description: 'switch برای بررسی چند حالت مختلف یک متغیر استفاده می‌شود.',
                    codeExample: '''int day = 3;

switch (day) {
    case 1:
        print("شنبه");
        break;
    case 2:
        print("یکشنبه");
        break;
    case 3:
        print("دوشنبه");
        break;
    default:
        print("روز نامعتبر");
}''',
                    explanation: 'بر اساس مقدار day، نام روز متناظر چاپ می‌شود. break باعث خروج از switch می‌شود.',
                    output: 'دوشنبه',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 7,
                    title: 'آرایه‌ها',
                    icon: Icons.view_list_rounded,
                    gradient: const [Color(0xFFff9a9e), Color(0xFFfecfef)],
                    description: 'آرایه‌ها مجموعه‌ای از عناصر با اندازه ثابت هستند. توجه: آرایه‌ها با اندازه مشخص تعریف می‌شوند.',
                    codeExample: '''int numbers[5];
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;

print(numbers[0]);
print(numbers[1]);
print(numbers[2]);''',
                    explanation: 'یک آرایه با 5 عنصر ایجاد شده و مقادیر به آن نسبت داده می‌شوند. اندیس‌گذاری از 0 شروع می‌شود.',
                    output: '10\n20\n30',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 8,
                    title: 'توابع',
                    icon: Icons.functions_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'توابع بلوک‌های قابل استفاده مجدد از کد هستند که می‌توانند مقادیری دریافت و برگردانند.',
                    codeExample: '''int add(int a, int b) {
    return a + b;
}

void main() {
    int result = add(5, 3);
    print(result);
}''',
                    explanation: 'تابع add دو عدد را جمع می‌کند و نتیجه را برمی‌گرداند. تابع main نقطه شروع برنامه است.',
                    output: '8',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 9,
                    title: 'توابع بازگشتی',
                    icon: Icons.autorenew_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'توابع بازگشتی توابعی هستند که خودشان را فراخوانی می‌کنند.',
                    codeExample: '''int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

void main() {
    print(factorial(5));
}''',
                    explanation: 'این تابع فاکتوریل یک عدد را محاسبه می‌کند. factorial(5) = 5 * 4 * 3 * 2 * 1 = 120',
                    output: '120',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 10,
                    title: 'توابع Lambda',
                    icon: Icons.code_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'Lambda توابع بی‌نام کوچکی هستند که می‌توانند به‌عنوان مقدار استفاده شوند. محدودیت: فقط یک expression می‌توانند داشته باشند.',
                    codeExample: '''void main() {
    var multiply = (int x, int y) => x * y;
    int result = multiply(4, 5);
    print(result);
}''',
                    explanation: 'یک تابع lambda برای ضرب دو عدد تعریف شده است. این تابع در یک متغیر ذخیره و سپس فراخوانی می‌شود. Lambda فقط یک expression برمی‌گرداند.',
                    output: '20',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 11,
                    title: 'عملگرهای منطقی',
                    icon: Icons.lightbulb_rounded,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'عملگرهای منطقی برای ترکیب شرط‌ها استفاده می‌شوند.',
                    codeExample: '''boolean a = true;
boolean b = false;

print(a && b);
print(a || b);
print(!a);''',
                    explanation: '&& (و منطقی)، || (یا منطقی) و ! (نقیض) عملگرهای منطقی هستند.',
                    output: 'false\ntrue\nfalse',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 12,
                    title: 'break و continue',
                    icon: Icons.skip_next_rounded,
                    gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
                    description: 'break از حلقه خارج می‌شود و continue به تکرار بعدی می‌رود.',
                    codeExample: '''for (int i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
        continue;
    }
    if (i == 5) {
        break;
    }
    print(i);
}''',
                    explanation: 'عدد 3 با continue رد می‌شود و حلقه با break در عدد 5 متوقف می‌شود.',
                    output: '1\n2\n4',
                  ),
                  const SizedBox(height: 32),
                  _buildTipsSection(),
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
              Icons.school_rounded,
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
                  'آموزش زبان MiniLang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'مفاهیم پایه و پیشرفته',
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

  Widget _buildTipsSection() {
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
              Colors.amber.shade50,
              Colors.orange.shade50,
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
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'نکات مهم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem('برای اجرای برنامه، باید تابع main() تعریف شود'),
            _buildTipItem('همه دستورات باید با semicolon (;) پایان یابند'),
            _buildTipItem('نام متغیرها و توابع باید با حرف یا underscore شروع شوند'),
            _buildTipItem('از تورفتگی (indentation) مناسب استفاده کنید'),
            _buildTipItem('می‌توانید با // یا /* */ توضیحات بنویسید'),
            _buildTipItem('آرایه‌ها باید با اندازه مشخص تعریف شوند: int arr[10];'),
            _buildTipItem('توابع lambda فقط یک expression می‌توانند داشته باشند'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}