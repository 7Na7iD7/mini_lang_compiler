import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'code_intelligence.dart';

class ModernOverlayTheme {
  static const double borderRadius = 16.0;
  static const double smallRadius = 8.0;
  static const double blurStrength = 15.0;

  static final primaryGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static final accentGradient = [
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  static final darkGradient = [
    Color(0xFF1a1a2e).withOpacity(0.95),
    Color(0xFF16213e).withOpacity(0.92),
  ];

  static BoxDecoration premiumGlassDecoration(Color accentColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: darkGradient,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        width: 1.5,
        color: Colors.white.withOpacity(0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.3),
          blurRadius: 30,
          spreadRadius: -5,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 25,
          offset: Offset(0, 15),
        ),
      ],
    );
  }
}

class AutoCompleteOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final int currentLine;
  final List<CompletionItem> completions;
  final int selectedIndex;
  final Function(CompletionItem) onSelect;

  const AutoCompleteOverlay({
    super.key,
    required this.layerLink,
    required this.currentLine,
    required this.completions,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<AutoCompleteOverlay> createState() => _AutoCompleteOverlayState();
}

class _AutoCompleteOverlayState extends State<AutoCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset(68, widget.currentLine * 19.6 + 20),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.topLeft,
          child: _buildPremiumContainer(),
        ),
      ),
    );
  }

  Widget _buildPremiumContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ModernOverlayTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: ModernOverlayTheme.blurStrength,
          sigmaY: ModernOverlayTheme.blurStrength,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 450, maxHeight: 380),
          decoration: ModernOverlayTheme.premiumGlassDecoration(Colors.purple),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernHeader(),
              _buildShimmerDivider(),
              _buildCompletionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ModernOverlayTheme.borderRadius),
          topRight: Radius.circular(ModernOverlayTheme.borderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ModernOverlayTheme.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Suggestions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Context-aware completions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.cyan.shade400],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Text(
              '${widget.completions.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerDivider() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.transparent,
                Colors.purple.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionsList() {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(8),
        itemCount: widget.completions.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(-20 * (1 - value), 0),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _ModernCompletionItem(
              completion: widget.completions[index],
              isSelected: index == widget.selectedIndex,
              onTap: () => widget.onSelect(widget.completions[index]),
              index: index,
            ),
          );
        },
      ),
    );
  }
}

class _ModernCompletionItem extends StatefulWidget {
  final CompletionItem completion;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _ModernCompletionItem({
    required this.completion,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_ModernCompletionItem> createState() => _ModernCompletionItemState();
}

class _ModernCompletionItemState extends State<_ModernCompletionItem>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSelected || _isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 3),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.4),
                    Colors.blue.withOpacity(0.3),
                  ],
                )
                    : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05 * _hoverController.value),
                    Colors.white.withOpacity(0.02 * _hoverController.value),
                  ],
                ),
                borderRadius: BorderRadius.circular(ModernOverlayTheme.smallRadius),
                border: widget.isSelected
                    ? Border.all(color: Colors.purple.withOpacity(0.6), width: 1.5)
                    : null,
                boxShadow: widget.isSelected
                    ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
                    : null,
              ),
              child: Row(
                children: [
                  _buildIconBadge(),
                  SizedBox(width: 12),
                  Expanded(child: _buildContent()),
                  if (widget.completion.score > 0.8) _buildBestBadge(),
                  if (widget.isSelected) _buildSelectedArrow(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.completion.color.withOpacity(0.3),
            widget.completion.color.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.completion.color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Icon(
        widget.completion.icon,
        size: 18,
        color: widget.completion.color,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.completion.label,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Courier New',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.completion.detail.isNotEmpty) ...[
          SizedBox(height: 3),
          Text(
            widget.completion.detail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'Courier New',
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildBestBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Best',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedArrow() {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.purple.shade300,
      ),
    );
  }
}

class SignatureHelpOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final int currentLine;
  final SignatureHelp? signatureHelp;

  const SignatureHelpOverlay({
    super.key,
    required this.layerLink,
    required this.currentLine,
    required this.signatureHelp,
  });

  @override
  State<SignatureHelpOverlay> createState() => _SignatureHelpOverlayState();
}

class _SignatureHelpOverlayState extends State<SignatureHelpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 350),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signatureHelp == null) return SizedBox.shrink();

    final signature = widget.signatureHelp!
        .signatures[widget.signatureHelp!.activeSignature];

    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.bottomLeft,
      offset: Offset(68, (widget.currentLine - 1) * 19.6 - 8),
      child: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          alignment: Alignment.bottomLeft,
          child: _buildSignatureContainer(signature),
        ),
      ),
    );
  }

  Widget _buildSignatureContainer(FunctionSignature signature) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ModernOverlayTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: ModernOverlayTheme.blurStrength,
          sigmaY: ModernOverlayTheme.blurStrength,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 550),
          padding: EdgeInsets.all(16),
          decoration: ModernOverlayTheme.premiumGlassDecoration(Colors.cyan),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(signature),
              if (signature.parameters.isNotEmpty) ...[
                SizedBox(height: 12),
                ..._buildParameters(signature.parameters),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FunctionSignature signature) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan.shade400, Colors.blue.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Icon(Icons.functions_rounded, size: 18, color: Colors.white),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            signature.displayText,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Courier New',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParameters(List<String> parameters) {
    return parameters.asMap().entries.map((entry) {
      final isActive = entry.key == widget.signatureHelp!.activeParameter;
      return _buildParameterItem(entry.value, isActive, entry.key);
    }).toList();
  }

  Widget _buildParameterItem(String param, bool isActive, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-10 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: EdgeInsets.only(top: 8, left: 32),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
            colors: [
              Colors.cyan.withOpacity(0.3),
              Colors.blue.withOpacity(0.2),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(ModernOverlayTheme.smallRadius),
          border: isActive
              ? Border.all(color: Colors.cyan.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive ? Colors.cyan.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.play_arrow : Icons.circle,
                size: isActive ? 14 : 8,
                color: isActive ? Colors.cyan.shade300 : Colors.white.withOpacity(0.4),
              ),
            ),
            SizedBox(width: 10),
            Text(
              param,
              style: TextStyle(
                color: isActive ? Colors.cyan.shade200 : Colors.white.withOpacity(0.7),
                fontFamily: 'Courier New',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorTooltipOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final Offset position;
  final String errorMessage;
  final String? suggestion;

  const ErrorTooltipOverlay({
    super.key,
    required this.layerLink,
    required this.position,
    required this.errorMessage,
    this.suggestion,
  });

  @override
  State<ErrorTooltipOverlay> createState() => _ErrorTooltipOverlayState();
}

class _ErrorTooltipOverlayState extends State<ErrorTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.bottomLeft,
      offset: widget.position,
      child: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          alignment: Alignment.bottomLeft,
          child: _buildErrorContainer(),
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ModernOverlayTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: ModernOverlayTheme.blurStrength,
          sigmaY: ModernOverlayTheme.blurStrength,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ModernOverlayTheme.darkGradient,
            ),
            borderRadius: BorderRadius.circular(ModernOverlayTheme.borderRadius),
            border: Border.all(color: Colors.red.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.pink.shade400],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.error_outline, size: 18, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.errorMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.suggestion != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.cyan.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ModernOverlayTheme.smallRadius),
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates, size: 16, color: Colors.cyan.shade300),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.suggestion!,
                          style: TextStyle(
                            color: Colors.cyan.shade200,
                            fontFamily: 'Courier New',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}