import 'package:flutter/material.dart';

class AdminStatCard extends StatelessWidget {
  final String label;
  final String? value;
  final double? numericValue;
  final Color? color;

  const AdminStatCard({
    super.key,
    required this.label,
    this.value,
    this.numericValue,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          if (numericValue != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: numericValue!),
              duration: const Duration(milliseconds: 900),
              builder: (context, val, child) {
                final display = val % 1 == 0
                    ? val.toInt().toString()
                    : val.toStringAsFixed(0);

                return Text(
                  display,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            )
          else
            Text(
              value ?? "-",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
        ],
      ),
    );
  }
}
