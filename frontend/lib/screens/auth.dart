import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:frontend/screens/vendor_home.dart';
import 'package:frontend/screens/customer_home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isAuthenticating = false;
  String _role = 'customer';
  String _enteredEmail = '';
  String _enteredPassword = '';
  String _enteredUsername = '';
  String _enteredPhoneNumber = '';
  String _enteredBusinessName = '';
  String _enteredBusinessDescription = '';

  void _clearFields() {
    setState(() {
      _enteredEmail = '';
      _enteredPassword = '';
      _enteredUsername = '';
      _enteredPhoneNumber = '';
      _enteredBusinessName = '';
      _enteredBusinessDescription = '';
    });
    _form.currentState?.reset();
  }

  final _dio = Dio();

  Future<void> _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    _form.currentState!.save();
    setState(() {
      _isAuthenticating = true;
    });

    final url =
        _isLogin
            ? 'http://localhost:8000/api/user/login'
            : 'http://localhost:8000/api/user/register';

    final requestData = {
      "email": _enteredEmail,
      "password": _enteredPassword,
      "role": _role,
    };

    if (!_isLogin) {
      if (_role == "vendor") {
        requestData.addAll({
          "name": _enteredUsername,
          "phone": _enteredPhoneNumber,
          "businessName": _enteredBusinessName,
          "businessDescription": _enteredBusinessDescription,
        });
      } else {
        requestData.addAll({
          "name": _enteredUsername,
          "phone": _enteredPhoneNumber,
        });
      }
    }

    try {
      final response = await _dio.post(url, data: requestData);
       debugPrint("API Response: ${response.data}");

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData == null || !responseData.containsKey("success")) {
          throw Exception("Invalid response from server.");
        }

        if (responseData["success"]) {
          if (!mounted) return;

          if (_isLogin) {
            if (responseData["user"] == null ||
                !responseData["user"].containsKey("role")) {
              throw Exception("Invalid user data received.");
            }
            String userRole = responseData["user"]["role"];

            if (userRole == "vendor") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => VendorHome()),
              );
            } else if (userRole == "customer") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CustomerHome()),
              );
            }
          } else {
            debugPrint("Signup successful! Please log in.");
            setState(() {
              _isLogin = true;
              _clearFields();
            });
          }
        } else {
          debugPrint(responseData["message"]);
        }
      } else {
        debugPrint(
          "Unexpected response code: ${response.statusCode} - ${response.data}",
        );
      }
    } on DioException catch (e) {
      debugPrint("Dio Error: ${e.response?.data}");
    } catch (error) {
      debugPrint("Authentication failed: $error");
    }

    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(title: const Text('Get Started')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Radio(
                                      value: 'customer',
                                      groupValue: _role,
                                      onChanged: (value) {
                                        setState(() {
                                          _role = value as String;
                                          _clearFields();
                                        });
                                      },
                                    ),
                                    const Text('Customer'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio(
                                      value: 'vendor',
                                      groupValue: _role,
                                      onChanged: (value) {
                                        setState(() {
                                          _role = value as String;
                                          _clearFields();
                                        });
                                      },
                                    ),
                                    const Text('Vendor'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          TextFormField(
                            key: ValueKey('email'),
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin) ...[
                            TextFormField(
                              key: ValueKey('name'),
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length < 4) {
                                  return 'Enter at least 4 characters.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                            TextFormField(
                              key: ValueKey('phone'),
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().length < 10) {
                                  return 'Enter a valid phone number.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPhoneNumber = value!;
                              },
                            ),
                            if (_role == 'vendor') ...[
                              TextFormField(
                                key: ValueKey('businessName'),
                                decoration: const InputDecoration(
                                  labelText: 'Business Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter a business name.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredBusinessName = value!;
                                },
                              ),
                              TextFormField(
                                key: ValueKey('businessDescription'),
                                decoration: const InputDecoration(
                                  labelText: 'Business Description',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter a business description.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredBusinessDescription = value!;
                                },
                              ),
                            ],
                          ],
                          TextFormField(
                            key: ValueKey('password'),
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 20),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              ),
                              onPressed: _submit,
                              child: Text(_isLogin ? 'Login' : 'Sign Up'),
                            ),
                          const SizedBox(height: 20),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _clearFields();
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? 'Create an Account'
                                    : 'I already have an account',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
