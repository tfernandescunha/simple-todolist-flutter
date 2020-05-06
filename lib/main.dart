import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  return runApp(new TodoList());
}

class TodoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  final TextEditingController titleTodo = TextEditingController();

  @override
  void initState() {
    super.initState();

    this._readData().then((data) {
      setState(() {
        this._todoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    if (titleTodo.text.isNotEmpty) {
      setState(() {
        Map<String, dynamic> newTodo = Map();
        newTodo["title"] = titleTodo.text;
        newTodo["ok"] = false;
        titleTodo.clear();

        _todoList.add(newTodo);

        _saveData();
      });
    }
  }

  void _checkTodo(index, checked) {
    setState(() {
      this._todoList[index]["ok"] = checked;
      _saveData();
    });
  }

  void _removeTodo(index) {
    setState(() {
      this._lastRemoved = Map.from(_todoList[index]);
      this._lastRemovedPos = index;
      this._todoList.removeAt(index);
    });
    this._saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Flutter ToDo List"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 10.0, 17.0, 17.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: this.titleTodo,
                          decoration: InputDecoration(
                              labelText: 'Nova Tarefa',
                              labelStyle: TextStyle(color: Colors.blueAccent)),
                        ),
                      ),
                      RaisedButton(
                        color: Colors.blueAccent,
                        child: Text('ADD'),
                        textColor: Colors.white,
                        onPressed: this._addTodo,
                      )
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
              onRefresh: this.refresh,
              child: ListView.builder(
                padding: EdgeInsets.all(0),
                itemCount: _todoList.length,
                itemBuilder: this.buildDismissibleItem,
              ),
            ))
          ],
        ));
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      this._todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });

      this._saveData();
    });

    return null;
  }

  Widget buildDismissibleItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (checked) {
          this._checkTodo(index, checked);
        },
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error)),
      ),
      onDismissed: (direction) {
        this._removeTodo(index);
        final snack = SnackBar(
          content: Text('Tarefa ${this._lastRemoved["title"]} removida com sucesso!'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                this._todoList.insert(this._lastRemovedPos, this._lastRemoved);
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 5),
        );
        Scaffold.of(context).removeCurrentSnackBar();

        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
