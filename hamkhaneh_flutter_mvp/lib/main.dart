import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:image_picker/image_picker.dart';
import 'state/household_store.dart';
import 'state/font_settings.dart';
import 'services/task_reminder_service.dart';
const ink = Color(0xff26352f);
const green = Color(0xff137c72);
const cream = Color(0xfffff8ee);
const orange = Color(0xfff28c45);
const coral = Color(0xffe45d4f);
const paleMint = Color(0xffe6f4ef);

Widget brandMark({double size = 72, double radius = 22}) => ClipRRect(
  borderRadius: BorderRadius.circular(radius),
  child: Image.asset('assets/branding/hamkhaneh_logo.png', width: size, height: size, fit: BoxFit.cover),
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TaskReminderService.instance.initialize();
  final fontSettings = FontSettings();
  await fontSettings.load();
  runApp(MultiProvider(providers:[
    ChangeNotifierProvider(create:(_)=>HouseholdStore()..refresh()),
    ChangeNotifierProvider.value(value:fontSettings),
  ],child:const App()));
}
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) {
    final fontFamily = c.watch<FontSettings>().family;
    return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'خونمون',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(
        primary: green, secondary: orange, tertiary: coral, surface: Colors.white,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: ink, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xffe8e1d5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: green, width: 1.5)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white, indicatorColor: paleMint, elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: orange, foregroundColor: Colors.white),
    ),
    builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
    home: Consumer<HouseholdStore>(builder: (c, s, _) => s.signedIn ? const Shell() : const AuthPage()),
  );
  }
}
String jd(DateTime d)=>Jalali.fromDateTime(d).toString();
class AuthPage extends StatefulWidget{const AuthPage({super.key});@override State<AuthPage> createState()=>_AuthState();}
class _AuthState extends State<AuthPage> {
  bool signup = false;
  final name = TextEditingController(), email = TextEditingController(), pass = TextEditingController();
  String selectedRole = 'فرزند خونه';
  @override
  Widget build(BuildContext c) {
    final s = context.watch<HouseholdStore>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: [Color(0xffe9f4ee), cream, Color(0xffffecd8)],
        )),
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(
            children: [
              brandMark(size: 112, radius: 30),
              const SizedBox(height: 16),
              const Text('خونمون', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 6),
              Text(signup ? 'یه خونهٔ گرم، باهم می‌سازیم' : 'کارهای خانه، باهم ساده‌تره',
                style: const TextStyle(fontSize: 16, color: Color(0xff61736b))),
              const SizedBox(height: 26),
              Card(elevation: 2, shadowColor: green.withValues(alpha: .10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
                  if (signup) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'نام شما', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: selectedRole, decoration: const InputDecoration(labelText: 'نقش شما در خونه'), items: HouseholdStore.householdRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(), onChanged: (value) { if (value != null) setState(() => selectedRole = value); }), const SizedBox(height: 12)],
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock_outline))),
                  if (s.error != null) Padding(padding: const EdgeInsets.all(10), child: Text(s.error!, style: const TextStyle(color: coral))),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
                    onPressed: s.loading ? null : () => signup ? s.signUp(name.text, email.text, pass.text, selectedRole: selectedRole) : s.signIn(email.text, pass.text),
                    icon: s.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(signup ? Icons.favorite_outline : Icons.login),
                    label: Text(signup ? 'ساخت حساب کاربری' : 'ورود به خونمون'),
                  )),
                  TextButton(onPressed: () => setState(() => signup = !signup), child: Text(signup ? 'حساب دارید؟ وارد شوید' : 'تازه اومدید؟ حساب بسازید')),
                ])),
              ),
              const SizedBox(height: 18),
              const Text('باهم، خونه رو قشنگ‌تر می‌کنیم ✨', style: TextStyle(color: Color(0xff7a8178))),
            ],
          )),
        )),
      ),
    );
  }
}
class Shell extends StatefulWidget{const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell> {
  int tab = 0;
  final pages = const [HomePage(), TasksPage(), WeekPage(), ShoppingPage(), ProfilePage()];
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(leadingWidth: 58, leading: Padding(padding: const EdgeInsets.all(8), child: brandMark(size: 42, radius: 12)),
      title: const Text('خونمون', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [IconButton(onPressed: () => context.read<HouseholdStore>().refresh(), icon: const Icon(Icons.sync), tooltip: 'همگام‌سازی')]),
    body: pages[tab],
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
      NavigationDestination(icon: Icon(Icons.checklist), label: 'کارها'),
      NavigationDestination(icon: Icon(Icons.calendar_view_week), label: 'تقویم هفتگی'),
      NavigationDestination(icon: Icon(Icons.shopping_basket_outlined), label: 'خریدها'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'پروفایل'),
    ]),
  );
}
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<HouseholdStore>();
    final pending = s.tasks.where((t) => !t.done).take(5).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [green, Color(0xff0c625e)]),
        borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: green.withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 8))],
      ), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سلام و خوش اومدی 👋', style: TextStyle(color: Color(0xffd9f2e9), fontSize: 14)),
          const SizedBox(height: 7),
          Text(s.displayName.isEmpty ? 'خونمون' : s.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 9),
          Text('${s.homeName}  •  ${jd(DateTime.now())}', style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(30)),
            child: const Text('خونهٔ مرتب، حالِ بهتر ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ])),
        const SizedBox(width: 12), brandMark(size: 82, radius: 22),
      ])),
      const SizedBox(height: 18),
      Row(children: [Stat('کارهای امروز', '${s.todayTasks}', Icons.today_rounded, green), const SizedBox(width: 10), Stat('خریدهای ماه', '${s.purchasedItemCount} قلم', Icons.shopping_basket_rounded, orange)]),
      const SizedBox(height: 22),
      Row(children: [const Expanded(child: Text('کارهای پیش‌رو', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink))),
        if (pending.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: paleMint, borderRadius: BorderRadius.circular(20)),
          child: Text('${pending.length} مورد', style: const TextStyle(color: green, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 8),
      if (pending.isEmpty) Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: const Padding(padding: EdgeInsets.all(20), child: Row(children: [Icon(Icons.celebration_rounded, color: orange, size: 30), SizedBox(width: 12), Expanded(child: Text('همه‌چیز مرتبه! فعلاً کاری باقی نمونده.', style: TextStyle(fontWeight: FontWeight.w600)))])))
      else ...pending.map((t) => TaskTile(t)),
    ]);
  }
}
class Stat extends StatelessWidget{const Stat(this.a,this.b,this.i,this.color,{super.key});final String a,b;final IconData i;final Color color;@override Widget build(BuildContext c)=>Expanded(child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:color),Text(a),Text(b,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))]))));}
class TasksPage extends StatefulWidget{const TasksPage({super.key});@override State<TasksPage> createState()=>_TasksState();}class _TasksState extends State<TasksPage>{String f='همه';@override Widget build(BuildContext c){final s=c.watch<HouseholdStore>();final list=s.tasks.where((t)=>f=='همه'||(f=='باز'&&!t.done)||(f=='انجام‌شده'&&t.done)).toList();return Scaffold(backgroundColor:cream,floatingActionButton:FloatingActionButton(onPressed:()=>showDialog(context:c,builder:(_)=>const TaskDialog()),child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('کارهای خانه',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),Wrap(spacing:8,children:['همه','باز','انجام‌شده'].map((x)=>ChoiceChip(label:Text(x),selected:f==x,onSelected:(_)=>setState(()=>f=x))).toList()),...list.map((task) => TaskTile(task))]));}}
class TaskTile extends StatelessWidget{const TaskTile(this.t,{super.key});final HomeTask t;@override Widget build(BuildContext c)=>Card(child:CheckboxListTile(value:t.done,onChanged:(_)=>c.read<HouseholdStore>().toggleTask(t),title:Text(t.title,style:TextStyle(decoration:t.done?TextDecoration.lineThrough:null)),subtitle:Text('${t.assignee} • ${jd(t.due)}${(t.isWeekend || t.due.weekday == DateTime.thursday || t.due.weekday == DateTime.friday)?' • آخر هفته':''}'),controlAffinity:ListTileControlAffinity.leading));}
class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key});
  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final title = TextEditingController();
  DateTime due = DateTime.now();
  bool weekend = false;

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('کار جدید'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان کار')),
      ListTile(
        title: Text('موعد: ${jd(due)}'),
        onTap: () async {
          final selected = await showDatePicker(
            context: c,
            initialDate: due,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 1000)),
          );
          if (selected != null) {
            setState(() {
              if (weekend) {
                final offset = [(4 - selected.weekday + 7) % 7, (5 - selected.weekday + 7) % 7]
                    .reduce((a, b) => a < b ? a : b);
                due = DateTime(selected.year, selected.month, selected.day).add(Duration(days: offset));
              } else {
                due = selected;
              }
            });
          }
        },
      ),
      SwitchListTile(
        value: weekend,
        onChanged: (value) => setState(() {
          weekend = value;
          if (value) {
            final daysUntilWeekend = [(4 - due.weekday + 7) % 7, (5 - due.weekday + 7) % 7]
                .reduce((a, b) => a < b ? a : b);
            due = DateTime(due.year, due.month, due.day).add(Duration(days: daysUntilWeekend));
          }
        }),
        title: const Text('کار آخر هفته (پنجشنبه/جمعه)'),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('لغو')),
      FilledButton(
        onPressed: () {
          if (title.text.trim().isNotEmpty) {
            final store = c.read<HouseholdStore>();
            store.addTask(HomeTask(
              title: title.text.trim(),
              assignee: 'من',
              assignedTo: store.userId,
              due: due,
              isWeekend: weekend,
            ));
            Navigator.pop(c);
          }
        },
        child: const Text('ثبت'),
      ),
    ],
  );
}

class WeekPage extends StatelessWidget {
  const WeekPage({super.key});
  @override
  Widget build(BuildContext c) {
    final store = c.watch<HouseholdStore>();
    final start = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('تقویم هفتگی', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      ...List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        final dayTasks = store.tasks.where((task) => store.sameDay(task.due, day)).toList();
        return Card(child: ExpansionTile(
          title: Text('${jd(day)}${(day.weekday == DateTime.thursday || day.weekday == DateTime.friday) ? ' • آخر هفته' : ''}'),
          children: dayTasks.isEmpty
              ? [const ListTile(title: Text('کاری ثبت نشده'))]
              : dayTasks.map((task) => TaskTile(task)).toList(),
        ));
      }),
    ]);
  }
}

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});
  @override
  Widget build(BuildContext c) {
    final store = c.watch<HouseholdStore>();
    return Scaffold(
      backgroundColor: cream,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(context: c, builder: (_) => const ItemDialog()),
        child: const Icon(Icons.add),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('خریدها', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        Card(color: green, child: ListTile(
          title: const Text('اقلام خریداری‌شده در این ماه', style: TextStyle(color: Colors.white)),
          subtitle: Text('${store.purchasedItemCount} قلم خریداری‌شده', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        )),
        ...store.items.map((item) => Card(child: CheckboxListTile(
          value: item.purchased,
          onChanged: (_) => store.toggleItem(item),
          title: Text(item.name),
          subtitle: Text('${item.quantity} • ${item.category}'),
          controlAffinity: ListTileControlAffinity.leading,
        ))),
      ]),
    );
  }
}

class ItemDialog extends StatefulWidget {
  const ItemDialog({super.key});
  @override
  State<ItemDialog> createState() => _ItemState();
}

class _ItemState extends State<ItemDialog> {
  final n = TextEditingController();
  final q = TextEditingController(text: '۱ عدد');
  final category = TextEditingController(text: 'سایر');
  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('افزودن قلم خرید'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')),
      TextField(controller: q, decoration: const InputDecoration(labelText: 'مقدار')),
      TextField(controller: category, decoration: const InputDecoration(labelText: 'دسته‌بندی')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('لغو')),
      FilledButton(onPressed: () {
        if (n.text.trim().isNotEmpty) {
          c.read<HouseholdStore>().addItem(ShoppingItem(
            name: n.text.trim(),
            quantity: q.text.trim(),
            category: category.text.trim().isEmpty ? 'سایر' : category.text.trim(),
          ));
          Navigator.pop(c);
        }
      }, child: const Text('ثبت')),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<HouseholdStore>();
    final font = c.watch<FontSettings>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: CircleAvatar(radius: 42, backgroundImage: s.avatarUrl == null ? null : NetworkImage(s.avatarUrl!), child: s.avatarUrl == null ? const Icon(Icons.person, size: 42) : null)),
      Center(child: Text(s.displayName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
      Center(child: Chip(avatar: const Icon(Icons.family_restroom, size: 18), label: Text(s.role))),
      FilledButton.icon(onPressed: () => showDialog(context: c, builder: (_) => const ProfileDialog()), icon: const Icon(Icons.edit), label: const Text('ویرایش پروفایل')),
      const Divider(),
      const Text('نمایش و فونت', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Card(child: ListTile(
        leading: const Icon(Icons.text_fields),
        title: const Text('فونت برنامه'),
        subtitle: Text('${font.selected.title} — ${font.selected.description}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showDialog<void>(context: c, builder: (_) => const FontChooserDialog()),
      )),
      const Divider(),
      const Text('مدیریت خانه', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ListTile(title: Text(s.homeName), subtitle: Text('${s.members.length} عضو'), leading: const Icon(Icons.home)),
      ...s.members.map((m) => ListTile(dense: true, leading: const Icon(Icons.person_outline), title: Text(m))),
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: () => showDialog(context: c, builder: (_) => const HouseDialog()), icon: const Icon(Icons.add_home), label: const Text('ساخت خانه'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () => showDialog(context: c, builder: (_) => const JoinDialog()), icon: const Icon(Icons.key), label: const Text('پیوستن'))),
      ]),
      OutlinedButton.icon(onPressed: () async { await s.makeInvite(); if (c.mounted && s.inviteCode.isNotEmpty) showDialog(context: c, builder: (_) => AlertDialog(title: const Text('کد دعوت'), content: SelectableText(s.inviteCode))); }, icon: const Icon(Icons.share), label: const Text('ساخت کد دعوت')),
      TextButton.icon(onPressed: s.signOut, icon: const Icon(Icons.logout), label: const Text('خروج')),
    ]);
  }
}

class FontChooserDialog extends StatelessWidget {
  const FontChooserDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<FontSettings>();
    return AlertDialog(
      title: const Text('انتخاب فونت'),
      content: RadioGroup<String>(
        groupValue: settings.family,
        onChanged: (value) { if (value != null) settings.select(value); },
        child: Column(mainAxisSize: MainAxisSize.min, children: FontSettings.options.map((option) => RadioListTile<String>(
          value: option.id,
          title: Text(option.title, style: TextStyle(fontFamily: option.id)),
          subtitle: Text(option.description, style: TextStyle(fontFamily: option.id)),
        )).toList()),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
    );
  }
}
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});
  @override
  State<ProfileDialog> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileDialog> {
  final n = TextEditingController();
  XFile? image;
  late String selectedRole;
  bool initialized = false;

  @override
  Widget build(BuildContext c) {
    final store = c.read<HouseholdStore>();
    if (!initialized) {
      n.text = store.displayName;
      selectedRole = store.role;
      initialized = true;
    }
    return AlertDialog(
      title: const Text('ویرایش پروفایل'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: 'نام')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selectedRole,
          decoration: const InputDecoration(labelText: 'نقش در خونه'),
          items: HouseholdStore.householdRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
          onChanged: (value) { if (value != null) setState(() => selectedRole = value); },
        ),
        TextButton.icon(
          onPressed: () async {
            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (picked != null) setState(() => image = picked);
          },
          icon: const Icon(Icons.image),
          label: Text(image == null ? 'انتخاب تصویر' : 'تصویر انتخاب شد'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('لغو')),
        FilledButton(onPressed: () async {
          store.role = selectedRole;
          await store.updateProfile(n.text, image);
          if (c.mounted) Navigator.pop(c);
        }, child: const Text('ذخیره')),
      ],
    );
  }
}

class HouseDialog extends StatefulWidget {
  const HouseDialog({super.key});
  @override
  State<HouseDialog> createState() => _HouseState();
}

class _HouseState extends State<HouseDialog> {
  final n = TextEditingController();
  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('ساخت خانه'),
    content: TextField(controller: n, decoration: const InputDecoration(labelText: 'نام خانه')),
    actions: [FilledButton(onPressed: () {
      if (n.text.isNotEmpty) {
        c.read<HouseholdStore>().createHome(n.text);
        Navigator.pop(c);
      }
    }, child: const Text('ساخت'))],
  );
}

class JoinDialog extends StatefulWidget {
  const JoinDialog({super.key});
  @override
  State<JoinDialog> createState() => _JoinState();
}

class _JoinState extends State<JoinDialog> {
  final code = TextEditingController();
  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('پیوستن به خانه'),
    content: TextField(controller: code, decoration: const InputDecoration(labelText: 'کد دعوت')),
    actions: [FilledButton(onPressed: () {
      c.read<HouseholdStore>().joinHome(code.text);
      Navigator.pop(c);
    }, child: const Text('پیوستن'))],
  );
}
