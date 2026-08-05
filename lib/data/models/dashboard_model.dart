class DashboardSummary {
  final double todaySalesTotal;
  final int todaySalesCount;
  final double todayProfit;
  final double todayExpenses;
  final double yesterdaySalesTotal;
  final double stockCostValue;
  final double stockRetailValue;
  final int lowStockCount;
  final int outOfStockCount;
  final double customersOwingTotal;
  final int customersOwingCount;
  final double thisMonthTotal;
  final List<RecentSaleItem> recentSales;
  final List<TopProduct> topProductsToday;
  final List<HourlyPoint> hourlyChart;

  const DashboardSummary({
    required this.todaySalesTotal,
    required this.todaySalesCount,
    required this.todayProfit,
    required this.todayExpenses,
    required this.yesterdaySalesTotal,
    required this.stockCostValue,
    required this.stockRetailValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.customersOwingTotal,
    required this.customersOwingCount,
    required this.thisMonthTotal,
    required this.recentSales,
    required this.topProductsToday,
    required this.hourlyChart,
  });

  double get salesVsYesterdayPercent {
    if (yesterdaySalesTotal == 0) return 0;
    return ((todaySalesTotal - yesterdaySalesTotal) / yesterdaySalesTotal) *
        100;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final stockValue = json['stock_value'] as Map<String, dynamic>? ?? {};
    final customersOwing =
        json['customers_owing'] as Map<String, dynamic>? ?? {};
    final thisMonth = json['this_month'] as Map<String, dynamic>? ?? {};

    return DashboardSummary(
      todaySalesTotal:
          (json['today_sales_total'] as num?)?.toDouble() ?? 0.0,
      todaySalesCount: (json['today_sales_count'] as num?)?.toInt() ?? 0,
      todayProfit: (json['today_profit'] as num?)?.toDouble() ?? 0.0,
      todayExpenses: (json['today_expenses'] as num?)?.toDouble() ?? 0.0,
      yesterdaySalesTotal:
          (json['yesterday_sales_total'] as num?)?.toDouble() ?? 0.0,
      stockCostValue:
          (stockValue['cost_value'] as num?)?.toDouble() ?? 0.0,
      stockRetailValue:
          (stockValue['retail_value'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['out_of_stock_count'] as num?)?.toInt() ?? 0,
      customersOwingTotal:
          (customersOwing['total_owed'] as num?)?.toDouble() ?? 0.0,
      customersOwingCount:
          (customersOwing['count'] as num?)?.toInt() ?? 0,
      thisMonthTotal:
          (thisMonth['total'] as num?)?.toDouble() ?? 0.0,
      recentSales: (json['recent_sales'] as List<dynamic>?)
              ?.map((e) =>
                  RecentSaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProductsToday: (json['top_products_today'] as List<dynamic>?)
              ?.map((e) =>
                  TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyChart: (json['hourly_chart'] as List<dynamic>?)
              ?.map((e) => HourlyPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RecentSaleItem {
  final int id;
  final String saleNumber;
  final double total;
  final String paymentMethod;
  final String createdAt;
  final String? customerName;
  final int itemsCount;

  const RecentSaleItem({
    required this.id,
    required this.saleNumber,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.customerName,
    required this.itemsCount,
  });

  factory RecentSaleItem.fromJson(Map<String, dynamic> json) => RecentSaleItem(
        id: json['id'] as int,
        saleNumber: json['sale_number'] as String,
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        createdAt: json['created_at'] as String,
        customerName: (json['customer'] as Map<String, dynamic>?)?['name']
            as String?,
        itemsCount:
            (json['items'] as List<dynamic>?)?.length ?? 0,
      );
}

class TopProduct {
  final int id;
  final String name;
  final double totalQty;
  final double totalRevenue;
  final double totalProfit;

  const TopProduct({
    required this.id,
    required this.name,
    required this.totalQty,
    required this.totalRevenue,
    required this.totalProfit,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
        id: json['id'] as int,
        name: json['name'] as String,
        totalQty: (json['total_qty'] as num?)?.toDouble() ?? 0.0,
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
        totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      );
}

class HourlyPoint {
  final int hour;
  final double total;
  final int count;

  const HourlyPoint({
    required this.hour,
    required this.total,
    required this.count,
  });

  factory HourlyPoint.fromJson(Map<String, dynamic> json) => HourlyPoint(
        hour: int.tryParse(json['hour']?.toString() ?? '0') ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class PeriodReport {
  final String period;
  final String from;
  final String to;
  final double totalRevenue;
  final double totalProfit;
  final double totalExpenses;
  final double netProfit;
  final int totalTransactions;
  final List<ChartPoint> revenueChart;
  final List<TopProduct> topProducts;

  const PeriodReport({
    required this.period,
    required this.from,
    required this.to,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalTransactions,
    required this.revenueChart,
    required this.topProducts,
  });

  factory PeriodReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return PeriodReport(
      period: json['period'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalRevenue: (summary['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (summary['total_profit'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (summary['total_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (summary['net_profit'] as num?)?.toDouble() ?? 0.0,
      totalTransactions:
          (summary['total_transactions'] as num?)?.toInt() ?? 0,
      revenueChart: (json['revenue_chart'] as List<dynamic>?)
              ?.map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts: (json['top_products'] as List<dynamic>?)
              ?.map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(
        label: json['label']?.toString() ?? '',
        value: (json['total'] as num?)?.toDouble() ??
            (json['value'] as num?)?.toDouble() ??
            0.0,
      );
}
