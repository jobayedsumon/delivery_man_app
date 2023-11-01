import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resturant_delivery_boy/data/model/response/base/api_response.dart';
import 'package:resturant_delivery_boy/data/model/response/base/error_response.dart';
import 'package:resturant_delivery_boy/provider/splash_provider.dart';
import 'package:resturant_delivery_boy/view/screens/auth/login_screen.dart';

class ApiChecker {
  static void checkApi(BuildContext context, ApiResponse apiResponse) {
    String _message;
    if(apiResponse.error is String) {
      _message = apiResponse.error;
    }else{
      _message = ErrorResponse.fromJson(apiResponse.error).errors[0].message;
    }

    if((_message == 'Unauthenticated.' || _message == 'Invalid token!')) {
      Provider.of<SplashProvider>(context, listen: false).removeSharedData();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false);
    }else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }
}