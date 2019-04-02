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
  int currentIdx = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
            onTap: (int index) {
              if (currentIdx == index) return;
              setState(() {
                currentIdx = index;
              });
            },
            type: BottomNavigationBarType.shifting,
            currentIndex: currentIdx,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.accessible,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'builder',
                    style: TextStyle(color: Colors.blue),
                  )),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.accessible_forward,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'list',
                    style: TextStyle(color: Colors.blue),
                  )),
            ]),
        body: IndexedStack(
          index: currentIdx,
          children: <Widget>[
            DragList<int>.buildFromBuilder(
              updateDragDataIdx: (data) => list.indexWhere((i) => i == data),
              widgetBuilder: (ctx, index) {
                if (index >= list.length) return null;
                int value = list[index];
                //设置组件大小每个都不一样
                double height = 50.0 + (value % 10 * 10).toDouble();
                return Data2Widget<int>(
                    data: value,
                    widget: SizedBox(
                      height: height,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.blue),
                            borderRadius:
                                BorderRadius.all(Radius.circular(0.5))),
                        child: ListTile(
                          title: Text("text $value"),
                        ),
                      ),
                    ));
              },
              onDragEnd: (from, to) {
                if (from == to) return;
                setState(() {
                  int f = list.removeAt(from);
                  list.insert(to, f);
                });
              },
            ),
            DragList.buildFromList(
                scrollDirection: Axis.horizontal,
                list: () {
                  List<Widget> _list = new List<Widget>();
                  for (int index = 0; index < list.length; ++index) {
                    int value = list[index];
                    //设置组件大小每个都不一样
                    double width = 60.0 + (value % 10 * 10).toDouble();
                    _list.add(SizedBox(
                      width: width,
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.blue),
                            borderRadius:
                                BorderRadius.all(Radius.circular(0.5))),
                        child: ListTile(
                          title:
                              Text("text $value", textAlign: TextAlign.start),
                        ),
                      ),
                    ));
                  }
                  return _list;
                }(),
                onDragEnd: (from, to) {
                  if (from == to) return;
                  setState(() {
                    int f = list.removeAt(from);
                    list.insert(to, f);
                  });
                }),
          ],
        ),
      ),
    );
  }
}
