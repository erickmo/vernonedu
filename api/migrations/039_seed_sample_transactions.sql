INSERT INTO accounting_transactions (reference_number, description, transaction_type, amount, category, transaction_date, status) VALUES
('TRX-2026-001', 'Pendapatan Course Digital Marketing Batch 5', 'income', 15000000, 'Pendapatan Course', '2026-03-20', 'completed'),
('TRX-2026-002', 'Gaji Fasilitator Maret 2026', 'expense', 8500000, 'Gaji & SDM', '2026-03-19', 'completed'),
('TRX-2026-003', 'Biaya Iklan Meta Ads', 'expense', 3200000, 'Marketing', '2026-03-18', 'completed'),
('TRX-2026-004', 'Pendapatan Course Barbershop Batch 3', 'income', 9800000, 'Pendapatan Course', '2026-03-17', 'completed'),
('TRX-2026-005', 'Sewa Gedung Training Center', 'expense', 5000000, 'Operasional', '2026-03-15', 'completed'),
('TRX-2026-006', 'Pendapatan Course Tata Boga Batch 7', 'income', 12400000, 'Pendapatan Course', '2026-03-14', 'completed'),
('TRX-2026-007', 'Langganan Platform LMS', 'expense', 1800000, 'Teknologi', '2026-03-12', 'completed'),
('TRX-2026-008', 'Pendapatan Course Digital Marketing Batch 4', 'income', 13200000, 'Pendapatan Course', '2026-02-28', 'completed'),
('TRX-2026-009', 'Gaji Fasilitator Februari 2026', 'expense', 8000000, 'Gaji & SDM', '2026-02-25', 'completed'),
('TRX-2026-010', 'Biaya Iklan Google Ads', 'expense', 2800000, 'Marketing', '2026-02-20', 'completed')
ON CONFLICT DO NOTHING;
