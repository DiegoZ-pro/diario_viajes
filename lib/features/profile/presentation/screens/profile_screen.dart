import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../map/application/entradas_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final entradas = ref.watch(entradasProvider);

    final nombre = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Usuario';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar y nombre ───────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _iniciales(nombre),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(nombre, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(email,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Estadísticas ──────────────────────────────────────────
          Text('Mis estadísticas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${entradas.length}',
                  label: 'Lugares',
                  icon: Icons.place,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value:
                      '${entradas.fold(0, (sum, e) => sum + e.fotos.length)}',
                  label: 'Fotos',
                  icon: Icons.photo,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: entradas.isEmpty
                      ? '0'
                      : '${entradas.last.fechaVisita.year}',
                  label: 'Desde',
                  icon: Icons.calendar_today,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Opciones ──────────────────────────────────────────────
          Text('Cuenta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _OptionTile(
              icon: Icons.person_outline, label: 'Editar perfil', onTap: () {}),
          _OptionTile(
              icon: Icons.lock_outline,
              label: 'Cambiar contraseña',
              onTap: () {}),
          _OptionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacidad',
              onTap: () {}),

          const SizedBox(height: 16),

          // ── Cerrar sesión ─────────────────────────────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
