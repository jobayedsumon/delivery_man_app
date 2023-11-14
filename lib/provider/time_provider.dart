import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resturant_delivery_boy/data/model/response/order_model.dart';

class TimerProvider with ChangeNotifier {
  Duration _duration;
  Timer _timer;
  Duration get duration => _duration;

  Future<void> countDownTimer(OrderModel order, BuildContext context) async {
    DateTime _orderTime;
    try{
      _orderTime =  DateFormat("yyyy-MM-dd HH:mm:ss").parse('${order.deliveryDate} ${order.deliveryTime}');
    }catch(_){
      _orderTime =  DateFormat("yyyy-MM-dd HH:mm").parse('${order.deliveryDate} ${order.deliveryTime}');
    }
    DateTime endTime = _orderTime.add(Duration(minutes: int.parse(order.preparationTime)));

    DateTime now = DateTime.now().toUtc().add(Duration(hours: 11));
    now = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);

    _duration = endTime.difference(now);
    _timer?.cancel();
    _timer = null;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if(!_duration.isNegative && _duration.inSeconds > 0) {
        _duration = _duration - Duration(seconds: 1);
        notifyListeners();
      }

    });
    if(_duration.isNegative) {
      _duration = Duration();
    }

  }

}
