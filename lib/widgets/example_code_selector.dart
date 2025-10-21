import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';

class ExampleCodeSelector extends StatefulWidget {
  final VoidCallback? onExampleSelected;
  const ExampleCodeSelector({super.key, this.onExampleSelected});

  @override
  State<ExampleCodeSelector> createState() => _ExampleCodeSelectorState();
}

class _ExampleCodeSelectorState extends State<ExampleCodeSelector> {
  String? _lastLoadedExample;
  String _selectedCategory = 'All';

  static const examples = [
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
      'name': 'fibonacci',
      'title': 'Fibonacci',
      'description': 'Recursive function with mathematical sequence',
      'icon': Icons.functions,
      'difficulty': 'Intermediate',
      'color': Colors.orange,
      'estimatedLines': 15,
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
      'name': 'loop',
      'title': 'For Loop',
      'description': 'Iteration and loop constructs',
      'icon': Icons.loop,
      'difficulty': 'Intermediate',
      'color': Colors.cyan,
      'estimatedLines': 16,
      'category': 'Basic',
    },
    {
      'name': 'do_while',
      'title': 'Do-While Loop',
      'description': 'Loop that executes at least once',
      'icon': Icons.replay,
      'difficulty': 'Beginner',
      'color': Colors.teal,
      'estimatedLines': 10,
      'category': 'New Features',
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
      'category': 'New Features',
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
      'category': 'New Features',
      'badge': 'NEW',
    },
    {
      'name': 'lambda',
      'title': 'Lambda Functions',
      'description': 'Anonymous functions with arrow syntax',
      'icon': Icons.arrow_forward,
      'difficulty': 'Intermediate',
      'color': Colors.pink,
      'estimatedLines': 14,
      'category': 'New Features',
      'badge': 'NEW',
    },
    {
      'name': 'advanced_lambda',
      'title': 'Advanced Lambda',
      'description': 'Higher-order functions with lambdas',
      'icon': Icons.functions_rounded,
      'difficulty': 'Advanced',
      'color': Colors.deepPurple,
      'estimatedLines': 16,
      'category': 'New Features',
      'badge': 'NEW',
    },
    {
      'name': 'recursive',
      'title': 'Recursion',
      'description': 'Factorial and power with recursion',
      'icon': Icons.cached,
      'difficulty': 'Intermediate',
      'color': Colors.amber,
      'estimatedLines': 18,
      'category': 'Advanced',
    },
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(isCacheEnabled: state.isCacheEnabled),
            const SizedBox(height: 20),
            if (state.isCacheEnabled)
              _CacheStatusBadge(hitRate: state.cacheStats['hitRate'] ?? '0%'),
            if (state.isCacheEnabled) const SizedBox(height: 16),
            _CategoryTabs(
              selectedCategory: _selectedCategory,
              isDisabled: state.isCompiling,
              onCategoryChanged: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: 16),
            _ExampleGrid(
              selectedCategory: _selectedCategory,
              lastLoadedExample: _lastLoadedExample,
              isDisabled: state.isCompiling,
              onExampleSelected: _loadExample,
            ),
            if (_lastLoadedExample != null) ...[
              const SizedBox(height: 16),
              _LastLoadedInfo(exampleName: _lastLoadedExample!),
            ],
          ],
        ),
      ),
    );
  }

  void _loadExample(String name, String title) {
    final provider = context.read<CompilerProvider>();

    provider.loadExampleCode(name);

    setState(() => _lastLoadedExample = name);

    // FIXED: Safe firstWhere with orElse
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
            Icon(example['icon'] as IconData, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Loaded: $title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${example['difficulty']} - ~${example['estimatedLines']} lines',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: example['color'] as Color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Compile',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            provider.compile();
          },
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onExampleSelected?.call();
      }
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

  const _Header({required this.isCacheEnabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.library_books, size: 24, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Example Code Library',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Choose from 12 examples • New features available!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (isCacheEnabled)
          Tooltip(
            message: 'Smart caching enabled',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.flash_on, size: 16, color: Colors.green.shade600),
            ),
          ),
      ],
    );
  }
}

class _CacheStatusBadge extends StatelessWidget {
  final String hitRate;

  const _CacheStatusBadge({required this.hitRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            'Cache Hit Rate: $hitRate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  static const categories = ['All', 'Basic', 'New Features', 'Advanced'];

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
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$category ($count)'),
              selected: isSelected,
              onSelected: isDisabled ? null : (_) => onCategoryChanged(category),
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade700,
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
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 4);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
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

class _ExampleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final name = example['name'] as String;
    final title = example['title'] as String;
    final description = example['description'] as String;
    final icon = example['icon'] as IconData;
    final difficulty = example['difficulty'] as String;
    final color = example['color'] as Color;
    final estimatedLines = example['estimatedLines'] as int;
    final badge = example['badge'] as String?;

    return RepaintBoundary(
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => onTap(name, title),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? color
                        : isDisabled
                        ? Colors.grey.shade300
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey.shade100
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isDisabled ? Colors.grey.shade400 : color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey.shade400 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _getDifficultyColor(difficulty),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '~$estimatedLines lines',
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge == 'NEW' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Currently loaded: ${example['title']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}