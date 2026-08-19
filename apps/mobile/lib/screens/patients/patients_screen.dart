import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Patient> _patients = [];
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
      final data = await api.get('/patients');
      setState(() {
        _patients = (data as List).map((j) => Patient.fromJson(j)).toList();
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
      appBar: AppBar(title: const Text('Pacientes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _patients.isEmpty
                      ? const Center(child: Text('Nenhum paciente cadastrado'))
                      : ListView.builder(
                          itemCount: _patients.length,
                          itemBuilder: (context, i) {
                            final p = _patients[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(p.fullName[0].toUpperCase()),
                              ),
                              title: Text(p.fullName),
                              subtitle: p.birthDate != null
                                  ? Text(
                                      'Nascimento: ${p.birthDate!.day}/${p.birthDate!.month}/${p.birthDate!.year}')
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showPatientDetails(p),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPatientDetails(Patient patient) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.fullName,
                style: Theme.of(ctx).textTheme.titleLarge),
            if (patient.birthDate != null)
              Text(
                  'Nascimento: ${patient.birthDate!.day}/${patient.birthDate!.month}/${patient.birthDate!.year}'),
            const SizedBox(height: 16),
            const Text('Ações disponíveis em breve: editar, ver sessões'),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo paciente'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nome completo',
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
              await _createPatient(nameCtrl.text.trim());
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPatient(String name) async {
    if (name.isEmpty) return;
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/patients', {'fullName': name});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente criado')),
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
}
