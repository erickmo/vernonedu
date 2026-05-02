import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_dashboard/features/accounting/data/models/bank_account_model.dart';

void main() {
  group('BankAccountModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'a1',
        'branch_id': 'b1',
        'name': 'Kas Operasional',
        'bank_name': 'BCA',
        'account_number': '1234567890',
        'balance_cents': 1500000,
        'currency': 'IDR',
        'coa_code': '1101',
        'is_active': true,
      };

      final model = BankAccountModel.fromJson(json);

      expect(model.id, 'a1');
      expect(model.branchId, 'b1');
      expect(model.name, 'Kas Operasional');
      expect(model.bankName, 'BCA');
      expect(model.accountNumber, '1234567890');
      expect(model.balanceCents, 1500000);
      expect(model.currency, 'IDR');
      expect(model.coaCode, '1101');
      expect(model.isActive, true);
    });

    test('fromJson tolerates missing optional fields', () {
      final model = BankAccountModel.fromJson({'id': 'x'});
      expect(model.id, 'x');
      expect(model.balanceCents, 0);
      expect(model.currency, 'IDR');
      expect(model.isActive, true);
    });

    test('toEntity preserves field values', () {
      final model = BankAccountModel.fromJson({
        'id': 'a1',
        'branch_id': 'b1',
        'name': 'Kas',
        'balance_cents': 250000,
        'is_active': false,
      });
      final entity = model.toEntity();
      expect(entity.id, 'a1');
      expect(entity.branchId, 'b1');
      expect(entity.name, 'Kas');
      expect(entity.balanceCents, 250000);
      expect(entity.isActive, false);
      expect(entity.balance, 2500.0);
    });

    test('toCreateJson and toUpdateJson produce expected shape', () {
      const model = BankAccountModel(
        id: 'a1',
        branchId: 'b1',
        name: 'Kas',
        bankName: 'BCA',
        accountNumber: '111',
        balanceCents: 100,
        currency: 'IDR',
        coaCode: '1101',
        isActive: true,
      );
      expect(model.toCreateJson()['branch_id'], 'b1');
      expect(model.toCreateJson()['balance_cents'], 100);
      expect(model.toUpdateJson().containsKey('branch_id'), false);
      expect(model.toUpdateJson()['name'], 'Kas');
    });
  });
}
