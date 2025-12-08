import 'package:flutter/material.dart';

class SkeletonDetailWidget extends StatefulWidget {
  const SkeletonDetailWidget({super.key});

  @override
  State<SkeletonDetailWidget> createState() => _SkeletonDetailWidgetState();
}

class _SkeletonDetailWidgetState extends State<SkeletonDetailWidget>
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
          // Header Skeleton
          FadeTransition(
            opacity: _animation,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row Skeleton
          Row(
            children: List.generate(3, (index) => Expanded(
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 24),

          // List Items Skeleton
          ...List.generate(4, (index) => FadeTransition(
            opacity: _animation,
            child: Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   const SizedBox(width: 16),
                   Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), shape: BoxShape.circle)),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(width: 120, height: 16, color: Colors.grey.withValues(alpha: 0.2)),
                         const SizedBox(height: 8),
                         Container(width: 80, height: 12, color: Colors.grey.withValues(alpha: 0.2)),
                       ],
                     )
                   )
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
