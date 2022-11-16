// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'StateManagementForSignIn.Up.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

//comment
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}


class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
   App({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

late StateManagement firebaseUser;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StateManagement>(
      create: (_) => StateManagement.instance(),
      child: Consumer<StateManagement>(
        builder: (context, login, _) =>
            MaterialApp(
              title: 'Startup Name Generator',
              theme: ThemeData(
                  primaryColor: Colors.deepPurple,
                  primarySwatch: Colors.deepPurple,
              ),
              // home: LoginScreen(),
              home: const RandomWords(),
            ),
      ),
    );
  }
}

class _RandomWordsState extends State<RandomWords> {
  final snappingSheetController = SnappingSheetController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    firebaseUser = Provider.of<StateManagement>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  const SavedSuggestions()),
              );
            },
            tooltip: 'Saved Suggestions',
          ),
          firebaseUser.isAuthenticated?
          IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: (){
                firebaseUser.signOut();
                const snackBar = SnackBar(
                  content: Text('Successfully logged out'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                Navigator.of(context).popUntil((route) => route.isFirst);
                },
              tooltip: 'Logged_in screen',
            ) :
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  const LogIn()),
              );
            },
            tooltip: 'Login',
          ),
        ],
      ),
      body: firebaseUser.isAuthenticated?
          SnappingSheet(
            grabbingHeight: 75,
            grabbing: Grabbing(firebaseUser:firebaseUser),
            sheetBelow: SnappingSheetContent(
              childScrollController: _scrollController,
                  draggable: true,
                  child: Container(
                    color: Colors.white,
                    child:
                    Column(
                      children:<Widget>[
                        Row(
                          children:  <Widget>[
                            Column(
                              children:  <Widget>[
                                Text(firebaseUser.email),
                                const SizedBox(
                                  height: 10,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () async {},
                                  child: const Text('Change avatar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Flexible(
                          fit: FlexFit.tight,
                          flex: 1,
                          child: Container(
                              color: Colors.white
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                controller: snappingSheetController,
            child: const Main(),
          )
      : const Main()
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key});
  @override
  State<RandomWords> createState() => _RandomWordsState();
}


///***********CLASS LOGIN***********////
class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  LogInScreen createState() => LogInScreen();
}

class LogInScreen extends State<LogIn>{

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<StateManagement>(context);
    TextEditingController nameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController passwordConfirm = TextEditingController();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
            child: ListView(
              children: <Widget>[
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      'Welcome to Startup Names Generator, please log in',
                      style: TextStyle(fontSize: 10),
                    )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                firebaseUser.status == Status.authenticating?
                const Center(child: CircularProgressIndicator())
                :Container(
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ElevatedButton(
                     child: const Text('Login'),
                    onPressed: () async {
                        bool res = await firebaseUser.signIn(nameController.text.trim(), passwordController.text.trim());
                        if (!mounted) return;
                        if(res){
                          Set<WordPair>? newSet = firebaseUser.getFinalData();
                          firebaseUser.updateFavorites(firebaseUser.saved);
                          firebaseUser.addTotalSaved(newSet);
                          for(var pair in newSet){
                            if(firebaseUser.suggestions.contains(pair) == false){
                              firebaseUser.insertToSuggestions(pair);
                            }
                          }
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                        else{
                          const snackBar = SnackBar(
                            content: Text('There was an error logging into the app'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(
                      child: const Text('New user? Click to Sign up'),
                      onPressed: () async{
                        showModalBottomSheet<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AnimatedPadding(
                                  padding: MediaQuery
                                      .of(context)
                                      .viewInsets,
                                  duration: const Duration(milliseconds: 2),
                                  child: SizedBox(
                                      height: 200,
                                      child: Center(
                                          child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                          const Text('Please confirm your password below:'),
                                          TextField(
                                              controller: passwordConfirm,
                                              obscureText: true,
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.fromLTRB(
                                                    20.0, 20.0, 20.0, 20.0),
                                                labelText: 'Password',
                                                errorText: (passwordConfirm.text != passwordController.text) ? 'Passwords must  match' : null,
                                              )
                                          ),
                                                ElevatedButton(
                                                    onPressed: () async {
                                                      UserCredential? newUser;
                                                      if(passwordController.text == passwordConfirm.text) {
                                                        newUser = await firebaseUser.signUp(nameController.text.trim(), passwordController.text.trim());
                                                      }
                                                      if (!mounted) return;
                                                      if(newUser == null){
                                                        const snackBar = SnackBar(
                                                          content: Text('There was an error signing up to the app'),
                                                        );
                                                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                      }
                                                      else{
                                                        const snackBar = SnackBar(
                                                          content: Text('You were signed up successfully'),
                                                        );
                                                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                        firebaseUser.updateFavorites(firebaseUser.saved);
                                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                                      }
                                                    },
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                                  child: const Text("confirm"),
                                                )
                                              ]
                                          ),
                                      ),
                                  ),
                              );
                            }
                        );
                      },
                    )
                ),
              ],
            )
        )
    );
  }
}


///***********CLASS SAVED SUGGESTIONS***********////
class SavedSuggestions extends StatefulWidget {
  const SavedSuggestions({super.key});

  @override
  SavedSuggestionsScreen createState() => SavedSuggestionsScreen();
}
class SavedSuggestionsScreen extends State<SavedSuggestions> {
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<StateManagement>(context);
    final tiles = firebaseUser.saved.map(
          (pair) {
        return ListTile(
          title: Text(
            pair.asPascalCase,
            style: _biggerFont,
          ),
        );
      },
    );
    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList()
        : <Widget>[];
    return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Suggestions'),
        ),
        body: ListView.separated(
          itemCount: divided.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              background: Container(
                color: Colors.deepPurple,
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    children:const [
                      Icon(Icons.delete, color: Colors.white),
                      Text('  Delete suggestion',
                          style: TextStyle(fontSize: 20, color: Colors.white))],
                  ),
                ),
              ),
              key: ValueKey<Widget>(divided.elementAt(index)),
              confirmDismiss: (DismissDirection direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Delete Confirmation"),
                      content: Text("Are you sure you want to delete ${firebaseUser.suggestions[index].asPascalCase.toString()} from your saved suggestions?"),
                      actions: <Widget>[
                        ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Yes")
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("No"),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (DismissDirection direction) {
                setState(() {
                  firebaseUser.deleteFromSaved(firebaseUser.suggestions[index]);
                  if(firebaseUser.isAuthenticated) {
                    firebaseUser.updateFavorite(firebaseUser.suggestions[index],true);
                  }
                });
              },
              child: buildListTile(divided.elementAt(index)),
            );
          },
        )
    );
  }
  Widget buildListTile(Widget item) =>
      ListTile(
        title: Column(
          children: [item],
        ),
      );
}



///******** MainScreen Class **********////
class Main extends StatefulWidget {
  const Main({super.key});

  @override
  MainScreen createState() => MainScreen();
}

class MainScreen extends State<Main> {
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<StateManagement>(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return const Divider();
        final index = i ~/ 2;
        if (index >= firebaseUser.saved.length) {firebaseUser.addTotalSuggestions(generateWordPairs().take(10));
        }
        final alreadySaved = firebaseUser.saved.contains(firebaseUser.suggestions[index]) ;
        return ListTile(
          title: Text(
            firebaseUser.suggestions[index].asPascalCase,
            style: _biggerFont,
          ),
          trailing: Icon(
            alreadySaved ? Icons.favorite : Icons.favorite_border,
            color: alreadySaved ? Colors.red : null,
            semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
          ),
          onTap: () {
            setState(() {
              if (alreadySaved) {
                firebaseUser.deleteFromSaved(firebaseUser.suggestions[index]);
                if(firebaseUser.isAuthenticated){
                  firebaseUser.updateFavorite(firebaseUser.suggestions[index],true);
                }
              } else {
                firebaseUser.addToSaved(firebaseUser.suggestions[index]);
                if(firebaseUser.isAuthenticated){
                  firebaseUser.updateFavorite(firebaseUser.suggestions[index],false);
                }
              }
            });
          },
        );
      },
    );
  }
}

class Grabbing extends StatelessWidget {

  const Grabbing(
      {Key? key,required firebaseUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      InkWell(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                spreadRadius: 10,
                color: Colors.black.withOpacity(0.15),
              )
            ],
            /*  borderRadius: _getBorderRadius(),*/
            color: Colors.grey,
          ),
          child: Transform.rotate(
            angle: 0,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.5),
                  child: Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(10),
                    child:  Row( children :  <Widget> [Text(" Welcome back, ${firebaseUser.email}",
                      style: const TextStyle(fontSize: 16.0),
                      // textAlign: TextAlign.center,
                    ),
                      Expanded(
                        child: Container(
                          color: Colors.grey,
                          width: 100,
                        ),
                      ),
                      IconButton(
                          onPressed:() {
                      }, icon: const Icon(Icons.expand_less )),]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap:() => SnappingSheetController().snapToPosition(
          const SnappingPosition.factor(positionFactor: 0.21),
        ) ,
      );
  }
}
