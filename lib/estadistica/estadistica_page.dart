// lib/estadistica/estadistica_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:collection';
import 'package:moodlog/database/database_helper.dart';

class EstadisticaPage extends StatefulWidget {
  final int userId;
  const EstadisticaPage({Key? key, required this.userId}) : super(key: key);

  @override
  _EstadisticaPageState createState() => _EstadisticaPageState();
}

enum RangeMode { day, week, month }

class _EstadisticaPageState extends State<EstadisticaPage> {
  List<Map<String, dynamic>> _estados = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  RangeMode _mode = RangeMode.day;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarEstados();
  }

  @override
  void didUpdateWidget(covariant EstadisticaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _cargarEstados();
    }
  }

  Future<void> _cargarEstados() async {
    setState(() => _isLoading = true);
    final memories = await DatabaseHelper().getMemoriesByUser(widget.userId);
    setState(() {
      _estados = memories.map((mem) {
        return {
          'fecha': DateTime.parse(mem['created_at']),
          'emoji': mem['emoji'],
        };
      }).toList();
      _isLoading = false;
    });
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupByDay(List<Map<String, dynamic>> estados) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (var e in estados) {
      final fecha = e['fecha'] as DateTime;
      final day = DateTime(fecha.year, fecha.month, fecha.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  String? _predominantEmojiForDay(DateTime day) {
    final grouped = _groupByDay(_estados);
    final list = grouped[DateTime(day.year, day.month, day.day)];
    if (list == null || list.isEmpty) return null;
    final counts = <String, int>{};
    for (var e in list) {
      final emoji = e['emoji'] as String;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    String best = counts.keys.first;
    counts.forEach((k, v) {
      if (v > counts[best]!) best = k;
    });
    return best;
  }

  DateTimeRange _rangeForMode(DateTime reference) {
    if (_mode == RangeMode.day) {
      final start = DateTime(reference.year, reference.month, reference.day);
      final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      return DateTimeRange(start: start, end: end);
    } else if (_mode == RangeMode.week) {
      final weekday = reference.weekday;
      final start = DateTime(reference.year, reference.month, reference.day)
          .subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      return DateTimeRange(start: start, end: end);
    } else {
      final start = DateTime(reference.year, reference.month, 1);
      final end = DateTime(reference.year, reference.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      return DateTimeRange(start: start, end: end);
    }
  }

  Map<String, int> _countsInRange(DateTimeRange range) {
    final counts = <String, int>{};
    for (var e in _estados) {
      final fecha = e['fecha'] as DateTime;
      if (fecha.isAfter(range.end) || fecha.isBefore(range.start)) continue;
      final emoji = e['emoji'] as String;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final sorted = SplayTreeMap<String, int>((a, b) => counts[b]!.compareTo(counts[a]!));
    sorted.addAll(counts);
    return Map<String, int>.from(sorted);
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> counts) {
    final entries = counts.entries.toList();
    return List.generate(entries.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries[i].value.toDouble(),
            color: Colors.blueAccent,
            width: 20,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  List<String> _xLabels(Map<String, int> counts) => counts.keys.toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')), // puedes mantener const en Text
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final range = _rangeForMode(_selectedDay ?? _focusedDay);
    final counts = _countsInRange(range);
    final barGroups = _buildBarGroups(counts);
    final xLabels = _xLabels(counts);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Día'),
                    selected: _mode == RangeMode.day,
                    onSelected: (_) => setState(() => _mode = RangeMode.day),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Semana'),
                    selected: _mode == RangeMode.week,
                    onSelected: (_) => setState(() => _mode = RangeMode.week),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Mes'),
                    selected: _mode == RangeMode.month,
                    onSelected: (_) => setState(() => _mode = RangeMode.month),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final emoji = _predominantEmojiForDay(day);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day.day}', style: const TextStyle(fontSize: 12)),
                          if (emoji != null) ...[
                            const SizedBox(height: 4),
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                          ],
                        ],
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final emoji = _predominantEmojiForDay(day);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15), // ✅ Corregido
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${day.day}', style: const TextStyle(fontSize: 12)),
                            if (emoji != null) ...[
                              const SizedBox(height: 4),
                              Text(emoji, style: const TextStyle(fontSize: 18)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _mode == RangeMode.day
                      ? 'Día: ${_selectedDay != null ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}" : ""}'
                      : _mode == RangeMode.week
                      ? 'Semana: ${range.start.day}/${range.start.month}/${range.start.year} - ${range.end.day}/${range.end.month}/${range.end.year}'
                      : 'Mes: ${range.start.month}/${range.start.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: counts.isEmpty
                        ? const Center(child: Text('No hay registros en este rango'))
                        : Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              final barWidth = 48.0;
                              final totalWidth = xLabels.length * barWidth;
                              final needScroll = totalWidth > constraints.maxWidth;

                              final chart = BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (counts.values.isNotEmpty
                                      ? counts.values.reduce((a, b) => a > b ? a : b)
                                      : 1)
                                      .toDouble() +
                                      1,
                                  barTouchData: BarTouchData(enabled: true), // ✅ sin const
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 48,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= xLabels.length)
                                            return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: SizedBox(
                                              width: 40,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  xLabels[idx],
                                                  style: const TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                  barGroups: barGroups,
                                ),
                              );

                              if (needScroll) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: totalWidth,
                                    height: constraints.maxHeight,
                                    child: chart,
                                  ),
                                );
                              }
                              return chart;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: counts.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(label: Text('${e.key}  ${e.value}')),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}