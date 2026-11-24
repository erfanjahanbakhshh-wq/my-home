import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'config/app_config.dart';
import 'state/household_store.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HouseholdStore(),
      child: const HamkhanehApp(),
    ),
  );
}

const ink = Color(0xff26352f);
const green = Color(0xff557a60);
const cream = Color(0xfff7f4ec);
const orange = Color(0xffdf9856);

class HamkhanehApp extends StatelessWidget {
  const HamkhanehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هم‌خانه',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green, surface: cream),
        scaffoldBackgroundColor: cream,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const MainShell(),
    );
  }
}

String jdate(DateTime d) => Jalali.fromDateTime(d).toString();
String money(num n) => '${n.toStringAsFixed(0)} تومان';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    TasksPage(),
    ShoppingPage(),
    HousePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('هم‌خانه', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (AppConfig.demoMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Chip(
                  avatar: Icon(Icons.wifi_off, size: 16),
                  label: Text('نسخهٔ نمایشی'),
                ),
              ),
            ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'کارها',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            label: 'خرید',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'خانه‌ما',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'سلام، به خانه خوش آمدی 🌿',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ink,
              ),
        ),
        const SizedBox(height: 5),
        Text('${s.homeName}  •  ${jdate(now)}',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 18),
        if (AppConfig.demoMode)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffffefd9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('اطلاعات این نسخه فقط روی همین دستگاه نگهداری می‌شود.'),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.today,
                title: 'کارهای امروز',
                value: '${s.todayTasks} مورد',
                color: green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.payments_outlined,
                title: 'خرج ماه',
                value: money(s.monthlySpend),
                color: orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.weekend_outlined,
                title: 'کار باز',
                value: '${s.tasks.where((t) => !t.done).length} مورد',
                color: const Color(0xff7587a0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.people_alt_outlined,
                title: 'اعضای خانه',
                value: '${s.members.length} نفر',
                color: const Color(0xffa47786),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'کارهای پیش‌رو',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
          ),
        ),
        ...s.tasks.where((t) => !t.done).take(3).map((t) => TaskTile(task: t)),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String filter = 'همه';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();
    final list = s.tasks.where((t) {
      if (filter == 'باز') return !t.done;
      if (filter == 'انجام‌شده') return t.done;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const TaskDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('کار جدید'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'فهرست کارهای خانه',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
            ),
          ),
          Wrap(
            spacing: 8,
            children: ['همه', 'باز', 'انجام‌شده'].map((f) {
              return ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('کاری در این فهرست نیست'),
              ),
            ),
          ...list.map((t) => TaskTile(task: t)),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final HomeTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: CheckboxListTile(
        value: task.done,
        onChanged: (_) => context.read<HouseholdStore>().toggleTask(task),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('${task.assignee}  •  ${task.category}  •  ${jdate(task.due)}'),
        secondary: Icon(
          task.priority == 'بالا' ? Icons.priority_high : Icons.task_alt,
          color: task.priority == 'بالا' ? orange : green,
        ),
      ),
    );
  }
}

class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final notes = TextEditingController();
  DateTime due = DateTime.now();
  String assignee = 'من';
  String category = 'خانه';
  String priority = 'معمولی';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن کار'),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان کار'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'عنوان را وارد کنید' : null,
              ),
              TextFormField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)'),
              ),
              DropdownButtonFormField<String>(
                value: assignee,
                decoration: const InputDecoration(labelText: 'مسئول'),
                items: ['من', 'سارا', 'علی']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => assignee = v ?? 'من'),
              ),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                items: ['خانه', 'خرید', 'مالی', 'سایر']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? 'خانه'),
              ),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'اولویت'),
                items: ['معمولی', 'بالا', 'کم']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => setState(() => priority = v ?? 'معمولی'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('موعد: ${jdate(due)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: due,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (d != null) setState(() => due = d);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              context.read<HouseholdStore>().addTask(
                    HomeTask(
                      title: title.text.trim(),
                      notes: notes.text,
                      assignee: assignee,
                      due: due,
                      category: category,
                      priority: priority,
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('ثبت کار'),
        ),
      ],
    );
  }
}

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<HouseholdStore>();

    return Scaffold(
      backgroundColor: cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const ItemDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('افزودن قلم'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'خریدهای این ماه',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
            ),
          ),
          Card(
            elevation: 0,
            color: green,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.white),
              title: const Text('جمع خریدهای انجام‌شده',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                money(s.monthlySpend),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...s.items.map(
            (x) => Card(
              elevation: 0,
              child: CheckboxListTile(
                value: x.purchased,
                onChanged: (_) => s.toggleItem(x),
                title: Text(x.name),
                subtitle: Text(
                  '${x.quantity}  •  ${money(x.purchased ? x.actual : x.estimated)}${x.purchased ? ' (پرداخت‌شده)' : ''}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
        ],
      ),
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
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن به فهرست خرید'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام کالا'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'نام کالا را وارد کنید' : null,
            ),
            TextFormField(
              controller: qty,
              decoration: const InputDecoration(labelText: 'مقدار / تعداد'),
            ),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قیمت تخمینی (تومان)'),
              validator: (v) => double.tryParse(v ?? '') == null
                  ? 'قیمت معتبر وارد کنید'
                  : null,
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
            if (formKey.currentState!.validate()) {
              context.read<HouseholdStore>().addItem(
                    ShoppingItem(
                      name: name.text.trim(),
                      quantity: qty.text.trim(),
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
            title: Text(s.homeName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('مدیر خانه: من'),
          ),
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
              subtitle: const Text('عضو'),
              trailing: const Icon(Icons.verified_user_outlined),
            ),
          ),
        ),
      ],
    );
  }
}
