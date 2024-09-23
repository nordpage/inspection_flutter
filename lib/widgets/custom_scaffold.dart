import 'package:flutter/material.dart';

class CustomScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  const CustomScaffold({super.key, required this.title, required this.body});

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/priemka.png", width: 300, height: 100,),
              SizedBox(height: 24,),
              SizedBox(width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "Логин"
                    ),
                  )
              ),
              SizedBox(height: 8,),
              SizedBox(width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "Пароль"
                    ),
                  )
              ),
              SizedBox(height: 24,),
              SizedBox(
                  height: 60,
                  width: 180,
                  child: ElevatedButton(onPressed: () {}, child: Text("войти в систему"))),
              SizedBox(height: 16,),
              SizedBox(
                  height: 56,
                  width: 350,
                  child: OutlinedButton.icon(icon: Image.asset("assets/ic_question_answer.png", width: 32, height: 32,) ,onPressed: () {}, label: Text("описание возможностей приложения\nи чат со специалистом"))),
            ],
          ),
        ),
      ),
    );
  }
}
