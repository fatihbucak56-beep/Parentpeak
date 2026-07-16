import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parentpeak/models/cooking_hub.dart';

enum KitaHarmonyStatus { harmonisch, ueberschneidung, unbekannt }

class MealPlannerCard extends StatelessWidget {
  const MealPlannerCard({
    super.key,
    required this.hub,
    required this.kitaStatus,
    required this.onTap,
    required this.onSosTap,
  });

  final CookingHub hub;
  final KitaHarmonyStatus kitaStatus;
  final VoidCallback onTap;
  final VoidCallback onSosTap;

  @override
  Widget build(BuildContext context) {
    final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaysCook = hub.weeklyRotationalPlanner[dayKey];
    final todayLabel = todaysCook != null
        ? 'Heute bekocht dich: ${_displayName(todaysCook)}'
        : 'Schnelles 10-Min-Gericht für heute';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Color(0xFFE07B39),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Essensplaner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8395A7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2A3A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _KitaStatusDot(status: kitaStatus),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.people_outline_rounded,
                    label: todaysCook != null
                        ? '${hub.memberUserIds.length} Familien'
                        : 'Alleine kochen',
                    color: const Color(0xFFE8F0FF),
                    iconColor: const Color(0xFF3B72E8),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _InfoChip(
                    icon: Icons.eco_rounded,
                    label: 'Tarnmodus',
                    color: Color(0xFFEAF8EF),
                    iconColor: Color(0xFF2E9E5B),
                  ),
                ),
                const SizedBox(width: 8),
                _SosButton(onTap: onSosTap),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(String userId) {
    const labels = {
      'mama_fatih': 'Familie Fatih',
      'mueller': 'Familie Müller',
      'kaya': 'Familie Kaya',
      'nguyen': 'Familie Nguyen',
    };
    return labels[userId] ?? userId;
  }
}

class _KitaStatusDot extends StatelessWidget {
  const _KitaStatusDot({required this.status});

  final KitaHarmonyStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      KitaHarmonyStatus.harmonisch => const Color(0xFF22C55E),
      KitaHarmonyStatus.ueberschneidung => const Color(0xFFF97316),
      KitaHarmonyStatus.unbekannt => const Color(0xFFCBD5E1),
    };
    final tooltip = switch (status) {
      KitaHarmonyStatus.harmonisch => 'Kein doppeltes Essen – alles passt',
      KitaHarmonyStatus.ueberschneidung => 'Überschneidung mit Kita-Menü',
      KitaHarmonyStatus.unbekannt => 'Kita-Status unbekannt',
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sos_rounded, size: 14, color: Color(0xFFD91022)),
            SizedBox(width: 4),
            Text(
              'SOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD91022),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
