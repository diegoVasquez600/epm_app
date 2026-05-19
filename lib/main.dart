import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const EpmPrototypeApp());
}

class EpmPrototypeApp extends StatelessWidget {
  const EpmPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPM App Prototipo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF13873A),
          secondary: Color(0xFF65BE70),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6F2),
        textTheme: GoogleFonts.manropeTextTheme(),
      ),
      home: const EpmRootPage(),
    );
  }
}

class EpmRootPage extends StatefulWidget {
  const EpmRootPage({super.key});

  @override
  State<EpmRootPage> createState() => _EpmRootPageState();
}

class _EpmRootPageState extends State<EpmRootPage> {
  late final Future<AppData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<AppData> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/mock/dashboard.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppData.fromJson(json);
    } catch (_) {
      return AppData.prototypeFallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('No fue posible cargar el prototipo.')),
          );
        }

        return EpmMainShell(data: snapshot.data!);
      },
    );
  }
}

class EpmMainShell extends StatefulWidget {
  const EpmMainShell({required this.data, super.key});

  final AppData data;

  @override
  State<EpmMainShell> createState() => _EpmMainShellState();
}

class _EpmMainShellState extends State<EpmMainShell> {
  int _currentTab = 0;
  bool _isPaying = false;

  Future<void> _simulatePayment() async {
    if (_isPaying) {
      return;
    }

    setState(() {
      _isPaying = true;
    });

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Procesando pago...',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    navigator.pop();

    final now = DateTime.now();
    final ticket =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF13873A)),
              SizedBox(width: 8),
              Text('Pago exitoso'),
            ],
          ),
          content: Text(
            'Tu pago por ${widget.data.dashboard.billing.amount} fue aprobado.\n\nComprobante: $ticket',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Listo'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeDashboardPage(
        data: widget.data,
        onPayPressed: _simulatePayment,
        isPaying: _isPaying,
      ),
      HistoryPage(data: widget.data),
      ServicesHubPage(data: widget.data),
      TipsPage(data: widget.data),
      NotificationsPage(data: widget.data),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F5EA), Color(0xFFF8FBF8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 1000 ? 1100.0 : 460.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      children: [
                        Expanded(child: pages[_currentTab]),
                        const SizedBox(height: 10),
                        BottomTabs(
                          items: widget.data.tabs,
                          currentIndex: _currentTab,
                          onTap: (index) {
                            setState(() {
                              _currentTab = index;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    required this.data,
    required this.onPayPressed,
    required this.isPaying,
    super.key,
  });

  final AppData data;
  final VoidCallback onPayPressed;
  final bool isPaying;

  @override
  Widget build(BuildContext context) {
    final dashboard = data.dashboard;

    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${data.user.name}!',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF162117),
                    ),
                  ),
                  Text(
                    data.user.greeting,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38433A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.notifications_none_rounded, size: 28),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consumo actual\n${dashboard.period}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(dashboard.consumptionStatus),
                    backgroundColor: const Color(0xFFDEF2E2),
                    labelStyle: const TextStyle(
                      color: Color(0xFF1B8A3B),
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < dashboard.consumption.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: ConsumptionTile(item: dashboard.consumption[i]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.billing.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dashboard.billing.amount,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton(
                    onPressed: isPaying ? null : onPayPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF13873A),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isPaying ? 'Pagando...' : dashboard.billing.cta),
                  ),
                ],
              ),
              Text(
                dashboard.billing.dueDate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.savings.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dashboard.savings.message,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    Text(
                      dashboard.savings.subMessage,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: dashboard.savings.percentage / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFDCE5DC),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF13873A)),
                    ),
                    Center(
                      child: Text(
                        '${dashboard.savings.percentage}%',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.data, super.key});

  final AppData data;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _service = 'energia';
  int _year = 2026;

  @override
  Widget build(BuildContext context) {
    final history = widget.data.historyByYear[_year] ?? const <MonthlyConsumption>[];
    final maxValue = history
        .map((m) => m.valueFor(_service))
        .fold<int>(1, (prev, e) => e > prev ? e : prev)
        .toDouble();

    return ListView(
      children: [
        const Text(
          'Historial de consumo',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final service in ['energia', 'agua', 'gas'])
              ChoiceChip(
                label: Text(capitalize(service)),
                selected: _service == service,
                onSelected: (_) {
                  setState(() {
                    _service = service;
                  });
                },
                selectedColor: const Color(0xFFE1F4E5),
                labelStyle: TextStyle(
                  color: _service == service ? const Color(0xFF13873A) : const Color(0xFF4D574E),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final year in widget.data.historyByYear.keys.toList()..sort())
              ChoiceChip(
                label: Text('$year'),
                selected: _year == year,
                onSelected: (_) {
                  setState(() {
                    _year = year;
                  });
                },
                selectedColor: const Color(0xFFE1F4E5),
                labelStyle: TextStyle(
                  color: _year == year ? const Color(0xFF13873A) : const Color(0xFF4D574E),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'kWh',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6A746B)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in history)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: item.valueFor(_service) / maxValue,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF62B96D),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.month,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B655C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalle mensual $_year',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              for (final item in history.reversed.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.periodLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${item.valueFor(_service)} ${unitForService(_service)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ComparisonPage(data: widget.data),
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE7F3EA),
            foregroundColor: const Color(0xFF1B8A3B),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'Comparar con otro periodo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class ServicesHubPage extends StatelessWidget {
  const ServicesHubPage({required this.data, super.key});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;

    return ListView(
      children: [
        const Text(
          'Todo lo que necesitas para gestionar\ntus servicios de forma facil y inteligente',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
            color: Color(0xFF13873A),
          ),
        ),
        const SizedBox(height: 12),
        if (wide)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final module in data.modules)
                SizedBox(
                  width: 200,
                  child: ModuleTile(
                    module: module,
                    onTap: () => _openModule(context, module.key),
                  ),
                ),
            ],
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => SizedBox(
                width: 180,
                child: ModuleTile(
                  module: data.modules[index],
                  onTap: () => _openModule(context, data.modules[index].key),
                ),
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: data.modules.length,
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modulos principales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF13873A),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.modules.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final module = data.modules[index];
                    return SizedBox(
                      width: 260,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E3DA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${module.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E2820),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                module.preview,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF455046),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                onPressed: () => _openModule(context, module.key),
                                child: const Text('Abrir modulo'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openModule(BuildContext context, String key) {
    late final Widget page;

    switch (key) {
      case 'alertas':
        page = AlertsPage(data: data);
        break;
      case 'historial':
        page = HistoryPage(data: data);
        break;
      case 'recomendaciones':
        page = TipsPage(data: data);
        break;
      case 'comparacion':
        page = ComparisonPage(data: data);
        break;
      case 'notificaciones':
        page = NotificationsPage(data: data);
        break;
      default:
        page = AlertsPage(data: data);
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ModuleScaffold(body: page)),
    );
  }
}

class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modulo EPM'),
        backgroundColor: const Color(0xFFE7F5EA),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F5EA), Color(0xFFF8FBF8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({required this.data, super.key});

  final AppData data;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String _filter = 'todos';

  @override
  Widget build(BuildContext context) {
    final alerts = widget.data.alerts.where((alert) {
      if (_filter == 'todos') {
        return true;
      }
      return alert.service == _filter;
    }).toList();

    return ListView(
      children: [
        const Text(
          'Alertas de consumo',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final item in ['todos', 'energia', 'agua', 'gas'])
              ChoiceChip(
                label: Text(capitalize(item)),
                selected: _filter == item,
                onSelected: (_) {
                  setState(() {
                    _filter = item;
                  });
                },
                selectedColor: const Color(0xFFE2F4E6),
                labelStyle: TextStyle(
                  color: _filter == item ? const Color(0xFF13873A) : const Color(0xFF536054),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    alert.severity == 'high' ? Icons.warning_rounded : Icons.info_rounded,
                    color: alert.severity == 'high'
                        ? const Color(0xFFE34A4A)
                        : const Color(0xFF13873A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert.detail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F5A50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.delta,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A756B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class TipsPage extends StatelessWidget {
  const TipsPage({required this.data, super.key});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Recomendaciones\nde ahorro',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: 10),
        const Text(
          'Consejos para ti',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF13873A)),
        ),
        const SizedBox(height: 8),
        for (final tip in data.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.eco_rounded, color: Color(0xFF13873A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tip.detail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A554B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF13873A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Ver mas consejos'),
        ),
      ],
    );
  }
}

class ComparisonPage extends StatelessWidget {
  const ComparisonPage({required this.data, super.key});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final comparison = data.comparison;

    return ListView(
      children: [
        const Text(
          'Comparacion\nmensual',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD3DDD4)),
                ),
                child: Text(comparison.currentPeriod),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD3DDD4)),
                ),
                child: Text(comparison.previousPeriod),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(child: Text('Servicio', style: TextStyle(fontWeight: FontWeight.w800))),
                  Text('Mes actual', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(width: 16),
                  Text('Mes previo', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(width: 16),
                  Text('Variacion', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              for (final row in comparison.rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(capitalize(row.service))),
                      Text(row.current),
                      const SizedBox(width: 22),
                      Text(row.previous),
                      const SizedBox(width: 22),
                      Row(
                        children: [
                          Icon(
                            row.changePercent >= 0
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: const Color(0xFF13873A),
                          ),
                          Text(
                            '${row.changePercent.abs()}%',
                            style: const TextStyle(
                              color: Color(0xFF13873A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text(comparison.summary),
              const SizedBox(height: 10),
              Container(
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDDEEDF), Color(0xFFF0F8F1)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.landscape_rounded, color: Color(0xFF53A55D), size: 40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({required this.data, super.key});

  final AppData data;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _mode = 'todo';

  @override
  Widget build(BuildContext context) {
    final list = widget.data.notifications.where((n) {
      if (_mode == 'todo') {
        return true;
      }
      if (_mode == 'no leidas') {
        return n.status == 'unread';
      }
      return n.status == 'read';
    }).toList();

    return ListView(
      children: [
        const Text(
          'Notificaciones',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in ['todo', 'no leidas', 'leidas'])
              ChoiceChip(
                label: Text(capitalize(mode)),
                selected: _mode == mode,
                onSelected: (_) {
                  setState(() {
                    _mode = mode;
                  });
                },
                selectedColor: const Color(0xFFE2F4E6),
                labelStyle: TextStyle(
                  color: _mode == mode ? const Color(0xFF13873A) : const Color(0xFF536054),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.status == 'unread' ? Icons.notifications_active_rounded : Icons.notifications_rounded,
                    color: item.status == 'unread' ? const Color(0xFFE34A4A) : const Color(0xFF8A958B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B564C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ModuleTile extends StatelessWidget {
  const ModuleTile({
    required this.module,
    required this.onTap,
    super.key,
  });

  final ModuleInfo module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE4DD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconFromName(module.icon), color: module.color, size: 26),
            const SizedBox(height: 8),
            Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              module.description,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A655B),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsumptionTile extends StatelessWidget {
  const ConsumptionTile({required this.item, super.key});

  final ConsumptionItem item;

  @override
  Widget build(BuildContext context) {
    final up = item.direction == 'up';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(iconFromName(item.icon), color: item.color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '${item.value} ${item.unit}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 20,
                color: const Color(0xFF13873A),
              ),
              Text(
                '${item.trend}%',
                style: const TextStyle(
                  color: Color(0xFF13873A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<String> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.widgets_rounded,
      Icons.menu_book_rounded,
      Icons.notifications_rounded,
    ];

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1F2F21),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[i],
                      size: 22,
                      color: i == currentIndex ? const Color(0xFF13873A) : const Color(0xFF6E7A6F),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == currentIndex ? FontWeight.w800 : FontWeight.w600,
                        color: i == currentIndex ? const Color(0xFF13873A) : const Color(0xFF6E7A6F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A233728),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}

String capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}

String unitForService(String service) {
  switch (service) {
    case 'energia':
      return 'kWh';
    case 'agua':
    case 'gas':
      return 'm3';
    default:
      return '';
  }
}

IconData iconFromName(String name) {
  switch (name) {
    case 'alert':
      return Icons.notification_important_rounded;
    case 'history':
      return Icons.bar_chart_rounded;
    case 'tips':
      return Icons.lightbulb_rounded;
    case 'compare':
      return Icons.compare_arrows_rounded;
    case 'notifications':
      return Icons.notifications_active_rounded;
    case 'electricity':
      return Icons.bolt_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'fire':
      return Icons.local_fire_department_rounded;
    default:
      return Icons.circle;
  }
}

class AppData {
  AppData({
    required this.user,
    required this.dashboard,
    required this.tabs,
    required this.modules,
    required this.alerts,
    required this.recommendations,
    required this.notifications,
    required this.comparison,
    required this.historyByYear,
  });

  final UserProfile user;
  final DashboardSummary dashboard;
  final List<String> tabs;
  final List<ModuleInfo> modules;
  final List<AlertItem> alerts;
  final List<TipItem> recommendations;
  final List<NotificationItem> notifications;
  final ComparisonData comparison;
  final Map<int, List<MonthlyConsumption>> historyByYear;

  factory AppData.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['historyByYear'] as Map<String, dynamic>;

    return AppData(
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      dashboard: DashboardSummary.fromJson(json['dashboard'] as Map<String, dynamic>),
      tabs: List<String>.from(json['tabs'] as List<dynamic>),
      modules: (json['modules'] as List<dynamic>)
          .map((item) => ModuleInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      alerts: (json['alerts'] as List<dynamic>)
          .map((item) => AlertItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((item) => TipItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      notifications: (json['notifications'] as List<dynamic>)
          .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      comparison: ComparisonData.fromJson(json['comparison'] as Map<String, dynamic>),
      historyByYear: {
        for (final entry in historyRaw.entries)
          int.parse(entry.key): (entry.value as List<dynamic>)
              .map((item) => MonthlyConsumption.fromJson(item as Map<String, dynamic>))
              .toList(),
      },
    );
  }

  factory AppData.prototypeFallback() {
    return AppData.fromJson({
      'user': {
        'name': 'Ana',
        'greeting': 'Bienvenida a tu espacio EPM',
      },
      'dashboard': {
        'period': 'Mayo 2026',
        'consumptionStatus': 'Dentro de meta',
        'consumption': [
          {
            'icon': 'electricity',
            'label': 'Energia',
            'value': 180,
            'unit': 'kWh',
            'trend': 12,
            'direction': 'up',
          },
          {
            'icon': 'water_drop',
            'label': 'Agua',
            'value': 12,
            'unit': 'm3',
            'trend': 8,
            'direction': 'up',
          },
          {
            'icon': 'fire',
            'label': 'Gas',
            'value': 9,
            'unit': 'm3',
            'trend': 5,
            'direction': 'down',
          },
        ],
        'billing': {
          'title': 'Valor aproximado de tu factura',
          'amount': r'$145.000',
          'dueDate': 'Fecha de pago: 28 May 2026',
          'cta': 'Pagar ahora',
        },
        'savings': {
          'title': 'Tu estado de ahorro',
          'message': 'Vas por buen camino!',
          'subMessage': 'Estas dentro de tu meta mensual',
          'percentage': 85,
        },
      },
      'tabs': ['Inicio', 'Consumos', 'Servicios', 'Formacion', 'Mas'],
      'modules': [
        {
          'key': 'alertas',
          'title': 'Alertas de consumo',
          'icon': 'alert',
          'description': 'Recibe alertas inteligentes sobre cambios en tu consumo.',
          'preview': 'Tu consumo de energia aumento 20% frente al mes anterior.',
          'color': 4293084746,
        },
        {
          'key': 'historial',
          'title': 'Historial de consumo',
          'icon': 'history',
          'description': 'Consulta tu historial y visualiza tendencias por servicio.',
          'preview': 'Visualiza 2025 y 2026 con filtros por energia, agua y gas.',
          'color': 4283524520,
        },
        {
          'key': 'recomendaciones',
          'title': 'Recomendaciones de ahorro',
          'icon': 'tips',
          'description': 'Consejos personalizados para ahorrar en casa cada dia.',
          'preview': 'Desconecta aparatos inactivos para reducir hasta 8% consumo.',
          'color': 4286736269,
        },
        {
          'key': 'comparacion',
          'title': 'Comparacion mensual',
          'icon': 'compare',
          'description': 'Compara tu consumo actual con el mes anterior.',
          'preview': 'Energia +17%, Agua +20%, Gas +17% frente al mes previo.',
          'color': 4285749584,
        },
        {
          'key': 'notificaciones',
          'title': 'Notificaciones de alto consumo',
          'icon': 'notifications',
          'description': 'Actua rapido cuando se detecta una subida fuerte.',
          'preview': 'Has alcanzado 85% de tu meta mensual de energia.',
          'color': 4294945317,
        },
      ],
      'alerts': [
        {
          'service': 'energia',
          'title': 'Tu consumo de energia aumento 20%',
          'detail': 'Frente al mes anterior. Revisa uso de aires y cocina.',
          'delta': '+20 kWh',
          'severity': 'high',
        },
        {
          'service': 'agua',
          'title': 'Incremento de 15% en agua esta semana',
          'detail': 'Posible fuga detectada en zona de lavadora.',
          'delta': '+1.8 m3',
          'severity': 'medium',
        },
        {
          'service': 'gas',
          'title': 'Perfil de fuga detectada en uso nocturno',
          'detail': 'Actividad inusual entre 2AM y 4AM.',
          'delta': '+0.6 m3',
          'severity': 'high',
        },
      ],
      'recommendations': [
        {
          'title': 'Usa bombillas LED',
          'detail': 'Reduce uso de energia hasta 20% en iluminacion.',
        },
        {
          'title': 'Toma duchas de maximo 5 minutos',
          'detail': 'Ahorra agua sin perder confort diario.',
        },
        {
          'title': 'Desconecta aparatos inactivos',
          'detail': 'Evita consumo fantasma durante la noche.',
        },
        {
          'title': 'Aprovecha luz natural',
          'detail': 'Disminuye uso de focos durante el dia.',
        },
      ],
      'notifications': [
        {
          'title': 'Has alcanzado 85% de tu meta mensual de energia',
          'detail': 'Te queda margen de ahorro para cerrar bien el mes.',
          'status': 'unread',
        },
        {
          'title': 'Tu consumo de agua esta por encima del promedio',
          'detail': 'Aproximadamente +18% frente al promedio.',
          'status': 'unread',
        },
        {
          'title': 'Recordatorio: menor consumo de gas en frio',
          'detail': 'Revisa termostato y ventilacion para optimizar.',
          'status': 'read',
        },
      ],
      'comparison': {
        'currentPeriod': 'Mayo 2026',
        'previousPeriod': 'Abr 2026',
        'summary': 'Tu consumo total aumento 17% respecto al mes anterior.',
        'rows': [
          {
            'service': 'energia',
            'current': '180 kWh',
            'previous': '154 kWh',
            'changePercent': 17,
          },
          {
            'service': 'agua',
            'current': '12 m3',
            'previous': '10 m3',
            'changePercent': 20,
          },
          {
            'service': 'gas',
            'current': '9 m3',
            'previous': '7.7 m3',
            'changePercent': 17,
          },
        ],
      },
      'historyByYear': {
        '2025': [
          {'month': 'Ene', 'energia': 144, 'agua': 9, 'gas': 7},
          {'month': 'Feb', 'energia': 147, 'agua': 9, 'gas': 7},
          {'month': 'Mar', 'energia': 151, 'agua': 10, 'gas': 7},
          {'month': 'Abr', 'energia': 149, 'agua': 10, 'gas': 8},
          {'month': 'May', 'energia': 154, 'agua': 10, 'gas': 8},
          {'month': 'Jun', 'energia': 157, 'agua': 10, 'gas': 8},
          {'month': 'Jul', 'energia': 160, 'agua': 11, 'gas': 8},
          {'month': 'Ago', 'energia': 163, 'agua': 11, 'gas': 8},
          {'month': 'Sep', 'energia': 161, 'agua': 11, 'gas': 8},
          {'month': 'Oct', 'energia': 166, 'agua': 11, 'gas': 9},
          {'month': 'Nov', 'energia': 169, 'agua': 11, 'gas': 9},
          {'month': 'Dic', 'energia': 172, 'agua': 12, 'gas': 9}
        ],
        '2026': [
          {'month': 'Ene', 'energia': 168, 'agua': 10, 'gas': 8},
          {'month': 'Feb', 'energia': 170, 'agua': 10, 'gas': 8},
          {'month': 'Mar', 'energia': 174, 'agua': 11, 'gas': 8},
          {'month': 'Abr', 'energia': 154, 'agua': 10, 'gas': 7},
          {'month': 'May', 'energia': 180, 'agua': 12, 'gas': 9},
          {'month': 'Jun', 'energia': 183, 'agua': 12, 'gas': 9},
          {'month': 'Jul', 'energia': 186, 'agua': 12, 'gas': 9},
          {'month': 'Ago', 'energia': 182, 'agua': 12, 'gas': 9},
          {'month': 'Sep', 'energia': 179, 'agua': 11, 'gas': 8},
          {'month': 'Oct', 'energia': 181, 'agua': 11, 'gas': 8},
          {'month': 'Nov', 'energia': 184, 'agua': 12, 'gas': 8},
          {'month': 'Dic', 'energia': 187, 'agua': 12, 'gas': 9}
        ]
      },
    });
  }
}

class UserProfile {
  UserProfile({required this.name, required this.greeting});

  final String name;
  final String greeting;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      greeting: json['greeting'] as String,
    );
  }
}

class DashboardSummary {
  DashboardSummary({
    required this.period,
    required this.consumptionStatus,
    required this.consumption,
    required this.billing,
    required this.savings,
  });

  final String period;
  final String consumptionStatus;
  final List<ConsumptionItem> consumption;
  final BillingData billing;
  final SavingsData savings;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      period: json['period'] as String,
      consumptionStatus: json['consumptionStatus'] as String,
      consumption: (json['consumption'] as List<dynamic>)
          .map((item) => ConsumptionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      billing: BillingData.fromJson(json['billing'] as Map<String, dynamic>),
      savings: SavingsData.fromJson(json['savings'] as Map<String, dynamic>),
    );
  }
}

class ConsumptionItem {
  ConsumptionItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.trend,
    required this.direction,
  });

  final String icon;
  final String label;
  final int value;
  final String unit;
  final int trend;
  final String direction;

  Color get color {
    switch (icon) {
      case 'electricity':
        return const Color(0xFFF7B61D);
      case 'water_drop':
        return const Color(0xFF2F96D9);
      case 'fire':
        return const Color(0xFF52AB2C);
      default:
        return const Color(0xFF13873A);
    }
  }

  factory ConsumptionItem.fromJson(Map<String, dynamic> json) {
    return ConsumptionItem(
      icon: json['icon'] as String,
      label: json['label'] as String,
      value: json['value'] as int,
      unit: json['unit'] as String,
      trend: json['trend'] as int,
      direction: json['direction'] as String,
    );
  }
}

class BillingData {
  BillingData({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.cta,
  });

  final String title;
  final String amount;
  final String dueDate;
  final String cta;

  factory BillingData.fromJson(Map<String, dynamic> json) {
    return BillingData(
      title: json['title'] as String,
      amount: json['amount'] as String,
      dueDate: json['dueDate'] as String,
      cta: json['cta'] as String,
    );
  }
}

class SavingsData {
  SavingsData({
    required this.title,
    required this.message,
    required this.subMessage,
    required this.percentage,
  });

  final String title;
  final String message;
  final String subMessage;
  final int percentage;

  factory SavingsData.fromJson(Map<String, dynamic> json) {
    return SavingsData(
      title: json['title'] as String,
      message: json['message'] as String,
      subMessage: json['subMessage'] as String,
      percentage: json['percentage'] as int,
    );
  }
}

class ModuleInfo {
  ModuleInfo({
    required this.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.preview,
    required this.color,
  });

  final String key;
  final String title;
  final String icon;
  final String description;
  final String preview;
  final Color color;

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      key: json['key'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      preview: json['preview'] as String,
      color: Color(json['color'] as int),
    );
  }
}

class AlertItem {
  AlertItem({
    required this.service,
    required this.title,
    required this.detail,
    required this.delta,
    required this.severity,
  });

  final String service;
  final String title;
  final String detail;
  final String delta;
  final String severity;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      service: json['service'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      delta: json['delta'] as String,
      severity: json['severity'] as String,
    );
  }
}

class TipItem {
  TipItem({required this.title, required this.detail});

  final String title;
  final String detail;

  factory TipItem.fromJson(Map<String, dynamic> json) {
    return TipItem(
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }
}

class NotificationItem {
  NotificationItem({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final String status;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] as String,
      detail: json['detail'] as String,
      status: json['status'] as String,
    );
  }
}

class ComparisonData {
  ComparisonData({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.summary,
    required this.rows,
  });

  final String currentPeriod;
  final String previousPeriod;
  final String summary;
  final List<ComparisonRow> rows;

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      currentPeriod: json['currentPeriod'] as String,
      previousPeriod: json['previousPeriod'] as String,
      summary: json['summary'] as String,
      rows: (json['rows'] as List<dynamic>)
          .map((item) => ComparisonRow.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ComparisonRow {
  ComparisonRow({
    required this.service,
    required this.current,
    required this.previous,
    required this.changePercent,
  });

  final String service;
  final String current;
  final String previous;
  final int changePercent;

  factory ComparisonRow.fromJson(Map<String, dynamic> json) {
    return ComparisonRow(
      service: json['service'] as String,
      current: json['current'] as String,
      previous: json['previous'] as String,
      changePercent: json['changePercent'] as int,
    );
  }
}

class MonthlyConsumption {
  MonthlyConsumption({
    required this.month,
    required this.energia,
    required this.agua,
    required this.gas,
  });

  final String month;
  final int energia;
  final int agua;
  final int gas;

  String get periodLabel => '$month 2026';

  int valueFor(String service) {
    switch (service) {
      case 'energia':
        return energia;
      case 'agua':
        return agua;
      case 'gas':
        return gas;
      default:
        return energia;
    }
  }

  factory MonthlyConsumption.fromJson(Map<String, dynamic> json) {
    return MonthlyConsumption(
      month: json['month'] as String,
      energia: json['energia'] as int,
      agua: json['agua'] as int,
      gas: json['gas'] as int,
    );
  }
}
