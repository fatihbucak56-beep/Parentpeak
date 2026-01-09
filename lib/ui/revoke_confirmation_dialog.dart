import 'package:flutter/material.dart';

class RevokeConfirmationDialog extends StatefulWidget {
  final String deviceName;

  const RevokeConfirmationDialog({Key? key, required this.deviceName}) : super(key: key);

  @override
  State<RevokeConfirmationDialog> createState() => _RevokeConfirmationDialogState();
}

class _RevokeConfirmationDialogState extends State<RevokeConfirmationDialog> {
  final _controller = TextEditingController();
  bool _isConfirmed = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkInput(String input) {
    setState(() {
      _isConfirmed = input.trim() == widget.deviceName;
      _errorText = _isConfirmed ? null : 'Der eingegebene Name stimmt nicht überein.';
    });
  }

  void _onSubmitted(String _) {
    if (_isConfirmed) _confirm();
  }

  void _confirm() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final errorText = _errorText;
    return AlertDialog(
      title: Text('Gerät entfernen und Daten löschen?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sie entfernen das Gerät "${widget.deviceName}". Bitte geben Sie den Gerätenamen zur Bestätigung ein:',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: _checkInput,
            onSubmitted: _onSubmitted,
            decoration: InputDecoration(
              labelText: 'Gerätename eingeben',
              helperText: 'Geben Sie den Gerätenamen exakt ein',
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: _isConfirmed ? _confirm : null,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Gerät entfernen'),
        ),
      ],
    );
  }
}
