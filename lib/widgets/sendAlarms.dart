import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:intl/intl.dart';
import 'dart:collection'; 

class SendAlarms extends StatefulWidget {
  final MqttClient client;
  final List<String> alarms;
  
  const SendAlarms({Key key, @required this.client, @required this.alarms}) : super(key: key);
  
  @override
  _SendAlarmsState createState() => _SendAlarmsState();
}

class _SendAlarmsState extends State<SendAlarms> {

TextEditingController textModeController = TextEditingController();
  String _messageContent;
  String _realPayload = "";
  String _topicContent = 'IoZpYfJVmF/in/alarms';
  bool _saveNeeded = false;
  bool _hasMessage = false;

  DateTime _dateTime = DateTime.now();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Alarm'), 
        actions: <Widget>[
          FlatButton(
            child: Text(
              'ADD', 
              style: theme.textTheme.bodyText1.copyWith(color: Colors.grey)),
            onPressed: () {
              if(_formKey.currentState.validate()) {
                _formKey.currentState.save();

                for(var alarm in widget.alarms){
                  _realPayload += alarm;
                }

                _realPayload += _messageContent;

                print("-- REAL PAYLOAD -- : " + _realPayload);
                _sendMessage();

              }
            },
          )
        ]),
        body: Form(
          key: _formKey,
          onWillPop: _onWillPop,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(
                  border: Border.all()
                ),
                child: TimePickerSpinner(
                  is24HourMode: true,
                  normalTextStyle: TextStyle(
                    color: Colors.grey
                    
                  ),
                  highlightedTextStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  spacing: 10,
                  itemHeight: 30,
                  isForce2Digits: true,
                
                  onTimeChange: (time) {
                    setState(() {
                      _dateTime = time;
                      String formattedTime = DateFormat.Hm().format(_dateTime); 
                      String hour = formattedTime.replaceAll(':', '');
                      _messageContent = hour;
                    });
                  },
                ),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 alignment: Alignment.bottomLeft,
                 child: TextFormField(
                   controller: textModeController,
                   decoration: const InputDecoration(
                     labelText: 'Enter Alarm Mode: On 1 - Off 0',
                     ),
                    validator: validateMode,
                    onSaved: (String value) {
                      setState(() {
                        if(value == '0') {
                          _messageContent += value;
                        } else if(value == '1') {
                          _messageContent += value;
                        } 
                        _hasMessage = true;
                        _saveNeeded = true;
                        print(_messageContent);
                      });
                    },
                 ),
              )
            ],
          ),
        ),
    );
  }
  String validateMode(String value) {
    if(value.isEmpty) {
      return 'Please enter valid text, Only 0 or 1';
    } 
    return null;
  }

  Future<bool> _onWillPop() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subtitle1.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('Discard alarm?', style: dialogTextStyle),
          actions: <Widget>[
            FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              }
            ),
            FlatButton(
              child: const Text('DISCARD'),
              onPressed: () {
                Navigator.of(context).pop(true);
              }
            )
          ],
        );
      },
    ) ?? false;
  }

  void _sendMessage(){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();

    builder.addString(_realPayload);
    widget.client.publishMessage(
      _topicContent, 
      MqttQos.values[0], 
      builder.payload);
    Navigator.pop(context, _messageContent);
  }
  
}
