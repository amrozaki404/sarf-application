import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSkeletonBlock extends StatefulWidget {
  final double height;
  final int rows;

  const AppSkeletonBlock({
    super.key,
    this.height = 180,
    this.rows = 3,
  });

  @override
  State<AppSkeletonBlock> createState() => _AppSkeletonBlockState();
}

class _AppSkeletonBlockState extends State<AppSkeletonBlock>
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
    _opacity = Tween<double>(begin: 0.45, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.xxl,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: List.generate(widget.rows, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.rows - 1 ? 0 : 12,
                      ),
                      child: const _SkeletonRow(),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.skeletonBase,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 110,
                decoration: BoxDecoration(
                  color: AppColors.skeletonHighlight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 12,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.skeletonHighlight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
