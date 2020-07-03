import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iotapp/providers/theme_provider.dart';
import 'package:iotapp/widgets/sendAlarms.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

// void main() => runApp(MyApp());
void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(isLightTheme: true),
    child: MyApp(),
  ));
}

/// This Widget is the main application widget.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PageController _pageController;
  int _currentPage = 0;

  String broker = 'broker.hivemq.com';
  int port = 1883;
  String topicState = 'IoZpYfJVmF/in/bulbState';
  String messageStateOn = 'on';
  String messageStateOff = 'off';
  String topicAutoWeather = 'IoZpYfJVmF/in/autoWeather';
  String topicAutoLocal = 'IoZpYfJVmF/in/autoLocal';
  String messageAutoOn = 'enabled';
  String messageAutoOff = 'disabled';
  String topicAlarms = 'IoZpYfJVmF/in/alarms';

  MqttClient client;
  MqttConnectionState connectionState;

  StreamSubscription subscription;

  TextEditingController brokerController = TextEditingController();
  TextEditingController topicController = TextEditingController();

  List<String> alarms = <String>[];
  ScrollController alarmController = ScrollController();

  bool _autoWeather = false;
  bool _autoLocal = false;
  bool _light = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    IconData connectionStateIcon;
    switch (client?.connectionState) {
      case MqttConnectionState.disconnecting:
        connectionStateIcon = Icons.cloud_off;
        break;
      case MqttConnectionState.disconnected:
        connectionStateIcon = Icons.cloud_download;
        break;
      case MqttConnectionState.connecting:
        connectionStateIcon = Icons.cloud_upload;
        break;
      case MqttConnectionState.faulted:
        connectionStateIcon = Icons.error_outline;
        break;
      case MqttConnectionState.connected:
        connectionStateIcon = Icons.cloud_done;
        break;
      default:
        connectionStateIcon = Icons.cloud_off;
    }
    void navigationTapped(int page) {
      _pageController.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }

    void onPageChanged(int page) {
      setState(() {
        this._currentPage = page;
      });
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getThemeData,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('MyLamp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 23,
                      color: Colors.grey)),
              SizedBox(width: 8.0),
              Icon(connectionStateIcon, color: Colors.grey)
            ],
          ),
        ),
        floatingActionButton: _currentPage == 2
            ? Builder(builder: (BuildContext context) {
                return FloatingActionButton(
                  backgroundColor: Colors.greenAccent[400],
                  child: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute<String>(
                          builder: (BuildContext context) =>
                              SendAlarms(client: client, alarms: alarms),
                          fullscreenDialog: true,
                        )).then((value) {
                      if (value == null) {
                        print('aqui hay algo raro');
                      } else {
                        setState(() {
                          alarms.add(value);
                          print(alarms);
                        });
                      }
                    });
                  },
                );
              })
            : null,
        bottomNavigationBar: BottomNavigationBar(
          onTap: navigationTapped,
          currentIndex: _currentPage,
          fixedColor: Colors.lightBlue,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), title: Text('Settings')),
            BottomNavigationBarItem(
                icon: Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: Icon(Icons.alarm), title: Text('Alarms'))
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: onPageChanged,
          children: <Widget>[
            _buildSettingsPage(connectionStateIcon),
            _buildMainPage(),
            _buildAlarmsPage()
          ],
        ),
      ),
    );
  }

  Column _buildSettingsPage(IconData connectionStateIcon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: const Text('Dark Mode'),
          //activeTrackColor: Colors.greenAccent[400],
          //inactiveTrackColor: Colors.grey,

          value: themeProvider.isLightTheme,
          onChanged: (val) {
            themeProvider.setThemeData = val;
          },
          secondary: const Icon(Icons.brightness_3),
        ),
        Container(
          child: Row(
            children: [],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: TextField(
            style: TextStyle(
                fontSize: 16.0, color: Colors.grey, fontFamily: 'OpenSans'),

            controller: brokerController,

            decoration: InputDecoration(

                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 3.0),
                ),

                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 3.0),
                ),

                labelText: 'Broker Address',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'broker.hivemq.com'),

          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: RaisedButton(
            child: Text(client?.connectionState == MqttConnectionState.connected
                ? 'Disconnect'
                : 'Connect'),
            onPressed: () {
              if (brokerController.value.text.isNotEmpty) {
                broker = brokerController.value.text;
              }
              if (client?.connectionState == MqttConnectionState.connected) {
                _disconnect();
              } else {
                _connect();
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Text(
            'On Port: ' + brokerController.value.text + ':' + port.toString(),
            style: TextStyle(
                fontSize: 24.0, color: Colors.grey, fontFamily: 'OpenSans'),
          ),
        ),
      ],
    );
  }

  Column _buildMainPage() {
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: const Text('Automatic Weather Mode'),
          activeTrackColor: Colors.greenAccent[400],
          inactiveTrackColor: Colors.grey,
          value: _autoWeather,
          onChanged: (bool value) {
            setState(() {
              if (_autoWeather == true) {
                _sendTopicMessage(topicAutoWeather, messageAutoOn);
                _autoWeather = value;
              } else if (_autoWeather == false) {
                _sendTopicMessage(topicAutoWeather, messageAutoOff);
                _autoWeather = value;
              }
            });
          },
          secondary: const Icon(Icons.cloud_queue),
        ),
        SwitchListTile(
          title: const Text('Automatic Mode'),
          activeTrackColor: Colors.greenAccent[400],
          inactiveTrackColor: Colors.grey,
          value: _autoLocal,
          onChanged: (bool value) {
            setState(() {
              if (_autoLocal == true) {
                _sendTopicMessage(topicAutoLocal, messageAutoOn);
                _autoLocal = value;
              } else if (_autoLocal == false) {
                _sendTopicMessage(topicAutoLocal, messageAutoOff);
                _autoLocal = value;
              }
            });
          },
          secondary: const Icon(Icons.wb_incandescent),
        ),
        Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Container(
                margin: const EdgeInsets.only(top: 10.0),
                child: RaisedButton(
                  color: _light ? Colors.greenAccent[400] : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80)),
                  padding: const EdgeInsets.all(100),
                  onPressed: () {
                    setState(() {
                      _light = !_light;
                      if (_light == true) {
                        _sendTopicMessage(topicState, messageStateOn);
                      } else {
                        _sendTopicMessage(topicState, messageStateOff);
                      }
                    });
                  },
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white70,
                    size: 50,
                  ),
                ))
          ],
        ),
      ],
    );
  }

  Column _buildAlarmsPage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: alarmController,
            children: _buildAlarmList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
            child: Text('Clear All Alarms'),
            onPressed: () {
              setState(() {
                alarms.clear();
                _sendTopicMessage(topicAlarms, 'none');
              });
            },
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  List<Widget> _buildAlarmList() {
  
    return alarms
         
        .map((String alarm) => Card(
              color: Colors.green[200],
              child: ListTile(
                
                title: _builAlarmMessageText(alarm),
                subtitle: _builAlarmModeText(alarm),
              ),
            ))
        .toList()
        .reversed
        .toList();

        
  }

  Text _builAlarmMessageText(String alarm) {
    String titleMessage = alarm[0] + alarm[1] + ':' + alarm[2] + alarm[3];
    return Text(titleMessage);
  }

  Text _builAlarmModeText(String alarm) {
    String subtitleMessage;
    if (alarm[4] == '1') {
      subtitleMessage = 'Light Mode On';
    } else if (alarm[4] == '0') {
      subtitleMessage = 'Light Mode Off';
    }
    return Text(subtitleMessage);
  }

  void _connect() async {
    client = MqttClient(broker, '');
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 3600;
    client.onDisconnected = _onDisconnected;

    final MqttMessage connMessage = MqttConnectMessage()
        .withClientIdentifier('MyLampApp123')
        .startClean()
        .keepAliveFor(3600);
    client.connectionMessage = connMessage;

    try {
      await client.connect('', '');
    } catch (e) {
      print(e);
      _disconnect();
    }

    if (client.connectionState == MqttConnectionState.connected) {
      print('MQTT Client connected');
      setState(() {
        connectionState = client.connectionState;
      });
    } else {
      print('ERROR: MQTT client connection failed.');
      _disconnect();
    }
  }

  void _disconnect() {
    client.disconnect();
    _onDisconnected();
  }

  void _sendTopicMessage(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.values[0], builder.payload);
  }

  void _onDisconnected() {
    setState(() {
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('MQTT client disconnected');
  }
}
