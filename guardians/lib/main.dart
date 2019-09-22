import 'package:flutter/material.dart';
import 'package:guardians/map.dart';
import 'package:guardians/web.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    GlobalKey<MyHomePageState> key = GlobalKey<MyHomePageState>();

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
      home: MyHomePage(title: 'Flutter Demo Home Page', key: key,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  String _url;
  Widget _webView;
  int _cameraPosition;

  @override
  void initState() {
    super.initState();
    setState(() {
      _cameraPosition = 0;
      _url = 'http://192.168.29.223:3000/cctv/5/';
      _webView = Web(key: GlobalKey(), url: _url,);
    });
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
        title: Text('가디언즈'),
        centerTitle: true,
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
              child: _webView,
            ),
            Container(
              height: 2,
              color: Colors.blueAccent,
            ),
            Expanded(
                child: PlaceBody(parentKey: widget.key))
          ],
        ),
      ),
    );
  }

  changeProperty(position) {
    switch (position) {
      case 4:
        print("1");
        if(_cameraPosition != 0) {
          setState(() {
            _cameraPosition = 0;
            _url = 'http://192.168.29.223:3000/cctv/4/';
            _webView = Web(key: GlobalKey(), url: _url,);
          });
        }

        break;
      case 1:
        break;
      case 5:
        print("2");
        if(_cameraPosition != 2) {
          setState(() {
            _cameraPosition = 2;
            _url = 'http://192.168.29.223:3000/cctv/5/';
            _webView = Web(key: GlobalKey(), url: _url,);
          });
        }
        break;
      case 3:
        break;
    }
  }
}
