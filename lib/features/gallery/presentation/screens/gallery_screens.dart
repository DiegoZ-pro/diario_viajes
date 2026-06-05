import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../map/application/entradas_provider.dart';
import '../../../map/data/models/entrada_viaje_model.dart';
import 'photo_viewer_screen.dart';

enum _SortMode { newest, oldest, alphabetical, mostPhotos }

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isGridView = false;
  _SortMode _sortMode = _SortMode.newest;

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

  List<EntradaViaje> _applyFilters(List<EntradaViaje> all) {
    List<EntradaViaje> result = all;

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase().trim();
      result = result
          .where((e) =>
              e.titulo.toLowerCase().contains(q) ||
              e.nota.toLowerCase().contains(q))
          .toList();
    }

    switch (_sortMode) {
      case _SortMode.newest:
        result = [...result]
          ..sort((a, b) => b.fechaVisita.compareTo(a.fechaVisita));
      case _SortMode.oldest:
        result = [...result]
          ..sort((a, b) => a.fechaVisita.compareTo(b.fechaVisita));
      case _SortMode.alphabetical:
        result = [...result]
          ..sort((a, b) => a.titulo.compareTo(b.titulo));
      case _SortMode.mostPhotos:
        result = [...result]
          ..sort((a, b) => b.fotos.length.compareTo(a.fotos.length));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(entradasNotifierProvider);
    final filtered = _applyFilters(state.entradas);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          IconButton(
            icon: Icon(
                _isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
            tooltip: _isGridView ? 'Vista lista' : 'Vista cuadrícula',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.sort_outlined),
            tooltip: 'Ordenar',
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Búsqueda ────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} lugar${filtered.length == 1 ? '' : 'es'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                if (_sortMode != _SortMode.newest)
                  Chip(
                    label: Text(_sortLabel(_sortMode),
                        style: theme.textTheme.labelSmall),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _sortMode = _SortMode.newest),
                  ),
              ],
            ),
          ),

          // ── Lista / Cuadrícula ──────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(query: _query)
                    : _isGridView
                        ? _GridContent(entries: filtered)
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _EntryCard(entry: filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(_SortMode mode) {
    switch (mode) {
      case _SortMode.newest:
        return 'Más reciente';
      case _SortMode.oldest:
        return 'Más antiguo';
      case _SortMode.alphabetical:
        return 'A-Z';
      case _SortMode.mostPhotos:
        return 'Más fotos';
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ordenar por',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ..._SortMode.values.map((mode) => RadioListTile<_SortMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_sortLabel(mode)),
                    value: mode,
                    groupValue: _sortMode,
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() {});
                      setState(() => _sortMode = v);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vista cuadrícula ──────────────────────────────────────────────────
class _GridContent extends StatelessWidget {
  final List<EntradaViaje> entries;
  const _GridContent({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _EntryGridCard(entry: entries[i]),
    );
  }
}

class _EntryGridCard extends StatelessWidget {
  final EntradaViaje entry;
  const _EntryGridCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = AppColorUtils.forSeed(entry.titulo);
    final foto = entry.fotoPrincipal;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.gallery}/${entry.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            foto != null
                ? Hero(
                    tag: 'entry_cover_${entry.id}',
                    child: Image.network(foto.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: color.withValues(alpha: 0.2))),
                  )
                : Container(
                    color: color.withValues(alpha: 0.15),
                    child: Icon(Icons.place_rounded,
                        color: color.withValues(alpha: 0.5), size: 40),
                  ),
            // Degradado inferior
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Título
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Text(
                entry.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Contador de fotos
            if (entry.fotos.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('${entry.fotos.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            // Fecha
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('dd/MM').format(entry.fechaVisita),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de lista ──────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final EntradaViaje entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColorUtils.forSeed(entry.titulo);
    final foto = entry.fotoPrincipal;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.gallery}/${entry.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            Container(
              height: 160,
              width: double.infinity,
              color: color.withValues(alpha: 0.15),
              child: foto != null
                  ? Hero(
                      tag: 'entry_cover_${entry.id}',
                      child: Image.network(foto.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image,
                              size: 56, color: color.withValues(alpha: 0.4))),
                    )
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
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
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
                        DateFormat('dd/MM/yyyy').format(entry.fechaVisita),
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

// ── Estado vacío ──────────────────────────────────────────────────────
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

// ── Detalle de entrada ────────────────────────────────────────────────
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

    final color = AppColorUtils.forSeed(entry.titulo);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => context.push(
                  '${AppRoutes.gallery}/$entryId/edit',
                  extra: entry,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartir',
                onPressed: () => _share(entry),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
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
                  ? Hero(
                      tag: 'entry_cover_${entry.id}',
                      child: Image.network(entry.fotoPrincipal!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: color.withValues(alpha: 0.2),
                              child: Icon(Icons.image,
                                  size: 80,
                                  color: color.withValues(alpha: 0.4)))),
                    )
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
                    runSpacing: 8,
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
                        label: DateFormat('dd/MM/yyyy')
                            .format(entry.fechaVisita),
                        color: theme.colorScheme.primary,
                      ),
                      if (entry.fotos.isNotEmpty)
                        _MetaChip(
                          icon: Icons.photo_library_outlined,
                          label:
                              '${entry.fotos.length} foto${entry.fotos.length == 1 ? '' : 's'}',
                          color: theme.colorScheme.tertiary,
                        ),
                    ],
                  ),

                  // Galería de fotos
                  if (entry.fotos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('Fotos', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        if (entry.fotos.length > 1)
                          TextButton(
                            onPressed: () =>
                                _openPhotoViewer(context, entry, 0),
                            child: const Text('Ver todas'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: entry.fotos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () =>
                              _openPhotoViewer(context, entry, i),
                          child: Hero(
                            tag: 'photo_hero_${entry.fotos[i].id}',
                            child: ClipRRect(
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
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(entry.nota,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                    ),
                  ],

                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir este lugar'),
                    onPressed: () => _share(entry),
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

  void _openPhotoViewer(
      BuildContext context, EntradaViaje entry, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => PhotoViewerScreen(
          fotos: entry.fotos,
          initialIndex: index,
          entryTitle: entry.titulo,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _share(EntradaViaje entry) {
    final lines = <String>[entry.titulo];
    lines.add('📅 ${DateFormat('dd/MM/yyyy').format(entry.fechaVisita)}');
    if (entry.tieneUbicacion) {
      lines.add(
          '📍 ${entry.latitud!.toStringAsFixed(5)}°, ${entry.longitud!.toStringAsFixed(5)}°');
    }
    if (entry.nota.isNotEmpty) {
      lines.add('');
      lines.add(entry.nota);
    }
    lines.add('');
    lines.add('Compartido desde Diario de Viajes 🗺️');
    Share.share(lines.join('\n'), subject: entry.titulo);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content:
            const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
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
