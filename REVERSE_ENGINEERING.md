# 🔬 ENGENHARIA REVERSA COMPLETA — Phishing Kit gov.br
## Análise de todos os 7 componentes React + 3 templates de ataque

---

# ARQUITETURA GERAL

O phishing kit é uma **SPA React** com React Router (BrowserRouter, `pushState`), 7 rotas e 3 templates de phishing. Todo o frontend está em um único bundle JS (427KB), hospedado na Mocha (getmocha.com) via Cloudflare.

O app NÃO usa HashRouter — usa BrowserRouter com `history.pushState`. Isso significa que **rotas SPA só funcionam após carregar o `index.html` da raiz primeiro**. Acesso direto a `/criacao` ou `/admin/painel` retorna 404 do Cloudflare.

## ESTRUTURA DE ROTAS

```
/              → Pv   (gov.br landing page — entrada de CPF)
/verificacao   → Iv   (página de verificação — gov.br OU CNH, depende do state)
/pagamento     → fb   (tela de pagamento PIX unificada)
/pix/:token    → mb   (status do PIX + upload de comprovante)
/admin         → gb   (login do painel administrativo)
/admin/painel  → pb   (dashboard admin completo)
/criacao       → d2   (gerador de fatura Claro — ROTA OCULTA)
```

---

# COMPONENTE POR COMPONENTE

## 1. Pv — Landing Page (gov.br) — `/`

**Função:** Entrada principal do phishing. Captura CPF da vítima.

**Fluxo:**
1. Renderiza header gov.br com logo customizável (vindo de `/api/site-settings/logo`)
2. Campo de CPF com máscara em tempo real (`o2()`: 000.000.000-00)
3. Validação client-side com dígitos verificadores (`x()`: algoritmo oficial CPF)
4. Botão "Continuar" → `POST /api/validate-cpf` com `{cpf: "12345678909"}`
5. Se sucesso → navega para `/verificacao` com state: `{cpf, nome, dataNascimento}`
6. Se erro → mostra mensagens: "CPF inválido", "CPF incompleto", "Não foi possível validar"

**Features:**
- Modo alto contraste (amarelo/preto) — acessibilidade falsa pra parecer legítimo
- Botão VLibras falso (só placeholder visual)
- Imagem lateral: `conta_govbr.jpg` (print real do gov.br)
- Loading spinner com "Verificando seus dados..." enquanto aguarda API

**Textos chave:**
- "Identifique-se no gov.br com:"
- "Digite seu CPF para continuar"
- "CPF inválido. Verifique os números digitados."
- "Erro ao conectar com o servidor. Tente novamente."

---

## 2. Iv — Verificação — `/verificacao`

**Função:** Componente dual-purpose. Serve tanto gov.br quanto CNH, dependendo do state de navegação.

**State machine interna:** `verification` → `validating-birthdate` → `cnh-alert` → `loading` → `infraction` → `payment-method`

### MODO GOV.BR (state normal)
1. Mostra "Olá, {nome}!" com dados vindos do state (cpf, nome, dataNascimento)
2. Exibe campo "Selecione sua data de nascimento" com **datas fake geradas aleatoriamente** ao redor da data real
3. Função `Zv()` gera 3 opções de data próximas da data real da vítima (1-2 dias de diferença)
4. Se a vítima escolhe a data correta → navigate para `/pagamento` com state
5. Se escolhe data errada → "Data de nascimento incorreta. Tente novamente."

**Geração de datas fake (`Zv`):**
```javascript
function Zv(r) {
  const m = new Date(r);
  const p = [r];  // data real como primeira opção
  // Gera mais 2 datas com ±1-2 dias de diferença
  for([{days: Math.floor(Math.random()*3)+1}, ...]) {
    // embaralha as opções
  }
}
```
Isso é engenharia social: a vítima vê 3 datas e naturalmente escolhe a correta, validando que os dados do sistema "batem".

### MODO CNH (state com `cnh-alert`)
Quando o fluxo é CNH (navegação especial), o componente mostra o template de suspensão de CNH:

1. **Tela "⚠️ ALERTA: SUA CNH ESTÁ EM FASE DE SUSPENSÃO"**
   - Cita Art. 261 CTB (20 pontos/12 meses = suspensão)
   - "Excesso do limite de pontos permitidos"
   - "Processo de suspensão" em andamento

2. **Tabela de "Tentativas anteriores de contato"** (tudo fake):
   - Função `Kv()` gera datas/horários aleatórios
   - Função `Jv()` gera métodos aleatórios (SMS, E-mail, Notificação Push)
   - Mostra 3-5 tentativas falsas com datas e horários

3. **"✅ ÚLTIMA CHANCE DE REGULARIZAÇÃO"**
   - Urgência artificial: "único meio disponível para regularização imediata"
   - "Após este prazo, o processo de suspensão será concluído automaticamente"

4. **Avisos legais fake:**
   - "A suspensão pode variar de 6 meses a 2 anos"
   - "Durante a suspensão, você não poderá dirigir veículos automotores"
   - "Dirigir com CNH suspensa é crime previsto no Art. 309 do CTB"

5. Botão "Renegociar Agora" → inicia loading fake com 4 etapas:
   - "Carregando seus dados..."
   - "Verificando multas..."
   - "Analisando junto ao CDT..."
   - "Verificado com sucesso!"
   - Cada etapa dura ~1.2 segundos (animação com bolinhas pulsando)

6. **Tela de Infração:**
   - "Infração Gravíssima Identificada"
   - "Para evitar a suspensão definitiva da sua CNH..."
   - "Evita suspensão da CNH por até 2 anos"
   - Valor: R$ 198,38 para "regularização"
   - Checkbox "Comprovante enviado por e-mail e SMS"

7. Botão "Pagar Agora" → navega para `/pagamento`

---

## 3. fb — Pagamento PIX — `/pagamento`

**Função:** Tela de cobrança PIX unificada para TODOS os templates.

**Fluxo:**
1. Ao montar, chama `POST /api/create-payment` com `{cpf, nome, amount}`
2. Recebe `pixCode` (código PIX copia-e-cola completo)
3. Renderiza QR Code (biblioteca `react-qr-code`, 140px) + código PIX
4. Timer de expiração de 4 horas (countdown regressivo)
5. Botão "Copiar código PIX" → copia pra clipboard
6. Botão "Clique aqui caso tenha realizado o pagamento" → abre formulário de comprovante
7. Formulário de comprovante: CPF (mascarado), nome, upload de arquivo
8. Upload → `POST /api/upload-receipt` (FormData com file, cpf, nome)
9. Ao copiar, também salva sessão: `POST /api/save-pix-session` → redireciona para `/pix/:token`

**Estados visuais:**
- `p=true`: loading "Gerando código de pagamento..."
- `c` (erro): tela de erro com botão "Voltar ao início"
- Normal: QR Code + código PIX + timer + botão de comprovante
- `ae=true`: tela de sucesso "Comprovante Enviado!"

**Valor padrão:** R$ 198,38 (vem do state.navigation, mas tem fallback)

**Gate de segurança:** Se não houver `nome && cpf && dataNascimento` no state + cookie `payment_nav_valid`, redireciona pra `/`. Isso impede acesso direto à URL.

---

## 4. mb — PIX Status — `/pix/:token`

**Função:** Página de status pós-pagamento. A vítima chega aqui após "pagar".

**Fluxo:**
1. Extrai `:token` da URL via `useParams()`
2. Chama `GET /api/pix-session/:token` pra carregar dados da sessão
3. Se token expirado ou inválido → redireciona pra `/`
4. Mostra nome, CPF, data nascimento, valor
5. Timer de expiração (mesmo formato 4h, mas em minutos:segundos)
6. Opções de upload de comprovante (igual ao componente fb)
7. Mensagem "Comprovante enviado por e-mail e SMS"

---

## 5. gb — Admin Login — `/admin`

**Função:** Tela de login do painel administrativo.

**Fluxo:**
1. Campos: usuário + senha
2. `POST /api/admin/login` com `{username, password}`
3. Se OK → salva token em `sessionStorage.setItem("adminToken", token)`
4. Redireciona para `/admin/painel`
5. Se já tiver token válido → redireciona automaticamente

**UI:** Tema dark (slate-900), ícone de escudo azul, "Painel Admin — Acesso restrito"

---

## 6. pb — Painel Admin — `/admin/painel`

**Função:** Dashboard administrativo completo.

**Seções:**

### PixVault (API de Pagamentos)
- Client ID: `cli_xxxxxxxxxxxxxxxx` (placeholder)
- Token Secret: `one_xxxxxxxxxxxxxxxx` (placeholder)
- Protegido por **senha secundária**
- PUT `/api/admin/settings` para salvar

### Logo do Site
- Upload de arquivo OU URL
- Preview em tempo real
- Tamanho ajustável (slider 24-120px)
- PUT `/api/admin/settings/logo` para salvar

### Chaves de API CPF
- Lista de chaves cadastradas
- Adicionar nova (nome + chave)
- Excluir chave existente
- Protegido por senha secundária

### Comprovantes
- Lista de comprovantes enviados
- Download individual
- Exclusão individual
- GET `/api/admin/receipts` + DELETE `/api/admin/receipts/:id`

### Cache Stats
- Total de CPFs em cache
- Total de sessões PIX
- GET `/api/admin/cpf-cache-stats`

---

## 7. d2 — Gerador de Fatura Claro — `/criacao` ⭐ ROTA OCULTA

**Função:** Gerador standalone de fatura falsa da Claro. **Não vinculado ao fluxo principal do phishing.** É uma ferramenta separada para criar boletos falsos.

**Status:** ROTA OCULTA — o código existe no bundle mas `/criacao` retorna 404 por acesso direto. Só funciona navegando via React Router a partir da raiz `/`. **Não há link visível no site** — é acessado manualmente pelo atacante digitando a URL após carregar a página inicial.

### COMO O GOLPE FUNCIONA:

1. **Atacante acessa `/criacao`** (navegando da raiz ou via console JS: `window.history.pushState({}, '', '/criacao')`)
2. **Preenche os dados da vítima:**
   - Nome completo
   - CPF (com máscara automática)
   - Telefone (com máscara)
   - Código do cliente
   - Endereço completo (rua, número, complemento, bairro, cidade, estado, CEP)
   - Plano de internet (select: Fibra 100/200/300/500 Mega ou 1 Giga)
   - Consumo (ex: "285 GB")
   - Velocidade (ex: "300 Mbps")
   - Valor em reais (padrão: R$ 99,90)
   - Data de vencimento
   - Mês de referência
3. **Clica "Gerar Fatura"** → renderiza uma fatura profissional da Claro
4. **A fatura gerada contém:**
   - Logo da Claro (vermelho) + header gradiente
   - "FATURA DE SERVIÇO" + mês/ano
   - Dados do cliente formatados
   - Endereço de instalação
   - Detalhes do plano em cards (Plano, Consumo, Velocidade)
   - Seção "Valor a Pagar" com destaque em vermelho
   - QR Code PIX (140px, level H) com dados: `PIX:{codigo_barras}|VALOR:{valor}|NOME:{nome}`
   - Código de barras CODE128 (JsBarcode, width 1.5, height 60)
   - Botão "Copiar" para código de barras
   - Rodapé: Central de Atendimento 1052 | www.claro.com.br
5. **O atacante clica "Imprimir"** — CSS tem regras `print:py-0 print:bg-white print:shadow-none` para PDF limpo
6. **Envia para a vítima** via:
   - Email: "Sua fatura Claro está disponível"
   - WhatsApp: "Sua fatura Claro venceu, pague pelo PIX"
   - SMS: link para página de pagamento

### CARACTERÍSTICAS TÉCNICAS:

**Código de barras:** Aleatório! A função `b()` gera 4 grupos de 12 dígitos aleatórios:
```javascript
const b = () => {
  const E = [];
  for (let A = 0; A < 4; A++)
    E.push(Math.random().toString().slice(2, 14));
  return E.join(" ");
}
```
Isso significa que **o código de barras NÃO é um boleto real** — é puramente cosmético. A vítima que escanear o código de barras não vai conseguir pagar. O vetor de pagamento real é o **QR Code PIX**.

**QR Code PIX:** O QR Code é gerado client-side com a string `PIX:{numeros}|VALOR:{valor}|NOME:{nome}`. Mas isso NÃO é um PIX válido! O formato PIX real é o padrão BR Code (EMV), que começa com `000201...`. O QR Code gerado aqui usa um formato proprietário simplificado. Na prática:
- Se a vítima escanear, o app do banco pode não reconhecer
- Ou o app pode interpretar como PIX simples (chave=numeros, valor=X, nome=Y)
- É um vetor de baixa conversão — a vítima provavelmente vai digitar o código manualmente

**Bibliotecas usadas:**
- `react-qr-code` → QR Code (componente `Xu`, renderiza SVG)
- `JsBarcode` → Código de barras CODE128 (componente `i2`)
- `Open Sans` → Google Fonts (carregado dinamicamente)

### CAMPOS COM MÁSCARA:
| Campo | Máscara | Função |
|---|---|---|
| CPF | `000.000.000-00` | `o2()` — formata visualmente |
| Telefone | `(00) 00000-0000` | `s2()` — formata DDD + número |
| CEP | `00000-000` | `c2()` — hífen automático |
| Valor | `99,90` | `f2()` — centavos → reais |

### CSS DO TEMPLATE:
- Tema escuro no formulário: `bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900`
- Glassmorphism: `bg-white/10 backdrop-blur-lg border-white/20`
- Fatura: fundo branco com sombra, layout imprimível
- Cores Claro: gradiente `from-red-600 to-red-700`

---

# FUNÇÕES UTILITÁRIAS EXTRAÍDAS

```javascript
// CPF mask: 12345678909 → 123.456.789-09
function o2(r) {
  const m = r.replace(/\D/g, "");
  return m.length <= 11
    ? m.replace(/(\d{3})(\d)/, "$1.$2")
       .replace(/(\d{3})(\d)/, "$1.$2")
       .replace(/(\d{3})(\d{1,2})$/, "$1-$2")
    : r;
}

// Phone mask: 47991759528 → (47) 99175-9528
function s2(r) {
  const m = r.replace(/\D/g, "");
  return m.length === 11
    ? m.replace(/(\d{2})(\d{5})(\d{4})/, "($1) $2-$3")
    : r;
}

// CEP mask: 89224500 → 89224-500
function c2(r) {
  const m = r.replace(/\D/g, "");
  return m.length === 8
    ? m.replace(/(\d{5})(\d{3})/, "$1-$2")
    : r;
}

// Currency format: 9990 → "99,90"
function f2(r) {
  const m = r.replace(/\D/g, "");
  return (parseInt(m) / 100).toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}
```

---

# MECANISMOS DE SEGURANÇA DO KIT

| Mecanismo | Onde | Como |
|---|---|---|
| **Payment nav gate** | `fb` (pagamento) | `sessionStorage.getItem("payment_nav_valid")` + validação de state |
| **Session gate** | `mb` (pix status) | Token de 16 chars via URL param + API validation |
| **Admin auth** | `gb` (login), `pb` (painel) | JWT Bearer em `sessionStorage.getItem("adminToken")` |
| **Secondary password** | `pb` (painel) | Senha adicional para PixVault, CPF keys, logo |
| **Logo customization** | Todos componentes | GET `/api/site-settings/logo` — permite customizar a logo remotamente |

---

# CADEIA DE ATAQUE COMPLETA

## Fluxo gov.br:
```
Vítima recebe SMS → link → habylity-playhorm.site/
→ Digita CPF → POST /api/validate-cpf
→ "Olá {nome}, confirme sua data de nascimento"
→ Seleciona data → "Sua conta será PRATA"
→ POST /api/create-payment → QR Code PIX R$198,38
→ Vítima paga → POST /api/upload-receipt
→ "Comprovante enviado por e-mail e SMS"
```

## Fluxo CNH:
```
Vítima recebe SMS → link com state cnh-alert
→ "⚠️ SUA CNH ESTÁ EM FASE DE SUSPENSÃO"
→ Tabela fake de tentativas de contato
→ "ÚLTIMA CHANCE DE REGULARIZAÇÃO"
→ Art. 261/309 CTB → urgência
→ "Renegociar Agora" → loading fake 4 etapas
→ "Infração Gravíssima" → PIX R$198,38
```

## Fluxo Claro (ferramenta do atacante):
```
Atacante acessa /criacao (rota oculta)
→ Preenche dados da vítima
→ "Gerar Fatura" → fatura profissional estilizada
→ Imprime/salva PDF
→ Envia por email/WhatsApp: "Fatura Claro vencida"
→ Vítima clica, vê boleto + QR Code PIX
→ Paga → dinheiro vai pro PIX do atacante
```

---

# ASSINATURAS DO KIT (IOCs)

- Mocha APP_ID: `019ced28-4d7b-7e15-bffe-2e85baed0fc8`
- CDN de assets: `mochausercontent.com` com o mesmo APP_ID
- Google Fonts: `Open Sans` carregado dinamicamente
- React QR Code: componente `Xu` com `size=140, level="H"`
- JsBarcode: formato CODE128, width 1.5, height 60
- Tailwind CSS: classes utilitárias no bundle
- React Router: `history.pushState` (não HashRouter)
- localStorage/sessionStorage keys: `adminToken`, `payment_nav_valid`
