import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

void main() {
  runApp(const MaterialApp(home: ReplayHome()));
}

class ReplayHome extends StatefulWidget {
  const ReplayHome({Key? key}) : super(key: key);

  @override
  State<ReplayHome> createState() => _ReplayHomeState();
}

class _ReplayHomeState extends State<ReplayHome> with SingleTickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> telemetry = {};
  bool loading = true;
  late AnimationController controller;
  String message = '';

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 60));
    fetchTelemetry().then((_) {
      controller.repeat();
      setState(() { loading = false; });
    }).catchError((e) {
      setState(() { message = e.toString(); loading = false; });
    });
  }

  Future<void> fetchTelemetry() async {
    final url = Uri.parse('$serverBase/session/2025/12/telemetry?lap=1&sample_ms=100');
    final resp = await http.get(url).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final tele = body['telemetry'] as Map<String, dynamic>;
      final parsed = <String, List<Map<String, dynamic>>>{};
      tele.forEach((k, v) {
        parsed[k] = (v as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
      telemetry = parsed;
    } else {
      throw Exception('Failed to fetch telemetry');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (message.isNotEmpty) {
      return Scaffold(body: Center(child: Text('Error: $message')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('F1 Replay Mobile')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: TrackPainter(telemetry, controller.value),
            child: Container(),
          );
        },
      ),
    );
  }
}

class TrackPainter extends CustomPainter {
  final Map<String, List<Map<String, dynamic>>> telemetry;
  final double t;

  TrackPainter(this.telemetry, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0B1020);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return true;
  }
}
