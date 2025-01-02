import 'package:flutter/material.dart';
import 'register_driver_screen.dart'; // 새로 만든 파일 import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You can navigate to the driver registration screen.'),
            ElevatedButton(
              onPressed: () {
                // RegisterDriverScreen으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterDriverScreen(),
                  ),
                );
              },
              child: const Text('운전자 등록 페이지로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
