import 'package:flutter/material.dart';
import 'package:time_planner/src/time_planner_style.dart';

import 'package:time_planner/src/config/global_config.dart' as config;
import 'package:time_planner/src/time_planner_task.dart';
import 'package:time_planner/src/time_planner_time.dart';
import 'package:time_planner/src/time_planner_title.dart';

/// Time planner widget
class TimePlanner extends StatefulWidget {
  /// Time start from this, it will start from 0
  final int startHour;

  /// Time end at this hour, max value is 23
  final int endHour;

  /// Create days from here, each day is a TimePlannerTitle.
  ///
  /// you should create at least one day
  final List<TimePlannerTitle> headers;

  /// List of widgets on time planner
  final List<TimePlannerTask>? tasks;

  /// Style of time planner
  final TimePlannerStyle? style;

  /// When widget loaded scroll to current time with an animation. Default is true
  final bool? currentTimeAnimation;

  /// Time planner widget
  const TimePlanner({
    Key? key,
    required this.startHour,
    required this.endHour,
    required this.headers,
    this.tasks,
    this.style,
    this.currentTimeAnimation,
  }) : super(key: key);
  @override
  _TimePlannerState createState() => _TimePlannerState();
}

class _TimePlannerState extends State<TimePlanner> {
  ScrollController mainHorizontalController = ScrollController();
  ScrollController mainVerticalController = ScrollController();
  ScrollController dayHorizontalController = ScrollController();
  ScrollController timeVerticalController = ScrollController();
  TimePlannerStyle style = TimePlannerStyle();
  List<TimePlannerTask> tasks = [];
  bool? isAnimated = true;
  bool _syncingMainToDay = false;
  bool _syncingDayToMain = false;
  bool _syncingMainToTime = false;

  /// check input value rules
  void _checkInputValue() {
    if (widget.startHour > widget.endHour) {
      throw FlutterError("Start hour should be lower than end hour");
    } else if (widget.startHour < 0) {
      throw FlutterError("Start hour should be larger than 0");
    } else if (widget.endHour > 23) {
      throw FlutterError("Start hour should be lower than 23");
    } else if (widget.headers.isEmpty) {
      throw FlutterError("header can't be empty");
    }
  }

  /// create local style
  void _convertToLocalStyle() {
    style.backgroundColor = widget.style?.backgroundColor;
    style.cellHeight = widget.style?.cellHeight ?? 80;
    style.cellWidth = widget.style?.cellWidth ?? 90;
    style.horizontalTaskPadding = widget.style?.horizontalTaskPadding ?? 0;
    style.borderRadius = widget.style?.borderRadius ??
        const BorderRadius.all(Radius.circular(8.0));
    style.dividerColor = widget.style?.dividerColor;
    style.showScrollBar = widget.style?.showScrollBar ?? false;
  }

  /// store input data to static values
  void _initData() {
    _checkInputValue();
    _convertToLocalStyle();
    config.horizontalTaskPadding = style.horizontalTaskPadding;
    config.cellHeight = style.cellHeight;
    config.cellWidth = style.cellWidth;
    config.totalHours = (widget.endHour - widget.startHour).toDouble();
    config.totalDays = widget.headers.length;
    config.startHour = widget.startHour;
    config.borderRadius = style.borderRadius;
    isAnimated = widget.currentTimeAnimation;
    tasks = widget.tasks ?? [];
  }

  @override
  void initState() {
    _initData();
    super.initState();
    mainHorizontalController.addListener(syncMainToDay);
    dayHorizontalController.addListener(syncDayToMain);
    mainVerticalController.addListener(syncMainToTime);

    Future.delayed(Duration.zero).then((_) {
      int hour = DateTime.now().hour;
      if (isAnimated != null && isAnimated == true) {
        if (hour > widget.startHour) {
          double scrollOffset =
              (hour - widget.startHour) * config.cellHeight!.toDouble();
          mainVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
          timeVerticalController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCirc,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    mainHorizontalController.removeListener(syncMainToDay);
    dayHorizontalController.removeListener(syncDayToMain);
    mainVerticalController.removeListener(syncMainToTime);

    mainHorizontalController.dispose();
    dayHorizontalController.dispose();
    mainVerticalController.dispose();
    timeVerticalController.dispose();

    super.dispose();
  }

  void syncMainToDay() {
    if (!_syncingDayToMain) {
      _syncingMainToDay = true;
      dayHorizontalController.jumpTo(mainHorizontalController.offset);
      _syncingMainToDay = false;
    }
  }

  void syncDayToMain() {
    if (!_syncingMainToDay) {
      _syncingDayToMain = true;
      mainHorizontalController.jumpTo(dayHorizontalController.offset);
      _syncingDayToMain = false;
    }
  }

  void syncMainToTime() {
    if (!_syncingMainToTime) {
      _syncingMainToTime = true;
      timeVerticalController.jumpTo(mainVerticalController.offset);
      _syncingMainToTime = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: style.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SingleChildScrollView(
              controller: dayHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 60,
                  ),
                  for (int i = 0; i < config.totalDays; i++) widget.headers[i],
                ],
              ),
            ),
            Container(
              height: 1,
              color: style.dividerColor ?? Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: timeVerticalController,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              //first number is start hour and second number is end hour
                              for (int i = widget.startHour;
                                  i <= widget.endHour;
                                  i++)
                                TimePlannerTime(
                                  time: i.toString() + ':00',
                                ),
                            ],
                          ),
                          Container(
                            height:
                                (config.totalHours * config.cellHeight!) + 80,
                            width: 2,
                            color: style.dividerColor ??
                                Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: buildMainBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMainBody() {
    return Scrollbar(
      controller: mainVerticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: mainVerticalController,
        child: Scrollbar(
          controller: mainHorizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: mainHorizontalController,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: (config.totalHours * config.cellHeight!) + 80,
                      width: (config.totalDays * config.cellWidth!).toDouble(),
                      child: Stack(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (var i = 0; i < config.totalHours; i++)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(
                                      height:
                                          (config.cellHeight! - 1).toDouble(),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Colors.white,
                                    ),
                                  ],
                                )
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (var i = 0; i < config.totalDays; i++)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(
                                      width: (config.cellWidth! - 1).toDouble(),
                                    ),
                                    Container(
                                      width: 1,
                                      height: (config.totalHours *
                                              config.cellHeight!) +
                                          config.cellHeight!,
                                      color: Colors.white,
                                    )
                                  ],
                                )
                            ],
                          ),
                          for (int i = 0; i < tasks.length; i++) tasks[i],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
