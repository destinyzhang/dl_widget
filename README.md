# flutter 简单可拖动列表框

![](https://raw.githubusercontent.com/destinyzhang/resource/master/dl_widget/demo_draglist.gif)


### 使用buider函数 默认纵向
List<int> list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
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
            );
### 使用List<Widget> 指定横向
List<int> list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
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
                });