import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'RGOqrgamYLfeNjPN6O5JFTgTQx0FzzWOLjrTYwBz';
  const keyClientKey = 'pssOXrSMpivxpdrTJGpBb6YQe56KxPbKktJMxqVf';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey,
      liveQueryUrl: 'https://flutterassignment.b4a.io',
      debug: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Assignment 2022mt1225'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController taskTitleController = TextEditingController();
  TextEditingController taskDescController = TextEditingController();
  TextEditingController taskeditTitleController = TextEditingController();
  TextEditingController taskeditDescController = TextEditingController();

  final todoController = TextEditingController();
  List<ParseObject> taskList = [];
  final QueryBuilder<ParseObject> queryTodo =
      QueryBuilder<ParseObject>(ParseObject('taskList'))
        ..orderByAscending('createdAt');

  StreamController<List<ParseObject>> streamController = StreamController();

  final LiveQuery liveQuery = LiveQuery(debug: true);
  late Subscription<ParseObject> subscription;

  void addToDo() async {
    if (taskTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Title can not be blank"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTask(taskTitleController.text, taskDescController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Task added"),
      duration: Duration(seconds: 2),
    ));
    taskTitleController.clear();
    taskDescController.clear();
  }

  void editTask(String id) async {
    if (taskeditTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Title can not be blank"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await updateTask(
        id, taskeditTitleController.text, taskeditDescController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Task updated"),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  void initState() {
    super.initState();
    getTodoList();
    startLiveQuery();
  }

  void startLiveQuery() async {
    subscription = await liveQuery.client.subscribe(queryTodo);

    subscription.on(LiveQueryEvent.create, (value) {
      debugPrint('*** CREATE ***: $value ');
      taskList.add(value);
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.update, (value) {
      debugPrint('*** UPDATE ***: $value ');
      taskList[taskList
          .indexWhere((element) => element.objectId == value.objectId)] = value;
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.delete, (value) {
      debugPrint('*** DELETE ***: $value ');
      taskList.removeWhere((element) => element.objectId == value.objectId);
      streamController.add(taskList);
    });
  }

  void cancelLiveQuery() async {
    liveQuery.client.unSubscribe(subscription);
  }

  Future<void> saveTask(String title, String description) async {
    final todo = ParseObject('taskList')
      ..set('Title', title)
      ..set('Description', description)
      ..set('Completed', false);
    await todo.save();
  }

  void getTodoList() async {
    final ParseResponse apiResponse = await queryTodo.query();

    if (apiResponse.success && apiResponse.results != null) {
      taskList.addAll(apiResponse.results as List<ParseObject>);
      streamController.add(apiResponse.results as List<ParseObject>);
    } else {
      taskList.clear();
      streamController.add([]);
    }
  }

  Future<void> updateDone(String id, bool completedFlag) async {
    var todo = ParseObject('taskList')
      ..objectId = id
      ..set('Completed', completedFlag);
    await todo.save();
  }

  Future<void> updateTask(String id, String title, String description) async {
    var todo = ParseObject('taskList')
      ..objectId = id
      ..set('Title', title)
      ..set('Description', description);
    await todo.save();
  }

  Future<void> deleteTodo(String id) async {
    var todo = ParseObject('taskList')..objectId = id;
    await todo.delete();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<ParseObject>>(
                stream: streamController.stream,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Center(
                        child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator()),
                      );
                    default:
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error..."),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text("No Data..."),
                        );
                      } else {
                        return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final tiledata = snapshot.data![index];
                              return ListTile(
                                onTap: () async {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: Text(
                                                tiledata.get<String>('Title')!),
                                            content: Text(tiledata.get<String>(
                                                        'Description') ==
                                                    null
                                                ? ''
                                                : tiledata.get<String>(
                                                    'Description')!),
                                          ));
                                },
                                leading: CircleAvatar(
                                    child: Text((index + 1).toString()),
                                    backgroundColor:
                                        tiledata.get<bool>('Completed')!
                                            ? Colors.green
                                            : Colors.yellow),

                                title: Text(tiledata.get<String>('Title')!,
                                    style: tiledata.get<bool>('Completed')!
                                        ? const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough)
                                        : const TextStyle()),

                                subtitle: Text(
                                    tiledata.get<String>('Description') == null
                                        ? ''
                                        : tiledata.get<String>('Description')!,
                                    style: tiledata.get<bool>('Completed')!
                                        ? const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough)
                                        : const TextStyle()), //alllow null Description

                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                          value:
                                              tiledata.get<bool>('Completed'),
                                          onChanged: (value) async {
                                            await updateDone(
                                                tiledata.objectId!, value!);
                                          }),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          taskeditTitleController.text =
                                              tiledata.get<String>('Title')!;
                                          taskeditDescController.text = tiledata
                                                      .get<String>(
                                                          'Description') ==
                                                  null
                                              ? ''
                                              : tiledata
                                                  .get<String>('Description')!;
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Edit Task'),
                                              content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    TextFormField(
                                                      controller:
                                                          taskeditTitleController,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Enter Task Title',
                                                      ),
                                                    ),
                                                    TextFormField(
                                                      controller:
                                                          taskeditDescController,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Enter Task Description',
                                                      ),
                                                    ),
                                                  ]),
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      const snackBar = SnackBar(
                                                        content:
                                                            Text("Cancelled"),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      );
                                                      ScaffoldMessenger.of(
                                                          context)
                                                        ..removeCurrentSnackBar()
                                                        ..showSnackBar(
                                                            snackBar);
                                                      Navigator.pop(
                                                          context, true);
                                                      //});
                                                    },
                                                    child:
                                                        const Text('Cancel')),
                                                TextButton(
                                                    onPressed: () async {
                                                      editTask(
                                                          tiledata.objectId!);
                                                      Navigator.pop(
                                                          context, true);
                                                      //});
                                                    },
                                                    child: const Text(
                                                        'Edit Task')),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          await deleteTodo(tiledata.objectId!);
                                          //setState(() {
                                          const snackBar = SnackBar(
                                            content: Text("Task deleted!"),
                                            duration: Duration(seconds: 2),
                                          );
                                          ScaffoldMessenger.of(context)
                                            ..removeCurrentSnackBar()
                                            ..showSnackBar(snackBar);
                                          //});
                                        },
                                      )
                                    ]),
                              );
                            });
                      }
                  }
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Task'),
              content:
                  Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                TextFormField(
                  controller: taskTitleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Task Title',
                  ),
                ),
                TextFormField(
                  controller: taskDescController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Task Description',
                  ),
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () async {
                      const snackBar = SnackBar(
                        content: Text("Cancelled"),
                        duration: Duration(seconds: 2),
                      );
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(snackBar);
                      Navigator.pop(context, true);
                      //});
                    },
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () async {
                      addToDo();
                      Navigator.pop(context, true);
                      //});
                    },
                    child: const Text('Add Task')),
              ],
            ),
          );
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
