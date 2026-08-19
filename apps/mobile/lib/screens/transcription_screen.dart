import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

class TranscriptionScreen extends StatefulWidget {
  final String sessionId;
  final String patientName;

  const TranscriptionScreen({
    super.key,
    required this.sessionId,
    required this.patientName,
  });

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  Transcription? _transcription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/transcriptions/sessions/${widget.sessionId}');
      setState(() {
        _transcription = Transcription.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_transcription == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TerapiaPremium — Transcrição de Sessão',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Paciente: ${widget.patientName}'),
            pw.Text(
              'Data: ${_transcription!.createdAt.day}/${_transcription!.createdAt.month}/${_transcription!.createdAt.year}',
            ),
            pw.Text('Idioma: ${_transcription!.language}'),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text(
              _transcription!.text,
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.Text(
              'Documento gerado em conformidade com a LGPD. '
              'Dados sensíveis de saúde mental.',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'transcricao_${widget.patientName}_${_transcription!.createdAt.millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transcrição — ${widget.patientName}'),
        actions: [
          if (_transcription != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportPdf,
              tooltip: 'Exportar PDF',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : _transcription == null
                  ? const Center(child: Text('Transcrição não disponível'))
                  : SingleChildScrollView(
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
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Criptografado em repouso',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Idioma: ${_transcription!.language} • '
                                    'Gerada em: ${_transcription!.createdAt.day}/${_transcription!.createdAt.month}/${_transcription!.createdAt.year}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _transcription!.text,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
