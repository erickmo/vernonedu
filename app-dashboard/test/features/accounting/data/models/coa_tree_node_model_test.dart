import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_dashboard/features/accounting/data/models/coa_tree_node_model.dart';

void main() {
  group('CoaTreeNodeModel', () {
    test('fromJson parses scalar fields and snake_case keys', () {
      final json = <String, dynamic>{
        'id': 'n1',
        'code': '1',
        'name': 'Aset',
        'account_type': 'asset',
        'parent_code': '',
        'is_active': true,
        'balance': 100,
        'children': const <Map<String, dynamic>>[],
      };

      final model = CoaTreeNodeModel.fromJson(json);

      expect(model.id, 'n1');
      expect(model.code, '1');
      expect(model.name, 'Aset');
      expect(model.accountType, 'asset');
      expect(model.parentCode, '');
      expect(model.isActive, true);
      expect(model.balance, 100);
      expect(model.children, isEmpty);
    });

    test('fromJson parses nested children recursively (2 levels deep)', () {
      final json = <String, dynamic>{
        'code': '1',
        'name': 'Aset',
        'account_type': 'asset',
        'balance': 100,
        'children': [
          {
            'code': '1.1',
            'name': 'Kas',
            'account_type': 'asset',
            'balance': 50,
            'children': [
              {
                'code': '1.1.1',
                'name': 'Kas BCA',
                'account_type': 'asset',
                'balance': 25,
                'children': const <Map<String, dynamic>>[],
              },
            ],
          },
        ],
      };

      final m = CoaTreeNodeModel.fromJson(json);

      expect(m.children.length, 1);
      expect(m.children.first.code, '1.1');
      expect(m.children.first.children.length, 1);
      expect(m.children.first.children.first.code, '1.1.1');
      expect(m.children.first.children.first.balance, 25);
    });

    test('fromJson tolerates missing children and balance', () {
      final m = CoaTreeNodeModel.fromJson({'code': '5', 'name': 'X'});
      expect(m.code, '5');
      expect(m.balance, isNull);
      expect(m.children, isEmpty);
    });

    test('toEntity preserves nested structure', () {
      final json = <String, dynamic>{
        'code': '1',
        'name': 'Aset',
        'children': const [
          {'code': '1.1', 'name': 'Kas', 'children': <Map<String, dynamic>>[]},
        ],
      };
      final entity = CoaTreeNodeModel.fromJson(json).toEntity();
      expect(entity.children.length, 1);
      expect(entity.children.first.code, '1.1');
    });
  });
}
