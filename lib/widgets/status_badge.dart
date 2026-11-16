import 'package:flutter/material.dart';
import '../models/parking_session.dart';

class StatusBadge extends StatelessWidget {
  final SessionStatus status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case SessionStatus.active:
        color = const Color(0xFF2ECC71);
        label = 'En cours';
        break;
      case SessionStatus.retrieved:
        color = const Color(0xFF3498DB);
        label = 'Récupéré';
        break;
      case SessionStatus.notRetrieved:
        color = const Color(0xFFE74C3C);
        label = 'Non récupéré';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
