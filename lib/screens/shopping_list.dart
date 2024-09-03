import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item.dart';
import 'package:shopping_list/widgets/shopping_list_item.dart';

import 'package:http/http.dart' as http;

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<GroceryItem> _groceryList = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-shopping-list-7d171-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Opps... Something went wrong. Try again later!';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final List<GroceryItem> tempItems = [];
      for (final item in data.entries) {
        final category = categories.entries.firstWhere((element) {
          return element.value.title == item.value['category'];
        }).value;
        tempItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        _groceryList = tempItems;
      });
    } catch (err) {
      setState(() {
        _error = '$err';
      });
    }
  }

  void _addItem() async {
    final item = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (item == null) {
      return;
    }
    setState(() {
      _groceryList.add(item);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryList.indexOf(item);
    final url = Uri.https(
      'flutter-shopping-list-7d171-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    setState(() {
      _groceryList.remove(item);
    });

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text(
              'Something went wrong. Item wasn\'t deleted. Try again later.'),
        ),
      );
      setState(() {
        _groceryList.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentContent = const Center(child: Text('No items added yet!'));

    if (_groceryList.isNotEmpty) {
      currentContent = ListView.builder(
        itemCount: _groceryList.length,
        itemBuilder: (ctx, index) {
          return Dismissible(
              onDismissed: (direction) {
                _removeItem(_groceryList[index]);
              },
              key: ValueKey(_groceryList[index].id),
              child: ShoppingListItem(groceryItem: _groceryList[index]));
        },
      );
    }

    if (_isLoading) {
      currentContent = const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_error != null) {
      currentContent = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: currentContent,
    );
  }
}
