import "expenses_model.dart";
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'expenses_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'weekly_chart_screen.dart'; // make sure you import the chart screen


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpensesFromDB();
    _loadBudget();
  }

  Future<void> _loadExpensesFromDB() async {
    final expenses = await ExpensesDatabase.instance.getAllExpenses();
    setState(() {
      _expenses.clear();
      _expenses.addAll(expenses);
    });
  }

  double _budget= 0;
  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budget = prefs.getDouble('budget') ?? 5000;
    });
  }

  Future<void> _saveBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget', newBudget);
    setState(() {
      _budget = newBudget;
    });
  }

  void _addExpense(String title, double amount, String category) async {
    final newExpense = Expense(
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
    );

    await ExpensesDatabase.instance.insertExpense(newExpense);
    _loadExpensesFromDB();
  }


  void _deleteExpense(String id) async {
    await ExpensesDatabase.instance.deleteExpense(id);
    _loadExpensesFromDB();
  }


  double get _totalBalance {
    return _budget - _totalExpenses;
  }

  double get _totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  void _showBudgetDialog() {
    final budgetController = TextEditingController(text: _budget.toString());

    showDialog(context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Update Budget"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: budgetController,
                decoration: InputDecoration(
                    labelText: "Budget Amount",
                    prefixText: "₹ ",
                    border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 8,),
              Text("Current Budget: ₹ ${_budget.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: (){
              Navigator.of(context).pop();
            }, child: Text("Cancel")),
            ElevatedButton(onPressed: () {
              if(budgetController.text.isNotEmpty){
                setState(() {
                  _saveBudget(double.parse(budgetController.text));
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Budget updated successfully"),
                      duration: Duration(seconds: 2),
                    ));
              }
            },
                child: Text("Update")
            ),

          ],
        ));
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = "Food";

    showModalBottomSheet(context: context,
        isScrollControlled: true,
        builder: (BuildContext context) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("add Expense",style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16,),
              TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  )
              ),
              SizedBox(height: 16,),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16,),
              DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  items: ["Consumables",
                    "Food",
                    "Bills",
                    "College",
                    "Transport",
                    "Entertainment",
                    "Shopping",
                    "Other"
                  ].map(
                          (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      )
                  ).toList(),
                  onChanged: (value) {
                    selectedCategory = value!;
                  }
              ),
              SizedBox(height: 16,),
              ElevatedButton(
                onPressed: () {
                  if(titleController.text.isNotEmpty && amountController.text.isNotEmpty){
                    _addExpense(
                      titleController.text,
                      double.parse(amountController.text),
                      selectedCategory,);
                    Navigator.of(context).pop();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("Add Expense"),
                ),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    double spentPercentage = (_totalExpenses / _budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Color.fromRGBO(0, 0, 128, .1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isPortrait = constraints.maxHeight > constraints.maxWidth;

            Widget totalBalanceSection = Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Color.fromRGBO(0, 25, 128, 1)],
                  begin: Alignment.topLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 50, 110, 2),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Balance",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade300)),
                      IconButton(
                        onPressed: _showBudgetDialog,
                        icon: Icon(Icons.edit, color: Colors.grey.shade300),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Text("₹ ${_totalBalance.toStringAsFixed(2)}",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Budget ₹${_budget.toStringAsFixed(2)}",
                          style: TextStyle(color: Colors.white70)),
                      Text("${(spentPercentage * 100).toStringAsFixed(1)}% Spent",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: spentPercentage,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        spentPercentage > .9
                            ? Colors.redAccent
                            : spentPercentage > .7
                            ? Colors.orange
                            : Colors.greenAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              color: Colors.lightGreenAccent),
                          SizedBox(width: 8),
                          Text("Budget", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8),
                          Text("₹ ${_budget.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text("Expenses", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8),
                          Text("₹ ${_totalExpenses.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            Widget transactionList = _expenses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: Colors.grey.shade400, size: 65),
                  SizedBox(height: 16),
                  Text("No Expenses yet!",
                      style:
                      TextStyle(color: Colors.white38, fontSize: 18)),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense =
                _expenses[_expenses.length - 1 - index]; // reverse
                return Dismissible(
                  key: Key(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteExpense(expense.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Expense Deleted"),
                      duration: Duration(seconds: 2),
                    ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Card(
                        surfaceTintColor: Colors.transparent,
                        color: Color.fromRGBO(0, 120, 120, .1),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                              color: Color.fromRGBO(0, 100, 255, .5),
                              width: 1),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              color: Colors.black,
                              expense.category == "Food"
                                  ? Icons.fastfood
                                  : expense.category == "Bills"
                                  ? Icons.payment
                                  : expense.category == "College"
                                  ? Icons.school
                                  : expense.category == "Transport"
                                  ? Icons.directions_car
                                  : expense.category ==
                                  "Entertainment"
                                  ? Icons.movie
                                  : expense.category ==
                                  "Shopping"
                                  ? Icons.shopping_cart
                                  : expense.category ==
                                  "Other"
                                  ? Icons.more_horiz
                                  : Icons.receipt,
                            ),
                          ),
                          title: Text(expense.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8))),
                          subtitle: Text(
                              DateFormat("dd/MM/yyyy")
                                  .format(expense.date),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6))),
                          trailing: Text(
                              "₹ ${expense.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

            Widget transactionSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    "Recent Transactions",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54),
                  ),
                ),
                Expanded(child: transactionList),
              ],
            );

            return isPortrait
                ? Column(
              children: [
                totalBalanceSection,
                Expanded(child: transactionSection),
              ],
            )
                : Row(
              children: [
                Expanded(child: totalBalanceSection),
                Expanded(child: transactionSection),
              ],
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
        animatedIcon: AnimatedIcons.menu_close,
        overlayOpacity: 0.1,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Expense',
            backgroundColor: Colors.green,
            onTap: _showAddExpenseDialog,
          ),
          SpeedDialChild(
            child: Icon(Icons.bar_chart),
            label: 'View Chart',
            backgroundColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyChartScreen(expenses: _expenses),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
