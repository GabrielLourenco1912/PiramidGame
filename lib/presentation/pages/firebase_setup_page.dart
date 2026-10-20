import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/ifpr_mark.dart';

class FirebaseSetupPage extends StatelessWidget {
  const FirebaseSetupPage({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IfprMark(size: 72),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Configure a conexão com o Firebase',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Siga o guia Instrucoes_Firebase_PiramidGame.pdf, '
                      'na raiz do projeto. Depois de configurar, reinicie o aplicativo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const SelectableText(
                      'flutterfire configure --platforms=android,web',
                    ),
                    const SizedBox(height: 20),
                    SelectableText(message, textAlign: TextAlign.center),
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
