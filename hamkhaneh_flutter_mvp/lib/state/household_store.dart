import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

import '../config/app_config.dart';
import '../services/task_reminder_service.dart';

class HomeTask {
  HomeTask({
    this.id = '',
    required this.title,
    this.notes = '',
    required this.assignee,
    this.assignedTo,
    required this.due,
    this.category = 'خانه',
    this.priority = 'معمولی',
    this.done = false,
    this.isWeekend = false,
  });

  final String id, title, notes, assignee, category, priority;
  final String? assignedTo;
  final DateTime due;
  bool done;
  final bool isWeekend;

  factory HomeTask.fromRecord(RecordModel record, {String currentUserId = ''}) {
    final data = record.data;
    final assignedTo = _relationId(data['assigned_to']);
    return HomeTask(
      id: record.id,
      title: _string(data['title']),
      assignee: assignedTo == null
          ? 'بدون مسئول'
          : (assignedTo == currentUserId ? 'من' : 'عضو خانوار'),
      assignedTo: assignedTo,
      due: DateTime.tryParse(_string(data['due_date'])) ?? DateTime.now(),
      done: data['is_completed'] == true,
      isWeekend: data['is_weekend'] == true ||
          (DateTime.tryParse(_string(data['due_date']))?.weekday == DateTime.thursday) ||
          (DateTime.tryParse(_string(data['due_date']))?.weekday == DateTime.friday),
    );
  }
}

class ShoppingItem {
  ShoppingItem({
    this.id = '',
    required this.name,
    required this.quantity,
    this.category = 'سایر',
    this.purchased = false,
    this.monthKey = '',
  });

  final String id, name, quantity, category, monthKey;
  bool purchased;

  factory ShoppingItem.fromRecord(RecordModel record) {
    final data = record.data;
    return ShoppingItem(
      id: record.id,
      name: _string(data['name']),
      quantity: _string(data['quantity']),
      category: _string(data['category'], fallback: 'سایر'),
      purchased: data['is_bought'] == true,
      monthKey: _string(data['month_key']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

String? _relationId(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  if (value is RecordModel) return value.id;
  if (value is Map) {
    final id = value['id'];
    return id is String && id.isNotEmpty ? id : null;
  }
  return null;
}

class HouseholdStore extends ChangeNotifier {
  HouseholdStore() : pb = PocketBase(AppConfig.pocketBaseUrl);

  final PocketBase pb;
  final List<HomeTask> tasks = [];
  final List<ShoppingItem> items = [];
  final List<String> members = [];

  String homeName = 'خانه من', homeId = '', inviteCode = '', displayName = '';
  String role = 'فرزند خونه';
  static const householdRoles = <String>['خانم خونه', 'آقای خونه', 'فرزند خونه'];
  String? avatarUrl;
  bool loading = false;
  String? error;
  bool get signedIn => pb.authStore.isValid;
  String get userId => pb.authStore.record?.id ?? '';

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      error = 'ایمیل و رمز عبور را وارد کنید';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      await pb.collection(AppConfig.usersCollection)
          .authWithPassword(normalizedEmail, password);
      await refresh();
    } catch (e) {
      error = 'ورود ناموفق بود: ${_message(e)}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String name, String email, String password, {String selectedRole = 'فرزند خونه'}) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty || normalizedEmail.isEmpty || password.length < 8) {
      error = 'نام، ایمیل و رمز عبور حداقل ۸ حرفی را وارد کنید';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      await pb.collection(AppConfig.usersCollection).create(body: {
        'name': normalizedName,
        'email': normalizedEmail,
        'password': password,
        'passwordConfirm': password,
        'emailVisibility': true,
        'role': householdRoles.contains(selectedRole) ? selectedRole : 'فرزند خونه',
      });
      await pb.collection(AppConfig.usersCollection)
          .authWithPassword(normalizedEmail, password);
      await refresh();
    } catch (e) {
      error = 'ثبت‌نام ناموفق بود: ${_message(e)}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void signOut() {
    pb.authStore.clear();
    tasks.clear();
    items.clear();
    TaskReminderService.instance.cancelAll();
    members.clear();
    homeId = '';
    homeName = 'خانه من';
    inviteCode = '';
    displayName = '';
    role = 'فرزند خونه';
    avatarUrl = null;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!signedIn) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final user = pb.authStore.record;
      displayName = _string(user?.data['name'], fallback: _string(user?.data['email']));
      final storedRole = _string(user?.data['role']);
      role = householdRoles.contains(storedRole) ? storedRole : 'فرزند خونه';
      final avatar = user?.data['avatar'];
      avatarUrl = avatar is String && avatar.isNotEmpty && user != null
          ? pb.files.getUrl(user, avatar).toString()
          : null;

      // Avoid relying on PocketBase-specific multi-relation filter syntax. Filter the
      // accessible house records client-side; API rules must limit records server-side.
      final rows = await pb.collection(AppConfig.housesCollection)
          .getFullList(expand: 'owner,members');
      final accessible = rows.where((house) =>
          _relationId(house.data['owner']) == userId ||
          _relationIds(house.data['members']).contains(userId)).toList();
      RecordModel? selected;
      for (final house in accessible) {
        if (house.id == homeId) { selected = house; break; }
      }
      selected ??= accessible.isEmpty ? null : accessible.first;
      if (selected == null) {
        homeId = '';
        homeName = 'خانه من';
        members
          ..clear()
          ..add(displayName.isEmpty ? 'من' : displayName);
        tasks.clear();
        items.clear();
      } else {
        homeId = selected.id;
        homeName = _string(selected.data['name'], fallback: 'خانه من');
        inviteCode = _string(selected.data['invite_code']);
        await _loadMembers(selected);
        await _loadData();
      }
      await TaskReminderService.instance.synchronize(tasks);
    } catch (e) {
      error = 'همگام‌سازی انجام نشد: ${_message(e)}';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMembers(RecordModel house) async {
    final ids = _relationIds(house.data['members']);
    final ownerId = _relationId(house.data['owner']);
    if (ids.isEmpty && ownerId != null) ids.add(ownerId);
    // PocketBase exposes expanded relations as a typed map of record lists.
    // Keep a nullable fallback for houses fetched without the requested expand.
    final List<RecordModel> expandedMembers =
        house.get<List<RecordModel>>('expand.members') ?? const <RecordModel>[];
    final namesById = <String, String>{};
    for (final RecordModel member in expandedMembers) {
      namesById[member.id] =
          _string(member.data['name'], fallback: 'عضو خانوار');
    }
    if (!namesById.containsKey(userId) && ids.contains(userId)) {
      namesById[userId] = displayName.isEmpty ? 'من' : displayName;
    }
    members
      ..clear()
      ..addAll(ids.map((id) => namesById[id] ?? (id == userId ? 'من' : 'عضو خانوار')));
  }

  Future<void> _loadData() async {
    if (homeId.isEmpty) return;
    final filter = 'house = "${_escapeFilter(homeId)}"';
    final itemRows = await pb.collection(AppConfig.shoppingCollection)
        .getFullList(filter: filter, sort: '-created');
    final currentMonth = monthKey(DateTime.now());
    items
      ..clear()
      ..addAll(itemRows.map(ShoppingItem.fromRecord)
          .where((item) => item.monthKey.isEmpty || item.monthKey == currentMonth));
    final taskRows = await pb.collection(AppConfig.tasksCollection)
        .getFullList(filter: filter, sort: 'due_date');
    tasks
      ..clear()
      ..addAll(taskRows.map((row) => HomeTask.fromRecord(row, currentUserId: userId)));
  }

  Future<void> createHome(String name) async {
    final value = name.trim();
    if (value.isEmpty || userId.isEmpty) return;
    try {
      final house = await pb.collection(AppConfig.housesCollection).create(body: {
        'name': value,
        'invite_code': _newInviteCode(),
        'owner': userId,
        'members': [userId],
      });
      homeId = house.id;
      homeName = value;
      await refresh();
    } catch (e) {
      error = 'ساخت خانه انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> joinHome(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty || userId.isEmpty) return;
    try {
      final house = await pb.collection(AppConfig.housesCollection).getFirstListItem(
        'invite_code = "${_escapeFilter(normalized)}"', expand: 'members',
      );
      final ids = _relationIds(house.data['members']);
      if (!ids.contains(userId)) ids.add(userId);
      await pb.collection(AppConfig.housesCollection).update(house.id, body: {'members': ids});
      homeId = house.id;
      await refresh();
    } catch (e) {
      error = 'پیوستن انجام نشد؛ کد معتبر نیست یا دسترسی تغییر اعضا مجاز نیست. ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> makeInvite() async {
    if (homeId.isEmpty) {
      error = 'ابتدا یک خانه بسازید یا انتخاب کنید.';
    } else {
      try {
        inviteCode = _newInviteCode();
        await pb.collection(AppConfig.housesCollection)
            .update(homeId, body: {'invite_code': inviteCode});
      } catch (e) {
        inviteCode = '';
        error = 'ساخت کد دعوت ممکن نشد: ${_message(e)}';
      }
    }
    notifyListeners();
  }

  Future<void> updateProfile(String name, [XFile? image]) async {
    try {
      final files = <http.MultipartFile>[];
      if (image != null) files.add(await http.MultipartFile.fromPath('avatar', image.path));
      await pb.collection(AppConfig.usersCollection).update(
        userId, body: {'name': name.trim(), 'role': householdRoles.contains(role) ? role : 'فرزند خونه'}, files: files,
      );
      await refresh();
    } catch (e) {
      error = 'ویرایش پروفایل انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> addTask(HomeTask task) async {
    if (homeId.isEmpty) return;
    try {
      final body = <String, dynamic>{
        'house': homeId,
        'title': task.title,
        'due_date': task.due.toIso8601String(),
        'is_completed': false,
        'is_weekend': task.isWeekend || task.due.weekday == DateTime.thursday || task.due.weekday == DateTime.friday,
      };
      if (task.assignedTo != null) body['assigned_to'] = task.assignedTo;
      final record = await pb.collection(AppConfig.tasksCollection).create(body: body);
      final createdTask = HomeTask(
        id: record.id,
        title: task.title,
        assignee: task.assignee,
        assignedTo: task.assignedTo,
        due: task.due,
        isWeekend: task.isWeekend || task.due.weekday == DateTime.thursday || task.due.weekday == DateTime.friday,
      );
      tasks.insert(0, createdTask);
      await TaskReminderService.instance.synchronize(tasks);
      notifyListeners();
    } catch (e) {
      error = 'ثبت کار انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> toggleTask(HomeTask task) async {
    if (task.id.isEmpty) return;
    final previous = task.done;
    task.done = !previous;
    try {
      await pb.collection(AppConfig.tasksCollection)
          .update(task.id, body: {'is_completed': task.done});
      await TaskReminderService.instance.synchronize(tasks);
      notifyListeners();
    } catch (e) {
      task.done = previous;
      error = 'تغییر وضعیت کار انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> addItem(ShoppingItem item) async {
    if (homeId.isEmpty) return;
    final month = monthKey(DateTime.now());
    try {
      final record = await pb.collection(AppConfig.shoppingCollection).create(body: {
        'house': homeId,
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category,
        'is_bought': false,
        'month_key': month,
      });
      items.insert(0, ShoppingItem(
        id: record.id,
        name: item.name,
        quantity: item.quantity,
        category: item.category,
        monthKey: month,
      ));
      notifyListeners();
    } catch (e) {
      error = 'ثبت قلم خرید انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  Future<void> toggleItem(ShoppingItem item) async {
    if (item.id.isEmpty) return;
    final previous = item.purchased;
    item.purchased = !previous;
    try {
      await pb.collection(AppConfig.shoppingCollection)
          .update(item.id, body: {'is_bought': item.purchased});
      notifyListeners();
    } catch (e) {
      item.purchased = previous;
      error = 'تغییر قلم خرید انجام نشد: ${_message(e)}';
      notifyListeners();
    }
  }

  int get purchasedItemCount => items.where((item) => item.purchased).length;
  int get todayTasks => tasks.where((task) =>
      !task.done && sameDay(task.due, DateTime.now())).length;

  String monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _escapeFilter(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');
}

List<String> _relationIds(Object? value) {
  if (value is String) return value.isEmpty ? <String>[] : <String>[value];
  if (value is! Iterable<Object?>) return <String>[];
  final ids = <String>[];
  for (final Object? relation in value) {
    final id = _relationId(relation);
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}
