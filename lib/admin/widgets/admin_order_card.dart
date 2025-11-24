import 'package:flutter/material.dart';

class AdminOrderCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;
  const AdminOrderCard({super.key, required this.id, required this.title, required this.subtitle, required this.status, this.onTap});

  Color _statusColor(String s) {
    final key = s.toLowerCase();
    if (key.contains('paid')) return Colors.green.shade600;
    if (key.contains('completed')) return Colors.blue.shade600;
    if (key.contains('pending')) return Colors.orange.shade700;
    if (key.contains('cancel')) return Colors.red.shade600;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color.fromRGBO(0,0,0,0.03), blurRadius: 6)]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.grey))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.18))),
            child: Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ]),
      ),
    );
  }
}
