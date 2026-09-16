import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceTrackerApp());
}

// ----------------------------------------------------
// MODELOS DE DATOS
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

class MandatoryBudget {
  final String category;
  final double amount;
  final String frequency; // 'diario', 'semanal', 'mensual'

  MandatoryBudget({
    required this.category,
    required this.amount,
    required this.frequency,
  });

  double get monthlyEstimated {
    if (frequency == 'diario') return amount * 30;
    if (frequency == 'semanal') return amount * 4.33;
    return amount;
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'amount': amount,
        'frequency': frequency,
      };

  factory MandatoryBudget.fromMap(Map<String, dynamic> map) => MandatoryBudget(
        category: map['category'],
        amount: (map['amount'] as num).toDouble(),
        frequency: map['frequency'],
      );
}

// ----------------------------------------------------
// PERSISTENCIA PERMANENTE MULTIUSUARIO
// ----------------------------------------------------
class StorageService {
  static const _keyUsers = 'app_users';
  static const _keyCurrentSession = 'app_current_session';

  static Future<bool> registerUser(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final usersRaw = prefs.getString(_keyUsers);
    Map<String, dynamic> users = usersRaw != null ? jsonDecode(usersRaw) : {};

    if (users.containsKey(email)) return false; // Usuario ya existe

    users[email] = {
      'name': name,
      'password': password,
      'transactions': [],
      'budgets': [],
    };

    await prefs.setString(_keyUsers, jsonEncode(users));
    await prefs.setString(_keyCurrentSession, email);
    return true;
  }

  static Future<bool> loginUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersRaw = prefs.getString(_keyUsers);
    if (usersRaw == null) return false;

    Map<String, dynamic> users = jsonDecode(usersRaw);
    if (users.containsKey(email) && users[email]['password'] == password) {
      await prefs.setString(_keyCurrentSession, email);
      return true;
    }
    return false;
  }

  static Future<String?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentSession);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentSession);
  }

  static Future<String> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyCurrentSession);
    if (email == null) return 'Usuario';
    final users = jsonDecode(prefs.getString(_keyUsers) ?? '{}');
    return users[email]?['name'] ?? 'Usuario';
  }

  static Future<List<TransactionItem>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyCurrentSession);
    if (email == null) return [];

    final users = jsonDecode(prefs.getString(_keyUsers) ?? '{}');
    final list = users[email]?['transactions'] as List? ?? [];
    return list.map((item) => TransactionItem.fromMap(item)).toList();
  }

  static Future<void> saveTransactions(List<TransactionItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyCurrentSession);
    if (email == null) return;

    final users = jsonDecode(prefs.getString(_keyUsers) ?? '{}');
    users[email]['transactions'] = list.map((t) => t.toMap()).toList();
    await prefs.setString(_keyUsers, jsonEncode(users));
  }

  static Future<List<MandatoryBudget>> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyCurrentSession);
    if (email == null) return [];

    final users = jsonDecode(prefs.getString(_keyUsers) ?? '{}');
    final list = users[email]?['budgets'] as List? ?? [];
    return list.map((item) => MandatoryBudget.fromMap(item)).toList();
  }

  static Future<void> saveBudgets(List<MandatoryBudget> list) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyCurrentSession);
    if (email == null) return;

    final users = jsonDecode(prefs.getString(_keyUsers) ?? '{}');
    users[email]['budgets'] = list.map((b) => b.toMap()).toList();
    await prefs.setString(_keyUsers, jsonEncode(users));
  }
}

// ----------------------------------------------------
// MOTOR PROPIO DE IA FINANCIERA (OFFLINE NLP / REGLAS)
// ----------------------------------------------------
class CustomFinancialAi {
  static String processQuery({
    required String query,
    required List<TransactionItem> transactions,
    required List<MandatoryBudget> budgets,
  }) {
    final text = query.toLowerCase();
    final totalIncome = transactions.where((t) => t.isIncome).fold(0.0, (s, i) => s + i.amount);
    final totalExpense = transactions.where((t) => !t.isIncome).fold(0.0, (s, i) => s + i.amount);
    final balance = totalIncome - totalExpense;
    final totalMandatory = budgets.fold(0.0, (s, b) => s + b.monthlyEstimated);

    // Detección de intenciones y análisis de datos
    if (text.contains('presupuesto') || text.contains('50/30/20') || text.contains('plan')) {
      if (totalIncome == 0) {
        return 'Para estructurar tu presupuesto con la regla 50/30/20, primero añade tus ingresos del mes.';
      }
      final needs = totalIncome * 0.50;
      final wants = totalIncome * 0.30;
      final savings = totalIncome * 0.20;

      return '📊 **Plan 50/30/20 con tus ingresos (${totalIncome.toStringAsFixed(2)} €):**\n\n'
          '• **50% Gastos Fijos / Necesidades:** ${needs.toStringAsFixed(2)} € (Tienes comprometidos ${totalMandatory.toStringAsFixed(2)} € en tu presupuesto obligatorio).\n'
          '• **30% Gastos Personales / Ocio:** ${wants.toStringAsFixed(2)} €\n'
          '• **20% Ahorro e Inversión:** ${savings.toStringAsFixed(2)} €\n\n'
          '${totalMandatory > needs ? "⚠️ Alerta: Tus presupuestos obligatorios superan el 50% recomendado de tus ingresos." : "✅ Tus gastos fijos están dentro de un rango saludable."}';
    }

    if (text.contains('ahorrar') || text.contains('ahorro') || text.contains('reducir')) {
      if (balance <= 0) {
        return '⚠️ **Diagnóstico Urgente:** Tu balance actual está en déficit (${balance.toStringAsFixed(2)} €). Revisa los gastos discrecionales de ocio para recuperar liquidez inmediata.';
      }
      final potential = balance * 0.3;
      return '💡 **Plan de Ahorro Inteligente:**\n\n'
          '• Tu balance positivo actual es de **${balance.toStringAsFixed(2)} €**.\n'
          '• Te recomiendo apartar de forma automática **${potential.toStringAsFixed(2)} €** a principios de mes.\n'
          '• Tus gastos obligatorios configurados son **${totalMandatory.toStringAsFixed(2)} €/mes**. Tras cubrirlos, te queda un margen libre de **${(totalIncome - totalMandatory).clamp(0, double.infinity).toStringAsFixed(2)} €**.';
    }

    if (text.contains('gasto') || text.contains('categoría') || text.contains('en qué')) {
      final Map<String, double> catSums = {};
      for (var e in transactions.where((t) => !t.isIncome)) {
        catSums[e.category] = (catSums[e.category] ?? 0.0) + e.amount;
      }
      if (catSums.isEmpty) return 'No tienes gastos registrados para analizar categorías.';

      final sorted = catSums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;

      return '🔍 **Análisis de Categorías:**\n\n'
          'Tu mayor foco de gasto es **${top.key}** con **${top.value.toStringAsFixed(2)} €** (${totalExpense > 0 ? ((top.value / totalExpense) * 100).toStringAsFixed(1) : 0}% del gasto total).\n\n'
          'Total gastos acumulados: **${totalExpense.toStringAsFixed(2)} €**.';
    }

    if (text.contains('obligatorio') || text.contains('budget') || text.contains('fijo')) {
      if (budgets.isEmpty) {
        return 'Aún no has configurado presupuestos obligatorios. Pulsa el botón de presupuesto arriba a la derecha para añadir alquiler, comida o facturas.';
      }
      final list = budgets.map((b) => '• ${b.category}: ${b.amount.toStringAsFixed(2)} € (${b.frequency})').join('\n');
      return '📋 **Tus Presupuestos Obligatorios:**\n\n$list\n\n**Total estimado al mes:** ${totalMandatory.toStringAsFixed(2)} €.';
    }

    return '🤖 **Asistente Financiero:** He analizado tu cuenta. Tienes un balance neto de **${balance.toStringAsFixed(2)} €**, ${transactions.length} transacciones y **${totalMandatory.toStringAsFixed(2)} €/mes** en presupuestos obligatorios. Puedes preguntarme:\n- "¿Cómo estructurar mi presupuesto?"\n- "¿En qué estoy gastando más?"\n- "¿Cuánto puedo ahorrar este mes?"';
  }
}

// ----------------------------------------------------
// APLICACIÓN PRINCIPAL
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
      home: const AuthWrapper(),
    );
  }
}

// Control de Sesión
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final session = await StorageService.getCurrentSession();
    setState(() {
      _loggedIn = session != null;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loggedIn) {
      return MainNavigationShell(onLogout: () => setState(() => _loggedIn = false));
    }
    return AuthScreen(onAuthSuccess: () => setState(() => _loggedIn = true));
  }
}

// ----------------------------------------------------
// PANTALLA DE LOGIN / REGISTRO
// ----------------------------------------------------
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _error = '';

  void _submit() async {
    setState(() => _error = '');
    final email = _emailController.text.trim().toLowerCase();
    final pass = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || pass.isEmpty || (!_isLogin && name.isEmpty)) {
      setState(() => _error = 'Por favor, rellena todos los campos.');
      return;
    }

    if (_isLogin) {
      final success = await StorageService.loginUser(email, pass);
      if (success) {
        widget.onAuthSuccess();
      } else {
        setState(() => _error = 'Correo o contraseña incorrectos.');
      }
    } else {
      final success = await StorageService.registerUser(email, pass, name);
      if (success) {
        widget.onAuthSuccess();
      } else {
        setState(() => _error = 'Este correo ya está registrado.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161926),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wallet_rounded, size: 50, color: Color(0xFF6C5CE7)),
                const SizedBox(height: 10),
                Text(
                  _isLogin ? 'Bienvenido de nuevo' : 'Crear Cuenta',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin ? 'Inicia sesión para acceder a tus finanzas' : 'Regístrate para guardar tus datos en local',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ),
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: const Color(0xFF0D0F17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: const Color(0xFF0D0F17),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: const Color(0xFF0D0F17),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? '¿No tienes cuenta? Regístrate gratis' : '¿Ya tienes cuenta? Inicia sesión',
                    style: const TextStyle(color: Color(0xFF00CEC9)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SHELL PRINCIPAL CON NAVEGACIÓN Y PRESUPUESTO
// ----------------------------------------------------
class MainNavigationShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationShell({super.key, required this.onLogout});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  List<TransactionItem> _transactions = [];
  List<MandatoryBudget> _budgets = [];
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final tList = await StorageService.loadTransactions();
    final bList = await StorageService.loadBudgets();
    final name = await StorageService.getCurrentUserName();
    setState(() {
      _transactions = tList;
      _budgets = bList;
      _userName = name;
      _isLoading = false;
    });
  }

  void _addTransaction(TransactionItem item) async {
    final updated = [item, ..._transactions];
    await StorageService.saveTransactions(updated);
    setState(() => _transactions = updated);
  }

  void _deleteTransaction(String id) async {
    final updated = _transactions.where((t) => t.id != id).toList();
    await StorageService.saveTransactions(updated);
    setState(() => _transactions = updated);
  }

  void _saveBudgets(List<MandatoryBudget> list) async {
    await StorageService.saveBudgets(list);
    setState(() => _budgets = list);
  }

  void _openBudgetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161926),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => MandatoryBudgetModal(
        initialBudgets: _budgets,
        onSaveBudgets: _saveBudgets,
      ),
    );
  }

  void _openAddTransactionModal({DateTime? initialDate}) {
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
        userName: _userName,
        transactions: _transactions,
        budgets: _budgets,
        onDelete: _deleteTransaction,
        onAddRequested: () => _openAddTransactionModal(),
        onOpenBudget: _openBudgetModal,
        onOpenAi: () => setState(() => _currentIndex = 3),
        onLogout: () async {
          await StorageService.logout();
          widget.onLogout();
        },
      ),
      CalendarScreen(
        transactions: _transactions,
        onDelete: _deleteTransaction,
        onAddForDate: (date) => _openAddTransactionModal(initialDate: date),
      ),
      StatsScreen(transactions: _transactions, budgets: _budgets),
      AiChatScreen(transactions: _transactions, budgets: _budgets),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF161926),
        indicatorColor: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wallet_rounded), label: 'Billetera'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Gráficos'),
          NavigationDestination(icon: Icon(Icons.psychology_rounded), label: 'Mi IA'),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C5CE7),
              onPressed: () => _openAddTransactionModal(),
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
  final String userName;
  final List<TransactionItem> transactions;
  final List<MandatoryBudget> budgets;
  final Function(String) onDelete;
  final VoidCallback onAddRequested;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenAi;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.transactions,
    required this.budgets,
    required this.onDelete,
    required this.onAddRequested,
    required this.onOpenBudget,
    required this.onOpenAi,
    required this.onLogout,
  });

  double get _totalIncome => transactions.where((t) => t.isIncome).fold(0.0, (s, i) => s + i.amount);
  double get _totalExpense => transactions.where((t) => !t.isIncome).fold(0.0, (s, i) => s + i.amount);
  double get _totalBalance => _totalIncome - _totalExpense;
  double get _totalMandatory => budgets.fold(0.0, (s, b) => s + b.monthlyEstimated);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, $userName 👋', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Control Financiero', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00CEC9)),
            tooltip: 'Crear Presupuesto Obligatorio',
            onPressed: onOpenBudget,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Balance
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
            const SizedBox(height: 18),

            // Resumen de Presupuesto Obligatorio
            InkWell(
              onTap: onOpenBudget,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161926),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Color(0xFF00CEC9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gasto Obligatorio Mensual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '${_totalMandatory.toStringAsFixed(2)} €/mes (${budgets.length} categorías fijadas)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_note_rounded, color: Color(0xFF6C5CE7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

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
                  child: Text('No hay registros todavía. Pulsa en Nuevo.', style: TextStyle(color: Colors.grey)),
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
// MODAL PARA FIJAR PRESUPUESTO OBLIGATORIO (BUDGET)
// ----------------------------------------------------
class MandatoryBudgetModal extends StatefulWidget {
  final List<MandatoryBudget> initialBudgets;
  final Function(List<MandatoryBudget>) onSaveBudgets;

  const MandatoryBudgetModal({
    super.key,
    required this.initialBudgets,
    required this.onSaveBudgets,
  });

  @override
  State<MandatoryBudgetModal> createState() => _MandatoryBudgetModalState();
}

class _MandatoryBudgetModalState extends State<MandatoryBudgetModal> {
  late List<MandatoryBudget> _tempBudgets;
  String _selectedCategory = expenseCategories.first.name;
  String _selectedFrequency = 'mensual';
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempBudgets = List.from(widget.initialBudgets);
  }

  void _addOrUpdateBudget() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    setState(() {
      _tempBudgets.removeWhere((b) => b.category == _selectedCategory);
      _tempBudgets.add(
        MandatoryBudget(
          category: _selectedCategory,
          amount: amount,
          frequency: _selectedFrequency,
        ),
      );
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMonthly = _tempBudgets.fold(0.0, (s, b) => s + b.monthlyEstimated);

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
                const Text('Presupuesto Obligatorio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Text(
              'Define el gasto fijo que necesitas obligatoriamente en cada categoría.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),

            // Selector de Categoría
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                filled: true,
                fillColor: const Color(0xFF0D0F17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: expenseCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat.name,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 10),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Importe (€)',
                      filled: true,
                      fillColor: const Color(0xFF0D0F17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFrequency,
                    decoration: InputDecoration(
                      labelText: 'Frecuencia',
                      filled: true,
                      fillColor: const Color(0xFF0D0F17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'diario', child: Text('Diario')),
                      DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                      DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    ],
                    onChanged: (val) => setState(() => _selectedFrequency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00CEC9),
                  side: const BorderSide(color: Color(0xFF00CEC9)),
                ),
                onPressed: _addOrUpdateBudget,
                icon: const Icon(Icons.add),
                label: const Text('Fijar esta Categoría'),
              ),
            ),
            const Divider(height: 30, color: Colors.white10),

            const Text('Categorías Obligatorias Fijadas', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_tempBudgets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('No has fijado presupuestos obligatorios.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ..._tempBudgets.map((b) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${b.amount.toStringAsFixed(2)} € / ${b.frequency} (≈ ${b.monthlyEstimated.toStringAsFixed(0)} €/mes)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => setState(() => _tempBudgets.remove(b)),
                  ),
                );
              }),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0D0F17), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Gasto Fijo Estimado:'),
                  Text('${totalMonthly.toStringAsFixed(2)} €/mes', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00CEC9))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.onSaveBudgets(_tempBudgets);
                  Navigator.pop(context);
                },
                child: const Text('Guardar Presupuesto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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
                  Text(_periodTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    onPressed: () => _navigatePeriod(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
  final List<MandatoryBudget> budgets;

  const StatsScreen({super.key, required this.transactions, required this.budgets});

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
                      const Text('Tasa de Ahorro Real', style: TextStyle(fontSize: 14, color: Colors.white70)),
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

            const Text('Distribución de Gastos Reales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
// 4. CHAT CON LA IA PROPIA INTEGRADA
// ----------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiChatScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final List<MandatoryBudget> budgets;

  const AiChatScreen({super.key, required this.transactions, required this.budgets});

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
        text: '¡Hola! Soy tu asistente financiero inteligente integrado. Conozco tu balance actual, tus gastos registrados y tus presupuestos obligatorios. Pregúntame sobre cómo optimizar tus ahorros o planificar tu presupuesto.',
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
      _isTyping = true;
      _controller.clear();
    });

    // Procesamiento con el motor de IA local
    Future.delayed(const Duration(milliseconds: 600), () {
      final response = CustomFinancialAi.processQuery(
        query: userText,
        transactions: widget.transactions,
        budgets: widget.budgets,
      );

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        _isTyping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF00CEC9), size: 22),
            SizedBox(width: 8),
            Text('Mi IA Financiera', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
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
                  Text('Analizando tus métricas financieras...', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                      hintText: 'Pregúntame (ej. ¿En qué gasto más? o ¿Cómo ahorro?)...',
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
// MODAL DE AÑADIR REGISTRO
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
                separatorBuilder: (_, _) => const SizedBox(width: 8),
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