import 'package:flutter/material.dart';

import '../models/pill_model.dart';

class PillShapeWidget extends StatelessWidget {
  final PillShape shape;
  final Color color;
  final double size;

  const PillShapeWidget({
    super.key,
    required this.shape,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case PillShape.capsule:
        return _buildCapsule();

      case PillShape.tablet:
        return _buildTablet();

      case PillShape.caplet:
        return _buildCaplet();

      case PillShape.softgel:
        return _buildSoftgel();
    }
  }

  Widget _buildCapsule() {
    final double width = size * 1.5;
    final double height = size * 0.68;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: color,
              ),
            ),
            Expanded(
              child: Container(
                color: Color.lerp(
                  color,
                  Colors.white,
                  0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 2,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCaplet() {
    final double width = size * 1.5;
    final double height = size * 0.7;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.5,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftgel() {
    final double width = size * 1.2;
    final double height = size * 0.82;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Positioned(
            top: height * 0.16,
            left: width * 0.18,
            child: Container(
              width: width * 0.28,
              height: height * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}