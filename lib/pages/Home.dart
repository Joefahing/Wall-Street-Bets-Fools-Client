import 'dart:async';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as Charts;

import '../components/adaptive.dart';
import '../controllers/APIController.dart';
import '../model/post.dart';
import '../model/summary.dart';
import '../components/theme_data.dart' as theme;

import '../widgets/line_chart.dart';
import '../widgets/metric_card.dart';

class WallStreetBetHomePage extends StatefulWidget {
  WallStreetBetHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _WallStreetBetHomePageState createState() => _WallStreetBetHomePageState();
}

class _WallStreetBetHomePageState extends State<WallStreetBetHomePage> {
  Future<List<Post>> posts;
  Future<PostSummary> summary;
  Future<List<Charts.Series>> lineGraphDataSet;
  String interval = 'week';
  List<bool> _toggleSelection = [false, true, false];

  final apiController = APIController();

  ///This helper method refetches data from API base on current interval and set
  ///them to instance variables used to power the data and display
  void _prepareAPIData() {
    final apiResponse = apiController.fetchPosts(interval);
    summary = apiController.getSummary(response: apiResponse);
    posts = apiController.getPosts(response: apiResponse);
    lineGraphDataSet = apiController.getGainLossDataPoint(response: apiResponse);
  }

  String _prepareChartTitle(String interval) {
    switch (interval) {
      case 'week':
        return 'Weekly';
      case 'day':
        return 'Daily';
      case 'month':
        return 'Monthly';
      default:
        throw Exception('Invalid Interval');
    }
  }

  void _resetSelection() {
    _toggleSelection = [false, false, false];
  }

  void updateWeeklyInterval() {
    setState(() {
      interval = 'week';
      _prepareAPIData();
    });
  }

  void updateMonthlyInterval() {
    setState(() {
      interval = 'month';
      _prepareAPIData();
    });
  }

  void updateDailyInterval() {
    setState(() {
      interval = 'day';
      _prepareAPIData();
    });
  }

  void updateInterval(index) {
    final Map<int, String> toggleMap = {0: 'month', 1: 'week', 2: 'day'};
    final defaultInterval = 'month';
    final selection = toggleMap.containsKey(index) ? toggleMap[index] : defaultInterval;

    switch (selection) {
      case 'month':
        updateMonthlyInterval();
        break;
      case 'week':
        updateWeeklyInterval();
        break;
      case 'day':
        updateDailyInterval();
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _prepareAPIData();
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveWindow.fromContext(context: context);
    final measurements = adaptive.getBreakpoint();

    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(
            right: measurements.leftRightMargin,
            left: measurements.leftRightMargin,
            top: measurements.topDownMargin,
            bottom: measurements.topDownMargin),
        child: Column(
          children: [
            FlatBackgroundBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flex(
                    direction: Axis.vertical,
                    children: [
                      Text('Wall Street Bets for Fools', style: theme.headline1),
                      Text('Lose Money With Friends', style: theme.headline3),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.lightGray,
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: [
                        IntervalFlatButton(
                            title: 'Monthly',
                            color: interval == 'month' ? Colors.white : theme.lightGray,
                            onPressed: updateMonthlyInterval),
                        SizedBox(width: measurements.gutter),
                        IntervalFlatButton(
                            title: 'Weekly',
                            color: interval == 'week' ? Colors.white : theme.lightGray,
                            onPressed: updateWeeklyInterval),
                        SizedBox(width: measurements.gutter),
                        IntervalFlatButton(
                            title: 'Daily',
                            color: interval == 'day' ? Colors.white : theme.lightGray,
                            onPressed: updateDailyInterval),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: measurements.gutter / 2, width: measurements.gutter),
            APIDataSlicers(
              summary: summary,
              width: adaptive.width,
              gutter: measurements.gutter,
            ),
            SizedBox(height: measurements.gutter / 2, width: measurements.gutter),
            Expanded(
              child: FlatBackgroundBox(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_prepareChartTitle(interval)} Index'),
                        Row(
                          children: [
                            Text('Gain'),
                            SizedBox(width: 10),
                            Text('Loss'),
                            SizedBox(width: 10),
                            Text('Total'),
                          ],
                        )
                      ],
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: lineGraphDataSet,
                        builder: (BuildContext context, future) {
                          final marginMultiplier = 3;
                          if (future.hasData) {
                            return WallStreetBetTimeSeriesChart(series: future.data);
                          } else if (future.hasError) {
                            return Text("${future.error}");
                          }
                          return Center(
                            child: Padding(
                                padding: EdgeInsets.only(
                                  right: measurements.leftRightMargin * marginMultiplier,
                                  left: measurements.leftRightMargin * marginMultiplier,
                                ),
                                child: LinearProgressIndicator()),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntervalFlatButton extends StatelessWidget {
  final String title;
  final Color color;
  void Function() onPressed;

  IntervalFlatButton({@required this.title, this.color, @required this.onPressed});

  @override
  build(BuildContext context) {
    return FlatButton(
        child: Text(title, style: theme.headline4),
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius / 2)),
        onPressed: onPressed,
        hoverColor: theme.lightSilver);
  }
}

class FlatBackgroundBox extends StatelessWidget {
  final Widget child;

  FlatBackgroundBox({@required this.child});

  @override
  build(BuildContext context) {
    final adaptive = AdaptiveWindow.fromContext(context: context);
    final measurements = adaptive.getBreakpoint();
    return Container(
      padding: EdgeInsets.all(measurements.gutter),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        color: Colors.white,
      ),
      child: child,
    );
  }
}

class APIDataSlicers extends StatelessWidget {
  final Future<PostSummary> summary;
  final double width;
  final double gutter;
  final double textFieldHeigh = 80;
  final double minWidth = 750;
  final double percentage = 100.0;
  final String bullIcon = '../assets/images/bull_icon.png';
  final String bearIcon = '../assets/images/bear_icon.png';
  final String kangarooIcon = '../assets/images/kangaroo_icon.png';

  APIDataSlicers({this.summary, this.width, this.gutter});

  build(BuildContext context) {
    return FutureBuilder<PostSummary>(
        future: summary,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LayoutBuilder(
              builder: (context, constraint) {
                int crossAxisCount = width < minWidth ? 1 : 3;
                double itemWidth = constraint.maxWidth / crossAxisCount;

                return GridView.count(
                  primary: false,
                  shrinkWrap: true,
                  childAspectRatio: itemWidth / textFieldHeigh,
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gutter,
                  mainAxisSpacing: gutter,
                  children: [
                    MetricCard(
                      title: 'Gain',
                      rate: snapshot.data.gainGrowthRate * percentage,
                      total: snapshot.data.gain,
                      imageUrl: bullIcon,
                      color: theme.lightGreen,
                    ),
                    MetricCard(
                      title: 'Loss',
                      rate: snapshot.data.lossGrowthRate * percentage,
                      total: snapshot.data.loss,
                      imageUrl: bearIcon,
                      color: theme.lightPink,
                    ),
                    MetricCard(
                        title: 'Difference',
                        rate: snapshot.data.differenceGrowthRate * percentage,
                        total: snapshot.data.difference,
                        imageUrl: kangarooIcon,
                        color: theme.lightOrange)
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return SizedBox(
            height: 30,
          );
        });
  }
}
