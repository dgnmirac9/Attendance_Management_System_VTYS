import 'package:flutter/material.dart';

class SkeletonFormWidget extends StatefulWidget {
  const SkeletonFormWidget({super.key});

  @override
  State<SkeletonFormWidget> createState() => _SkeletonFormWidgetState();
}

class _SkeletonFormWidgetState extends State<SkeletonFormWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 1500)
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar Skeleton
          FadeTransition(
            opacity: _animation,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Form Fields Skeleton
          ...List.generate(5, (index) => FadeTransition(
            opacity: _animation,
            child: Container(
              height: 56,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Button Skeleton
          FadeTransition(
            opacity: _animation,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
