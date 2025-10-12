import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/compiler_provider.dart';


class AnimatedStatusIndicator extends StatefulWidget {
  const AnimatedStatusIndicator({super.key});

  @override
  State<AnimatedStatusIndicator> createState() => _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _updateAnimations(CompilerState state) {
    switch (state) {
      case CompilerState.idle:
        _pulseController.stop();
        _rotationController.stop();
        _shimmerController.stop();
        break;
      case CompilerState.lexing:
      case CompilerState.parsing:
      case CompilerState.analyzing:
      case CompilerState.interpreting:
      case CompilerState.optimizing:
        _pulseController.repeat();
        _rotationController.repeat();
        _shimmerController.repeat();
        break;
      case CompilerState.completed:
        _pulseController.stop();
        _rotationController.stop();
        _shimmerController.stop();
        // Quick success animation
        _pulseController.forward(from: 0).then((_) => _pulseController.reset());
        break;
      case CompilerState.error:
        _pulseController.stop();
        _rotationController.stop();
        _shimmerController.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompilerProvider>(
      builder: (context, provider, _) {
        _updateAnimations(provider.state);

        return AnimatedBuilder(
          animation: Listenable.merge([
            _pulseAnimation,
            _rotationAnimation,
            _shimmerAnimation,
          ]),
          builder: (context, _) {
            return Transform.scale(
              scale: provider.isRunning ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _getStatusGradient(provider.state),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(provider.state).withOpacity(0.4),
                      spreadRadius: provider.isRunning ? 3 : 0,
                      blurRadius: provider.isRunning ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (provider.isRunning)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Transform.translate(
                            offset: Offset(_shimmerAnimation.value * 200, 0),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (provider.isRunning)
                          Transform.rotate(
                            angle: _rotationAnimation.value * 2 * 3.14159,
                            child: Icon(
                              _getStatusIcon(provider.state),
                              size: 18,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            _getStatusIcon(provider.state),
                            size: 18,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(provider.state),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(CompilerState state) {
    switch (state) {
      case CompilerState.idle:
        return Icons.radio_button_unchecked;
      case CompilerState.lexing:
        return Icons.text_fields_rounded;
      case CompilerState.parsing:
        return Icons.account_tree_rounded;
      case CompilerState.analyzing:
        return Icons.analytics_rounded;
      case CompilerState.interpreting:
        return Icons.play_circle_rounded;
      case CompilerState.optimizing:
        return Icons.flash_on_rounded;
      case CompilerState.completed:
        return Icons.check_circle_rounded;
      case CompilerState.error:
        return Icons.error_outline_rounded;
    }
  }

  Color _getStatusColor(CompilerState state) {
    switch (state) {
      case CompilerState.idle:
        return const Color(0xFF78909C);
      case CompilerState.lexing:
        return const Color(0xFF42A5F5);
      case CompilerState.parsing:
        return const Color(0xFFAB47BC);
      case CompilerState.analyzing:
        return const Color(0xFFFF7043);
      case CompilerState.interpreting:
        return const Color(0xFF5C6BC0);
      case CompilerState.optimizing:
        return const Color(0xFF26C6DA);
      case CompilerState.completed:
        return const Color(0xFF66BB6A);
      case CompilerState.error:
        return const Color(0xFFEF5350);
    }
  }

  LinearGradient _getStatusGradient(CompilerState state) {
    final color = _getStatusColor(state);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getStatusText(CompilerState state) {
    switch (state) {
      case CompilerState.idle:
        return 'آماده';
      case CompilerState.lexing:
        return 'تحلیل لغوی';
      case CompilerState.parsing:
        return 'تجزیه نحوی';
      case CompilerState.analyzing:
        return 'تحلیل معنایی';
      case CompilerState.interpreting:
        return 'اجرا';
      case CompilerState.optimizing:
        return 'بهینه‌سازی';
      case CompilerState.completed:
        return 'تکمیل شد';
      case CompilerState.error:
        return 'خطا';
    }
  }
}

class AnimatedRunButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isRunning;
  final String? label;

  const AnimatedRunButton({
    super.key,
    this.onPressed,
    required this.isRunning,
    this.label,
  });

  @override
  State<AnimatedRunButton> createState() => _AnimatedRunButtonState();
}

class _AnimatedRunButtonState extends State<AnimatedRunButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Pulse animation for running state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Rotation for loading icon
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 12.0, end: 4.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(AnimatedRunButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      _pulseController.repeat();
      _shimmerController.repeat();
      _rotationController.repeat();
    } else if (!widget.isRunning && oldWidget.isRunning) {
      _pulseController.stop();
      _shimmerController.stop();
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isRunning
          ? null
          : (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: widget.isRunning
          ? null
          : (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        if (widget.onPressed != null) {
          HapticFeedback.mediumImpact();
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pressController,
          _pulseController,
          _shimmerController,
          _rotationController,
        ]),
        builder: (context, _) {
          final scale = widget.isRunning
              ? _scaleAnimation.value * _pulseAnimation.value
              : _scaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _getGradientColors().first.withOpacity(0.4),
                    blurRadius: widget.isRunning ? 20 : _elevationAnimation.value * 2,
                    spreadRadius: widget.isRunning ? 2 : _elevationAnimation.value / 4,
                    offset: Offset(0, widget.isRunning ? 6 : _elevationAnimation.value / 2),
                  ),
                  BoxShadow(
                    color: _getGradientColors().last.withOpacity(0.3),
                    blurRadius: widget.isRunning ? 30 : _elevationAnimation.value * 3,
                    spreadRadius: widget.isRunning ? -5 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Stack(
                    children: [
                      // Main gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getGradientColors(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),

                      // Shimmer overlay when running
                      if (widget.isRunning)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Transform.translate(
                              offset: Offset(_shimmerAnimation.value * 300, 0),
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.5),
                                      Colors.white.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Glass morphism layer
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),

                      // Content
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isRunning ? null : widget.onPressed,
                          borderRadius: BorderRadius.circular(24),
                          splashColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIcon(),
                                const SizedBox(width: 14),
                                Text(
                                  widget.label ?? _getDefaultLabel(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.isRunning) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating circle
          Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2.5,
                ),
              ),
            ),
          ),
          // Inner spinning icon
          Transform.rotate(
            angle: -_rotationAnimation.value * 2 * 3.14159,
            child: const Icon(
              Icons.autorenew_rounded,
              size: 26,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: const Icon(
          Icons.rocket_launch_rounded,
          size: 22,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      );
    }
  }

  List<Color> _getGradientColors() {
    if (widget.isRunning) {
      return [
        const Color(0xFFFF6B9D), // Pink
        const Color(0xFFC06C84), // Rose
        const Color(0xFF9B59B6), // Purple
      ];
    } else {
      return [
        const Color(0xFF667EEA), // Indigo
        const Color(0xFF764BA2), // Purple
        const Color(0xFFF093FB), // Pink
      ];
    }
  }

  String _getDefaultLabel() {
    return widget.isRunning ? 'در حال اجرا...' : 'کامپایل و اجرا';
  }
}

class AnimatedInfoCard extends StatefulWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const AnimatedInfoCard({
    super.key,
    required this.child,
    required this.title,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  State<AnimatedInfoCard> createState() => _AnimatedInfoCardState();
}

class _AnimatedInfoCardState extends State<AnimatedInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _borderAnimation = Tween<double>(begin: 1, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.2),
                      blurRadius: _elevationAnimation.value,
                      spreadRadius: _elevationAnimation.value / 6,
                      offset: Offset(0, _elevationAnimation.value / 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            cardColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isHovered
                              ? cardColor.withOpacity(0.6)
                              : Colors.grey.withOpacity(0.2),
                          width: _borderAnimation.value,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(cardColor),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: widget.child,
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
      ),
    );
  }

  Widget _buildHeader(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withOpacity(0.15),
            cardColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: cardColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, cardColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cardColor.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (widget.onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: cardColor.withOpacity(0.5),
            ),
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final String label;
  final Color? color;
  final bool showPercentage;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.label,
    this.color,
    this.showPercentage = true,
    this.height = 10,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.color ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (widget.showPercentage)
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(_progressAnimation.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    child: FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              progressColor,
                              progressColor.withOpacity(0.7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Shimmer effect
                  if (_progressAnimation.value > 0 && _progressAnimation.value < 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      child: FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Transform.translate(
                          offset: Offset(_shimmerAnimation.value * 100, 0),
                          child: Container(
                            width: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 24,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onPressed != null) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: buttonColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: buttonColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PageTransitionHelper {
  static Widget slideTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }

  // Fade transition
  static Widget fadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }

  // Scale with fade
  static Widget scaleTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Slide from bottom
  static Widget slideFromBottomTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Rotation with scale
  static Widget rotationTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return RotationTransition(
      turns: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AnimatedChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;

  const AnimatedChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.selected = false,
  });

  @override
  State<AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<AnimatedChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.selected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = widget.color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          HapticFeedback.selectionClick();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: widget.selected
                    ? LinearGradient(
                  colors: [chipColor, chipColor.withOpacity(0.8)],
                )
                    : null,
                color: widget.selected ? null : chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.selected
                      ? chipColor
                      : chipColor.withOpacity(0.3),
                  width: widget.selected ? 2 : 1.5,
                ),
                boxShadow: widget.selected
                    ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.selected ? Colors.white : chipColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.selected ? Colors.white : chipColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}