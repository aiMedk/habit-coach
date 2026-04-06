import 'package:flutter/material.dart';

/// T146: Skeleton loading placeholder with a pulsing opacity animation.
///
/// Used in [ChatScreen] and [ReviewDetailScreen] while AI content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.25,
      end: 0.55,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder:
          (_, __) => Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
    );
  }
}

/// A skeleton row that mimics a single chat message bubble.
class ChatMessageSkeleton extends StatelessWidget {
  const ChatMessageSkeleton({super.key, this.isAssistant = true});

  final bool isAssistant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            const SkeletonBox(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: isAssistant ? 220 : 160, height: 14),
              const SizedBox(height: 6),
              SkeletonBox(width: isAssistant ? 180 : 130, height: 14),
              const SizedBox(height: 6),
              SkeletonBox(width: isAssistant ? 140 : 100, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// A skeleton layout for the weekly review detail screen while AI content loads.
class ReviewDetailSkeleton extends StatelessWidget {
  const ReviewDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 180, height: 20),
          const SizedBox(height: 24),
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            SkeletonBox(width: 280 - i * 20, height: 14),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          const SkeletonBox(width: 120, height: 20),
          const SizedBox(height: 12),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
