import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';
import 'dart:ui';

class ExampleCodeSelector extends StatefulWidget {
  final VoidCallback? onExampleSelected;
  const ExampleCodeSelector({super.key, this.onExampleSelected});

  @override
  State<ExampleCodeSelector> createState() => _ExampleCodeSelectorState();
}

class _ExampleCodeSelectorState extends State<ExampleCodeSelector> with TickerProviderStateMixin {
  String? _lastLoadedExample;
  String _selectedCategory = 'All';
  late AnimationController _pulseController;
  late AnimationController _slideController;

  static const examples = [
    // Basic Examples
    {
      'name': 'simple',
      'title': 'Hello World',
      'description': 'Simple greeting function and variables',
      'icon': Icons.waving_hand,
      'difficulty': 'Beginner',
      'color': Colors.green,
      'estimatedLines': 8,
      'category': 'Basic',
    },
    {
      'name': 'var_demo',
      'title': 'Variable Demo',
      'description': 'Variable declarations with var keyword',
      'icon': Icons.text_fields,
      'difficulty': 'Beginner',
      'color': Colors.purple,
      'estimatedLines': 6,
      'category': 'Basic',
    },
    {
      'name': 'array',
      'title': 'Array Operations',
      'description': 'Array declaration, assignment and loops',
      'icon': Icons.list,
      'difficulty': 'Beginner',
      'color': Colors.blue,
      'estimatedLines': 12,
      'category': 'Basic',
    },
    {
      'name': 'loop',
      'title': 'For Loop',
      'description': 'Iteration and loop constructs',
      'icon': Icons.loop,
      'difficulty': 'Beginner',
      'color': Colors.cyan,
      'estimatedLines': 16,
      'category': 'Basic',
    },
    // Control Flow
    {
      'name': 'do_while',
      'title': 'Do-While Loop',
      'description': 'Loop that executes at least once',
      'icon': Icons.replay,
      'difficulty': 'Beginner',
      'color': Colors.teal,
      'estimatedLines': 10,
      'category': 'Control Flow',
      'badge': 'NEW',
    },
    {
      'name': 'break_continue',
      'title': 'Break & Continue',
      'description': 'Control flow with break and continue',
      'icon': Icons.exit_to_app,
      'difficulty': 'Beginner',
      'color': Colors.indigo,
      'estimatedLines': 22,
      'category': 'Control Flow',
      'badge': 'NEW',
    },
    {
      'name': 'switch_case',
      'title': 'Switch-Case',
      'description': 'Multi-way branching with switch',
      'icon': Icons.alt_route,
      'difficulty': 'Intermediate',
      'color': Colors.deepOrange,
      'estimatedLines': 20,
      'category': 'Control Flow',
      'badge': 'NEW',
    },
    // Functions
    {
      'name': 'lambda',
      'title': 'Lambda Functions',
      'description': 'Anonymous functions with arrow syntax',
      'icon': Icons.arrow_forward,
      'difficulty': 'Intermediate',
      'color': Colors.pink,
      'estimatedLines': 14,
      'category': 'Functions',
      'badge': 'NEW',
    },
    {
      'name': 'advanced_lambda',
      'title': 'Advanced Lambda',
      'description': 'Higher-order functions with lambdas',
      'icon': Icons.functions_rounded,
      'difficulty': 'Intermediate',
      'color': Colors.deepPurple,
      'estimatedLines': 16,
      'category': 'Functions',
    },
    {
      'name': 'recursive',
      'title': 'Recursion',
      'description': 'Factorial and power with recursion',
      'icon': Icons.cached,
      'difficulty': 'Intermediate',
      'color': Colors.amber,
      'estimatedLines': 18,
      'category': 'Functions',
    },
    {
      'name': 'fibonacci',
      'title': 'Fibonacci',
      'description': 'Recursive function with mathematical sequence',
      'icon': Icons.functions,
      'difficulty': 'Intermediate',
      'color': Colors.orange,
      'estimatedLines': 15,
      'category': 'Functions',
    },
    // Math & Numbers
    {
      'name': 'math_simple',
      'title': 'Simple Math',
      'description': 'Basic arithmetic operations',
      'icon': Icons.add_circle_outline,
      'difficulty': 'Beginner',
      'color': Colors.lightGreen,
      'estimatedLines': 30,
      'category': 'Math',
      'badge': 'NEW',
    },
    {
      'name': 'math_advanced',
      'title': 'Advanced Math',
      'description': 'GCD, LCM, Prime checking algorithms',
      'icon': Icons.calculate,
      'difficulty': 'Intermediate',
      'color': Colors.lightBlue,
      'estimatedLines': 45,
      'category': 'Math',
      'badge': 'NEW',
    },
    {
      'name': 'calculator',
      'title': 'Calculator',
      'description': 'Simple calculator with operations',
      'icon': Icons.dialpad,
      'difficulty': 'Beginner',
      'color': Colors.blueGrey,
      'estimatedLines': 40,
      'category': 'Math',
      'badge': 'NEW',
    },
    {
      'name': 'number_games',
      'title': 'Number Games',
      'description': 'Find max/min, sum range, count numbers',
      'icon': Icons.casino,
      'difficulty': 'Intermediate',
      'color': Colors.lime,
      'estimatedLines': 50,
      'category': 'Math',
      'badge': 'NEW',
    },
    // String & Patterns
    {
      'name': 'string_operations',
      'title': 'String Operations',
      'description': 'String concatenation and manipulation',
      'icon': Icons.abc,
      'difficulty': 'Beginner',
      'color': Colors.brown,
      'estimatedLines': 35,
      'category': 'String',
      'badge': 'NEW',
    },
    {
      'name': 'pattern_printing',
      'title': 'Pattern Printing',
      'description': 'Stars, triangles, and countdown patterns',
      'icon': Icons.grid_4x4,
      'difficulty': 'Beginner',
      'color': Colors.grey,
      'estimatedLines': 45,
      'category': 'String',
      'badge': 'NEW',
    },
    // Combined
    {
      'name': 'combined',
      'title': 'Combined Features',
      'description': 'All new features in one example',
      'icon': Icons.stars,
      'difficulty': 'Advanced',
      'color': Colors.red,
      'estimatedLines': 30,
      'category': 'Advanced',
      'badge': 'HOT',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<CompilerProvider, _CompilerUIState>(
      selector: (_, provider) => _CompilerUIState(
        isCompiling: provider.isCompiling,
        isCacheEnabled: provider.isCacheEnabled,
        cacheStats: provider.cacheStatistics,
      ),
      builder: (context, state, _) => _buildContent(state),
    );
  }

  Widget _buildContent(_CompilerUIState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50.withOpacity(0.3),
            Colors.purple.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Card(
            elevation: 0,
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    isCacheEnabled: state.isCacheEnabled,
                    totalExamples: examples.length,
                    pulseController: _pulseController,
                  ),
                  const SizedBox(height: 24),
                  if (state.isCacheEnabled)
                    _CacheStatusBadge(
                      hitRate: state.cacheStats['hitRate'] ?? '0%',
                      pulseController: _pulseController,
                    ),
                  if (state.isCacheEnabled) const SizedBox(height: 20),
                  _CategoryTabs(
                    selectedCategory: _selectedCategory,
                    isDisabled: state.isCompiling,
                    onCategoryChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: 20),
                  _ExampleGrid(
                    selectedCategory: _selectedCategory,
                    lastLoadedExample: _lastLoadedExample,
                    isDisabled: state.isCompiling,
                    onExampleSelected: _loadExample,
                  ),
                  if (_lastLoadedExample != null) ...[
                    const SizedBox(height: 20),
                    _LastLoadedInfo(exampleName: _lastLoadedExample!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadExample(String name, String title) {
    final provider = context.read<CompilerProvider>();
    provider.loadExampleCode(name);
    setState(() => _lastLoadedExample = name);

    final example = examples.firstWhere(
          (e) => e['name'] == name,
      orElse: () => {
        'name': name,
        'title': title,
        'icon': Icons.code,
        'difficulty': 'Unknown',
        'color': Colors.grey,
        'estimatedLines': 0,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(example['icon'] as IconData, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Loaded: $title',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${example['difficulty']} • ~${example['estimatedLines']} lines',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: example['color'] as Color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Compile Now',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            provider.compile();
          },
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExampleSelected?.call();
    });
  }
}

class _CompilerUIState {
  final bool isCompiling;
  final bool isCacheEnabled;
  final Map<String, dynamic> cacheStats;

  const _CompilerUIState({
    required this.isCompiling,
    required this.isCacheEnabled,
    required this.cacheStats,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _CompilerUIState &&
              isCompiling == other.isCompiling &&
              isCacheEnabled == other.isCacheEnabled &&
              cacheStats['hitRate'] == other.cacheStats['hitRate'];

  @override
  int get hashCode =>
      isCompiling.hashCode ^ isCacheEnabled.hashCode ^ cacheStats['hitRate'].hashCode;
}

class _Header extends StatelessWidget {
  final bool isCacheEnabled;
  final int totalExamples;
  final AnimationController pulseController;

  const _Header({
    required this.isCacheEnabled,
    required this.totalExamples,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.library_books, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Example Code Library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$totalExamples examples',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new, size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '6 new added!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isCacheEnabled)
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, size: 20, color: Colors.white),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CacheStatusBadge extends StatelessWidget {
  final String hitRate;
  final AnimationController pulseController;

  const _CacheStatusBadge({
    required this.hitRate,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade100.withOpacity(0.5 + pulseController.value * 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Text(
                'Cache Hit Rate: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hitRate,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final bool isDisabled;
  final ValueChanged<String> onCategoryChanged;

  const _CategoryTabs({
    required this.selectedCategory,
    required this.isDisabled,
    required this.onCategoryChanged,
  });

  static const categories = ['All', 'Basic', 'Control Flow', 'Functions', 'Math', 'String', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          final count = category == 'All'
              ? _ExampleCodeSelectorState.examples.length
              : _ExampleCodeSelectorState.examples
              .where((e) => e['category'] == category)
              .length;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : () => onCategoryChanged(category),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      )
                          : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExampleGrid extends StatelessWidget {
  final String selectedCategory;
  final String? lastLoadedExample;
  final bool isDisabled;
  final void Function(String name, String title) onExampleSelected;

  const _ExampleGrid({
    required this.selectedCategory,
    required this.lastLoadedExample,
    required this.isDisabled,
    required this.onExampleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filteredExamples = selectedCategory == 'All'
        ? _ExampleCodeSelectorState.examples
        : _ExampleCodeSelectorState.examples
        .where((e) => e['category'] == selectedCategory)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 170).floor().clamp(2, 4);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: filteredExamples.length,
          itemBuilder: (context, index) {
            return _ExampleCard(
              example: filteredExamples[index],
              isSelected: lastLoadedExample == filteredExamples[index]['name'],
              isDisabled: isDisabled,
              onTap: onExampleSelected,
            );
          },
        );
      },
    );
  }
}

class _ExampleCard extends StatefulWidget {
  final Map<String, dynamic> example;
  final bool isSelected;
  final bool isDisabled;
  final void Function(String name, String title) onTap;

  const _ExampleCard({
    required this.example,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.example['name'] as String;
    final title = widget.example['title'] as String;
    final description = widget.example['description'] as String;
    final icon = widget.example['icon'] as IconData;
    final difficulty = widget.example['difficulty'] as String;
    final color = widget.example['color'] as Color;
    final estimatedLines = widget.example['estimatedLines'] as int;
    final badge = widget.example['badge'] as String?;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled) {
          setState(() => _isHovered = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: RepaintBoundary(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isDisabled ? null : () => widget.onTap(name, title),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: widget.isSelected
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                      )
                          : null,
                      color: widget.isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.isSelected
                            ? color
                            : _isHovered
                            ? color.withOpacity(0.5)
                            : Colors.grey.shade200,
                        width: widget.isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isSelected
                              ? color.withOpacity(0.3)
                              : _isHovered
                              ? Colors.black.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: widget.isSelected || _isHovered ? 12 : 6,
                          offset: Offset(0, widget.isSelected || _isHovered ? 4 : 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: widget.isDisabled
                                        ? [Colors.grey.shade200, Colors.grey.shade300]
                                        : [color.withOpacity(0.2), color.withOpacity(0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  size: 28,
                                  color: widget.isDisabled ? Colors.grey.shade400 : color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDisabled ? Colors.grey.shade400 : Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getDifficultyColor(difficulty).withOpacity(0.2),
                                          _getDifficultyColor(difficulty).withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getDifficultyColor(difficulty).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      difficulty,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getDifficultyColor(difficulty),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.code, size: 10, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$estimatedLines',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (badge != null)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: badge == 'NEW'
                                      ? [Colors.green.shade400, Colors.green.shade600]
                                      : [Colors.red.shade400, Colors.red.shade600],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (badge == 'NEW' ? Colors.green : Colors.red)
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        if (widget.isSelected)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _LastLoadedInfo extends StatelessWidget {
  final String exampleName;

  const _LastLoadedInfo({required this.exampleName});

  @override
  Widget build(BuildContext context) {
    final example = _ExampleCodeSelectorState.examples
        .firstWhere((e) => e['name'] == exampleName, orElse: () => {});

    if (example.isEmpty) return const SizedBox.shrink();

    final color = example['color'] as Color;
    final icon = example['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Loaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.check_circle, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

