import 'package:flutter/material.dart';
import 'package:dl_widget/dl_draglist.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  Widget _widgetBuild(BuildContext context2, int value) {
    //设置组件大小每个都不一样
    double height = 50.0 + (value % 10 * 10).toDouble();
    return new SizedBox(
      height: height,
      child: new Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(0.5))),
        child: new ListTile(
          title: new Text("text $value"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DragList<int>(
          widgetBuilder: _widgetBuild,
          list: list,
          onDragEnd: (from, to) {
            if (from == to) return;
            setState(() {
              int f = list.removeAt(from);
              list.insert(to, f);
            });
          },
        ),
      ),
    );
  }
}
