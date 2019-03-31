library dl_widget;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

typedef DragListWidgetBuilder<T> = Widget Function(
    BuildContext context, T item);

typedef _OnDragStart = bool Function(int index, Size size);
typedef _OnDragEnd = void Function();
typedef _OnDragMove = void Function(Offset pos);
typedef OnDragEnd = void Function(int from, int to);

class DragList<T> extends StatefulWidget {
  final DragListWidgetBuilder<T> widgetBuilder;
  final List<T> list;
  final OnDragEnd onDragEnd;

  DragList({Key key, this.widgetBuilder, List<T> list, this.onDragEnd})
      : this.list = List<T>.generate(list.length, (i) => list[i]),
        super(key: key);

  @override
  _DragListState createState() => _DragListState<T>();
}

class _DragListState<T> extends State<DragList<T>> {
  List<T> list = new List<T>();
  _DragItemMeta dragItemMeta;
  ScrollController scrollController = ScrollController();
  bool _isScrollMove = false;

  @override
  void initState() {
    super.initState();
    list.addAll(widget.list);
  }

  @override
  void didUpdateWidget(DragList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    list.clear();
    list.addAll(widget.list);
  }

  void _scrollMove() {
    if (_isScrollMove) return;
    double topDy = dragItemMeta.pos.dy;
    double bottomDy = dragItemMeta.pos.dy + dragItemMeta.size.height;
    double height = Overlay.of(context).context.size.height;
    if (topDy < 10 || height - bottomDy < 10) {
      _isScrollMove = true;
      scrollController
          .animateTo(scrollController.offset + (topDy < 10 ? -20.0 : 20.0),
              duration: Duration(milliseconds: 500), curve: Curves.linear)
          .then((v) {
        _isScrollMove = false;
        if (dragItemMeta != null) _scrollMove();
      });
    }
  }

  //判断当前拖动位置在哪个item上
  void _checkWhichItemPick(SliverMultiBoxAdaptorElement ctx) {
    if (_isScrollMove) return;
    RenderSliverList it = ctx.findRenderObject();
    RenderBox currentRender = it.firstChild;
    while (currentRender != null) {
      Size _size = _TransformHelp.sizeRender(currentRender);
      Offset _pos =
          _TransformHelp.posRender(currentRender, Overlay.of(context));
      //判断点是否进入item区域
      if (Rect.fromLTWH(_pos.dx, _pos.dy, _size.width, _size.height)
          .contains(dragItemMeta.checkPos)) {
        SliverMultiBoxAdaptorParentData data = currentRender.parentData;
        //判断是否是不同的item,有可能是在替身SizedBox上面
        if (dragItemMeta.dragIndex != data.index) {
          //判断是否进入哦item的1/3中间空间,是的话交换
          if (Rect.fromLTWH(_pos.dx, _pos.dy + (_size.height / 3), _size.width,
                  _size.height / 3)
              .contains(dragItemMeta.checkPos)) {
            setState(() {
              T item = list.removeAt(dragItemMeta.dragIndex);
              list.insert(data.index, item);
              dragItemMeta.dragIndex = data.index;
            });
          }
        }
        return;
      }
      currentRender = it.childAfter(currentRender);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        controller: scrollController,
        itemBuilder: (BuildContext context2, int index) {
          if (index >= list.length) return null;
          T _value = list[index];
          //当前拖拽的元素，使用替身SizedBox占位
          if (index == dragItemMeta?.dragIndex)
            return SizedBox(
                height: dragItemMeta.size.height,
                width: dragItemMeta.size.width);
          return _DragListItem(
            widget: widget.widgetBuilder(context2, _value),
            index: index,
            onDragStart: (idx, size) {
              if (dragItemMeta != null) return false;
              setState(() {
                dragItemMeta = _DragItemMeta(size, idx, idx);
              });
              return true;
            },
            onDragEnd: () {
              setState(() {
                if (dragItemMeta != null && widget.onDragEnd != null)
                  widget.onDragEnd(dragItemMeta.index, dragItemMeta.dragIndex);
                dragItemMeta = null;
              });
            },
            onDragMove: (pos) {
              if (dragItemMeta != null) {
                dragItemMeta.pos = pos;
                dragItemMeta.checkPos =
                    pos.translate(10, dragItemMeta.size.height / 2);
                _scrollMove();
                _checkWhichItemPick(context2);
              }
            },
          );
        });
  }
}

class _DragListItem extends StatefulWidget {
  _DragListItem(
      {Key key,
      this.widget,
      this.index,
      this.onDragStart,
      this.onDragEnd,
      this.onDragMove})
      : super(key: key);
  final Widget widget;
  final int index;
  final _OnDragStart onDragStart;
  final _OnDragEnd onDragEnd;
  final _OnDragMove onDragMove;

  @override
  _DragListItemState createState() => _DragListItemState();
}

class _DragListItemState extends State<_DragListItem> {
  GestureRecognizer _gestureRecognizer;

  DelayedMultiDragGestureRecognizer createRecognizer() {
    return new DelayedMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        Size _size = _TransformHelp.sizeCtx(context);
        Offset _pos = _TransformHelp.posCtx(context);
        if (!widget.onDragStart(widget.index, _size)) return null;
        _OnDragEnd _onDragEnd = widget.onDragEnd;
        return _MyDrag(
          mySize: _size,
          subWidget: widget.widget,
          pos: _pos,
          overLayState: Overlay.of(
            context,
            debugRequiredFor: widget,
          ),
          onDragEnd: () {
            _onDragEnd();
          },
          onDragMove: widget.onDragMove,
        );
      };
  }

  void pointerDownEvent(PointerDownEvent event) {
    if (_gestureRecognizer == null) _gestureRecognizer = createRecognizer();
    _gestureRecognizer.addPointer(event);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: pointerDownEvent,
      child: widget.widget,
    );
  }
}

class _MyDrag extends Drag {
  Widget subWidget;
  OverlayEntry entry;
  Offset curPos;
  Size mySize;
  _OnDragEnd onDragEnd;
  _OnDragMove onDragMove;

  _MyDrag(
      {this.subWidget,
      this.mySize,
      this.onDragEnd,
      this.onDragMove,
      OverlayState overLayState,
      Offset pos}) {
    //位置下移5个像素制造选中效果
    this.curPos = Offset(pos.dx, pos.dy + 5);
    this.entry = OverlayEntry(builder: (context1) {
      return Positioned(
        left: curPos.dx,
        top: curPos.dy,
        child: SizedBox(
            height: mySize.height,
            width: mySize.width,
            child: subWidget is Material
                ? subWidget
                : Material(
                    child: subWidget,
                  )),
      );
    });
    overLayState.insert(entry);
  }

  @override
  void update(DragUpdateDetails details) {
    curPos = curPos.translate(0, details.delta.dy);
    this.entry.markNeedsBuild();
    onDragMove(curPos); //位置移动到中间来
  }

  @override
  void end(DragEndDetails details) {
    entry.remove();
    onDragEnd();
  }

  @override
  void cancel() {
    entry.remove();
    onDragEnd();
  }
}

//拖动项目元数据
class _DragItemMeta {
  final Size size;
  final int index;
  int dragIndex;
  Offset pos; //当前拖动控件位置
  Offset checkPos; //用来检查滑动位置
  _DragItemMeta(this.size, this.index, this.dragIndex);
}

//帮助取得ui大小和位置
class _TransformHelp {
  static Size sizeRender(RenderBox box) => Size.copy(box.size);

  static Size sizeCtx(BuildContext ctx) => sizeRender(ctx.findRenderObject());

  static Offset posRender(RenderObject obj, OverlayState os) {
    Vector3 v3 =
        obj.getTransformTo(os?.context?.findRenderObject()).getTranslation();
    return Offset(v3.x, v3.y);
  }

  static Offset posCtx(BuildContext ctx) =>
      posRender(ctx.findRenderObject(), Overlay.of(ctx));
}
