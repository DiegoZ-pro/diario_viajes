import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../map/application/entradas_provider.dart';
import '../../../map/data/models/entrada_viaje_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(entradasNotifierProvider.notifier).cargarEntradas());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<EntradaViaje> _filtrar(List<EntradaViaje> entradas) {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase().trim();
    return entradas.where((e) {
      return e.titulo.toLowerCase().contains(q) ||
          e.nota.toLowerCase().contains(q) ||
          (e.latitud?.toString().contains(q) ?? false) ||
          (e.longitud?.toString().contains(q) ?? false);
    }).toList();
  }

  void _onSearch(String value) => setState(() => _query = value);

  void _selectRecent(String term) {
    _searchController.text = term;
    setState(() => _query = term);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  void _saveSearch(String term) {
    if (term.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(entradasNotifierProvider);
    final entradas = state.entradas;
    final results = _filtrar(entradas);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Hero(
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearch,
              onSubmitted: _saveSearch,
              decoration: InputDecoration(
                hintText: 'Buscar lugares, notas...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              style: theme.textTheme.bodyLarge,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? _EmptyQuery(
                  recentSearches: _recentSearches,
                  onSelectRecent: _selectRecent,
                  onDeleteRecent: (term) =>
                      setState(() => _recentSearches.remove(term)),
                  onClearAll: () => setState(() => _recentSearches.clear()),
                  totalEntradas: entradas.length,
                )
              : results.isEmpty
                  ? _NoResults(query: _query)
                  : _ResultsList(
                      results: results,
                      query: _query,
                      onTap: (entry) {
                        _saveSearch(_query);
                        context.push('${AppRoutes.gallery}/${entry.id}');
                      },
                    ),
    );
  }
}

class _EmptyQuery extends StatelessWidget {
  final List<String> recentSearches;
  final void Function(String) onSelectRecent;
  final void Function(String) onDeleteRecent;
  final VoidCallback onClearAll;
  final int totalEntradas;

  const _EmptyQuery({
    required this.recentSearches,
    required this.onSelectRecent,
    required this.onDeleteRecent,
    required this.onClearAll,
    required this.totalEntradas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.travel_explore,
                  color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalEntradas lugares registrados',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Busca por nombre, nota o coordenadas',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (recentSearches.isNotEmpty) ...[
          Row(
            children: [
              Text('Búsquedas recientes',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: onClearAll,
                child:
                    const Text('Borrar todo', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentSearches.map((term) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.history,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
                title: Text(term, style: theme.textTheme.bodyMedium),
                trailing: IconButton(
                  icon: Icon(Icons.close,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => onDeleteRecent(term),
                ),
                onTap: () => onSelectRecent(term),
              )),
        ],
        const SizedBox(height: 20),
        Text('Prueba buscar por...',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Ciudad',
            'Playa',
            'Montaña',
            'Museo',
            'Restaurante',
            'Parque',
            'Hotel'
          ]
              .map((sugg) => ActionChip(
                    avatar: const Icon(Icons.search, size: 16),
                    label: Text(sugg),
                    onPressed: () => onSelectRecent(sugg),
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Sin resultados para',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              '"$query"',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Intenta con el nombre del lugar,\nparte de una nota o coordenadas.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<EntradaViaje> results;
  final String query;
  final void Function(EntradaViaje) onTap;

  const _ResultsList({
    required this.results,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(
            '${results.length} resultado${results.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ResultCard(
              entry: results[i],
              query: query,
              onTap: () => onTap(results[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final EntradaViaje entry;
  final String query;
  final VoidCallback onTap;

  const _ResultCard({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColorUtils.forSeed(entry.titulo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: entry.fotoPrincipal != null
                    ? Image.network(
                        entry.fotoPrincipal!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: color.withValues(alpha: 0.15),
                          child: Icon(Icons.place, color: color, size: 32),
                        ),
                      )
                    : Container(
                        color: color.withValues(alpha: 0.15),
                        child: Icon(Icons.place, color: color, size: 32),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightText(
                      text: entry.titulo,
                      query: query,
                      style: theme.textTheme.titleSmall!,
                      highlightColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    if (entry.nota.isNotEmpty)
                      _HighlightText(
                        text: entry.nota,
                        query: query,
                        style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        highlightColor: theme.colorScheme.primary,
                        maxLines: 2,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(entry.fechaVisita),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (entry.fotos.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.photo_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.fotos.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;
  final int maxLines;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w700,
          backgroundColor: highlightColor.withValues(alpha: 0.12),
        ),
      ));
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
