import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Web — saisie manuelle du code QR (caméra non disponible).
class PointageQrScanScreenImpl extends StatefulWidget {
  const PointageQrScanScreenImpl({super.key});

  @override
  State<PointageQrScanScreenImpl> createState() =>
      _PointageQrScanScreenImplState();
}

class _PointageQrScanScreenImplState extends State<PointageQrScanScreenImpl> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.premiumBlack,
      appBar: AppBar(
        title: const Text('Code membre'),
        backgroundColor: AppTheme.premiumBlack,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Saisissez le code QR ou le code membre.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Code membre',
                hintText: 'IFCM-LUB-…',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandOrange,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
