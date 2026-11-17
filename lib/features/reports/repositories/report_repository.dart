import '../models/business_report.dart';

abstract interface class ReportRepository {
  Future<BusinessReport> load({required DateTime start, required DateTime end});
}
