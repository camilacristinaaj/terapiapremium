# Conformidade LGPD — TerapiaPremium

Dados de saúde mental são **dados pessoais sensíveis** (art. 5º, II, LGPD).
Este documento define os requisitos obrigatórios para o desenvolvimento.

## Base legal

- **Art. 11, II, f** — tutela da saúde, em procedimento realizado por
  profissionais de saúde. Ainda assim, recomenda-se **consentimento
  específico e destacado** do paciente para gravação e transcrição.

## Requisitos obrigatórios

### 1. Consentimento
- [ ] Termo de consentimento específico para gravação de áudio
- [ ] Termo separado para transcrição automatizada
- [ ] Registro imutável do consentimento (data, versão do termo, IP/dispositivo)
- [ ] Revogação simples — paciente pode revogar a qualquer momento

### 2. Segurança (Art. 46)
- [x] Criptografia em repouso: AES-256-GCM para áudio e transcrições
- [x] Criptografia em trânsito: TLS 1.2+ obrigatório
- [ ] Autenticação multifator (MFA) para profissionais
- [ ] Controle de acesso por papel (RBAC)
- [ ] Logs de auditoria de acesso a dados clínicos
- [ ] Gestão de chaves via secret manager (nunca no código)

### 3. Direitos do titular (Art. 18)
- [ ] Exportação dos dados do paciente (portabilidade)
- [ ] Exclusão completa (direito ao esquecimento), respeitando
      obrigações legais de retenção de prontuário (CFP/CFM)
- [ ] Confirmação de existência de tratamento

### 4. Minimização e retenção
- [ ] Coletar apenas o necessário para a finalidade terapêutica
- [ ] Política de retenção alinhada às resoluções do CFP
      (prontuários: mínimo de 5 anos)
- [ ] Anonização/pseudonização para analytics (se houver)

### 5. Governança
- [ ] Nomear Encarregado de Dados (DPO)
- [ ] Relatório de Impacto à Proteção de Dados (RIPD)
- [ ] Contratos de operador (DPA) com qualquer fornecedor de nuvem
- [ ] Plano de resposta a incidentes (comunicação à ANPD em prazo razoável)

### 6. Transcrição
- Preferir **Whisper self-hosted**: o áudio não sai da infraestrutura.
- Se usar API externa, exigir DPA, criptografia ponta-a-ponta e
  proibição contratual de uso dos dados para treinamento de modelos.

## Sigilo profissional

Além da LGPD, aplicam-se os códigos de ética profissional
(CFP para psicólogos, CFM para médicos): o sigilo é regra, e a
quebra só ocorre nas hipóteses legais estritas.
