import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'state/household_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HouseholdStore()),
      ],
      child: const HamkhanehApp(),
    ),
  );
}

class HamkhanehApp extends StatelessWidget {
  const HamkhanehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        fontFamily: 'Vazirmatn',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    ShoppingListPage(),
    TasksPage(),
    ExpensesPage(),
    HousePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'خریدها',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'وظایف',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'هزینه‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
        ],
      ),
    );
  }
}

class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    return Scaffold(
      body: s.items.isEmpty
          ? const Center(child: Text('فهرست خرید خالی است.'))
          : ListView.builder(
              itemCount: s.items.length,
              itemBuilder: (ctx, idx) {
                final item = s.items[idx];
                return CheckboxListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('تعداد: ${item.quantity} | قیمت تخمینی: ${item.estimated.toStringAsFixed(0)} تومان'),
                  value: item.isDone,
                  onChanged: (_) => s.toggleItem(idx),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const ItemDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    return Scaffold(
      body: s.tasks.isEmpty
          ? const Center(child: Text('وظیفه‌ای تعریف نشده است.'))
          : ListView.builder(
              itemCount: s.tasks.length,
              itemBuilder: (ctx, idx) {
                final task = s.tasks[idx];
                return CheckboxListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('مسئول: ${task.assignee}'),
                  value: task.isDone,
                  onChanged: (_) => s.toggleTask(idx),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const TaskDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مجموع هزینه‌ها:', style: TextStyle(fontSize: 16)),
                  Text(
                    '${s.totalExpenses.toStringAsFixed(0)} تومان',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: s.expenses.isEmpty
                ? const Center(child: Text('هزینه‌ای ثبت نشده است.'))
                : ListView.builder(
                    itemCount: s.expenses.length,
                    itemBuilder: (ctx, idx) {
                      final exp = s.expenses[idx];
                      return ListTile(
                        title: Text(exp.title),
                        subtitle: Text('پرداخت‌کننده: ${exp.payer}'),
                        trailing: Text('${exp.amount.toStringAsFixed(0)} تومان'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const ExpenseDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HousePage extends StatelessWidget {
  const HousePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'خانه و اعضا',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.home)),
            title: Text(s.homeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('مدیر خانه: من'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const HomeDialog(join: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const HomeDialog(join: false),
                ),
                icon: const Icon(Icons.add_home),
                label: const Text('ساخت خانه'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const HomeDialog(join: true),
                ),
                icon: const Icon(Icons.vpn_key),
                label: const Text('پیوستن'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'اعضای خانه',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...s.members.map(
          (m) => Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xffe2ece2),
                child: Text(m.isNotEmpty ? m.substring(0, 1) : '?'),
              ),
              title: Text(m),
              subtitle: Text(m == 'من' ? 'مدیر' : 'عضو'),
              trailing: const Icon(Icons.verified_user_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('حالت محلی / نمایشی'),
            subtitle: Text('اطلاعات فقط تا زمان بسته‌شدن برنامه نگهداری می‌شود.'),
          ),
        ),
      ],
    );
  }
}

class ItemDialog extends StatefulWidget {
  const ItemDialog({super.key});

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  final name = TextEditingController();
  final qty = TextEditingController(text: '۱ عدد');
  final price = TextEditingController();
  final keyForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن به فهرست خرید'),
      content: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام کالا'),
              validator: (v) => v == null || v.isEmpty ? 'نام کالا را وارد کنید' : null,
            ),
            TextFormField(
              controller: qty,
              decoration: const InputDecoration(labelText: 'مقدار / تعداد'),
            ),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قیمت تخمینی (تومان)'),
              validator: (v) => double.tryParse(v ?? '') == null ? 'قیمت معتبر وارد کنید' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        FilledButton(
          onPressed: () {
            if (keyForm.currentState!.validate()) {
              context.read<HouseholdStore>().addItem(
                    ShoppingItem(
                      name: name.text,
                      quantity: qty.text,
                      estimated: double.parse(price.text),
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final title = TextEditingController();
  final assignee = TextEditingController(text: 'من');
  final keyForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن وظیفه جدید'),
      content: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'عنوان وظیفه'),
              validator: (v) => v == null || v.isEmpty ? 'عنوان را وارد کنید' : null,
            ),
            TextFormField(
              controller: assignee,
              decoration: const InputDecoration(labelText: 'مسئول انجام'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        FilledButton(
          onPressed: () {
            if (keyForm.currentState!.validate()) {
              context.read<HouseholdStore>().addTask(
                    HomeTask(
                      title: title.text,
                      assignee: assignee.text,
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

class ExpenseDialog extends StatefulWidget {
  const ExpenseDialog({super.key});

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final title = TextEditingController();
  final amount = TextEditingController();
  final payer = TextEditingController(text: 'من');
  final keyForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ثبت هزینه جدید'),
      content: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'بابت چه چیزی؟'),
              validator: (v) => v == null || v.isEmpty ? 'عنوان هزینه را وارد کنید' : null,
            ),
            TextFormField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'مبلغ (تومان)'),
              validator: (v) => double.tryParse(v ?? '') == null ? 'مبلغ معتبر وارد کنید' : null,
            ),
            TextFormField(
              controller: payer,
              decoration: const InputDecoration(labelText: 'پرداخت‌کننده'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        FilledButton(
          onPressed: () {
            if (keyForm.currentState!.validate()) {
              context.read<HouseholdStore>().addExpense(
                    HomeExpense(
                      title: title.text,
                      amount: double.parse(amount.text),
                      payer: payer.text,
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('ثبت'),
        ),
      ],
    );
  }
}

class HomeDialog extends StatefulWidget {
  final bool join;
  const HomeDialog({super.key, required this.join});

  @override
  State<HomeDialog> createState() => _HomeDialogState();
}

class _HomeDialogState extends State<HomeDialog> {
  final name = TextEditingController();
  final code = TextEditingController();
  final keyForm = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.join ? 'پیوستن با کد دعوت' : 'ساخت خانه'),
      content: Form(
        key: keyForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.join)
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'نام خانه'),
                validator: (v) => v == null || v.isEmpty ? 'نام را وارد کنید' : null,
              ),
            if (widget.join)
              TextFormField(
                controller: code,
                decoration: const InputDecoration(labelText: 'کد دعوت'),
                validator: (v) => v == null || v.isEmpty ? 'کد را وارد کنید' : null,
              ),
            if (widget.join)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('در حالت نمایشی هر کدی پذیرفته می‌شود؛ عضویت واقعی نیازمند اتصال به سرور است.'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        FilledButton(
          onPressed: () {
            if (keyForm.currentState!.validate()) {
              final s = context.read<HouseholdStore>();
              if (widget.join) {
                s.setHome(s.homeName, 'عضو جدید');
              } else {
                s.setHome(name.text.trim(), null);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.join ? 'به خانه پیوستید' : 'خانه ساخته شد')),
              );
            }
          },
          child: Text(widget.join ? 'پیوستن' : 'ساخت خانه'),
        ),
      ],
    );
  }
}
