import 'package:flutter/material.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/models/trusted_device.dart';
import 'package:parentpeak/ui/contacts_screen.dart';
import 'package:parentpeak/ui/device_management_screen.dart';
import 'package:parentpeak/ui/family_profile_screen.dart';
import 'package:parentpeak/ui/safety_guide_screen.dart';

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
    const primary = Color(0xFF2563EB);
    const accent = Color(0xFF7DD3FC);
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
                colors: [Color(0xFF0F172A), primary, accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.22),
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
                        'Ein sicherer Platz fuer euren Familienalltag.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hier startet alles, was Eltern schnell brauchen: Familienprofil, Schutzwissen, Kontakte und vertrauensvolle Geraete.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Heute wichtig: Familienprofil, Schutzwissen und Wiederherstellung sind hier gebuendelt, damit Eltern nicht durch doppelte Wege navigieren muessen.',
                    style: TextStyle(color: Color(0xFF334155), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _StatusStrip(
            items: [
              _StatusStripItem(label: 'Profil', value: 'Zentral'),
              _StatusStripItem(label: 'Schutz', value: 'Sichtbar'),
              _StatusStripItem(label: 'Kontakte', value: 'Schnell'),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionIntro(
            title: 'Familie im Blick',
            subtitle:
                'Alles, was euer Familienprofil, Rollen und vertrauensvolle Struktur im Alltag zusammenhaelt.',
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.family_restroom_rounded,
            color: primary,
            title: 'Familienprofil',
            subtitle:
                'Mitglieder, Sprache, Interessen und Kontodetails pflegen',
            badge: 'Zentrale',
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
          const SizedBox(height: 16),
          const _SectionIntro(
            title: 'Schutz & Sicherheit',
            subtitle:
                'Wissen, Kontakte und Geraetezugriffe, die Eltern im richtigen Moment schnell erreichen sollen.',
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.shield_rounded,
            color: const Color(0xFF0EA5A4),
            title: 'Sicherheitsleitfaden',
            subtitle: 'Praevention, Notfallwissen und Schutz im Alltag',
            badge: 'Leitfaden',
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
            badge: 'Direkt',
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
            badge: '${devices.length} aktiv',
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: Color(0xFF1D4ED8)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Elternfreundlich gedacht: Der Profilbereich fuehrt jetzt nicht mehr durch doppelte Wege, sondern konzentriert Familie, Schutz und Wiederherstellung an wenigen klaren Stellen.',
                    style: TextStyle(color: Color(0xFF334155), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF475569),
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.items});

  final List<_StatusStripItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: item == items.last ? 0 : 10,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatusStripItem {
  const _StatusStripItem({required this.label, required this.value});

  final String label;
  final String value;
}
