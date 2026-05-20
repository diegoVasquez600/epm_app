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
      AlertsPage(data: widget.data),
      SavingsPage(data: widget.data),
      MorePage(data: widget.data),
    ];

    return Scaffold(
      body: Container(
        color: const Color(0xFFF7F8F7),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 1000 ? 1100.0 : 460.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
    final alerts = data.alerts.take(2).toList();

    return ListView(
      children: [
        _HeaderBar(
          notificationsCount: data.notifications.length,
          onNotificationsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsPage(data: data),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          '¡Hola, ${data.user.name}! 👋',
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w900,
            color: Color(0xFF162117),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Asi va tu consumo hoy.',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3C463D),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F7D2C), Color(0xFF17A43A)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26177E38),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consumo de hoy',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCF2D0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Dentro de meta',
                      style: TextStyle(
                        color: Color(0xFF13873A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '12.4',
                    style: const TextStyle(
                      fontSize: 42,
                      height: 1,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      'kWh',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.arrow_drop_up, color: Color(0xFFC8F44A), size: 24),
                  Text(
                    '8% mas que ayer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 92,
                      child: DailyConsumptionSparkline(
                        points: dashboard.dailyConsumption,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.billing.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2F3830)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dashboard.billing.amount,
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF121712)),
                    ),
                  ),
                  FilledButton(
                    onPressed: isPaying ? null : onPayPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF13873A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isPaying ? 'Pagando...' : dashboard.billing.cta),
                  ),
                ],
              ),
              Text(
                dashboard.billing.dueDate,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374138)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.savings.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dashboard.savings.message,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu meta del mes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFF13873A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compra de lavadora eficiente',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B7F35)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            r'Has ahorrado $85.000 de $100.000',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF465247)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD2E2D6)),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            r'$15.000',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B7F35), fontSize: 16),
                          ),
                          Text(
                            'te faltan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Alertas activas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver todas'),
            ),
          ],
        ),
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDecoration(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: alert.service == 'energia'
                        ? const Color(0xFFFFC21A)
                        : const Color(0xFF5CA1E6),
                    child: Icon(
                      alert.service == 'energia'
                          ? Icons.lightbulb_rounded
                          : Icons.local_laundry_service_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(alert.detail, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A554B))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ahora',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6E776F)),
                      ),
                      SizedBox(height: 6),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF283029)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen del dia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DailySummaryChart(points: dashboard.dailyConsumption),
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
  late String _period;
  late int _year;

  int get _minYear => widget.data.historyByYear.keys.reduce((a, b) => a < b ? a : b);
  int get _maxYear => widget.data.historyByYear.keys.reduce((a, b) => a > b ? a : b);

  @override
  void initState() {
    super.initState();
    _period = 'anual';
    _year = _maxYear;
  }

  final List<double> _dailyValues = <double>[
    0.22,
    0.12,
    0.30,
    0.20,
    0.28,
    0.52,
    0.86,
    0.42,
    1.28,
    0.84,
    0.52,
    0.74,
    1.02,
    1.42,
    0.76,
    0.86,
    0.74,
    0.66,
    1.04,
    0.88,
    0.76,
    0.24,
    0.30,
    0.56,
  ];

  static const List<String> _months = <String>['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  static const List<double> _annualBars = <double>[520, 360, 450, 542, 520, 560, 590, 600, 535, 470, 460, 570];
  static const List<double> _annualPrev = <double>[500, 460, 480, 470, 495, 460, 450, 520, 650, 490, 430, 470];
  static const List<double> _annualCurrent = <double>[410, 320, 500, 460, 510, 450, 570, 612, 520, 430, 410, 540];

  String get _periodLabel {
    switch (_period) {
      case 'diario':
        return '28 de mayo de 2024';
      case 'mensual':
        return 'mayo de 2024';
      default:
        return '$_year';
    }
  }

  void _goPrevious() {
    setState(() {
      if (_period == 'anual') {
        _year = _year > _minYear ? _year - 1 : _year;
      }
    });
  }

  void _goNext() {
    setState(() {
      if (_period == 'anual') {
        _year = _year < _maxYear ? _year + 1 : _year;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF1F2721)),
            ),
            const Expanded(
              child: Text(
                'Historial de consumo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 33, fontWeight: FontWeight.w900, color: Color(0xFF121914)),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final item in const [
              ('diario', 'Diario'),
              ('mensual', 'Mensual'),
              ('anual', 'Anual'),
            ])
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _period = item.$1;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _period == item.$1 ? const Color(0xFF1FA34A) : const Color(0xFFDDE4DE),
                          width: _period == item.$1 ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _period == item.$1 ? const Color(0xFF1A973F) : const Color(0xFF586257),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE7EBE8)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _goPrevious,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1F2621)),
              ),
              const Icon(Icons.calendar_today_outlined, size: 19, color: Color(0xFF2D3730)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _periodLabel,
                  style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w800, color: Color(0xFF1A231D)),
                ),
              ),
              IconButton(
                onPressed: _goNext,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1F2621)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_period == 'diario') ..._buildDailyView() else ..._buildAnnualView(monthly: _period == 'mensual'),
      ],
    );
  }

  List<Widget> _buildDailyView() {
    return [
      _consumptionHeaderCard(
        title: 'Consumo total del dia',
        value: '11.6',
        unit: 'kWh',
        delta: '8%',
        vsLabel: 'vs. ayer',
      ),
      const SizedBox(height: 12),
      _DailyChart(values: _dailyValues, highlightIndex: 13, maxY: 2.5, tooltip: '1.2 kWh'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF4E5A52)),
                SizedBox(width: 8),
                Text(
                  'Consumo por franja horaria',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A231C)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final row in const [
              ('00:00 - 06:00', 1.8, 16),
              ('06:00 - 12:00', 3.2, 28),
              ('12:00 - 18:00', 4.0, 34),
              ('18:00 - 24:00', 2.6, 22),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.$1,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5A645C)),
                          ),
                        ),
                        Text(
                          '${row.$2.toStringAsFixed(1)} kWh',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF232E26)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${row.$3}%',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF556156)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: row.$3 / 100,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE9EEEA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          row.$3 >= 30 ? const Color(0xFF08933A) : const Color(0xFF17A13F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dispositivos que mas consumieron hoy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF18221C)),
            ),
            const SizedBox(height: 12),
            for (final item in const [
              ('Lavadora', '2.4 kWh', '21%', Icons.local_laundry_service_rounded, Color(0xFF2591F1)),
              ('Aire acondicionado', '2.1 kWh', '18%', Icons.ac_unit_rounded, Color(0xFFFF8C3A)),
              ('Nevera', '1.6 kWh', '14%', Icons.kitchen_rounded, Color(0xFF159B4B)),
              ('Iluminacion', '1.2 kWh', '10%', Icons.lightbulb_rounded, Color(0xFFFFB321)),
              ('Otros', '4.3 kWh', '37%', Icons.more_horiz_rounded, Color(0xFFC7CDD1)),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: (item.$5 as Color).withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: Icon(item.$4 as IconData, size: 19, color: item.$5 as Color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$1 as String,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A231C)),
                      ),
                    ),
                    Text(
                      item.$2 as String,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A231C)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.$3 as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF68726A)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B9590)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF188A3D),
          side: const BorderSide(color: Color(0xFF199447), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.event_note_rounded, size: 20),
        label: const Row(
          children: [
            Expanded(
              child: Text(
                'Ver recomendaciones para hoy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildAnnualView({required bool monthly}) {
    final title = monthly ? 'Consumo total del mes' : 'Consumo total del año';
    final value = monthly ? '355' : '4,256';
    final delta = monthly ? '5%' : '6%';
    final vs = monthly ? 'vs. abril' : 'vs. ${_year - 1}';

    return [
      _consumptionHeaderCard(
        title: title,
        value: value,
        unit: 'kWh',
        delta: delta,
        vsLabel: vs,
      ),
      const SizedBox(height: 12),
      _AnnualBarsChart(
        maxY: 800,
        months: _months,
        values: _annualBars,
        highlightIndex: 3,
        tooltip: '542 kWh',
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 18, color: Color(0xFF4E5A52)),
                SizedBox(width: 8),
                Text(
                  'Resumen anual',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A231C)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.28,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _AnnualStatTile(title: 'Promedio mensual', value: '355 kWh'),
                _AnnualStatTile(title: 'Mes de mayor consumo', value: 'Agosto\n612 kWh'),
                _AnnualStatTile(title: 'Mes de menor consumo', value: 'Febrero\n274 kWh'),
                _AnnualStatTile(title: 'Dia de mayor consumo', value: '15 de agosto\n24.3 kWh'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparación anual',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF18221C)),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                _LegendDot(color: Color(0xFFC8CDD0), label: '2023'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFF14913D), label: '2024'),
              ],
            ),
            const SizedBox(height: 8),
            _AnnualGroupedChart(
              maxY: 800,
              months: _months,
              previous: _annualPrev,
              current: _annualCurrent,
              highlightIndex: 7,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF188A3D),
          side: const BorderSide(color: Color(0xFF199447), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.route_rounded, size: 20),
        label: const Row(
          children: [
            Expanded(
              child: Text(
                'Ver recomendaciones para ahorrar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.eco_rounded, color: Color(0xFF79BB5B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tip anual: Mantener habitos de ahorro puede\nhacer una gran diferencia en tu consumo y en el planeta.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4B5F4D)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _consumptionHeaderCard({
    required String title,
    required String value,
    required String unit,
    required String delta,
    required String vsLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Color(0xFFD9F2DD), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF10A33F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF445147)),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(fontSize: 41, fontWeight: FontWeight.w900, color: Color(0xFF0F1A13)),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF0F1A13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDDF4E1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '▲ $delta',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E9D43)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vsLabel,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2A332D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({
    required this.values,
    required this.highlightIndex,
    required this.maxY,
    required this.tooltip,
  });

  final List<double> values;
  final int highlightIndex;
  final double maxY;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('kWh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6D756E))),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('2.5', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('2.0', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('1.5', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('1.0', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('0.5', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('0', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Align(
                                alignment: Alignment(0, 1 - (i / 5) * 2),
                                child: Container(height: 1, color: const Color(0xFFE8ECE9)),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < values.length; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: values[i] / maxY,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: i == highlightIndex ? const Color(0xFF14963D) : const Color(0xFF64C951),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Align(
                              alignment: Alignment(-0.02, -0.05),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E1435),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tooltip,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(child: Center(child: Text('00', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('04', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('08', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('12', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('16', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('20', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                          Expanded(child: Center(child: Text('24', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF646E67))))),
                        ],
                      ),
                    ],
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

class _AnnualBarsChart extends StatelessWidget {
  const _AnnualBarsChart({
    required this.maxY,
    required this.months,
    required this.values,
    required this.highlightIndex,
    required this.tooltip,
  });

  final double maxY;
  final List<String> months;
  final List<double> values;
  final int highlightIndex;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('kWh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6D756E))),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('800', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('600', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('400', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('200', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('0', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      for (var i = 1; i <= 4; i++)
                        Align(
                          alignment: Alignment(0, 1 - (i / 4) * 2),
                          child: Container(height: 1, color: const Color(0xFFE8ECE9)),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < values.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Container(
                                  height: 170 * (values[i] / maxY),
                                  decoration: BoxDecoration(
                                    color: i == highlightIndex ? const Color(0xFF14963D) : const Color(0xFF66C953),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment(-0.39, -0.98),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF0E1435), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            tooltip,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final month in months)
                Expanded(
                  child: Center(
                    child: Text(
                      month,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF606B63)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnualGroupedChart extends StatelessWidget {
  const _AnnualGroupedChart({
    required this.maxY,
    required this.months,
    required this.previous,
    required this.current,
    required this.highlightIndex,
  });

  final double maxY;
  final List<String> months;
  final List<double> previous;
  final List<double> current;
  final int highlightIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('800', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('600', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('400', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('200', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                      Text('0', style: TextStyle(fontSize: 13, color: Color(0xFF7A827B))),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      for (var i = 1; i <= 4; i++)
                        Align(
                          alignment: Alignment(0, 1 - (i / 4) * 2),
                          child: Container(height: 1, color: const Color(0xFFE8ECE9)),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < months.length; i++)
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1),
                                      child: Container(
                                        height: 150 * (previous[i] / maxY),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC8CDD0),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1),
                                      child: Container(
                                        height: 150 * (current[i] / maxY),
                                        decoration: BoxDecoration(
                                          color: i == highlightIndex ? const Color(0xFF0F8D36) : const Color(0xFF69C75A),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment(0.27, -0.96),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E5E2)),
                          ),
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '2023: 650 kWh\n',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8A9190)),
                                ),
                                TextSpan(
                                  text: '2024: 612 kWh',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1F9641)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final month in months)
                Expanded(
                  child: Center(
                    child: Text(
                      month,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF606B63)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5E6861))),
      ],
    );
  }
}

class _AnnualStatTile extends StatelessWidget {
  const _AnnualStatTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF5F7F6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF626D65)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A241D)),
              ),
            ),
          ),
        ],
      ),
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
      Icons.access_time_rounded,
      Icons.notifications_none_rounded,
      Icons.savings_rounded,
      Icons.more_horiz_rounded,
    ];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
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
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE7ECE8)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0E1B3020),
        blurRadius: 10,
        offset: Offset(0, 2),
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
        'dailyConsumption': [
          {'hour': 0, 'value': 0.0, 'highlight': false},
          {'hour': 1, 'value': 0.0, 'highlight': false},
          {'hour': 2, 'value': 0.1, 'highlight': false},
          {'hour': 3, 'value': 0.3, 'highlight': false},
          {'hour': 4, 'value': 0.7, 'highlight': false},
          {'hour': 5, 'value': 0.5, 'highlight': false},
          {'hour': 6, 'value': 0.6, 'highlight': false},
          {'hour': 7, 'value': 0.4, 'highlight': false},
          {'hour': 8, 'value': 0.3, 'highlight': false},
          {'hour': 9, 'value': 0.5, 'highlight': false},
          {'hour': 10, 'value': 1.2, 'highlight': false},
          {'hour': 11, 'value': 0.6, 'highlight': false},
          {'hour': 12, 'value': 0.7, 'highlight': false},
          {'hour': 13, 'value': 1.3, 'highlight': true},
          {'hour': 14, 'value': 0.8, 'highlight': false},
          {'hour': 15, 'value': 0.7, 'highlight': false},
          {'hour': 16, 'value': 0.5, 'highlight': false},
          {'hour': 17, 'value': 0.4, 'highlight': false},
          {'hour': 18, 'value': 0.6, 'highlight': false},
          {'hour': 19, 'value': 0.6, 'highlight': false},
          {'hour': 20, 'value': 0.4, 'highlight': false},
          {'hour': 21, 'value': 0.1, 'highlight': false},
          {'hour': 22, 'value': 0.0, 'highlight': false},
          {'hour': 23, 'value': 0.0, 'highlight': false},
        ],
      },
      'tabs': ['Inicio', 'Historial', 'Alertas', 'Ahorro', 'Mas'],
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
          'title': 'Lampara encendida',
          'detail': 'La lampara de la sala lleva encendida 3h 15m.',
          'delta': 'Ahora',
          'severity': 'high',
        },
        {
          'service': 'agua',
          'title': 'Uso alto de lavadora',
          'detail': 'Llevas 2 ciclos hoy, mas de lo habitual.',
          'delta': 'Ahora',
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
    required this.dailyConsumption,
  });

  final String period;
  final String consumptionStatus;
  final List<ConsumptionItem> consumption;
  final BillingData billing;
  final SavingsData savings;
  final List<DailyConsumptionPoint> dailyConsumption;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      period: json['period'] as String,
      consumptionStatus: json['consumptionStatus'] as String,
      consumption: (json['consumption'] as List<dynamic>)
          .map((item) => ConsumptionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      billing: BillingData.fromJson(json['billing'] as Map<String, dynamic>),
      savings: SavingsData.fromJson(json['savings'] as Map<String, dynamic>),
      dailyConsumption: (json['dailyConsumption'] as List<dynamic>)
          .map((item) => DailyConsumptionPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
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

class DailyConsumptionPoint {
  DailyConsumptionPoint({
    required this.hour,
    required this.value,
    required this.highlight,
  });

  final int hour;
  final double value;
  final bool highlight;

  String get hourLabel => hour.toString().padLeft(2, '0');

  factory DailyConsumptionPoint.fromJson(Map<String, dynamic> json) {
    return DailyConsumptionPoint(
      hour: json['hour'] as int,
      value: (json['value'] as num).toDouble(),
      highlight: json['highlight'] as bool? ?? false,
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.notificationsCount,
    required this.onNotificationsTap,
  });

  final int notificationsCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/logo.png',
          width: 96,
          height: 32,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const Spacer(),
        InkWell(
          onTap: onNotificationsTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 30, color: Color(0xFF111A13)),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$notificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class DailyConsumptionSparkline extends StatelessWidget {
  const DailyConsumptionSparkline({required this.points, super.key});

  final List<DailyConsumptionPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(points: points),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points});

  final List<DailyConsumptionPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final maxValue = points.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    final path = Path();
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFF1ED2C);

    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final normalized = points[i].value / maxValue;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * ((i - 1) / (points.length - 1));
        final prevY = size.height - ((points[i - 1].value / maxValue) * (size.height - 8)) - 4;
        final control1 = Offset(prevX + (x - prevX) * 0.45, prevY);
        final control2 = Offset(prevX + (x - prevX) * 0.55, y);
        path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final lastX = size.width;
    final lastY = size.height - ((points.last.value / maxValue) * (size.height - 8)) - 4;
    final dotPaint = Paint()..color = const Color(0xFFF1ED2C);
    canvas.drawCircle(Offset(lastX, lastY), 4.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.points != points;
}

class DailySummaryChart extends StatelessWidget {
  const DailySummaryChart({required this.points, super.key});

  final List<DailyConsumptionPoint> points;

  @override
  Widget build(BuildContext context) {
    final bars = points.take(24).toList();
    final maxValue = bars.map((point) => point.value).fold<double>(1, (prev, point) => point > prev ? point : prev);
    final highlighted = bars.where((e) => e.highlight).isNotEmpty ? bars.where((e) => e.highlight).first : bars[13];
    final highlightedIndex = bars.indexOf(highlighted);

    return Column(
      children: [
        SizedBox(
          height: 146,
          child: Row(
            children: [
              const SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2.0', style: TextStyle(fontSize: 11, color: Color(0xFF6E776F))),
                    Text('1.0', style: TextStyle(fontSize: 11, color: Color(0xFF6E776F))),
                    Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF6E776F))),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final point in bars)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: FractionallySizedBox(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: point.value / maxValue,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: point.highlight ? const Color(0xFF13873A) : const Color(0xFF34B233),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('04', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('08', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('12', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('16', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('20', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                        Text('24', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F5850))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment(
            ((highlightedIndex / 23) * 2) - 1,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${highlighted.value.toStringAsFixed(1)} kWh',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
class SavingsPage extends StatelessWidget {
  const SavingsPage({required this.data, super.key});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final tips = data.recommendations;
    const potential = ['5 kWh/mes', '7 kWh/mes', '4 kWh/mes', '3 kWh/mes'];
    const icons = [
      Icons.lightbulb_rounded,
      Icons.local_laundry_service_rounded,
      Icons.shower_rounded,
      Icons.kitchen_rounded,
    ];
    const colors = [
      Color(0xFFF3B21A),
      Color(0xFF5A86C9),
      Color(0xFF36A145),
      Color(0xFF8D63D9),
    ];

    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            const Expanded(
              child: Text(
                'Recomendaciones de ahorro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF18211B)),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Basadas en tu consumo y hábitos\nte recomendamos:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35, color: Color(0xFF1F2721)),
        ),
        const SizedBox(height: 14),
        ...List<Widget>.generate(tips.length, (index) {
          final tip = tips[index];
          final color = colors[index % colors.length];
          final icon = icons[index % icons.length];
          final amount = potential[index % potential.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: cardDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF18211B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.detail,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.25, color: Color(0xFF4D5650)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Ahorro potencial',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6E7771)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          amount,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E9B45)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AlertTab extends StatelessWidget {
  const _AlertTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF1E9B45) : const Color(0xFFE2E7E3),
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF1E9B45) : const Color(0xFF5E6862),
          ),
        ),
      ),
    );
  }
}

Color _alertColor(String service) {
  switch (service) {
    case 'energia':
      return const Color(0xFFF2BE1C);
    case 'agua':
      return const Color(0xFF5EA3E3);
    case 'gas':
      return const Color(0xFF52B53E);
    default:
      return const Color(0xFF1E9B45);
  }
}

IconData _alertIcon(String service) {
  switch (service) {
    case 'energia':
      return Icons.lightbulb_rounded;
    case 'agua':
      return Icons.local_laundry_service_rounded;
    case 'gas':
      return Icons.whatshot_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

class MorePage extends StatelessWidget {
  const MorePage({required this.data, super.key});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Mas', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        for (final module in data.modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: Row(
                children: [
                  Icon(iconFromName(module.icon), color: module.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(module.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(module.description, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF566157))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
