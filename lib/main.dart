import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FinanceTrackerApp());
}

// ----------------------------------------------------
// MODELO Y CATEGORÍAS
// ----------------------------------------------------
class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.name, this.icon, this.color);
}

final List<ExpenseCategory> expenseCategories = [
  const ExpenseCategory('Comida / Super', Icons.shopping_bag_rounded, Colors.orange),
  const ExpenseCategory('Ocio / Salidas', Icons.local_activity_rounded, Colors.purpleAccent),
  const ExpenseCategory('Transporte', Icons.directions_car_rounded, Colors.blue),
  const ExpenseCategory('Vivienda / Facturas', Icons.home_rounded, Colors.teal),
  const ExpenseCategory('Salud / Gym', Icons.favorite_rounded, Colors.redAccent),
  const ExpenseCategory('Otros Gastos', Icons.more_horiz_rounded, Colors.grey),
];

final List<ExpenseCategory> incomeCategories = [
  const ExpenseCategory('Nómina', Icons.work_rounded, Colors.green),
  const ExpenseCategory('Freelance / Proyectos', Icons.laptop_mac_rounded, Colors.lightGreen),
  const ExpenseCategory('Inversiones', Icons.trending_up_rounded, Colors.cyan),
  const ExpenseCategory('Otros Ingresos', Icons.attach_money_rounded, Colors.tealAccent),
];

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  final String note;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    this.note = '',
  });
}

// ----------------------------------------------------
// BASE DE DATOS / REPOSITORIO LOCAL
// ----------------------------------------------------
class FinanceDatabase {
  static final List<TransactionItem> _db = [
    TransactionItem(
      id: '1',
      title: 'Compra Mercadona',
      amount: 45.30,
      isIncome: false,
      category: 'Comida / Super',
      date: DateTime.now(),
      note: 'Compra del día',
    ),
    TransactionItem(
      id: '2',
      title: 'Cena Restaurante',
      amount: 26.50,
      isIncome: false,
      category: 'Ocio / Salidas',
      date: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Con amigos',
    ),
    TransactionItem(
      id: '3',
      title: 'Nómina',
      amount: 1850.00,
      isIncome: true,
      category: 'Nómina',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionItem(
      id: '4',
      title: 'Gasolina Repsol',
      amount: 60.00,
      isIncome: false,
      category: 'Transporte',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static Future<List<TransactionItem>> getTransactions() async {
    return List.from(_db);
  }

  static Future<void> insert(TransactionItem item) async {
    _db.insert(0, item);
  }

  static Future<void> delete(String id) async {
    _db.removeWhere((item) => item.id == id);
  }
}

// ----------------------------------------------------
// APLICACIÓN PRINCIPAL CON 4 PESTAÑAS
// ----------------------------------------------------
class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance AI Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF00CEC9),
          surface: Color(0xFF161926),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  List<TransactionItem> _transactions = [];
  bool _isLoading = true;
  String _geminiApiKey = ''; // Clave de Gemini

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await FinanceDatabase.getTransactions();
    setState(() {
      _transactions = list;
      _isLoading = false;
    });
  }

  void _addTransaction(TransactionItem item) async {
    await FinanceDatabase.insert(item);
    await _loadData();
  }

  void _deleteTransaction(String id) async {
    await FinanceDatabase.delete(id);
    await _loadData();
  }

  void _openAddTransactionModal(BuildContext context, {DateTime? initialDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161926),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AddTransactionModal(
        initialDate: initialDate ?? DateTime.now(),
        onSave: _addTransaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      HomeScreen(
        transactions: _transactions,
        onDelete: _deleteTransaction,
        onAddRequested: () => _openAddTransactionModal(context),
        onOpenAi: () => setState(() => _currentIndex = 3),
      ),
      CalendarScreen(
        transactions: _transactions,
        onDelete: _deleteTransaction,
        onAddForDate: (date) => _openAddTransactionModal(context, initialDate: date),
      ),
      StatsScreen(transactions: _transactions),
      AiChatScreen(
        transactions: _transactions,
        apiKey: _geminiApiKey,
        onApiKeyChanged: (key) => setState(() => _geminiApiKey = key),
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF161926),
        indicatorColor: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wallet_rounded),
            selectedIcon: Icon(Icons.wallet_rounded, color: Color(0xFF6C5CE7)),
            label: 'Billetera',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF6C5CE7)),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF00CEC9)),
            label: 'Gráficos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF00CEC9)),
            label: 'Gemini IA',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C5CE7),
              onPressed: () => _openAddTransactionModal(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

// ----------------------------------------------------
// 1. PANTALLA PRINCIPAL (HOME)
// ----------------------------------------------------
class HomeScreen extends StatelessWidget {
  final List<TransactionItem> transactions;
  final Function(String) onDelete;
  final VoidCallback onAddRequested;
  final VoidCallback onOpenAi;

  const HomeScreen({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onAddRequested,
    required this.onOpenAi,
  });

  double get _totalIncome => transactions.where((t) => t.isIncome).fold(0.0, (sum, i) => sum + i.amount);
  double get _totalExpense => transactions.where((t) => !t.isIncome).fold(0.0, (sum, i) => sum + i.amount);
  double get _totalBalance => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mi Billetera', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF00CEC9)),
            tooltip: 'Chat Gemini IA',
            onPressed: onOpenAi,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalBalance.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPill(Icons.arrow_downward, 'Ingresos', '+${_totalIncome.toStringAsFixed(2)} €', const Color(0xFF00B894)),
                      _buildPill(Icons.arrow_upward, 'Gastos', '-${_totalExpense.toStringAsFixed(2)} €', const Color(0xFFFF7675)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: onOpenAi,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161926),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF00CEC9)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gemini IA listo para analizar tus finanzas y darte recomendaciones.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Movimientos Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${transactions.length} registros', style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 15),

            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No hay registros todavía.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final item = transactions[index];
                  final cat = (item.isIncome ? incomeCategories : expenseCategories).firstWhere(
                    (c) => c.name == item.category,
                    orElse: () => ExpenseCategory(item.category, Icons.receipt_long, Colors.blueGrey),
                  );

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => onDelete(item.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161926),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cat.color.withValues(alpha: 0.2),
                            child: Icon(cat.icon, color: cat.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  '${item.category} • ${item.date.day}/${item.date.month}/${item.date.year}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.isIncome ? '+' : '-'}${item.amount.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: item.isIncome ? const Color(0xFF00B894) : const Color(0xFFFF7675),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String title, String amount, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 2. PESTAÑA CALENDARIO (DÍAS, SEMANAS, MESES, AÑOS)
// ----------------------------------------------------
enum CalendarViewMode { dias, semanas, meses, anos }

class CalendarScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final Function(String) onDelete;
  final Function(DateTime) onAddForDate;

  const CalendarScreen({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onAddForDate,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarViewMode _mode = CalendarViewMode.dias;
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameWeek(DateTime a, DateTime b) {
    final startOfWeekA = a.subtract(Duration(days: a.weekday - 1));
    final startOfWeekB = b.subtract(Duration(days: b.weekday - 1));
    return _isSameDay(startOfWeekA, startOfWeekB);
  }

  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
  bool _isSameYear(DateTime a, DateTime b) => a.year == b.year;

  List<TransactionItem> get _filteredTransactions {
    return widget.transactions.where((t) {
      switch (_mode) {
        case CalendarViewMode.dias:
          return _isSameDay(t.date, _selectedDate);
        case CalendarViewMode.semanas:
          return _isSameWeek(t.date, _selectedDate);
        case CalendarViewMode.meses:
          return _isSameMonth(t.date, _selectedDate);
        case CalendarViewMode.anos:
          return _isSameYear(t.date, _selectedDate);
      }
    }).toList();
  }

  String get _periodTitle {
    const monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    switch (_mode) {
      case CalendarViewMode.dias:
        return '${_selectedDate.day} de ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
      case CalendarViewMode.semanas:
        final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return 'Semana: ${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
      case CalendarViewMode.meses:
        return '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
      case CalendarViewMode.anos:
        return 'Año ${_selectedDate.year}';
    }
  }

  void _navigatePeriod(int direction) {
    setState(() {
      switch (_mode) {
        case CalendarViewMode.dias:
          _selectedDate = _selectedDate.add(Duration(days: direction));
          break;
        case CalendarViewMode.semanas:
          _selectedDate = _selectedDate.add(Duration(days: direction * 7));
          break;
        case CalendarViewMode.meses:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + direction, _selectedDate.day.clamp(1, 28));
          break;
        case CalendarViewMode.anos:
          _selectedDate = DateTime(_selectedDate.year + direction, _selectedDate.month, _selectedDate.day.clamp(1, 28));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final totalIncome = filtered.where((t) => t.isIncome).fold(0.0, (s, i) => s + i.amount);
    final totalExpense = filtered.where((t) => !t.isIncome).fold(0.0, (s, i) => s + i.amount);
    final periodBalance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Financiero', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Modo (Días, Semanas, Meses, Años)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildModeTab('Días', CalendarViewMode.dias),
                  _buildModeTab('Semanas', CalendarViewMode.semanas),
                  _buildModeTab('Meses', CalendarViewMode.meses),
                  _buildModeTab('Años', CalendarViewMode.anos),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Navegador de Período
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    onPressed: () => _navigatePeriod(-1),
                  ),
                  Text(
                    _periodTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    onPressed: () => _navigatePeriod(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Resumen del Período
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance del Período', style: TextStyle(color: Colors.white70)),
                      Text(
                        '${periodBalance >= 0 ? '+' : ''}${periodBalance.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: periodBalance >= 0 ? const Color(0xFF00B894) : const Color(0xFFFF7675),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Ingresos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('+${totalIncome.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF00B894), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(height: 24, width: 1, color: Colors.white10),
                      Column(
                        children: [
                          const Text('Gastos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('-${totalExpense.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFFFF7675), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Lista de Movimientos Filtrados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Movimientos en esta fecha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C5CE7)),
                  tooltip: 'Añadir para esta fecha',
                  onPressed: () => widget.onAddForDate(_selectedDate),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF161926),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No hay movimientos registrados para este período.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final item = filtered[idx];
                  final cat = (item.isIncome ? incomeCategories : expenseCategories).firstWhere(
                    (c) => c.name == item.category,
                    orElse: () => ExpenseCategory(item.category, Icons.receipt_long, Colors.blueGrey),
                  );

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => widget.onDelete(item.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161926),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cat.color.withValues(alpha: 0.2),
                            child: Icon(cat.icon, color: cat.color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  '${item.category} • ${item.date.day}/${item.date.month}/${item.date.year}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.isIncome ? '+' : '-'}${item.amount.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: item.isIncome ? const Color(0xFF00B894) : const Color(0xFFFF7675),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, CalendarViewMode mode) {
    final isSelected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 3. PESTAÑA DE GRÁFICOS Y ANÁLISIS
// ----------------------------------------------------
class StatsScreen extends StatelessWidget {
  final List<TransactionItem> transactions;

  const StatsScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((t) => !t.isIncome).toList();
    final totalExpense = expenses.fold(0.0, (sum, i) => sum + i.amount);
    final totalIncome = transactions.where((t) => t.isIncome).fold(0.0, (sum, i) => sum + i.amount);
    final savingsRate = totalIncome > 0 ? (((totalIncome - totalExpense) / totalIncome) * 100).clamp(0, 100) : 0.0;

    final Map<String, double> categorySums = {};
    for (var exp in expenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis y Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasa de Ahorro del Mes', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      Text('${savingsRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00CEC9))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (savingsRate / 100).toDouble(),
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CEC9)),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text('Distribución de Gastos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            if (expenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('No hay suficientes gastos para generar gráficos.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...categorySums.entries.map((entry) {
                final percent = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                final catInfo = expenseCategories.firstWhere(
                  (c) => c.name == entry.key,
                  orElse: () => ExpenseCategory(entry.key, Icons.category, Colors.purple),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161926),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(catInfo.icon, color: catInfo.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(catInfo.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Text('${entry.value.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(catInfo.color),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. CHAT CONECTADO A LA API REAL DE GEMINI
// ----------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiChatScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final String apiKey;
  final Function(String) onApiKeyChanged;

  const AiChatScreen({
    super.key,
    required this.transactions,
    required this.apiKey,
    required this.onApiKeyChanged,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy tu asistente financiero con Google Gemini. Conozco tu balance actual, ingresos y gastos registrados. Pregúntame sobre cómo optimizar tus presupuestos o ahorrar para tus metas.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    if (widget.apiKey.isEmpty) {
      _showApiKeyDialog(message: 'Introduce tu Gemini API Key para chatear con la IA.');
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
      _controller.clear();
    });

    try {
      // Contexto financiero inyectado en el prompt
      final totalIncome = widget.transactions.where((t) => t.isIncome).fold(0.0, (s, i) => s + i.amount);
      final totalExpense = widget.transactions.where((t) => !t.isIncome).fold(0.0, (s, i) => s + i.amount);
      final balance = totalIncome - totalExpense;

      final expensesBreakdown = widget.transactions
          .where((t) => !t.isIncome)
          .map((e) => '- ${e.title} (${e.category}): ${e.amount.toStringAsFixed(2)} €')
          .join('\n');

      final systemPrompt = '''
Eres un asesor financiero personal experto, empático y motivador.
Datos actuales del usuario:
- Balance Total: ${balance.toStringAsFixed(2)} €
- Total Ingresos: ${totalIncome.toStringAsFixed(2)} €
- Total Gastos: ${totalExpense.toStringAsFixed(2)} €
- Desglose de gastos recientes:
$expensesBreakdown

Responde en español de forma concisa, clara y accionable. Usa formato con viñetas cuando sea apropiado.
Pregunta del usuario: $userText
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${widget.apiKey}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No pude generar una respuesta.';
        setState(() {
          _messages.add(ChatMessage(text: aiText, isUser: false, timestamp: DateTime.now()));
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error al conectar con Gemini (${response.statusCode}): Revisa si tu API Key es correcta.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: 'Error de red: $e', isUser: false, timestamp: DateTime.now()),
        );
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _showApiKeyDialog({String? message}) {
    final keyController = TextEditingController(text: widget.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161926),
        title: const Text('Configurar Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
              const SizedBox(height: 10),
            ],
            const Text(
              'Consigue tu clave gratuita en Google AI Studio (aistudio.google.com):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key (AIzaSy...)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () {
              widget.onApiKeyChanged(keyController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00CEC9), size: 20),
            SizedBox(width: 8),
            Text('Gemini AI Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              widget.apiKey.isEmpty ? Icons.key_off_rounded : Icons.key_rounded,
              color: widget.apiKey.isEmpty ? Colors.orangeAccent : const Color(0xFF00CEC9),
            ),
            tooltip: 'Configurar Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.apiKey.isEmpty)
            Container(
              color: Colors.orange.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Toca la llave arriba para configurar tu Gemini API Key.', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _showApiKeyDialog,
                    child: const Text('Configurar', style: TextStyle(color: Color(0xFF00CEC9))),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF6C5CE7) : const Color(0xFF161926),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                      border: !msg.isUser ? Border.all(color: Colors.white10) : null,
                    ),
                    child: Text(msg.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Gemini está analizando tus finanzas...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF161926),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Pregunta a Gemini (ej. ¿En qué gasto más?)...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0D0F17),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// MODAL DE AÑADIR REGISTRO AVANZADO
// ----------------------------------------------------
class AddTransactionModal extends StatefulWidget {
  final DateTime initialDate;
  final Function(TransactionItem) onSave;

  const AddTransactionModal({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  bool _isIncome = false;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = expenseCategories.first.name;
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = _isIncome ? incomeCategories : expenseCategories;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nuevo Movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Gasto', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: !_isIncome,
                    selectedColor: const Color(0xFFFF7675),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _isIncome = false;
                          _selectedCategory = expenseCategories.first.name;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Ingreso', style: TextStyle(fontWeight: FontWeight.bold))),
                    selected: _isIncome,
                    selectedColor: const Color(0xFF00B894),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _isIncome = true;
                          _selectedCategory = incomeCategories.first.name;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título o Comercio',
                filled: true,
                fillColor: const Color(0xFF0D0F17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Importe (€)',
                prefixIcon: const Icon(Icons.euro),
                filled: true,
                fillColor: const Color(0xFF0D0F17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 15),

            const Text('Categoría', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final cat = availableCategories[idx];
                  final isSelected = _selectedCategory == cat.name;
                  return FilterChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6C5CE7),
                    onSelected: (_) => setState(() => _selectedCategory = cat.name),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F17),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00CEC9)),
                    const SizedBox(width: 10),
                    Text('Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    const Spacer(),
                    const Text('Cambiar', style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Nota opcional',
                filled: true,
                fillColor: const Color(0xFF0D0F17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final title = _titleController.text.trim();
                  final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

                  if (title.isNotEmpty && amount > 0) {
                    widget.onSave(TransactionItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      amount: amount,
                      isIncome: _isIncome,
                      category: _selectedCategory,
                      date: _selectedDate,
                      note: _noteController.text.trim(),
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar Registro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}