import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import 'recording_screen.dart';
import 'transcription_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/sessions');
      setState(() {
        _sessions = (data as List).map((j) => Session.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _sessions.isEmpty
                      ? const Center(
                          child: Text('Nenhuma sessão registrada'),
                        )
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (context, i) {
                            final s = _sessions[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(s.patientName[0].toUpperCase()),
                                ),
                                title: Text(s.patientName),
                                subtitle: Text(
                                  '${s.startedAt.day}/${s.startedAt.month}/${s.startedAt.year} '
                                  '${s.startedAt.hour}:${s.startedAt.minute.toString().padLeft(2, '0')} • '
                                  '${s.status}',
                                ),
                                trailing: s.status == 'COMPLETED'
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.mic, color: Colors.teal),
                                onTap: () => _handleSessionTap(s),
                                onLongPress: () => _showSessionOptions(s),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewSessionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova sessão'),
      ),
    );
  }

  void _handleSessionTap(Session s) {
    if (s.status == 'COMPLETED') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TranscriptionScreen(
            sessionId: s.id,
            patientName: s.patientName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecordingScreen(
            sessionId: s.id,
            patientName: s.patientName,
          ),
        ),
      ).then((_) => _load());
    }
  }

  void _showSessionOptions(Session s) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar notas'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir sessão',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(s);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Session s) {
    final notesCtrl = TextEditingController(text: s.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar sessão'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notas',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateSession(s.id, notesCtrl.text.trim());
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSession(String id, String notes) async {
    try {
      final api = context.read<AuthProvider>().api;
      await api.patch('/sessions/$id', {'notes': notes});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão atualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _confirmDelete(Session s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir sessão'),
        content: Text(
          'Deseja excluir permanentemente a sessão de ${s.patientName}? '
          'Esta ação não pode ser desfeita e está de acordo com o direito '
          'ao esquecimento (LGPD Art. 18, VI).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteSession(s.id);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    try {
      final api = context.read<AuthProvider>().api;
      await api.delete('/sessions/$id');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão excluída')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showNewSessionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova sessão'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nome do paciente',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createPatientAndSession(nameCtrl.text.trim());
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPatientAndSession(String patientName) async {
    if (patientName.isEmpty) return;
    try {
      final api = context.read<AuthProvider>().api;
      final patient = await api.post('/patients', {'fullName': patientName});
      await api.post('/sessions', {'patientId': patient['id']});
      // Concede consentimentos (simplificado — em produção seria um termo assinado)
      await api.post(
        '/sessions/${patient['id']}/consent',
        {'purpose': 'AUDIO_RECORDING'},
      );
      await api.post(
        '/sessions/${patient['id']}/consent',
        {'purpose': 'TRANSCRIPTION'},
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}
