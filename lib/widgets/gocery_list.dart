import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _isLoading = true;
  List<GroceryItem> _groceryItems = [];
  String? _errorMessage;

  void _loadItems() async {
    final url = Uri.https('flutter-course-2d772-default-rtdb.firebaseio.com',

        'shopping-list.json');
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _errorMessage = 'Error loading data!';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.name == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
          _errorMessage = 'something went wrong!';
        });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute<GroceryItem>(
        builder: (BuildContext context) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item) async {
    //no problem if the item was being deleted in the background but you need to remove it instantly from the ui that why we didn't use async and await here
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-course-2d772-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error!, try again later')));
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No data'),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder: (context, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 20,
              height: 20,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
        itemCount: _groceryItems.length,
      );
    }

    if (_errorMessage != null) {
      content = Center(
        child: Text(_errorMessage!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
