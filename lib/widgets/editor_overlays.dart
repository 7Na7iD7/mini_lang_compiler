import 'package:flutter/material.dart';
import 'dart:ui';
import 'code_intelligence.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
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
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset(68, widget.currentLine * 19.6 + 16),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.topLeft,
            child: Align(
              alignment: Alignment.topLeft,
              child: _buildGlassmorphicContainer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B2B2B).withOpacity(0.9),
                const Color(0xFF1E1E1E).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEnhancedHeader(),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _buildCompletionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
          ),
          const SizedBox(width: 10),
          Text(
            'Smart Suggestions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              '${widget.completions.length}',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionList() {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: widget.completions.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.03;
              final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: Interval(delay, 1.0, curve: Curves.easeOut),
                ),
              );

              return FadeTransition(
                opacity: itemAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.2, 0),
                    end: Offset.zero,
                  ).animate(itemAnimation),
                  child: child,
                ),
              );
            },
            child: _CompletionListItem(
              completion: widget.completions[index],
              isSelected: index == widget.selectedIndex,
              onTap: () => widget.onSelect(widget.completions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CompletionListItem extends StatefulWidget {
  final CompletionItem completion;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompletionListItem({
    required this.completion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CompletionListItem> createState() => _CompletionListItemState();
}

class _CompletionListItemState extends State<_CompletionListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.2),
              ],
            )
                : _isHovering
                ? LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildContent()),
              if (widget.completion.score > 0.8) _buildBestBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.completion.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        widget.completion.icon,
        size: 16,
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
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Courier New',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.completion.detail.isNotEmpty) ...[
          const SizedBox(height: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star, size: 10, color: Colors.amber),
          SizedBox(width: 3),
          Text(
            'Best',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.signatureHelp == null) return const SizedBox.shrink();

    final signature = widget.signatureHelp!
        .signatures[widget.signatureHelp!.activeSignature];

    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.bottomLeft,
      offset: Offset(68, (widget.currentLine - 1) * 19.6),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.topLeft,
            child: _buildSignatureContainer(signature),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureContainer(FunctionSignature signature) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B2B2B).withOpacity(0.95),
                const Color(0xFF1E1E1E).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSignatureHeader(signature),
              if (signature.parameters.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._buildParameterList(signature.parameters),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureHeader(FunctionSignature signature) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.functions_rounded, size: 16, color: Colors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            signature.displayText,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Courier New',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParameterList(List<String> parameters) {
    return parameters.asMap().entries.map((entry) {
      final index = entry.key;
      final param = entry.value;
      final isActive = index == widget.signatureHelp!.activeParameter;

      return _ParameterItem(parameter: param, isActive: isActive);
    }).toList();
  }
}

class _ParameterItem extends StatelessWidget {
  final String parameter;
  final bool isActive;

  const _ParameterItem({
    required this.parameter,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: Colors.blue.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.arrow_right : Icons.circle,
              size: isActive ? 16 : 6,
              color: isActive ? Colors.blue : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            Text(
              parameter,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.white.withOpacity(0.7),
                fontFamily: 'Courier New',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverInfoOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final Offset position;
  final String title;
  final String description;
  final IconData? icon;

  const HoverInfoOverlay({
    super.key,
    required this.layerLink,
    required this.position,
    required this.title,
    required this.description,
    this.icon,
  });

  @override
  State<HoverInfoOverlay> createState() => _HoverInfoOverlayState();
}

class _HoverInfoOverlayState extends State<HoverInfoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controller.forward();
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
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          alignment: Alignment.bottomLeft,
          child: _buildInfoContainer(),
        ),
      ),
    );
  }

  Widget _buildInfoContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B2B2B).withOpacity(0.95),
                const Color(0xFF1E1E1E).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(widget.icon, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    height: 1.4,
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
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
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B2B2B).withOpacity(0.95),
                const Color(0xFF1E1E1E).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier New',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.suggestion != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.15),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, size: 14, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.suggestion!,
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontFamily: 'Courier New',
                            fontSize: 11,
                            height: 1.3,
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