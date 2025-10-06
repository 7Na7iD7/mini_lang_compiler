// learning_screen_pro.dart - اصلاح شده کامل
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearningScreenPro extends StatefulWidget {
  const LearningScreenPro({super.key});

  @override
  State<LearningScreenPro> createState() => _LearningScreenProState();
}

class _LearningScreenProState extends State<LearningScreenPro> {
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
                    title: 'توابع (Functions)',
                    icon: Icons.functions_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'توابع برای سازماندهی و استفاده مجدد از کد استفاده می‌شوند. تابع main() برای اجرای برنامه اجباری است.',
                    codeExample: '''void greet(string name) {
    print("سلام " + name);
}

int add(int a, int b) {
    return a + b;
}

void main() {
    greet("علی");
    int result = add(5, 3);
    print(result);
}''',
                    explanation: 'تابع greet یک رشته را چاپ می‌کند. تابع add دو عدد را جمع کرده و نتیجه را برمی‌گرداند. تابع main() نقطه شروع اجرای برنامه است.',
                    output: 'سلام علی\n8',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 1,
                    title: 'دستور switch',
                    icon: Icons.switch_account_rounded,
                    gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    description: 'دستور switch برای انتخاب بین چندین حالت بر اساس مقدار یک عبارت استفاده می‌شود.',
                    codeExample: '''int day = 3;

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
    default: 
        print("روز نامشخص");
}''',
                    explanation: 'بر اساس مقدار متغیر day، دستور مربوط به آن case اجرا می‌شود. دستور break برای خروج از switch ضروری است و default برای زمانی است که هیچ‌کدام از حالت‌ها مطابقت نداشته باشند.',
                    output: 'سه‌شنبه',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 2,
                    title: 'دستورات break و continue',
                    icon: Icons.skip_next_rounded,
                    gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    description: 'دستور break برای خروج کامل از حلقه و continue برای رد کردن تکرار فعلی و رفتن به تکرار بعدی استفاده می‌شود.',
                    codeExample: '''for (int i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
        continue;
    }
    if (i == 5) {
        break;
    }
    print(i);
}''',
                    explanation: 'وقتی i برابر 3 می‌شود، continue باعث می‌شود حلقه به تکرار بعدی برود. وقتی i برابر 5 می‌شود، break حلقه را متوقف می‌کند. در نتیجه اعداد 1، 2 و 4 چاپ می‌شوند.',
                    output: '1\n2\n4',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 3,
                    title: 'آرایه‌ها (Arrays)',
                    icon: Icons.grid_view_rounded,
                    gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
                    description: 'آرایه‌ها برای ذخیره مجموعه‌ای از مقادیر هم‌نوع در یک متغیر استفاده می‌شوند. باید با اندازه مشخص تعریف شوند.',
                    codeExample: '''int numbers[5];
numbers[0] = 10;
numbers[1] = 20;
numbers[2] = 30;
numbers[3] = 40;
numbers[4] = 50;

print(numbers[0]);
print(numbers[2]);''',
                    explanation: 'آرایه با اندازه 5 تعریف می‌شود. برای دسترسی به عناصر از [index] استفاده می‌شود. می‌توان مقدار عناصر را در طول برنامه تغییر داد.',
                    output: '10\n30',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 4,
                    title: 'توابع لامبدا (Lambda)',
                    icon: Icons.arrow_forward_rounded,
                    gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                    description: 'لامبدا توابع ناشناس و کوچکی هستند که معمولاً برای عملیات ساده و یک‌بار مصرف استفاده می‌شوند. فقط یک expression می‌توانند داشته باشند.',
                    codeExample: '''void main() {
    var multiply = (int a, int b) => a * b;
    int result = multiply(4, 5);
    print(result);
}''',
                    explanation: 'یک تابع lambda با ساختار (parameters) => expression تعریف می‌شود. در این مثال، تابع در متغیر multiply ذخیره و سپس فراخوانی شده است. Lambda فقط یک expression برمی‌گرداند و نمی‌تواند چند خط کد داشته باشد.',
                    output: '20',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 5,
                    title: 'const و var',
                    icon: Icons.lock_rounded,
                    gradient: const [Color(0xFFffecd2), Color(0xFFfcb69f)],
                    description: 'از const برای تعریف مقادیر ثابت و غیرقابل تغییر استفاده می‌شود. var به کامپایلر اجازه می‌دهد نوع را خودکار تشخیص دهد.',
                    codeExample: '''const float PI = 3.14;
var message = "سلام";

message = "خداحافظ";
print(PI);
print(message);''',
                    explanation: 'مقدار یک متغیر const پس از تعریف اولیه قابل تغییر نیست. متغیر var مانند int، string و غیره قابل تغییر است اما تعریف آن صریح‌تر است.',
                    output: '3.14\nخداحافظ',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 6,
                    title: 'نکات مهم درباره سینتکس',
                    icon: Icons.warning_amber_rounded,
                    gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    description: 'نکات کلیدی که باید در نوشتن کد MiniLang رعایت کنید.',
                    codeExample: '''// ✅ درست - تعریف تابع
int add(int a, int b) {
    return a + b;
}

// ❌ اشتباه - func وجود ندارد
// func add(int a, int b) : int {
//     return a + b;
// }

// ✅ درست - آرایه
int arr[5];
arr[0] = 10;

// ❌ اشتباه - مقداردهی با {}
// int arr[] = {1, 2, 3};

// ✅ درست - تغییر مقدار
x = x + 5;

// ❌ اشتباه - += وجود ندارد
// x += 5;''',
                    explanation: 'کلمه کلیدی func وجود ندارد - مستقیم نوع برگشتی را بنویسید. آرایه‌ها باید با اندازه مشخص تعریف شوند. عملگرهای ترکیبی (+=، -=) پشتیبانی نمی‌شوند.',
                    output: '---',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 7,
                    title: 'محدودیت‌های Lambda',
                    icon: Icons.info_outline_rounded,
                    gradient: const [Color(0xFF8360c3), Color(0xFF2ebf91)],
                    description: 'توابع Lambda محدودیت‌های خاصی دارند که باید به آنها توجه کنید.',
                    codeExample: '''void main() {
    // ✅ درست - یک expression ساده
    var square = (int x) => x * x;
    print(square(5));
    
    // ❌ اشتباه - نمی‌توان چند خط داشت
    // var complex = (int x) => {
    //     int temp = x * 2;
    //     return temp + 5;
    // };
    
    // برای عملیات پیچیده از تابع معمولی استفاده کنید
}''',
                    explanation: 'Lambda فقط یک expression می‌تواند داشته باشد. نمی‌توان چند خط کد یا statement در Lambda نوشت. برای منطق پیچیده‌تر، از توابع معمولی استفاده کنید.',
                    output: '25',
                  ),
                  const SizedBox(height: 16),
                  _buildLearningCard(
                    index: 8,
                    title: 'شمارش با حلقه',
                    icon: Icons.add_rounded,
                    gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    description: 'شمارش تعداد عناصری که شرط خاصی را برآورده می‌کنند.',
                    codeExample: '''int countPositive(int arr[5]) {
    int count = 0;
    for (int i = 0; i < 5; i = i + 1) {
        if (arr[i] > 0) {
            count = count + 1;
        }
    }
    return count;
}

void main() {
    int data[5];
    data[0] = -5;
    data[1] = 10;
    data[2] = -3;
    data[3] = 8;
    data[4] = 0;
    
    print(countPositive(data));
}''',
                    explanation: 'این تابع تعداد اعداد مثبت در آرایه را می‌شمارد. count برای هر عدد مثبت یک واحد افزایش می‌یابد.',
                    output: '2',
                  ),
                  const SizedBox(height: 32),
                  _buildImportantNotesSection(),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'آموزش حرفه‌ای MiniLang',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ویژگی‌های حرفه‌ای و بهترین شیوه‌ها',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
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

  Widget _buildImportantNotesSection() {
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
              Colors.orange.shade50,
              Colors.red.shade50,
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
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'نکات مهم و تفاوت‌ها',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildImportantNote(
              '❌ کلمه کلیدی func وجود ندارد',
              'مستقیماً نوع برگشتی را بنویسید: int add(...) نه func add(...)',
            ),
            _buildImportantNote(
              '❌ عملگرهای ترکیبی (+=، -=) پشتیبانی نمی‌شوند',
              'از فرم کامل استفاده کنید: x = x + 5',
            ),
            _buildImportantNote(
              '❌ آرایه‌ها با {} مقداردهی اولیه نمی‌شوند',
              'ابتدا با اندازه تعریف کنید، سپس عناصر را مقداردهی کنید',
            ),
            _buildImportantNote(
              '✅ تابع main() الزامی است',
              'برای اجرای برنامه باید تابع main() تعریف شود',
            ),
            _buildImportantNote(
              '✅ Lambda فقط یک expression',
              'نمی‌توان چند خط کد یا statement در Lambda نوشت',
            ),
            _buildImportantNote(
              '✅ همه دستورات با ; پایان می‌یابند',
              'فراموش نکنید semicolon در پایان هر دستور بگذارید',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNote(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.startsWith('❌') ? '❌' : '✅',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.substring(2),
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