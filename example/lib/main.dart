import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';

import 'package:cloud_firestore_rest/cloud_firestore_rest.dart';

void main() {
  GlobalConfiguration().loadFromMap({
    'projectId': 'flutter-shop-aec08',
    'webKey': 'AIzaSyDVGNPjOOMaa7kqgTKc4sy15ayVFkmpHHc',
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore REST Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firestore REST Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isInit = true;
  bool _isLoading = false;
  bool _isWrite = false;
  bool _isRead = false;
  bool _isUpdate = false;
  bool _isDelete = false;

  Map<String, dynamic> auth;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
        _isInit = false;
      });
      _register().then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        print(error);
      });
    }
    super.didChangeDependencies();
  }

  void operations() async {
    for (int i = 0; i < 10; i++) {
      await Firestore.add(
        collection: 'test',
        body: {'id': i, 'text': 'commment $i'},
      );
      setState(() {
        _counter++;
      });
    }
    setState(() {
      _isWrite = true;
      _counter = 0;
    });
    for (int i = 0; i < 10; i++) {
      await Firestore.getDocument(
        collection: 'test',
        id: i,
      );
      setState(() {
        _counter++;
      });
    }
    setState(() {
      _isRead = true;
      _counter = 0;
    });
    for (int i = 0; i < 10; i++) {
      await Firestore.delete(
        collection: 'test',
        id: i,
      );
      setState(() {
        _counter++;
      });
    }
    setState(() {
      _isDelete = true;
      _counter = 0;
    });
  }

  Future<void> _register() async {
    try {
      auth = await Firestore.signInOrSignUp(
          email: 'test12@test3.com',
          password: '123456',
          action: AuthAction.signInWithPassword);
    } catch (error) {
      try {
        auth = await Firestore.signInOrSignUp(
          email: 'test12@test3.com',
          password: '123456',
          action: AuthAction.signUp,
        );
      } catch (error) {
        print(error);
      }
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title + (auth == null ? 'Log in' : auth['email'])),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              child: Column(
                children: <Widget>[
                  if (auth != null) Text('You are logged in'),
                  if (_isWrite) Text('Write complete'),
                  if (_isRead) Text('Read complete'),
                  if (_isDelete) Text('Delete complete'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.edit),
        onPressed: () {
          operations();
        },
      ),
    );
  }
}
