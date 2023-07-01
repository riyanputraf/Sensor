import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:oscilloscope/oscilloscope.dart';
import 'package:sensor/app_resources.dart';
import 'package:sensor/firebase_options.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class LDRData {
  final DateTime timestamp;
  final int ldrValue;

  LDRData(this.timestamp, this.ldrValue);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LDR Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'LDR Data'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference _databaseReference = FirebaseDatabase.instance.reference().child('Sensor/ldr');
  List<LDRData> _data = [];
  // late Timer _timer;
  List<double> traceData = [];
  double globalCurrentSensorValue = 0;
  List<Color> gradientColors = [
    AppColors.contentColorCyan,
    AppColors.contentColorBlue,
  ];

  double count = 0;
  late Timer _timer2;
  List<FlSpot> chartData = [];
  FlSpot mostLeftSpot = FlSpot(0, 0);
  List<DataRow> rows = [];



  @override
  void dispose() {
    super.dispose();
    _timer2.cancel();
  }
  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer2 = Timer.periodic(Duration(milliseconds: 1000), _generateTrace2);
  }
  _generateTrace2(Timer t) {
    setState(() {
      count += 1;
      double x = count;
      double y = globalCurrentSensorValue;
      FlSpot spot = FlSpot(x, y);
      chartData.add(spot);
      if (mostLeftSpot == null || spot.x < mostLeftSpot!.x) {
        mostLeftSpot = spot;
      }
      rows.add(DataRow(
        cells: <DataCell>[
          DataCell(Text(count.toString())),
          DataCell(Text(globalCurrentSensorValue.toString())),
        ],
      ),);
    });
  }

  void _fetchData() {
    _databaseReference.onChildAdded.listen((event) {
      var value = event.snapshot.value as Map<dynamic, dynamic>; // Explicitly cast value to Map

      var timestamp =
      DateTime.fromMillisecondsSinceEpoch(value['timestamp'] as int); // Cast timestamp to int
      var ldrValue = (value['ldrValue'] as num).toDouble(); // Cast ldrValue to double

      setState(() {
        _data.add(LDRData(timestamp, ldrValue.toInt()));
      });
    });
  }

  void _signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      // User is signed in, do something with the user information
      User? user = userCredential.user;
      print('Signed in anonymously: ${user?.uid}');
    } catch (e) {
      // Handle sign-in errors
      print('Sign-in error: $e');
    }
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 5:
        text = const Text('5', style: style);
        break;
      case 100:
        text = const Text('100', style: style);
        break;
      case 200:
        text = const Text('200', style: style);
        break;
      case 300:
        text = const Text('300', style: style);
        break;
      case 400:
        text = const Text('400', style: style);
        break;
      case 500:
        text = const Text('500', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text;
    switch (value.toInt()) {
      case 100:
        text = '100';
        break;
      case 500:
        text = '500';
        break;
      case 1000:
        text = '1000';
        break;
      case 1500:
        text = '1500';
        break;
      default:
        return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  Widget buildStreamBuilder(){
    LineChartData graph = LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: mostLeftSpot!.x,
      maxX: 2000,
      minY: 0,
      maxY: 2000,
      lineBarsData: [
        LineChartBarData(
          spots: chartData,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],

    );

    return Container(
      child: StreamBuilder(
        stream: _databaseReference.onValue,
        builder: (context, snapshot){
          if(snapshot.hasData && snapshot.data!.snapshot.value != null){
            print("Snapshot Data : ${snapshot.data!.snapshot.value.toString()}");
            globalCurrentSensorValue = (snapshot.data!.snapshot.value as num).toDouble();
            print(globalCurrentSensorValue);
            // print(_timer.toString());
            // count += 1 ;
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                  child: LineChart(graph),
                ),
                ),
                SizedBox(height: 15,),
                Expanded(child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                      border: TableBorder.all(width: 1),
                    columnSpacing: 80,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'Time (Second)',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),

                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'LDR Value',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ],
                    rows: rows
                  ),
                ))
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: buildStreamBuilder(),
      floatingActionButton: FloatingActionButton(
        onPressed: _signInAnonymously,
        tooltip: 'Sign In',
        child: Icon(Icons.login),
      ),
    );
  }

  List<charts.Series<LDRData, DateTime>> _createData() {
    return [
      charts.Series<LDRData, DateTime>(
        id: 'LDR',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LDRData data, _) => data.timestamp,
        measureFn: (LDRData data, _) => data.ldrValue,
        data: _data,
      ),
    ];
  }
}
