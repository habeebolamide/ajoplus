import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool passwordHidden = true;
  bool confirmationHidden = true;

  @override
  void dispose() {
    for (final controller in [name, email, phone, password, confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().register(
        name.text,
        email.text,
        phone.text,
        password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start saving together',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Create an account to save with your groups.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: emailValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) =>
                      RegExp(
                        r'^\+?\d{10,14}$',
                      ).hasMatch((value ?? '').replaceAll(' ', ''))
                      ? null
                      : 'Enter a valid phone number',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: password,
                  obscureText: passwordHidden,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: passwordHidden
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () =>
                          setState(() => passwordHidden = !passwordHidden),
                      icon: Icon(
                        passwordHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'Use at least 8 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmation,
                  obscureText: confirmationHidden,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      tooltip: confirmationHidden
                          ? 'Show password confirmation'
                          : 'Hide password confirmation',
                      onPressed: () => setState(
                        () => confirmationHidden = !confirmationHidden,
                      ),
                      icon: Icon(
                        confirmationHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value != password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: context.watch<AuthProvider>().busy ? null : submit,
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
