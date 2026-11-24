import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'config/app_config.dart';
import 'state/household_store.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => HouseholdStore(),
        child: const HamkhanehApp(),
      ),
    );

const ink = Color(0xff26352f),
    green = Color(0xff557a60),
    cream = Color(0xfff7f4ec),
    orange = Color(0xffdf9856);

class HamkhanehApp extends StatelessWidget {
  const HamkhanehApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
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

String jdate(DateTime d) => Jalali.fromDateTime(d).toString();
String money(num n) => '${n.toStringAsFixed(0)} تومان';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final pages = const [
    DashboardPage(),
    TasksPage(),
    ShoppingPage(),
    HousePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('هم‌خانه',
              style: TextStyle(fontWeight: FontWeight.w800)),
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
                label: 'خانه'),
            NavigationDestination(
                icon: Icon(Icons.checklist), label: 'کارها'),
            NavigationDestination(
                icon: Icon(Icons.shopping_basket_outlined), label: 'خرید'),
            NavigationDestination(
                icon: Icon(Icons.people_outline), label: 'خانه‌ما'),
          ],
        ),
      );
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
        Text('سلام، به خانه خوش آمدی 🌿',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: ink)),
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
            child: const Text(
                'اطلاعات این نسخه فقط روی همین دستگاه و در حافظهٔ موقت نگهداری می‌شود.'),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: StatCard(
                  icon: Icons.today,
                  title: 'کارهای امروز',
                  value: '${s.todayTasks} مورد',
                  color: green)),
          const SizedBox(width: 10),
          Expanded(
              child: StatCard(
                  icon: Icons.payments_outlined,
                  title: 'خرج ماه',
                  value: money(s.monthlySpend),
                  color: orange)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: StatCard(
                  icon: Icons.weekend_outlined,
                  title: 'کار باز',
                  value: '${s.tasks.where((t) => !t.done).length} مورد',
                  color: const Color(0xff7587a0))),
          const SizedBox(width: 10),
          Expanded(
              child: StatCard(
                  icon: Icons.people_alt_outlined,
                  title: 'اعضای خانه',
                  value: '${s.members.length} نفر',
                  color: const Color(0xffa47786))),
        ]),
        const SizedBox(height: 20),
        const SectionTitle('کارهای پیش‌رو'),
        ...s.tasks.where((t) => !t.done).take(3).map((t) => TaskTile(task: t)),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.value,
      required this.color});
  final IconData icon;
  final String title, value;
  final Color color;
  @override
  Widget build(BuildContext c) => Card(
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
                const 
