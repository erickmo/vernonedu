INSERT INTO chart_of_accounts (code, name, account_type) VALUES
-- Assets
('1000', 'Aset', 'asset'),
('1100', 'Kas & Bank', 'asset'),
('1110', 'Kas Tunai', 'asset'),
('1120', 'Bank BCA', 'asset'),
('1130', 'Bank Mandiri', 'asset'),
('1200', 'Piutang Usaha', 'asset'),
('1210', 'Piutang Siswa', 'asset'),
('1300', 'Aset Lancar Lainnya', 'asset'),
('1400', 'Aset Tetap', 'asset'),
-- Liabilities
('2000', 'Kewajiban', 'liability'),
('2100', 'Hutang Usaha', 'liability'),
('2110', 'Hutang Komisi', 'liability'),
('2120', 'Hutang Fasilitator', 'liability'),
('2200', 'Kewajiban Jangka Panjang', 'liability'),
-- Equity
('3000', 'Ekuitas', 'equity'),
('3100', 'Modal', 'equity'),
('3200', 'Laba Ditahan', 'equity'),
-- Revenue
('4000', 'Pendapatan', 'revenue'),
('4100', 'Pendapatan Course', 'revenue'),
('4110', 'Pendapatan Program Karir', 'revenue'),
('4120', 'Pendapatan Reguler', 'revenue'),
('4130', 'Pendapatan Privat', 'revenue'),
('4140', 'Pendapatan Inhouse', 'revenue'),
('4200', 'Pendapatan Lainnya', 'revenue'),
-- Expenses
('5000', 'Beban', 'expense'),
('5100', 'Beban Gaji & SDM', 'expense'),
('5110', 'Beban Gaji Fasilitator', 'expense'),
('5120', 'Beban Komisi', 'expense'),
('5200', 'Beban Operasional', 'expense'),
('5210', 'Beban Sewa', 'expense'),
('5220', 'Beban Utilitas', 'expense'),
('5300', 'Beban Marketing', 'expense'),
('5310', 'Beban Iklan Digital', 'expense'),
('5400', 'Beban Teknologi', 'expense'),
('5410', 'Beban SaaS & Platform', 'expense'),
('5500', 'Beban Lainnya', 'expense')
ON CONFLICT (code) DO NOTHING;
