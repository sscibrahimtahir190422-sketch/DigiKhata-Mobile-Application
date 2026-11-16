import 'package:flutter_test/flutter_test.dart';
import 'package:digikhata/app/app.dart';

void main() {
  testWidgets('DigiKhata app starts', (tester) async {
    await tester.pumpWidget(const DigiKhataApp());

    expect(find.text('DigiKhata'), findsOneWidget);
  });
}
