library dl_widget;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dl_widget/dl_tool.dart';

typedef DragListWidgetBuilder<T> = Data2Widget<T> Function(
    BuildContext context, int index);

typedef UpdateDragDataIdx<T> = int Function(T data);

typedef _CheckCanDrag = bool Function();
typedef _OnDragStart = void Function(_ItemDrag drag);
typedef _OnDragEnd = void Function();
typedef _OnDragMove = void Function();
typedef OnDragEnd = void Function(int from, int to);

class Data2Widget<T> {
  Data2Widget({@required this.data, @required this.widget});

  final Widget widget;
  final T data;
}

class _DragMeta<T> {
  _DragMeta(
      {@required this.data,
      @required this.index,
      @required this.itemDrag,
      @required this.dragIndex});

  final T data;
  final _ItemDrag itemDrag;
  int index;
  int dragIndex;

  bool get isVertical => itemDrag.scrollDirection == Axis.vertical;

  Offset get pos => itemDrag.curPos;

  Size get size => itemDrag.widgetSize;

  Offset get checkPos => isVertical
      ? itemDrag.curPos.translate(10, itemDrag.widgetSize.height / 2)
      : itemDrag.curPos.translate(itemDrag.widgetSize.width / 2, 10);
}

class DragList<T> extends StatefulWidget {
  final DragListWidgetBuilder<T> widgetBuilder;
  final UpdateDragDataIdx<T> updateDragDataIdx;
  final OnDragEnd onDragEnd;
  final Axis scrollDirection;

  DragList.buildFromBuilder(
      {Key key,
      Axis scrollDirection,
      @required DragListWidgetBuilder<T> widgetBuilder,
      @required UpdateDragDataIdx<T> updateDragDataIdx,
      @required this.onDragEnd})
      : assert(widgetBuilder != null),
        this.scrollDirection = scrollDirection ?? Axis.vertical,
        this.widgetBuilder = ((ctx, idx) => widgetBuilder(ctx, idx)),
        this.updateDragDataIdx = updateDragDataIdx,
        super(key: key);

  static DragList buildFromList(
      {Key key,
      Axis scrollDirection,
      @required List<Widget> list,
      @required onDragEnd}) {
    return DragList<int>.buildFromBuilder(
        widgetBuilder: (ctx, idx) {
          if (idx >= list.length) return null;
          return Data2Widget<int>(data: idx, widget: list[idx]);
        },
        scrollDirection: scrollDirection,
        updateDragDataIdx: null,
        onDragEnd: onDragEnd);
  }

  @override
  _DragListState createState() => _DragListState<T>();
}

class _DragListState<T> extends State<DragList<T>> {
  _DragMeta<T> dragMeta;
  ScrollController scrollController = ScrollController();
  bool _isScrollMove = false;

  bool get isVertical => widget.scrollDirection == Axis.vertical;

  bool get isDrag => dragMeta != null;

  @override
  void didUpdateWidget(DragList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    //正在拖拽
    if (isDrag) {
      //没有更新拖拽数据索引的函数,就放弃拖拽
      dragMeta.itemDrag.scrollDirection = widget.scrollDirection;
      dragMeta.index = widget.updateDragDataIdx != null
          ? widget.updateDragDataIdx(dragMeta.data)
          : null;
      if (dragMeta.index == null || dragMeta.index < 0) {
        _DragMeta<T> _dragMeta = dragMeta;
        dragMeta = null;
        _dragMeta.itemDrag.cancel();
      }
    }
  }

  void _scrollMove() {
    if (_isScrollMove) return;
    double frontOff = isVertical ? dragMeta.pos.dy : dragMeta.pos.dx;
    double backOff = isVertical
        ? dragMeta.pos.dy + dragMeta.size.height
        : dragMeta.pos.dx + dragMeta.size.width;
    Size ovSize = Overlay.of(context).context.size;
    double ovOff = isVertical ? ovSize.height : ovSize.width;
    if (frontOff < 10 || ovOff - backOff < 10) {
      _isScrollMove = true;
      scrollController
          .animateTo(scrollController.offset + (frontOff < 10 ? -40.0 : 40.0),
              duration: Duration(milliseconds: 500), curve: Curves.linear)
          .then((v) {
        _isScrollMove = false;
        if (dragMeta != null) _scrollMove();
      });
    }
  }

  //判断当前拖动位置在哪个item上
  void _checkWhichItemPick(SliverMultiBoxAdaptorElement ctx) {
    if (_isScrollMove) return;
    RenderSliverList it = ctx.findRenderObject();
    RenderBox currentRender = it.firstChild;
    while (currentRender != null) {
      Size _size = WidgetTool.sizeRender(currentRender);
      Offset _pos = WidgetTool.posRender(currentRender, Overlay.of(context));
      //判断点是否进入item区域
      if (Rect.fromLTWH(_pos.dx, _pos.dy, _size.width, _size.height)
          .contains(dragMeta.checkPos)) {
        SliverMultiBoxAdaptorParentData data = currentRender.parentData;
        //判断是否是不同的item,有可能是在替身SizedBox上面
        if (dragMeta.dragIndex != data.index) {
          //判断是否进入哦item的1/3中间空间,是的话交换
          if (Rect.fromLTWH(
                  isVertical ? _pos.dx : _pos.dx + (_size.width / 3),
                  isVertical ? _pos.dy + (_size.height / 3) : _pos.dy,
                  isVertical ? _size.width : _size.width / 3,
                  isVertical ? _size.height / 3 : _size.height)
              .contains(dragMeta.checkPos)) {
            setState(() {
              dragMeta.dragIndex = data.index;
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
        scrollDirection: widget.scrollDirection,
        controller: scrollController,
        itemBuilder: (BuildContext context2, int index) {
          //在拖拽
          if (isDrag) {
            //绘制被拖拽的对象
            if (index == dragMeta.dragIndex)
              return SizedBox(
                  height: dragMeta.size.height, width: dragMeta.size.width);
            //往上拖了
            if (dragMeta.index > dragMeta.dragIndex) {
              if (dragMeta.dragIndex < index && index <= dragMeta.index)
                --index;
            } else if (dragMeta.index < dragMeta.dragIndex) {
              //往下拖了
              if (dragMeta.index <= index && index < dragMeta.dragIndex)
                ++index;
            }
          }
          Data2Widget<T> dw = widget.widgetBuilder(context2, index);
          if (dw == null) return null;
          T data = dw.data;
          return _DragListItem(
            scrollDirection: widget.scrollDirection,
            widget: dw.widget,
            onDragStart: (drag) {
              if (dragMeta != null) return;
              setState(() {
                dragMeta = _DragMeta<T>(
                    data: data, index: index, itemDrag: drag, dragIndex: index);
              });
            },
            onDragEnd: () {
              setState(() {
                if (dragMeta != null && widget.onDragEnd != null)
                  widget.onDragEnd(dragMeta.index, dragMeta.dragIndex);
                dragMeta = null;
              });
            },
            onDragMove: () {
              if (dragMeta != null) {
                _scrollMove();
                _checkWhichItemPick(context2);
              }
            },
            checkCanDrag: () => dragMeta == null,
          );
        });
  }
}

class _DragListItem extends StatefulWidget {
  _DragListItem(
      {Key key,
      this.scrollDirection,
      this.widget,
      this.onDragStart,
      this.onDragEnd,
      this.onDragMove,
      this.checkCanDrag})
      : super(key: key);
  final Widget widget;
  final _OnDragStart onDragStart;
  final _OnDragEnd onDragEnd;
  final _OnDragMove onDragMove;
  final _CheckCanDrag checkCanDrag;
  final Axis scrollDirection;

  @override
  _DragListItemState createState() => _DragListItemState();
}

class _DragListItemState extends State<_DragListItem> {
  GestureRecognizer _gestureRecognizer;

  DelayedMultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        if (!widget.checkCanDrag()) return null;
        _ItemDrag drag = _ItemDrag(
          scrollDirection: widget.scrollDirection,
          widgetSize: WidgetTool.sizeCtx(context),
          widget: widget.widget,
          pos: WidgetTool.posCtx(context),
          overLayState: Overlay.of(
            context,
            debugRequiredFor: widget,
          ),
          onDragEnd: widget.onDragEnd,
          onDragMove: widget.onDragMove,
        );
        widget.onDragStart(drag);
        return drag;
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

//拖动对象
class _ItemDrag extends Drag {
  final Widget widget;
  final Size widgetSize;
  final _OnDragEnd onDragEnd;
  final _OnDragMove onDragMove;
  Axis scrollDirection;
  Offset curPos;
  OverlayEntry _entry;

  bool get isVertical => scrollDirection == Axis.vertical;

  _ItemDrag(
      {this.scrollDirection,
      this.widget,
      this.widgetSize,
      this.onDragEnd,
      this.onDragMove,
      OverlayState overLayState,
      Offset pos}) {
    //位置下移5个像素制造选中效果
    this.curPos = isVertical ? pos.translate(0, 5) : pos.translate(5, 0);
    this._entry = OverlayEntry(builder: (context1) {
      return Positioned(
        left: curPos.dx,
        top: curPos.dy,
        child: SizedBox(
            height: widgetSize.height,
            width: widgetSize.width,
            child: widget is Material
                ? widget
                : Material(
                    child: widget,
                  )),
      );
    });
    overLayState.insert(_entry);
  }

  @override
  void update(DragUpdateDetails details) {
    curPos = isVertical
        ? curPos.translate(0, details.delta.dy)
        : curPos.translate(details.delta.dx, 0);
    this._entry?.markNeedsBuild();
    onDragMove();
  }

  @override
  void end(DragEndDetails details) {
    _entry?.remove();
    _entry = null;
    onDragEnd();
  }

  @override
  void cancel() {
    _entry?.remove();
    _entry = null;
    onDragEnd();
  }
}
