import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Firestore database = Firestore.instance;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State {
  @override
  Widget build(BuildContext context) {
    String name;
    return Scaffold(
      appBar: AppBar(title: Text('Baby Name Votes')),
      body: Column(
        children: <Widget>[
          Container(
            height: 300.0,
            child: _buildBody(context),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: TextField(
              onChanged: (value) {
                name = value;
              },
              decoration: InputDecoration(
                labelText: '名前',
              ),
            ),
          ),
          FlatButton(
            onPressed: () {
              print(name);
              database.collection('baby').add({
                'name': name,
                'votes': 0,
                'time': DateFormat.jm().format(DateTime.now()),
              });
            },
            color: Colors.blue,
            child: Text(
              '送信',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder(
      stream: database.collection('baby').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(record.name),
          subtitle: Text(record.time),
          trailing: Text(record.votes.toString()),
          onTap: () => database.runTransaction((transaction) async {
            final freshSnapshot = await transaction.get(record.reference);
            final fresh = Record.fromSnapshot(freshSnapshot);

            await transaction
                .update(record.reference, {'votes': fresh.votes + 1});
          }),
          onLongPress: () {
            record.reference.delete();
            print('working');
          },
        ),
      ),
    );
  }
}

class Record {
  final String name;
  final int votes;
  final String time;
  final DocumentReference reference;

  Record.fromMap(Map map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        assert(map['time'] != null),
        name = map['name'],
        votes = map['votes'],
        time = map['time'].toString();

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}
