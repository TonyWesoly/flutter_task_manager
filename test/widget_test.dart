import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_task_manager/main.dart';
import 'package:flutter_task_manager/database/database.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final database = AppDatabase();
    await tester.pumpWidget(MyApp(database: database));

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}