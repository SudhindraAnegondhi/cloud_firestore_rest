import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';

import 'package:cloud_firestore_rest/cloud_firestore_rest.dart';

void main() {
  ///
  /// Configure your Firebase Firestore settings here
  ///
  GlobalConfiguration().loadFromMap({
    'projectId': 'flutter-shop-aec08',
    'webKey': 'AIzaSyDVGNPjOOMaa7kqgTKc4sy15ayVFkmpHHc',
  });
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Cloud Firestore REST API Example',
      home: TodoList(),
    );
  }
}

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  bool _isInit = true;
  bool _isBusy = false;
  List<Map<String, dynamic>> _todoItems = [];

  Future<void> _addTodoItem() async {
    try {
      setState(() {
        _isBusy = true;
      });
      final item = await Firestore.add(collection: 'todo', body: {
        'text': 'Item #${_todoItems.length}',
      });

      setState(() {
        _todoItems.add(item);
        _isBusy = false;
      });
    } catch (error) {
      throw error;
    }
  }

  Future<void> _update({
    Map<String, dynamic> item,
    bool delete = false,
  }) async {
    try {
      setState(() {
        _isBusy = true;
      });
      if (delete) {
        await Firestore.delete(
          collection: 'todo',
          id: item['id'],
        );
        _todoItems.removeWhere((_item) => _item['id'] == item['id']);
      } else {
        await Firestore.setAll(
          collection: 'todo',
          id: item['id'],
          body: item,
        );
      }
    } catch (error) {
      print(error);
    }
    setState(() {
      _isBusy = false;
    });
  }

  Widget _buildTodoList() {
    return ListView.builder(
      itemBuilder: (context, index) {
        if (index < _todoItems.length) {
          return _buildTodoItem(_todoItems[index]);
        }
        return null;
      },
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> item) {
    return ListTile(
      title: Text(item['text']),
      onTap: () async {
        if (item['text'].contains('Done')) {
          await _update(item: item, delete: true);
        } else {
          item['text'] += ' Done';
          await _update(item: item);
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getTodos() async {
    final items = await Firestore.get(
      collection: 'todo',
      sortField: 'text',
    );
    return items;
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isBusy = true;
      _getTodos().then((items) {
        _todoItems = items;
      }).catchError((error) {
        print(error);
      }).whenComplete(() {
        setState(() {
          _isInit = false;
          _isBusy = false;
        });
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Text('Cloud Firestore REST API Example'),
            if (_isBusy)
              Container(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
          ],
        ),
      ),
      body: _buildTodoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoItem,
        tooltip: 'Add task',
        child: Icon(Icons.add),
      ),
    );
  }
}
