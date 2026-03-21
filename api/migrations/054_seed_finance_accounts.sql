-- Seed global finance accounts (branch_id = NULL means shared across all branches)
-- 1xxx Assets
INSERT INTO finance_accounts (code, name, type, parent_id) VALUES
('1000', 'Aset', 'asset', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1100', 'Kas & Bank', 'asset', id FROM finance_accounts WHERE code='1000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1101', 'Kas Tunai', 'asset', id FROM finance_accounts WHERE code='1100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1102', 'Bank BCA', 'asset', id FROM finance_accounts WHERE code='1100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1103', 'Bank Mandiri', 'asset', id FROM finance_accounts WHERE code='1100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1200', 'Piutang Usaha', 'asset', id FROM finance_accounts WHERE code='1000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1201', 'Piutang Siswa', 'asset', id FROM finance_accounts WHERE code='1200'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1300', 'Aset Tetap', 'asset', id FROM finance_accounts WHERE code='1000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '1301', 'Peralatan', 'asset', id FROM finance_accounts WHERE code='1300'
ON CONFLICT DO NOTHING;

-- 2xxx Liabilities
INSERT INTO finance_accounts (code, name, type, parent_id) VALUES
('2000', 'Kewajiban', 'liability', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '2100', 'Hutang Usaha', 'liability', id FROM finance_accounts WHERE code='2000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '2110', 'Hutang Komisi', 'liability', id FROM finance_accounts WHERE code='2100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '2120', 'Hutang Fasilitator', 'liability', id FROM finance_accounts WHERE code='2100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '2200', 'Kewajiban Jangka Panjang', 'liability', id FROM finance_accounts WHERE code='2000'
ON CONFLICT DO NOTHING;

-- 3xxx Equity
INSERT INTO finance_accounts (code, name, type, parent_id) VALUES
('3000', 'Ekuitas', 'equity', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '3100', 'Modal', 'equity', id FROM finance_accounts WHERE code='3000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '3200', 'Laba Ditahan', 'equity', id FROM finance_accounts WHERE code='3000'
ON CONFLICT DO NOTHING;

-- 4xxx Revenue
INSERT INTO finance_accounts (code, name, type, parent_id) VALUES
('4000', 'Pendapatan', 'revenue', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4100', 'Pendapatan Course', 'revenue', id FROM finance_accounts WHERE code='4000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4110', 'Pendapatan Program Karir', 'revenue', id FROM finance_accounts WHERE code='4100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4120', 'Pendapatan Reguler', 'revenue', id FROM finance_accounts WHERE code='4100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4130', 'Pendapatan Privat', 'revenue', id FROM finance_accounts WHERE code='4100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4140', 'Pendapatan Inhouse', 'revenue', id FROM finance_accounts WHERE code='4100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '4200', 'Pendapatan Lainnya', 'revenue', id FROM finance_accounts WHERE code='4000'
ON CONFLICT DO NOTHING;

-- 5xxx Expenses
INSERT INTO finance_accounts (code, name, type, parent_id) VALUES
('5000', 'Beban', 'expense', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5100', 'Beban SDM', 'expense', id FROM finance_accounts WHERE code='5000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5110', 'Beban Gaji Fasilitator', 'expense', id FROM finance_accounts WHERE code='5100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5120', 'Beban Komisi', 'expense', id FROM finance_accounts WHERE code='5100'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5200', 'Beban Operasional', 'expense', id FROM finance_accounts WHERE code='5000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5210', 'Beban Sewa', 'expense', id FROM finance_accounts WHERE code='5200'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5220', 'Beban Utilitas', 'expense', id FROM finance_accounts WHERE code='5200'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5300', 'Beban Marketing', 'expense', id FROM finance_accounts WHERE code='5000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5310', 'Beban Iklan Digital', 'expense', id FROM finance_accounts WHERE code='5300'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5400', 'Beban Teknologi', 'expense', id FROM finance_accounts WHERE code='5000'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5410', 'Beban SaaS & Platform', 'expense', id FROM finance_accounts WHERE code='5400'
ON CONFLICT DO NOTHING;

INSERT INTO finance_accounts (code, name, type, parent_id)
SELECT '5500', 'Beban Lainnya', 'expense', id FROM finance_accounts WHERE code='5000'
ON CONFLICT DO NOTHING;
