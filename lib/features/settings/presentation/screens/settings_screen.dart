import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── APARIENCIA ──────────────────────────────────────────────
          _SectionHeader('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ThemeOption(
                    label: 'Claro',
                    icon: Icons.light_mode_outlined,
                    selected: themeMode == ThemeMode.light,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
                  ),
                  Divider(
                      height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                  _ThemeOption(
                    label: 'Sistema',
                    icon: Icons.brightness_auto_outlined,
                    selected: themeMode == ThemeMode.system,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
                  ),
                  Divider(
                      height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                  _ThemeOption(
                    label: 'Oscuro',
                    icon: Icons.dark_mode_outlined,
                    selected: themeMode == ThemeMode.dark,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── CUENTA ─────────────────────────────────────────────────
          _SectionHeader('Cuenta'),
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Editar perfil',
            subtitle: 'Nombre y foto de perfil',
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Cambiar contraseña',
            subtitle: 'Actualiza tu contraseña de acceso',
            onTap: () => context.push(AppRoutes.profileChangePassword),
          ),

          const SizedBox(height: 8),

          // ── DATOS ──────────────────────────────────────────────────
          _SectionHeader('Datos'),
          _SettingsTile(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpiar caché local',
            subtitle: 'Borra preferencias guardadas localmente',
            onTap: () => _confirmClearCache(context),
          ),

          const SizedBox(height: 8),

          // ── INFORMACIÓN ────────────────────────────────────────────
          _SectionHeader('Información'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Versión',
            subtitle: '1.0.0',
            showArrow: false,
          ),
          _SettingsTile(
            icon: Icons.flutter_dash,
            label: 'Desarrollado con Flutter',
            subtitle: 'Material 3 · Supabase · Riverpod',
            showArrow: false,
          ),

          const SizedBox(height: 24),

          // ── SESIÓN / PELIGRO ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              onPressed: () => _confirmLogout(context, ref),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _confirmDeleteAccount(context, ref),
              child: const Text('Eliminar cuenta'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text('¿Quieres borrar los datos guardados localmente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Hive.box('settings').clear();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caché limpiada')),
          );
        }
      } catch (_) {}
    }
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
              child: const Text('Cancelar')),
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

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error, size: 40),
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es permanente. Todos tus datos serán eliminados y no se pueden recuperar.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Contacta al soporte para eliminar tu cuenta.')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: showArrow
          ? Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(label,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? theme.colorScheme.primary : null)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
