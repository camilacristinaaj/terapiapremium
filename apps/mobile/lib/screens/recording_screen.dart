import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';

class RecordingScreen extends StatefulWidget {
  final String sessionId;
  final String patientName;

  const RecordingScreen({
    super.key,
    required this.sessionId,
    required this.patientName,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _uploading = false;
  int _seconds = 0;

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path != null) await _upload(path);
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/sessao_${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        setState(() {
          _recording = true;
          _seconds = 0;
        });
        _startTimer();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de microfone negada')),
          );
        }
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_recording) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  Future<void> _upload(String path) async {
    setState(() => _uploading = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.uploadFile(
        '/recordings/sessions/${widget.sessionId}',
        path,
        'audio',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áudio enviado para transcrição')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload: $e')),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sessão — ${widget.patientName}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _recording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _recording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              _timerText,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            if (_uploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Enviando áudio criptografado...'),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(_recording ? 'Parar e enviar' : 'Iniciar gravação'),
                style: FilledButton.styleFrom(
                  backgroundColor: _recording ? Colors.red : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_recording)
              const Text(
                'O áudio será criptografado antes do envio',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
