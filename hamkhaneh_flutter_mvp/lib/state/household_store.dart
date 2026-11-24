import 'package:flutter/foundation.dart';

class HomeTask {
  HomeTask({required this.title, this.notes = '', required this.assignee,
    required this.due, required this.category, this.priority = 'معمولی', this.done = false});
  final String title, notes, assignee, category, priority;
  final DateTime due;
  bool done;
}
class ShoppingItem {
  ShoppingItem({required this.name, required this.quantity, required this.estimated,
    this.actual = 0, this.purchased = false});
  final String name, quantity;
  final double estimated;
  double actual;
  bool purchased;
}
class HouseholdStore extends ChangeNotifier {
  final List<HomeTask> tasks = [
    HomeTask(title:'خرید نان و شیر',assignee:'سارا',due:DateTime.now(),category:'خرید'),
    HomeTask(title:'آبیاری گل‌ها',assignee:'علی',due:DateTime.now().add(const Duration(days:1)),category:'خانه'),
    HomeTask(title:'پرداخت قبض برق',assignee:'من',due:DateTime.now().add(const Duration(days:2)),category:'مالی',priority:'بالا'),
  ];
  final List<ShoppingItem> items = [
    ShoppingItem(name:'برنج',quantity:'۲ کیلو',estimated:180000),
    ShoppingItem(name:'ماست',quantity:'۱ عدد',estimated:65000,purchased:true,actual:65000),
  ];
  String homeName = 'خانهٔ ما';
  final List<String> members = ['من','سارا','علی'];
  void addTask(HomeTask task){tasks.insert(0,task);notifyListeners();}
  void toggleTask(HomeTask task){task.done=!task.done;notifyListeners();}
  void addItem(ShoppingItem item){items.insert(0,item);notifyListeners();}
  void toggleItem(ShoppingItem item){item.purchased=!item.purchased;if(item.purchased)item.actual=item.estimated;notifyListeners();}
  void setHome(String name,String? member){homeName=name;if(member!=null&&!members.contains(member))members.add(member);notifyListeners();}
  double get monthlySpend => items.where((e)=>e.purchased).fold(0,(a,e)=>a+e.actual);
  int get todayTasks => tasks.where((e)=>!e.done&&e.due.year==DateTime.now().year&&e.due.month==DateTime.now().month&&e.due.day==DateTime.now().day).length;
}
