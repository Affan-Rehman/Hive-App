// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get the application documents directory for storing Hive data
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  
  // Register your Hive adapters (if any)
  Hive.registerAdapter(PersonAdapter());

  runApp(MainApp());
}


class MainApp extends StatelessWidget {
  MainApp({super.key});

  TextEditingController con1 = TextEditingController();
  TextEditingController con2 = TextEditingController();
  List<Person> persons = [];
  List<String> keys = [];

  void save() async {
    var box = await Hive.openBox('testBox');
    final person = Person(int.parse(con1.text), con2.text);
    persons.add(person);
    keys.add(con1.text);
    await box.put(con1.text, person);
    con1.clear();
    con2.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: con1,
                      decoration: const InputDecoration(labelText: 'id'),
                    ),
                    TextField(
                      controller: con2,
                      decoration: const InputDecoration(labelText: 'name'),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          child: const Text('Save'),
                          onPressed: save,
                        ),
                        ElevatedButton(
                            child: const Text('View'),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ViewScreen()));
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}

class Person extends HiveObject {
  int id;
  String name;
  Person(this.id, this.name);
  @override
  String toString() {
    return '$id: $name';
  }
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 0;

  @override
  Person read(BinaryReader reader) {
    final id = reader.readInt();
    final name = reader.readString();
    return Person(id, name);
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
  }
}


class ViewScreen extends StatefulWidget {
  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  Future<void> _deletePerson(BuildContext context, String key) async {
    var box = await Hive.openBox('testBox');
    await box.delete(key);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Person deleted'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Persons')),
        body: FutureBuilder(
          future: Hive.openBox('testBox'),
          builder:
              (BuildContext context, AsyncSnapshot<Box<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error opening box'));
            }
            final box = snapshot.data;
            final persons = box?.values.toList().cast<Person>();
            return ListView.builder(
              itemCount: persons?.length,
              itemBuilder: (BuildContext context, int index) {
                final person = persons?[index];
                return ListTile(
                  title: Text('${person?.id}: ${person?.name}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () { _deletePerson(context, box?.keyAt(index));
                    setState(() {
                      
                    });},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
