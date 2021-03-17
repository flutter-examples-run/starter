import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uhst/uhst.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final List<Widget> _tabs = <Widget>[
    Tab(icon: Icon(Icons.cloud_outlined), text: 'Host'),
    Tab(icon: Icon(Icons.center_focus_strong), text: 'Join'),
  ];
  late TabController _tabController;
  late Uhst uhst;
  int _counter = 0;
  int _hostCounter = 0;
  bool _hostReady = false;
  bool _clientReady = false;
  UhstHost? host;
  UhstSocket? client;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: _tabs.length)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          switch (_tabController.index) {
            case 0:
              // from client to host
              initHost();
              break;
            case 1:
              // from host to client
              break;
          }
        }
      });
    uhst = Uhst(debug: true);
    initHost();
  }

  void initHost() async {
    setState(() {
      _hostReady = false;
    });
    host?.disconnect();
    host = uhst.host();
    host
      ?..onReady(handler: ({required String hostId}) {
        setState(() {
          _hostReady = true;
        });
        initClient(hostId);
      })
      ..onError(handler: ({required Error error}) {
        print(error);
      })
      ..onDiagnostic(handler: ({required String message}) {
        print(message);
      })
      ..onConnection(handler: ({required UhstSocket uhstSocket}) {
        uhstSocket.onMessage(handler: ({required message}) {
          if (message == 'increment_counter') {
            _hostCounter++;
            host?.broadcastString(message: jsonEncode(_hostCounter));
          }
        });
        uhstSocket.onOpen(handler: () {
          // client connected
        });
      });
  }

  void initClient(hostId) async {
    setState(() {
      _clientReady = false;
    });
    client?.close();
    client = uhst.join(hostId: hostId);
    client
      ?..onError(handler: ({required Error error}) {
        print(error);
      })
      ..onDiagnostic(handler: ({required String message}) {
        print(message);
      })
      ..onOpen(handler: () {
        setState(() {
          _clientReady = true;
        });
      })
      ..onMessage(handler: ({required message}) {
        setState(() {
          _counter = jsonDecode(message);
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    client?.sendString(message: 'increment_counter');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title!),
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs,
          ),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                  height: 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      Center(
                        child: Text(
                            _hostReady ? host!.hostId : 'Host initializing...'),
                      ),
                      Center(
                        child: Column(children: <Widget>[
                          Text('QR code scanner'),
                        ]),
                      )
                    ],
                  )),
              Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: _clientReady
            ? FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: Icon(Icons.add),
              )
            : null
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
