import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        shadowColor: Colors.transparent,
      ),
      body: Container(
        color: Theme.of(context).primaryColorLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Вход',
                style: Theme.of(context).textTheme.headline4.copyWith(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.0),
              Card(
                margin: const EdgeInsets.all(32.0),
                elevation: 6.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Логин или ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        obscureText: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 18, 18, 0),
                        child: RaisedButton(
                          color: Theme.of(context).primaryColor,
                          elevation: 6.0,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text('Войти'),
                          ),
                          onPressed: () {
                            // TODO: Handle action
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 18.0),
                child: Text(
                  'или войти используя',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.red,
                    icon: FaIcon(FontAwesomeIcons.google),
                    onPressed: () {
                      // TODO: Handle action click
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.blueAccent,
                    icon: FaIcon(FontAwesomeIcons.vk),
                    onPressed: () {
                      // TODO: Handle action click
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.orange,
                    icon: FaIcon(FontAwesomeIcons.odnoklassniki),
                    onPressed: () {
                      // TODO: Handle action click
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.indigo,
                    icon: FaIcon(FontAwesomeIcons.facebook),
                    onPressed: () {
                      // TODO: Handle action click
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton(
                      child: Text('Восстановить доступ'),
                      onPressed: () {
                        // TODO: Handle button click
                      },
                    ),
                    Text(
                      'или',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    FlatButton(
                      child: Text('Зарегистрироваться'),
                      onPressed: () {
                        // TODO: Handle button click
                      },
                    ),Text(
                      '?',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
