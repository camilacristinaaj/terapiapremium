import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profissional de Saúde',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Registro profissional'),
            subtitle: const Text('CRP/CRM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('Autenticação em dois fatores (MFA)'),
            subtitle: const Text('Proteja sua conta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MfaSetupScreen()),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}

class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _qrCode;
  String? _secret;
  bool _enabled = false;

  Future<void> _setupMfa() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.post('/auth/mfa/setup', {});
      setState(() {
        _qrCode = res['qrCode'];
        _secret = res['secret'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _enableMfa() async {
    if (_codeCtrl.text.length != 6) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/auth/mfa/enable', {'code': _codeCtrl.text});
      setState(() {
        _enabled = true;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MFA ativado com sucesso!')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Código inválido: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar MFA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Autenticação em dois fatores adiciona uma camada extra de segurança à sua conta.',
            ),
            const SizedBox(height: 24),
            if (_enabled)
              const Card(
                color: Colors.greenAccent,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('MFA ativado!'),
                    ],
                  ),
                ),
              )
            else if (_qrCode == null)
              Center(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _setupMfa,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Gerar QR Code'),
                ),
              )
            else ...[
              const Text('1. Escaneie o QR Code com seu app autenticador:'),
              const SizedBox(height: 16),
              Center(
                child: Image.memory(
                  Uri.parse(_qrCode!).data!.contentAsBytes(),
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
              const Text('2. Ou insira manualmente a chave:'),
              SelectableText(
                _secret!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 24),
              const Text('3. Digite o código de 6 dígitos:'),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '000000',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _enableMfa,
                  child: const Text('Ativar MFA'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
