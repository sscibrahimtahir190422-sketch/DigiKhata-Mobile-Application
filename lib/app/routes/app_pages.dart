import 'package:get/get.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/reset_password_view.dart';
import '../../features/customers/bindings/customer_binding.dart';
import '../../features/customers/views/add_customer_view.dart';
import '../../features/customers/views/archived_customers_view.dart';
import '../../features/customers/views/customer_view.dart';
import '../../features/customers/views/edit_customer_view.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/khata/bindings/add_transaction_binding.dart';
import '../../features/khata/bindings/khata_binding.dart';
import '../../features/khata/views/add_transaction_view.dart';
import '../../features/khata/views/edit_transaction_view.dart';
import '../../features/khata/views/khata_view.dart';
import '../../features/inventory/bindings/inventory_binding.dart';
import '../../features/inventory/views/inventory_view.dart';
import '../../features/payments/bindings/payment_binding.dart';
import '../../features/payments/views/payment_view.dart';
import '../../features/reports/bindings/report_binding.dart';
import '../../features/reports/views/report_view.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/statements/bindings/customer_statement_binding.dart';
import '../../features/statements/views/customer_statement_view.dart';
import '../../features/suppliers/bindings/supplier_binding.dart';
import '../../features/suppliers/views/supplier_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomerView(),
      binding: CustomerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addCustomer,
      page: () => const AddCustomerView(),
      binding: CustomerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editCustomer,
      page: () => const EditCustomerView(),
      binding: CustomerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.khata,
      page: () => const KhataView(),
      binding: KhataBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addKhataTransaction,
      page: () => const AddTransactionView(),
      binding: AddTransactionBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editKhataTransaction,
      page: () => const EditTransactionView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.customerStatement,
      page: () => CustomerStatementView(),
      binding: CustomerStatementBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryView(),
      binding: InventoryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.payments,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => ReportView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SupplierView(),
      binding: SupplierBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.archivedCustomers,
      page: () => const ArchivedCustomersView(),
      binding: CustomerBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
