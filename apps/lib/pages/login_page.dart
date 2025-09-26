// lib/pages/login_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_diet_app/api/api_client.dart';
import 'package:flutter_diet_app/auth_repo.dart';

class LoginPage extends StatefulWidget {
  final ApiClient api;
  const LoginPage({super.key, required this.api});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = AuthRepo(widget.api);
    try {
      await repo.login(email: _email.text.trim(), password: _pw.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response?.data['detail'] ?? 'Login failed') : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                child: const Text("Don't have an account? Sign up"),
              )
            ],
          ),
        ),
      ),
    );
  }
}