import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/data/models/finance_analysis_model.dart';

void main() {
  group('FinancialRatiosModel', () {
    test('fromJson parses nested RatioMetric structures', () {
      final json = {
        'profit_margin': {
          'current': 12.5,
          'previous': 10.0,
          'change': 2.5,
          'change_pct': 25.0,
          'trend': 'up',
        },
        'expense_ratio': {'current': 70.0, 'trend': 'down'},
      };
      final m = FinancialRatiosModel.fromJson(json);
      expect(m.profitMargin.current, 12.5);
      expect(m.profitMargin.changePct, 25.0);
      expect(m.profitMargin.trend, 'up');
      expect(m.expenseRatio.current, 70.0);
      expect(m.expenseRatio.trend, 'down');
      // Missing keys default to empty.
      expect(m.collectionRate.current, 0.0);
      expect(m.collectionRate.trend, 'flat');
    });

    test('toEntity preserves all 8 ratio metrics', () {
      final m = FinancialRatiosModel.fromJson({});
      final e = m.toEntity();
      expect(e.profitMargin.current, 0.0);
      expect(e.daysSalesOutstanding.trend, 'flat');
    });
  });

  group('RevenueAnalysisModel', () {
    test('fromJson parses monthly_trend and by_group', () {
      final json = {
        'total_revenue': 1000000,
        'group_by': 'course_type',
        'monthly_trend': [
          {
            'month': '2026-01',
            'total': 500000,
            'regular': 200000,
            'career': 100000,
            'inhouse': 100000,
            'collab': 50000,
            'cert': 50000,
          },
        ],
        'by_group': [
          {
            'group_key': 'Reguler',
            'revenue': 200000,
            'pct_of_total': 40.0,
            'batch_count': 5,
            'avg_per_batch': 40000,
            'trend': 'up',
          },
        ],
      };
      final m = RevenueAnalysisModel.fromJson(json);
      expect(m.totalRevenue, 1000000);
      expect(m.groupBy, 'course_type');
      expect(m.monthlyTrend, hasLength(1));
      expect(m.monthlyTrend.first.regular, 200000);
      expect(m.byGroup.first.batchCount, 5);
      expect(m.byGroup.first.trend, 'up');
    });
  });

  group('CostAnalysisModel', () {
    test('fromJson parses monthly_trend, by_category, total_cost', () {
      final json = {
        'total_cost': 500000,
        'monthly_trend': [
          {
            'month': '2026-01',
            'total': 250000,
            'facilitator': 100000,
            'commission': 50000,
            'operational': 50000,
            'marketing': 25000,
            'other': 25000,
          },
        ],
        'by_category': [
          {
            'category': 'Fasilitator',
            'amount': 100000,
            'pct_of_total': 40.0,
            'vs_previous': 5000,
            'trend': 'up',
          },
        ],
      };
      final m = CostAnalysisModel.fromJson(json);
      expect(m.totalCost, 500000);
      expect(m.monthlyTrend.first.facilitator, 100000);
      expect(m.byCategory.first.pctOfTotal, 40.0);
      expect(m.byCategory.first.vsPrevious, 5000);
    });
  });

  group('BatchProfitModel', () {
    test('fromJson parses items list with expense + margin_pct', () {
      final json = {
        'avg_margin': 15.5,
        'sort': 'top',
        'items': [
          {
            'batch_id': 'b1',
            'batch_code': 'B-001',
            'course_name': 'Flutter',
            'revenue': 1000000,
            'expense': 700000,
            'commission': 50000,
            'profit': 250000,
            'margin_pct': 25.0,
          },
        ],
      };
      final m = BatchProfitModel.fromJson(json);
      expect(m.avgMargin, 15.5);
      expect(m.sort, 'top');
      expect(m.items.first.expense, 700000);
      expect(m.items.first.marginPct, 25.0);
    });
  });

  group('CashForecastModel', () {
    test('fromJson parses months[] + upcoming_events[] + current_cash', () {
      final json = {
        'current_cash': 5000000,
        'months': [
          {
            'month': '2026-01',
            'opening_cash': 5000000,
            'inflow': 1000000,
            'outflow': 800000,
            'closing_cash': 5200000,
          },
        ],
        'upcoming_events': [
          {
            'date': '2026-01-15',
            'event_type': 'inflow',
            'description': 'Pembayaran batch',
            'amount': 500000,
            'status': 'projected',
          },
        ],
      };
      final m = CashForecastModel.fromJson(json);
      expect(m.currentCash, 5000000);
      expect(m.months.first.openingCash, 5000000);
      expect(m.months.first.closingCash, 5200000);
      expect(m.upcomingEvents.first.eventType, 'inflow');
      expect(m.upcomingEvents.first.status, 'projected');
    });
  });

  group('FinancialAlertModel', () {
    test('fromJson parses level/code/message/count/amount', () {
      final m = FinancialAlertModel.fromJson({
        'level': 'warning',
        'code': 'OVERDUE_INVOICES',
        'message': '5 invoice jatuh tempo',
        'count': 5,
        'amount': 1500000,
      });
      expect(m.level, 'warning');
      expect(m.code, 'OVERDUE_INVOICES');
      expect(m.count, 5);
      expect(m.amount, 1500000);
    });

    test('fromJson defaults level to info if missing', () {
      final m = FinancialAlertModel.fromJson({'message': 'x'});
      expect(m.level, 'info');
    });
  });

  group('FinancialSuggestionModel', () {
    test('fromJson parses icon/message/amount/detail', () {
      final m = FinancialSuggestionModel.fromJson({
        'icon': '💡',
        'message': 'Tingkatkan margin',
        'amount': 100000,
        'detail': 'Reduce facilitator cost by 5%',
      });
      expect(m.icon, '💡');
      expect(m.message, 'Tingkatkan margin');
      expect(m.amount, 100000);
      expect(m.detail, 'Reduce facilitator cost by 5%');
    });
  });
}
