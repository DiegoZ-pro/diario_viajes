import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/color_utils.dart';
import '../../../map/application/entradas_provider.dart';
import '../../../map/data/models/entrada_viaje_model.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    Future.microtask(
        () => ref.read(entradasNotifierProvider.notifier).cargarEntradas());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _calcStats(List<EntradaViaje> entradas) {
    if (entradas.isEmpty) {
      return {
        'total': 0,
        'fotos': 0,
        'diasActivo': 0,
        'primerViaje': null,
        'ultimoViaje': null,
        'porMes': <int, int>{},
        'racha': 0,
      };
    }

    final totalFotos = entradas.fold(0, (s, e) => s + e.fotos.length);

    final diasUnicos = entradas
        .map((e) =>
            '${e.fechaVisita.year}-${e.fechaVisita.month}-${e.fechaVisita.day}')
        .toSet()
        .length;

    final porMes = <int, int>{};
    final ahora = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final mes = DateTime(ahora.year, ahora.month - i, 1);
      final key = mes.month;
      porMes[key] = entradas
          .where((e) =>
              e.fechaVisita.year == mes.year &&
              e.fechaVisita.month == mes.month)
          .length;
    }

    final fechas = entradas
        .map((e) => DateTime(
            e.fechaVisita.year, e.fechaVisita.month, e.fechaVisita.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int racha = 0;
    DateTime ref_ = DateTime.now();
    for (final f in fechas) {
      final diff = ref_.difference(f).inDays;
      if (diff <= 1) {
        racha++;
        ref_ = f;
      } else {
        break;
      }
    }

    return {
      'total': entradas.length,
      'fotos': totalFotos,
      'diasActivo': diasUnicos,
      'primerViaje': entradas.last.fechaVisita,
      'ultimoViaje': entradas.first.fechaVisita,
      'porMes': porMes,
      'racha': racha,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entradasNotifierProvider);
    final entradas = state.entradas;
    final stats = _calcStats(entradas);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : entradas.isEmpty
              ? _EmptyStats()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _SectionTitle(title: 'Resumen'),
                      const SizedBox(height: 12),
                      _SummaryGrid(stats: stats),
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Actividad últimos 6 meses'),
                      const SizedBox(height: 12),
                      _MonthlyBarChart(
                        porMes: stats['porMes'] as Map<int, int>,
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Tu historia de viajes'),
                      const SizedBox(height: 12),
                      _TimelineCard(
                        primero: stats['primerViaje'] as DateTime?,
                        ultimo: stats['ultimoViaje'] as DateTime?,
                        total: stats['total'] as int,
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Últimos lugares'),
                      const SizedBox(height: 12),
                      ...entradas.take(3).map(
                            (e) => _RecentEntryTile(entry: e),
                          ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          value: '${stats['total']}',
          label: 'Lugares',
          icon: Icons.place_rounded,
          color: Theme.of(context).colorScheme.primary,
          bgColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        _StatCard(
          value: '${stats['fotos']}',
          label: 'Fotos',
          icon: Icons.photo_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          bgColor: Theme.of(context).colorScheme.tertiaryContainer,
        ),
        _StatCard(
          value: '${stats['diasActivo']}',
          label: 'Días activo',
          icon: Icons.calendar_today_rounded,
          color: Theme.of(context).colorScheme.secondary,
          bgColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
        _StatCard(
          value: '${stats['racha']}',
          label: 'Racha actual',
          icon: Icons.local_fire_department_rounded,
          color: Theme.of(context).colorScheme.error,
          bgColor: Theme.of(context).colorScheme.errorContainer,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final Map<int, int> porMes;
  const _MonthlyBarChart({required this.porMes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final meses = porMes.entries.toList();
    final maxVal = meses.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    const nombMes = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxVal + 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (val, _) => val == val.roundToDouble()
                    ? Text('${val.toInt()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant))
                    : const SizedBox(),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= meses.length) return const SizedBox();
                  final mes = meses[idx].key;
                  if (mes < 1 || mes > 12) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      nombMes[mes],
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: meses.asMap().entries.map((entry) {
            final i = entry.key;
            final val = entry.value.value.toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: val > 0 ? color : theme.colorScheme.outlineVariant,
                  width: 28,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (maxVal + 1).toDouble(),
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()} lugar${rod.toY == 1 ? '' : 'es'}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final DateTime? primero;
  final DateTime? ultimo;
  final int total;
  const _TimelineCard({
    required this.primero,
    required this.ultimo,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Formato seguro sin locale
    final fmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primer viaje',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    primero != null ? fmt.format(primero!) : '-',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$total',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('lugares',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Último viaje',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    ultimo != null ? fmt.format(ultimo!) : '-',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentEntryTile extends StatelessWidget {
  final EntradaViaje entry;
  const _RecentEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColorUtils.forSeed(entry.titulo);
    final fmt = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: entry.fotoPrincipal != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      entry.fotoPrincipal!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.place, color: color, size: 28),
                    ),
                  )
                : Icon(Icons.place, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.titulo,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  fmt.format(entry.fechaVisita),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (entry.fotos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${entry.fotos.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 80, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Aún no hay estadísticas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Registra tu primer lugar para\nver tus estadísticas aquí',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
