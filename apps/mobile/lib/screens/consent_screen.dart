import 'package:flutter/material.dart';

class ConsentScreen extends StatefulWidget {
  final String patientName;
  final VoidCallback onConsentGranted;

  const ConsentScreen({
    super.key,
    required this.patientName,
    required this.onConsentGranted,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _audioConsent = false;
  bool _transcriptionConsent = false;
  bool _dataProcessingConsent = false;

  bool get _allGranted =>
      _audioConsent && _transcriptionConsent && _dataProcessingConsent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termo de Consentimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termo de Consentimento Livre e Esclarecido',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paciente: ${widget.patientName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'De acordo com a Lei Geral de Proteção de Dados (LGPD - Lei 13.709/2018), '
                      'solicitamos seu consentimento para:',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildConsentTile(
              title: 'Gravação de áudio',
              subtitle: 'Autorizo a gravação das sessões de terapia para fins de '
                  'documentação clínica e acompanhamento do tratamento.',
              value: _audioConsent,
              onChanged: (v) => setState(() => _audioConsent = v!),
            ),
            _buildConsentTile(
              title: 'Transcrição automatizada',
              subtitle: 'Autorizo a transcrição do áudio para texto por sistema '
                  'computacional, com armazenamento criptografado.',
              value: _transcriptionConsent,
              onChanged: (v) => setState(() => _transcriptionConsent = v!),
            ),
            _buildConsentTile(
              title: 'Tratamento de dados sensíveis',
              subtitle: 'Autorizo o tratamento de meus dados de saúde mental '
                  'exclusivamente para fins terapêuticos, conforme Art. 11, II, f da LGPD.',
              value: _dataProcessingConsent,
              onChanged: (v) => setState(() => _dataProcessingConsent = v!),
            ),
            const SizedBox(height: 24),
            const Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você pode revogar este consentimento a qualquer momento, '
                        'solicitando a exclusão dos dados.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _allGranted ? widget.onConsentGranted : null,
                child: const Text('Concordar e continuar'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão do termo: 1.0 — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
