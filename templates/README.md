# Templates Extraídos do Phishing Kit Original

O bundle JS contém **3 templates de phishing** completos + **construtor de templates**.

---

## Template 1: gov.br (CONTA SUSPENSA)
**Rota:** `/` → `/verificacao` → `/pagamento` → `/pix/:token`

Fluxo:
1. Entrada de CPF com máscara (000.000.000-00)
2. Validação via `/api/validate-cpf` → retorna nome + data nascimento
3. Tela "Sua conta será PRATA" com opções de identificação
4. PIX de R$ 198,38 com QR Code
5. Upload de comprovante

## Template 2: Claro (FATURA FALSA)
**Rota:** `/criacao` (template builder)

Fluxo:
1. Formulário completo:
   - Dados do cliente: nome, CPF, telefone, código cliente
   - Endereço: rua, número, complemento, bairro, cidade, estado, CEP
   - Plano: select (opções), consumo, velocidade
   - Cobrança: valor (R$), vencimento, mês referência
2. Geração de fatura estilizada (logo Claro, cores vermelhas)
3. Código de barras (CODE128 via JsBarcode)
4. QR Code PIX com dados da fatura
5. Layout imprimível (print:py-0 print:bg-white)

Campos padrão:
```json
{
  "plano": "Fibra 300 Mega",
  "consumo": "285 GB",
  "velocidade": "300 Mbps",
  "valor": "9990"  // R$ 99,90 (em centavos)
}
```

## Template 3: CNH (CARTEIRA SUSPENSA)
**Rota:** `/verificacao` (com state cnh-alert)

Fluxo:
1. "⚠️ ALERTA: SUA CNH ESTÁ EM FASE DE SUSPENSÃO"
2. Simula consulta com loading:
   - "Consultando base de dados..."
   - "Analisando multas..."
   - "Analisando junto ao CDT..."
   - "Verificado com sucesso!"
3. Mostra "Infração Gravíssima Identificada"
4. Excesso de pontos na carteira (>20 pontos/12 meses)
5. "Suspensão pode variar de 6 meses a 2 anos"
6. Cita Art. 309 CTB (crime)
7. PIX de R$ 198,38 para "regularização imediata"
8. Countdown de urgência

Mensagens:
- "Dirigir com CNH suspensa é crime previsto no Art. 309 do CTB"
- "Durante a suspensão, você não poderá dirigir veículos automotores"
- "A falta de regularização dentro do prazo resultará na suspensão automática da CNH"
- "Evita suspensão da CNH por até 2 anos"

---

## Construtor de Templates (/criacao)
**Componente:** `d2`

Permite criar templates customizados de phishing com:
- Seleção de tipo (gov.br, Claro, CNH, etc)
- Customização de campos
- Preview em tempo real
- Geração de link público

---
