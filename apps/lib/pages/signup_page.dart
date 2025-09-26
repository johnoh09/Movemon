// lib/pages/signup_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_diet_app/api/api_client.dart';
import 'package:flutter_diet_app/auth_repo.dart';

class SignupPage extends StatefulWidget {
  final ApiClient api;
  const SignupPage({super.key, required this.api});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _nickname = TextEditingController();
  final _pw = TextEditingController();
  String? _sex; // "M","F","N"
  final _age = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _nickname.dispose();
    _pw.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = AuthRepo(widget.api);
    try {
      await repo.signup(
        email: _email.text.trim(),
        nickname: _nickname.text.trim(),
        password: _pw.text,
        sex: _sex,
        age: _age.text.isEmpty ? null : int.tryParse(_age.text),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response?.data['detail'] ?? 'Signup failed') : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
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
                  controller: _nickname,
                  decoration: const InputDecoration(labelText: 'Nickname'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: const InputDecoration(labelText: 'Sex (optional)'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'F', child: Text('F')),
                    DropdownMenuItem(value: 'N', child: Text('N')),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _age,
                  decoration: const InputDecoration(labelText: 'Age (optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const CircularProgressIndicator() : const Text('Create account'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}