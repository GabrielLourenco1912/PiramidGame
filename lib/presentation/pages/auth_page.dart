import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/app_user.dart';
import '../widgets/ifpr_mark.dart';

class AuthPage extends SignalStatefulWidget {
  const AuthPage({this.registration = false, super.key});
  final bool registration;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AppDependencies.of(context).authViewModel;
    final input = AuthCredentials(email: _email.text, password: _password.text);
    await (widget.registration ? auth.registerCommand : auth.loginCommand)
        .execute(input);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppDependencies.of(context).authViewModel;
    final busy = auth.busy.value;
    final error = auth.errorMessage.value;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: IfprMark(size: 64)),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.registration
                          ? 'Crie sua conta para participar.'
                          : 'Entre para avaliar o campus.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Informe um e-mail válido.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        widget.registration
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: widget.registration
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a senha.';
                        }
                        if (widget.registration && value.length < 6) {
                          return 'Use pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (widget.registration) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmation,
                        enabled: !busy,
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'As senhas devem ser iguais.',
                        onFieldSubmitted: (_) => busy ? null : _submit(),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.registration ? 'Criar conta' : 'Entrar',
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => auth.loginGoogleCommand.execute(),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Entrar com Google'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              auth.errorMessage.value = null;
                              context.go(
                                widget.registration
                                    ? AppRoutes.login
                                    : AppRoutes.register,
                              );
                            },
                      child: Text(
                        widget.registration
                            ? 'Já tenho conta'
                            : 'Criar uma conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
