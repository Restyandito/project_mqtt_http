import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String broker = 'broker.emqx.io';
  final int port = 1883;
  final String topicTemperature = 'iotfrontier/temperature';
  final String topicHumidity = 'iotfrontier/humidity';
  MqttServerClient? client;
  String temperature = "Waiting...";
  String humidity = "Waiting...";

  @override
  void initState() {
    super.initState();
    connectMQTT();
    fetchHttpData();
  }

  Future<void> connectMQTT() async {
    client = MqttServerClient(broker, 'flutter_client');
    client!.port = port;
    client!.logging(on: false);
    client!.keepAlivePeriod = 60;
    client!.onConnected = () => print('Connected to MQTT Broker');
    client!.onDisconnected = () => print('Disconnected from MQTT Broker');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client!.connectionMessage = connMessage;

    try {
      await client!.connect();
    } catch (e) {
      print('MQTT Connection failed: $e');
      return;
    }

    client!.subscribe(topicTemperature, MqttQos.atMostOnce);
    client!.subscribe(topicHumidity, MqttQos.atMostOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMessage =
      messages[0].payload as MqttPublishMessage;
      final String messagePayload =
      MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      setState(() {
        if (messages[0].topic == topicTemperature) {
          temperature = messagePayload;
        } else if (messages[0].topic == topicHumidity) {
          humidity = messagePayload;
        }
      });
    });
  }

  Future<void> fetchHttpData() async {
    final response = await http.get(
        Uri.parse('http://jsonplaceholder.typicode.com/todos/1'));
    if (response.statusCode == 200) {
      print('HTTP Response: ${response.body}');
    } else {
      print('Failed to fetch HTTP data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('MQTT & HTTP Data')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Temperature: $temperature', style: TextStyle(fontSize: 20)),
              Text('Humidity: $humidity', style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchHttpData,
                child: Text('Fetch HTTP Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}