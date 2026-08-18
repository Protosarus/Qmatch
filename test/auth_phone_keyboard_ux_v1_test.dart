import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:qmatch/features/auth/widgets/auth_keyboard_dismiss.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping outside the focused input dismisses the keyboard',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthKeyboardDismiss(
          child: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('phone-input'),
                  focusNode: focus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                Container(
                  key: const Key('outside'),
                  height: 120,
                  width: double.infinity,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('phone-input')));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside')));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('keyboard Done / Continue action unfocuses the phone field',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntlPhoneField(
            focusNode: focus,
            disableLengthCheck: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => AuthKeyboardDismiss.unfocus(),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, TextInputType.phone);
    expect(textField.textInputAction, TextInputAction.done);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('forward accessory dismisses the focused phone field',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                focusNode: focus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              AuthKeyboardActionBar(
                onPressed: AuthKeyboardDismiss.unfocus,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    expect(find.text('Continue'), findsNothing);
    expect(find.byKey(AuthKeyboardActionBar.doneKey), findsOneWidget);
    expect(
      find.byKey(const Key('qmatch-phone-keyboard-forward')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byKey(AuthKeyboardActionBar.doneKey));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  test(
      'phone signup wires phone keyboard, forward dismiss, and outside dismiss',
      () {
    final src = File('lib/features/auth/screens/phone_signup_screen.dart')
        .readAsStringSync();
    expect(src.contains('AuthKeyboardDismiss'), isTrue);
    expect(src.contains('AuthKeyboardActionBar'), isTrue);
    expect(src.contains('TextInputType.phone'), isTrue);
    expect(src.contains('TextInputAction.done'), isTrue);
    expect(src.contains('qmatch-phone-number-field'), isTrue);
    expect(src.contains('continueButtonLabel'), isFalse);
    expect(src.contains('onSubmitted: (_) => _sendCode()'), isFalse);
    expect(src.contains('_dismissKeyboard()'), isTrue);
    expect(src.contains('_sendCode'), isTrue);
    expect(src.contains('_verifyCode'), isTrue);
  });
}
