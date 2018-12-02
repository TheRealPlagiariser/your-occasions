
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:youroccasions/models/user.dart';
import 'package:youroccasions/controllers/user_controller.dart';
import 'package:youroccasions/utilities/validator..dart';

final UserController _userController = UserController();
List<User> userList = [];

class SignUpWithEmailScreen extends StatefulWidget {
  @override
  _SignUpWithEmailScreen createState() => _SignUpWithEmailScreen();
}

class _SignUpWithEmailScreen extends State<SignUpWithEmailScreen> {
  TextEditingController firstNameController;
  TextEditingController lastNameController;
  TextEditingController emailController;
  TextEditingController passwordController;
  TextEditingController password2Controller;
  FocusNode firstNameNode;
  FocusNode lastNameNode;
  FocusNode emailNode;
  FocusNode passwordNode;
  FocusNode password2Node;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _emailKey = GlobalKey<FormFieldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isDuplicatedEmail;


  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    password2Controller = TextEditingController();

    firstNameNode = FocusNode();
    lastNameNode = FocusNode();
    emailNode = FocusNode();
    passwordNode = FocusNode();
    password2Node = FocusNode();

    _isDuplicatedEmail = false;
  }

  @override
  void dispose() {
    // Clean up the controllers when the Widget is removed from the Widget tree
    super.dispose();
    firstNameNode.dispose();
    lastNameNode.dispose();
    emailNode.dispose();
    passwordNode.dispose();
    password2Node.dispose();
    
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    password2Controller.dispose();
  }

  String _validateEmail(String input) {
    if (_isDuplicatedEmail) {
      _isDuplicatedEmail = false;
      return "The email address is already in use by another account";
    }
    
    if (!isEmail(input)) {
      return "Invalid Email";
    }

    return null;
  }

  void _submit() async {
    if (!this._formKey.currentState.validate()) {
      this._formKey.currentState.save();
      // Validate failed
      print("Invalid login");
      return;
    }

    this._formKey.currentState.save();

    try {
      var userFirebase = await _auth.createUserWithEmailAndPassword(
        email: emailController.text, 
        password: passwordController.text);

      String name = "${firstNameController.text} ${lastNameController.text}";

      User newUser = User(id: userFirebase.uid, email: userFirebase.email, provider: "password", name: name);
      await _userController.insert(newUser)
        .then((value) {
          print("Your account is created successfully!");
        }, onError: (e) {
          print("Sign up with email failed");
          print("error $e");
        }
      );
      // String id = userFirebase.uid;

      Navigator.of(context).pop();

      print(_auth.currentUser());

    } on PlatformException catch (e) {
      print("Error occurs: \n${e.toString()}");
      
      switch (e.message) {
        case "The email address is already in use by another account.":
          print("The email address is already in use by another account.");
          FocusScope.of(context).requestFocus(emailNode);
          _isDuplicatedEmail = true;
          this._emailKey.currentState.validate();
          break;
      }
    }
  }

  Widget _buildSignUpButton() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5 + 10,
      height: 40,
      child: FlatButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(45))),
        color: Colors.blue,
        onPressed: _submit,
        // color: Colors.lightBlueAccent,
        child: Text('SIGN UP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFirstNameInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5,
      child: TextFormField(
        focusNode: firstNameNode,
        controller: firstNameController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        validator: (name) => isName(name) ? null : "Invalid",
        autofocus: false,
        onFieldSubmitted: (term) {
          emailNode.unfocus();
          FocusScope.of(context).requestFocus(lastNameNode);
        },
        decoration: InputDecoration(
          labelText: "FIRST NAME",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)
        ),
      ));
  }

  Widget _buildLastNameInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5,
      child: TextFormField(
        focusNode: lastNameNode,
        controller: lastNameController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        validator: (name) => isName(name) ? null : "Invalid",
        autofocus: false,
        onFieldSubmitted: (term) {
          emailNode.unfocus();
          FocusScope.of(context).requestFocus(emailNode);
        },
        decoration: InputDecoration(
          labelText: "LAST NAME",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)
        ),
      ));
  }

  Widget _buildEmailInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5,
      child: TextFormField(
        key: _emailKey,
        focusNode: emailNode,
        controller: emailController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
        autofocus: false,
        onFieldSubmitted: (term) {
          emailNode.unfocus();
          FocusScope.of(context).requestFocus(passwordNode);
        },
        decoration: InputDecoration(
          labelText: "EMAIL",
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          errorMaxLines: 2
        ),
      ));
  }

  Widget _buildPasswordInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5,
      child: TextFormField(
        focusNode: passwordNode,
        controller: passwordController,
        autofocus: false,
        validator: (password) => isPassword(password) ? null : "Invalid",
        textInputAction: TextInputAction.next,
        obscureText: true,
        onFieldSubmitted: (term) {
          emailNode.unfocus();
          FocusScope.of(context).requestFocus(password2Node);
        },
        decoration: InputDecoration(
          labelText: "PASSWORD",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)
        )),
    );
  }

  Widget _buildPassword2Input() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width / 1.5,
      child: TextFormField(
        focusNode: password2Node,
        controller: password2Controller,
        autofocus: false,
        validator: (password) => isPassword(password) ? null : "Invalid",
        textInputAction: TextInputAction.done,
        obscureText: true,
        decoration: InputDecoration(
          labelText: "COMFIRM PASSWORD",
          labelStyle: TextStyle(fontWeight: FontWeight.bold)
        )),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return new Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () { Navigator.of(context).pop(); },
          icon: Icon(Icons.arrow_back, color: Colors.black,),
        ),
        // title: Text("Sign Up"),
      ),
      body: ListView(
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                SizedBox(height: screen.height * 0.1,),
                _buildFirstNameInput(),
                _buildLastNameInput(),
                _buildEmailInput(),
                _buildPasswordInput(),
                _buildPassword2Input(),
                SizedBox(height: screen.height * 0.05,),
                _buildSignUpButton(),
              ],
            ),
          ),
        ]
      )
    );
  }
}

bool isPasswordMatched(String password, String passwordRetype) {
  if (password == passwordRetype) {
    return true;
  }
  return false;
}
