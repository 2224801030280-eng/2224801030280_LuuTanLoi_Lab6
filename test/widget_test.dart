import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_music_player/screens/login_screen.dart';

void main() {
  testWidgets('Login screen displays the music app welcome flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Mở nhạc,\nchạm cảm xúc.'), findsOneWidget);
    expect(find.text('Tên tài khoản'), findsOneWidget);
    expect(find.text('Đăng nhập & khám phá'), findsOneWidget);
  });
}
