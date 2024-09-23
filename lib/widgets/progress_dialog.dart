import 'package:flutter/material.dart';

class ProgressDialog {
  static void show(BuildContext context, String message, int durationInSeconds, VoidCallback onComplete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                  message,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Закрытие диалога после указанного времени
    Future.delayed(Duration(seconds: durationInSeconds), () {
      Navigator.of(context).pop();  // Закрываем диалог
      onComplete();  // Вызываем Callback
    });
  }
}
