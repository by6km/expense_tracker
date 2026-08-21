import 'package:flutter/material.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      isIncome: map['isIncome'] == 1,
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }
}

// ----------------------------------------------------
// BASE DE DATOS / REPOSITORIO LOCAL
// ----------------------------------------------------
class FinanceDatabase {
  static final List<TransactionItem> _memoryDb = [
    TransactionItem(
      id: '1',
      title: 'Compra semanal Mercadona',
      amount: 64.30,
      isIncome: false,
      category: 'Comida / Super',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      note: 'Comida para toda la semana',
    ),
    TransactionItem(
      id: '2',
      title: 'Cena con amigos',
      amount: 28.50,
      isIncome: false,
      category: 'Ocio / Salidas',
      date: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Hamburguesería',
    ),
    TransactionItem(
      id: '3',
      title: 'Nómina Empresa',
      amount: 1950.00,
      isIncome: true,
      category: 'Nómina',
      date: DateTime.now().subtract(const Duration(days: 4)),
      note: 'Mes en curso',
    ),
    TransactionItem(
      id: '4',
      title: 'Gasolina',
      amount: 55.00,
      isIncome: false,
      category: 'Transporte',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static Future<List<TransactionItem>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_memoryDb);
  }

  static Future<void> insert(TransactionItem item) async {
    _memoryDb.insert(0, item);
  }

  static Future<void> delete(String id) async {
    _memoryDb.removeWhere((item) => item.id == id);
  }
}

// ----------------------------------------------------
// APLICACIÓN PRINCIPAL CON NAVEGACIÓN
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
        onOpenAi: () => setState(() => _currentIndex = 2),
      ),
      StatsScreen(transactions: _transactions),
      AiChatScreen(transactions: _transactions),
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
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF00CEC9)),
            label: 'Gráficos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF00CEC9)),
            label: 'Asistente IA',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C5CE7),
              onPressed: () => _openAddTransactionModal(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _openAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161926),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AddTransactionModal(onSave: _addTransaction),
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
            tooltip: 'Chat con IA',
            onPressed: onOpenAi,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
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

            // AI Insight Banner
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
                        'Asistente IA activo: Pulsa aquí para pedir consejos de ahorro sobre tu balance.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Movimientos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  '${item.category} • ${item.date.day}/${item.date.month}',
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
// 2. MODAL DE AÑADIR REGISTRO AVANZADO
// ----------------------------------------------------
class AddTransactionModal extends StatefulWidget {
  final Function(TransactionItem) onSave;

  const AddTransactionModal({super.key, required this.onSave});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  bool _isIncome = false;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCategory = expenseCategories.first.name;
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

            // Selector Tipo Gasto / Ingreso
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

            // Categoría con Scroll Horizontal
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

            // Selector de Fecha
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2025),
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

    // Agrupación de gastos por categoría
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
            // Tarjeta Tasa de Ahorro
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
// 4. CHAT INTELIGENTE CON LA IA
// ----------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiChatScreen extends StatefulWidget {
  final List<TransactionItem> transactions;

  const AiChatScreen({super.key, required this.transactions});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy tu asesor financiero de IA. He analizado tus transacciones registradas. Puedes preguntarme cómo optimizar tu presupuesto, en qué estás gastando más o qué plan de ahorro seguir.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
    });

    // Simulación del razonamiento IA contextualizado a las finanzas del usuario
    Future.delayed(const Duration(milliseconds: 700), () {
      final response = _generateFinancialAdvice(userText);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
      });
    });
  }

  String _generateFinancialAdvice(String prompt) {
    final expenses = widget.transactions.where((t) => !t.isIncome).toList();
    final totalExpense = expenses.fold(0.0, (sum, i) => sum + i.amount);
    final totalIncome = widget.transactions.where((t) => t.isIncome).fold(0.0, (sum, i) => sum + i.amount);
    final balance = totalIncome - totalExpense;

    final lower = prompt.toLowerCase();
    if (lower.contains('presupuesto') || lower.contains('50/30/20') || lower.contains('plan')) {
      return '📊 **Propuesta de Presupuesto 50/30/20** con tus ingresos actuales (${totalIncome.toStringAsFixed(2)} €):\n\n'
          '• **50% Necesidades básicas:** ${(totalIncome * 0.5).toStringAsFixed(2)} €\n'
          '• **30% Deseos / Ocio:** ${(totalIncome * 0.3).toStringAsFixed(2)} €\n'
          '• **20% Ahorro e inversión:** ${(totalIncome * 0.2).toStringAsFixed(2)} €\n\n'
          'Actualmente tus gastos totales suponen un ${totalIncome > 0 ? ((totalExpense / totalIncome) * 100).toStringAsFixed(0) : 0}% de tus ingresos.';
    } else if (lower.contains('ahorrar') || lower.contains('consejo') || lower.contains('reducir')) {
      return '💡 **Consejo personalizado:**\n\n'
          'Tu balance actual es de **${balance.toStringAsFixed(2)} €**.\n'
          'Si destinas una transferencia automática de ${(totalIncome * 0.15).toStringAsFixed(0)} € a una cuenta de ahorro nada más recibir la nómina, habrás acumulado más de ${(totalIncome * 0.15 * 12).toStringAsFixed(0)} € en un año.';
    } else {
      return 'He revisado tu cuenta: tienes ${widget.transactions.length} movimientos registrados con un balance neto de **${balance.toStringAsFixed(2)} €**. ¿Quieres que simulemos un objetivo de ahorro para un viaje o para un fondo de emergencia?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00CEC9), size: 20),
            SizedBox(width: 8),
            Text('Asesor Financiero IA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                );
              },
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
                      hintText: 'Pregúntale a la IA (ej. ¿Cómo ahorro más?)...',
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