import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/contacts_screen.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
import 'package:trusted_circle_demo/ui/safety_guide_screen.dart';

class ProfileSafetyScreen extends StatelessWidget {
  const ProfileSafetyScreen({
    super.key,
    required this.devices,
    required this.onRevoke,
    this.onBack,
  });

  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final displayName = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : 'Familie';

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? const BackButton()
            : onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: onBack,
                  )
                : null,
        title: const Text('Profil & Schutz'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Euer sicherer Ort fuer Profil, Hilfe und Schutz.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.family_restroom_rounded,
            color: const Color(0xFF2563EB),
            title: 'Familienprofil',
            subtitle:
                'Mitglieder, Sprache, Interessen und Kontodetails pflegen',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FamilyProfileScreen(
                    devices: devices,
                    onRevoke: onRevoke,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.shield_rounded,
            color: const Color(0xFF0EA5A4),
            title: 'Sicherheitsleitfaden',
            subtitle: 'Praevention, Notfallwissen und Schutz im Alltag',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SafetyGuideScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.contact_phone_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Notfallkontakte',
            subtitle: 'Wichtige Kontakte sofort erreichbar halten',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.phonelink_setup_rounded,
            color: const Color(0xFF7C3AED),
            title: 'Vertrauensgeraete',
            subtitle: 'Aktive Geraete einsehen und Berechtigungen steuern',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceManagementScreen(
                    devices: devices,
                    onRevoke: onRevoke,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
