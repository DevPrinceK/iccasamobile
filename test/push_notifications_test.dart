import 'package:flutter_test/flutter_test.dart';
import 'package:iccasa_mobile/core/services/push_notifications.dart';

void main() {
  test('only known notification destinations can be opened', () {
    expect(mobileNotificationRoute({'route': '/assignments'}), '/assignments');
    expect(mobileNotificationRoute({'route': '/records'}), '/records');
    expect(mobileNotificationRoute({'route': '/admin/users'}), '/home');
    expect(mobileNotificationRoute({}), '/home');
  });
}
