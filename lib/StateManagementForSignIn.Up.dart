import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum Status { unInitialized, authenticated, authenticating, unAuthenticated }

class StateManagement with ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  Status _status = Status.unInitialized;
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final FirebaseFirestore _firebaseFireStore = FirebaseFirestore.instance;
  MySet savedData = MySet();
  Set<WordPair> finalData = {};
  String _email = '';
  String _password = '';
  final FirebaseStorage _fireBaseStorage = FirebaseStorage.instance;

  StateManagement.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;
  Set<WordPair> get saved => savedData.saved;
  List<WordPair> get suggestions => savedData.suggestions;
  bool get isAuthenticated => status == Status.authenticated;
  String get email => _email;
  String get password => _password;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      _email = email;
      _password = password;
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _status = Status.unAuthenticated;
      _email = '';
      _password = '';
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      finalData = (await getFutureData())!;
      _email = email;
      _password = password;
      return true;
    } catch (e) {
      _status = Status.unAuthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.unAuthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.unAuthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.authenticated;
    }
    notifyListeners();
  }
  Future<void> addUser(Set<WordPair> favorites) {
    // Call the user's CollectionReference to add a new user
    return users
        .add({
      'Saved_favorites': favorites.map((wp) => wp.asPascalCase).toList(), // John Doe
    });
  }
  Future<void> updateFavorite(WordPair pair, bool delete) async {
     delete?
     await _firebaseFireStore.collection('users')
         .doc(_user!.uid)
         .collection('Saved Suggestions')
         .doc(pair.toString()).delete():
     await _firebaseFireStore.collection('users').doc(_user!.uid)
          .collection('Saved Suggestions')
          .doc(pair.toString())
          .set({'first': pair.first, 'second': pair.second});
     notifyListeners();
    }
  Future<void> updateFavorites(Set<WordPair> pairs) async {
    for (var pair in pairs) {
       await _firebaseFireStore.collection('users').doc(_user!.uid)
           .collection('Saved Suggestions')
           .doc(pair.toString())
           .set({'first': pair.first, 'second': pair.second});
    }
    notifyListeners();
  }

    Future<Set<WordPair>?> getFutureData() async {
      Set<WordPair> savedSuggestions = <WordPair>{};
      String first, second;
      await _firebaseFireStore.collection('users')
          .doc(_user!.uid)
          .collection('Saved Suggestions')
          .get()
          .then((querySnapshot) {
        for (var result in querySnapshot.docs) {
          first = result.data().entries.first.value.toString();
          second = result.data().entries.last.value.toString();
          savedSuggestions.add(WordPair(first, second));
        }
      });
      return Future<Set<WordPair>>.value(savedSuggestions);
    }
  void insertToSuggestions(WordPair pair){
   savedData.insertToSuggestions(pair);
  }
  void addTotalSuggestions(Iterable<WordPair> pairs) {
    savedData.addTotalSuggestions(pairs);
  }
  void addTotalSaved(Set<WordPair> pairs) {
    savedData.addTotalSaved(pairs);
  }
  void deleteFromSaved(WordPair pair){
    savedData.deleteFromSaved(pair);
  }
  void addToSaved(WordPair pair){
   savedData.addToSaved(pair);
    }
  Set<WordPair> getFinalData(){
    return finalData;
  }
}
class MySet{
  final _saved = <WordPair>{};
  final _suggestions = <WordPair>[];

  Set<WordPair> get saved => _saved;
  List<WordPair> get suggestions => _suggestions;

  void addToSaved(WordPair pair){
    if(_saved.contains(pair) == false) {
      _saved.add(pair);
    }
  }
  void addToSuggestions(WordPair pair){
    if(_suggestions.contains(pair) == false) {
      _suggestions.add(pair);
    }
  }
  void insertToSuggestions(WordPair pair){
    if(_suggestions.contains(pair) == false) {
      _suggestions.insert(0, pair);
    }
  }
  void deleteFromSaved(WordPair pair){
      _saved.remove(pair);
  }
  void deleteFromSuggestions(WordPair pair){
      _suggestions.remove(pair);
  }
  void addTotalSuggestions(Iterable<WordPair> pairs) {
    _suggestions.addAll(pairs);
  }
  void addTotalSaved(Set<WordPair> pairs) {
    _saved.addAll(pairs);
  }

}
