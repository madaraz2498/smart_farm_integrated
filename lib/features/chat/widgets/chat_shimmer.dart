import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Shimmer animation foundation ──────────────────────────────────────────────

class _ShimmerBase extends StatefulWidget {
  const _ShimmerBase({required this.child});
  final Widget child;

  @override
  State<_ShimmerBase> createState() => _ShimmerBaseState();
}

class _ShimmerBaseState extends State<_ShimmerBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFE0E0E0),
              Color(0xFFEEEEEE),
            ],
            stops: [
              math.max(0, _anim.value - 0.3),
              _anim.value.clamp(0.0, 1.0),
              math.min(1, _anim.value + 0.3),
            ],
            transform: GradientRotation(0),
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── Shimmer box primitive ─────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBase(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Session skeleton item ─────────────────────────────────────────────────────

class SessionSkeletonItem extends StatelessWidget {
  const SessionSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ShimmerBox(width: 28, height: 28, borderRadius: 6),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 5),
                ShimmerBox(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session list skeleton ─────────────────────────────────────────────────────

class SessionListSkeleton extends StatelessWidget {
  const SessionListSkeleton({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const SessionSkeletonItem(),
      ),
    );
  }
}

// ── Chat message bubble skeleton ──────────────────────────────────────────────

class MessageBubbleSkeleton extends StatelessWidget {
  const MessageBubbleSkeleton({super.key, this.isUser = false});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            ShimmerBox(width: 28, height: 28, borderRadius: 14),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: isUser ? 160 : 220,
                height: 14,
                borderRadius: 8,
              ),
              const SizedBox(height: 4),
              ShimmerBox(
                width: isUser ? 100 : 180,
                height: 14,
                borderRadius: 8,
              ),
              const SizedBox(height: 4),
              ShimmerBox(width: 40, height: 10, borderRadius: 4),
            ],
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            ShimmerBox(width: 28, height: 28, borderRadius: 14),
          ],
        ],
      ),
    );
  }
}

// ── Chat history skeleton ─────────────────────────────────────────────────────

class ChatHistorySkeleton extends StatelessWidget {
  const ChatHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        MessageBubbleSkeleton(isUser: true),
        MessageBubbleSkeleton(isUser: false),
        MessageBubbleSkeleton(isUser: true),
        MessageBubbleSkeleton(isUser: false),
        MessageBubbleSkeleton(isUser: true),
      ],
    );
  }
}
