# Assets Reaproveitáveis do Phishing Kit

## ARQUITETURA COMPLETA

O bundle contém um **kit de phishing multi-template** com 3 templates + construtor:

| Rota | Template | Função |
|---|---|---|
| `/` | Seleção de template | Escolhe qual golpe aplicar |
| `/verificacao` | gov.br / CNH | Validação de CPF e dados |
| `/pagamento` | Todos | Tela de pagamento PIX |
| `/pix/:token` | Todos | Status do PIX gerado |
| `/criacao` | — | **CONSTRUTOR DE TEMPLATES** |
| `/admin` | — | Login do painel admin |
| `/admin/painel` | — | Dashboard administrativo |

## TEMPLATE 1: gov.br (conta suspensa)
- Valida CPF → retorna nome + data nascimento
- Mostra "identifique-se no gov.br"
- Gera PIX de R$ 198,38
- Upload de comprovante

## TEMPLATE 2: Claro (fatura falsa)
- Campos: nome, cpf, telefone, código cliente, endereço completo
- Plano: Fibra 300 Mega, Consumo: 285 GB, Velocidade: 300 Mbps
- Valor padrão: R$ 99,90
- Gera boleto com código de barras (JsBarcode CODE128) + QR Code PIX
- Visual profissional: logo Claro, cores vermelhas, layout de fatura real
- Central de Atendimento: 1052 | *1052 (número real da Claro!)

## TEMPLATE 3: CNH (carteira suspensa)
- "⚠️ ALERTA: SUA CNH ESTÁ EM FASE DE SUSPENSÃO"
- "Infração Gravíssima Identificada"
- Cita Art. 309 do CTB (crime de trânsito)
- "Excesso do limite de pontos permitidos"
- Simula consulta ao DETRAN/CDT
- "Suspensão pode variar de 6 meses a 2 anos"
- Valor: R$ 198,38 para "regularização imediata"
- Urgência: "A falta de regularização resulta em suspensão automática"

---

## FUNÇÕES REUTILIZÁVEIS EXTRAÍDAS

### CPF Mask (formatação visual)
```javascript
function maskCPF(r) {
  const m = r.replace(/\D/g, "");
  return m.length <= 11
    ? m.replace(/(\d{3})(\d)/, "$1.$2")
       .replace(/(\d{3})(\d)/, "$1.$2")
       .replace(/(\d{3})(\d{1,2})$/, "$1-$2")
    : r;
}
```

### CPF Validation (dígitos verificadores)
```javascript
function validateCPF(cpf) {
  cpf = cpf.replace(/[^\d]+/g, '');
  if (cpf.length !== 11 || /^(\d)\1+$/.test(cpf)) return false;
  let sum = 0, remainder;
  for (let i = 0; i < 9; i++) sum += parseInt(cpf.charAt(i)) * (10 - i);
  remainder = (sum * 10) % 11;
  if (remainder === 10) remainder = 0;
  if (remainder !== parseInt(cpf.charAt(9))) return false;
  sum = 0;
  for (let i = 0; i < 10; i++) sum += parseInt(cpf.charAt(i)) * (11 - i);
  remainder = (sum * 10) % 11;
  if (remainder === 10) remainder = 0;
  return remainder === parseInt(cpf.charAt(10));
}
```

### CEP Mask
```javascript
function maskCEP(r) {
  const m = r.replace(/\D/g, "");
  return m.length === 8 ? m.replace(/(\d{5})(\d{3})/, "$1-$2") : r;
}
```

### Currency Format (centavos → reais)
```javascript
function formatCurrency(r) {
  const m = r.replace(/\D/g, "");
  return (parseInt(m) / 100).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
  });
}
```

### Phone Mask
```javascript
function maskPhone(r) {
  const m = r.replace(/\D/g, "");
  return m.length <= 11
    ? m.replace(/(\d{2})(\d)/, "($1) $2")
       .replace(/(\d{5})(\d)/, "$1-$2")
    : r;
}
```

---

## PAINEL ADMIN COMPLETO

### Funcionalidades:
1. **PixVault**: credenciais (client_id + token_secret)
   - Placeholder: `cli_xxxxxxxxxxxxxxxx` / `one_xxxxxxxxxxxxxxxx`
   - Protegido por senha secundária

2. **Logo Upload**: customiza o logo da página de phishing
   - Formatos: PNG, JPG, WEBP ou SVG
   - Preview em tempo real
   - URL ou upload de arquivo

3. **CPF API Keys**: gerencia chaves de consulta CPF
   - Adicionar/excluir chaves
   - Protegido por senha secundária

4. **Comprovantes**: visualizar/baixar/excluir
   - Lista todos os comprovantes enviados
   - Download do arquivo original
   - Exclusão individual

5. **Cache Stats**: estatísticas
   - Total de CPFs em cache
   - Total de sessões PIX

### Autenticação:
- JWT armazenado em `sessionStorage.getItem("adminToken")`
- Bearer token no header Authorization
- Senha secundária para operações sensíveis

---

## FLUXO DE PAGAMENTO PIX

### Estados da sessão PIX:
1. `pending` — aguardando pagamento
2. Timer de 4 horas para expiração
3. Botão "Clique aqui caso tenha realizado o pagamento"
4. Upload de comprovante
5. Confirmação com mensagem "Comprovante enviado por e-mail e SMS"

### Geração de QR Code PIX:
- Biblioteca: qrcode (react-qr-code ou similar)
- Formato: `PIX:{chave}|VALOR:{valor}|NOME:{nome}`
- Tamanho: 140px
- Nível de correção: H (30%)

### Código de Barras (Claro):
- Biblioteca: JsBarcode
- Formato: CODE128
- Width: 1.5, Height: 60
- Background: branco, LineColor: preto

---

## MENSAGENS DE ERRO (português PT-BR)

```
"CPF inválido. Verifique os números digitados."
"CPF incompleto. Digite os 11 dígitos."
"Data de nascimento incorreta. Tente novamente."
"Não foi possível validar o CPF. Tente novamente."
"Erro ao conectar com o servidor."
"Erro ao gerar pagamento."
"Erro ao salvar sessão."
"Credenciais inválidas"
"Não autorizado"
"Senha secundária incorreta"
"Arquivo muito grande. Máximo 10MB."
"Formato de arquivo não suportado."
"CPF já possui comprovante enviado."
```

---

## ENDPOINTS API (confirmados via bundle)

### Públicos (sem auth):
```
POST /api/validate-cpf          { cpf }
POST /api/create-payment         { cpf, nome, amount }
POST /api/save-pix-session       { pixCode, nome, cpf, dataNascimento, amount }
GET  /api/pix-session/:token
POST /api/upload-receipt         FormData { receipt, cpf, nome }
GET  /api/site-settings/logo
```

### Admin (JWT Bearer):
```
POST /api/admin/login            { username, password }
GET  /api/admin/settings
PUT  /api/admin/settings         { pixvault_client_id, pixvault_token_secret, secondary_password }
PUT  /api/admin/settings/logo    { logo_url, logo_size, secondary_password }
POST /api/admin/upload-logo      FormData { logo }
GET  /api/admin/receipts
GET  /api/admin/receipts/:id/download
DELETE /api/admin/receipts/:id
GET  /api/admin/cpf-keys
POST /api/admin/cpf-keys         { api_key, name, secondary_password }
DELETE /api/admin/cpf-keys/:id
GET  /api/admin/cpf-cache-stats
```

---

## ESTRUTURA DE DADOS

### Sessão PIX (pix-session):
```json
{
  "token": "abc123def456",
  "cpf": "12345678909",
  "nome": "Daiana Lassolli",
  "dataNascimento": "2000-04-27",
  "genero": "F",
  "pix_code": "0002012658...",
  "amount": 198.38,
  "status": "pending",
  "created_at": "2026-07-13T..."
}
```

### Comprovante (receipt):
```json
{
  "id": 1,
  "cpf": "12345678909",
  "file_name": "comprovante.png",
  "file_url": "/uploads/abc123.png",
  "uploaded_at": "2026-07-13T..."
}
```

---

## CONTATOS DOS ATACANTES (Imobiliária)

- Email: contato@imobiliariabarrasul.com
- Tel fixo: (47) 3376-0015
- WhatsApp Locação: (47) 99175-9528
- WhatsApp Vendas: (47) 99155-4645
- Região: Joinville/Itajaí - SC (DDD 47)
- Senha admin: barrasul2024
