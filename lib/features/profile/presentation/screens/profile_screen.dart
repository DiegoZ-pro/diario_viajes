import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../map/application/entradas_provider.dart';
import '../../application/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await Future.delayed(Duration.zero);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.lock_outline, size: 36),
        title: const Text('Privacidad'),
        content: const Text(
          'Todas tus entradas son privadas por defecto. Solo tú puedes ver tus lugares, fotos y notas.\n\nNadie más tiene acceso a tu diario de viajes.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final entradas = ref.watch(entradasProvider);
    final profile = ref.watch(profileNotifierProvider);
    final email = user?.email ?? '';

    final int totalFotos = entradas.fold(0, (s, e) => s + e.fotos.length);
    final DateTime? primerViaje = entradas.isEmpty
        ? null
        : entradas
            .map((e) => e.fechaVisita)
            .reduce((a, b) => a.isBefore(b) ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(profileNotifierProvider.notifier).cargar(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // avatar y nombre
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      _iniciales(profile.nombre),
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  await context.push(AppRoutes.profileEdit);
                                  ref
                                      .read(profileNotifierProvider.notifier)
                                      .cargar();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2),
                                  ),
                                  child: Icon(Icons.edit,
                                      size: 16,
                                      color: theme.colorScheme.onPrimary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.nombre.isNotEmpty
                              ? profile.nombre
                              : 'Sin nombre',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Editar perfil'),
                          onPressed: () async {
                            await context.push(AppRoutes.profileEdit);
                            ref
                                .read(profileNotifierProvider.notifier)
                                .cargar();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(160, 36),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // estadísticas
                  Text('Estadísticas', style: theme.textTheme.titleMedium),
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
                          value: '$totalFotos',
                          label: 'Fotos',
                          icon: Icons.photo,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: primerViaje != null
                              ? '${primerViaje.year}'
                              : '-',
                          label: 'Desde',
                          icon: Icons.calendar_today,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // cuenta
                  Text('Cuenta', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  _OptionTile(
                    icon: Icons.settings_outlined,
                    label: 'Ajustes',
                    subtitle: 'Tema, cuenta y preferencias',
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  _OptionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Mis estadísticas',
                    subtitle: 'Gráficas y resumen de tus viajes',
                    onTap: () => context.push(AppRoutes.profileStats),
                  ),
                  _OptionTile(
                    icon: Icons.person_outline,
                    label: 'Editar perfil',
                    subtitle: 'Nombre y foto de perfil',
                    onTap: () async {
                      await context.push(AppRoutes.profileEdit);
                      ref.read(profileNotifierProvider.notifier).cargar();
                    },
                  ),
                  _OptionTile(
                    icon: Icons.lock_outline,
                    label: 'Cambiar contraseña',
                    subtitle: 'Actualiza tu contraseña de acceso',
                    onTap: () => context.push(AppRoutes.profileChangePassword),
                  ),
                  _OptionTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacidad',
                    subtitle: 'Tus entradas son privadas por defecto',
                    onTap: () => _showPrivacyInfo(context),
                  ),

                  const SizedBox(height: 20),

                  // cerrar sesion
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
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
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

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
  final String subtitle;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
      ),
      title: Text(label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
