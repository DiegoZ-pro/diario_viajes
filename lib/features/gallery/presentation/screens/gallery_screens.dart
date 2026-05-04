import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../map/application/entradas_provider.dart';
import '../../../map/data/models/entrada_viaje_model.dart';

// ════════════════════════════════════════════════════════════════════
// GALLERY SCREEN
// ════════════════════════════════════════════════════════════════════
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(entradasNotifierProvider.notifier).cargarEntradas());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(entradasNotifierProvider);
    final filtered = ref.read(entradasNotifierProvider.notifier).buscar(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilters(context)),
        ],
      ),
      body: Column(
        children: [
          // ── Búsqueda ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar lugar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text('${filtered.length} lugares',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          // ── Lista ───────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(query: _query)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _EntryCard(entry: filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Ordenar por', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Más reciente', 'Más antiguo', 'A-Z'].map((label) {
                return FilterChip(
                  label: Text(label),
                  selected: label == 'Más reciente',
                  onSelected: (_) {},
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de entrada ────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final EntradaViaje entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        Colors.primaries[entry.titulo.length % Colors.primaries.length];
    final foto = entry.fotoPrincipal;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.gallery}/${entry.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de portada
            Container(
              height: 160,
              width: double.infinity,
              color: color.withValues(alpha: 0.15),
              child: foto != null
                  ? Image.network(foto.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image,
                          size: 56, color: color.withValues(alpha: 0.4)))
                  : Icon(Icons.image,
                      size: 56, color: color.withValues(alpha: 0.4)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.titulo, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        entry.tieneUbicacion
                            ? '${entry.latitud!.toStringAsFixed(3)}°, ${entry.longitud!.toStringAsFixed(3)}°'
                            : 'Sin ubicación',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.fechaVisita.day}/${entry.fechaVisita.month}/${entry.fechaVisita.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (entry.nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(entry.nota,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'Aún no tienes viajes' : 'Sin resultados',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty
                ? 'Toca el botón + en el mapa para agregar tu primer lugar'
                : 'Intenta con otro término',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// ENTRY DETAIL SCREEN
// ════════════════════════════════════════════════════════════════════
class EntryDetailScreen extends ConsumerWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entradas = ref.watch(entradasProvider);
    final entry = entradas.where((e) => e.id == entryId).firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Entrada no encontrada')),
      );
    }

    final color =
        Colors.primaries[entry.titulo.length % Colors.primaries.length];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.share_outlined), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                entry.titulo,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
              ),
              background: entry.fotoPrincipal != null
                  ? Image.network(entry.fotoPrincipal!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: color.withValues(alpha: 0.2),
                          child: Icon(Icons.image,
                              size: 80, color: color.withValues(alpha: 0.4))))
                  : Container(
                      color: color.withValues(alpha: 0.2),
                      child: Icon(Icons.image,
                          size: 80, color: color.withValues(alpha: 0.4))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chips de metadatos
                  Wrap(
                    spacing: 8,
                    children: [
                      if (entry.tieneUbicacion)
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label:
                              '${entry.latitud!.toStringAsFixed(4)}°, ${entry.longitud!.toStringAsFixed(4)}°',
                          color: color,
                        ),
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label:
                            '${entry.fechaVisita.day}/${entry.fechaVisita.month}/${entry.fechaVisita.year}',
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),

                  // Galería de fotos
                  if (entry.fotos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Fotos', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: entry.fotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            entry.fotos[i].url,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 110,
                              color: color.withValues(alpha: 0.2),
                              child: Icon(Icons.image, color: color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Nota
                  if (entry.nota.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Mi experiencia', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(entry.nota,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6)),
                    ),
                  ],

                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir este lugar'),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref
                  .read(entradasNotifierProvider.notifier)
                  .eliminarEntrada(entryId);
              if (ok && context.mounted) context.pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
