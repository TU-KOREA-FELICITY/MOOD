import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeRecognitionScreen extends StatefulWidget {
  @override
  _HomeRecognitionScreenState createState() => _HomeRecognitionScreenState();
}

class _HomeRecognitionScreenState extends State<HomeRecognitionScreen> {
  final List<Map<String, dynamic>> emotions = [
    {'name': 'ANGRY', 'color': Color(0xFFFFDBD6)},
    {'name': 'HAPPY', 'color': Color(0xFFFEEFF2)},
    {'name': 'SURPRISED', 'color': Color(0xFFFFFAD7)},
    {'name': 'DISGUSTED', 'color': Color(0xFFFFFBF4)},
    {'name': 'CALM', 'color': Color(0xFFE0F0E2)},
    {'name': 'SAD', 'color': Color(0xFFE9F5FD)},
    {'name': 'CONFUSED', 'color': Color(0xFFFBF4FB)},
    {'name': 'FEAR', 'color': Color(0xFFEFEFEF)},
  ];

  List<FlSpot> generateRandomData(int count) {
    final random = Random();
    return List.generate(
      count,
          (index) => FlSpot(index.toDouble(), random.nextInt(4).toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나의 집중도',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  height: 200,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(128),
                        blurRadius: 10,
                        spreadRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: 0.25,
                        verticalInterval: 0.25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              String text;
                              switch (value.toInt()) {
                                case 0:
                                  text = '양호';
                                  break;
                                case 1:
                                  text = '주의';
                                  break;
                                case 2:
                                  text = '위험';
                                  break;
                                case 3:
                                  text = '경고';
                                  break;
                                default:
                                  return Container();
                              }
                              return Text(
                                text,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black),
                      ),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 3,
                      lineBarsData: [
                        LineChartBarData(
                          spots: generateRandomData(7),
                          isCurved: true,
                          color: Color(0xFF0126FA),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Color(0xFF0126FA).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  '현재의 감정',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  children: emotions
                      .map((emotion) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: emotion['color'],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(128),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          emotion['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
