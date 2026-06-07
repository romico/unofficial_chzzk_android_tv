import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../common/constants/enums.dart'
    show KeyboardCase, KeyboardLanguage, VirtualKeyboardLayoutType;
import '../../../common/constants/styles.dart' show AppColors;
import '../../../common/widgets/dpad/dpad_widgets.dart';
import '../../../common/widgets/ui/ui_widgets.dart' show RoundedContainer;
import '../controller/virtual_keyboard_controller.dart'
    show VirtualKeyboardEvent, VirtualKeyboardState, virtualKeyboardControllerProvider;
import 'virtual_keyboard_key.dart' show VirtualKeyboardKey;

class VirtualKeyboardLayout extends HookConsumerWidget
    with VirtualKeyboardState {
  /// A virtual keyboard [GridView] layout.
  ///
  /// Use with the [VirtualKeyboardInputField].
  const VirtualKeyboardLayout({
    super.key,
    required this.routeName,
    this.layoutType = VirtualKeyboardLayoutType.qwerty,
    this.maxInputLength,
    this.keyboardFSN,
    this.bindings,
    this.dpadKeyNodeMap,
    this.borderRadius = 12.0,
    this.backgroundColor = Colors.transparent,
    this.padding = const EdgeInsets.all(10.0),
    this.margin = const EdgeInsets.all(10.0),
    this.initialLanguage = KeyboardLanguage.english,
    this.enterKeyName = 'ENTER',
    this.autoSubmitOnMaxLength = false,
    this.onNormalKeyPressed,
    required this.onEnterPressed,
  });

  final String routeName;
  final VirtualKeyboardLayoutType layoutType;
  final int? maxInputLength;
  final FocusScopeNode? keyboardFSN;
  final ShortcutsBindings Function(int index)? bindings;
  final DpadKeyNodeMap? dpadKeyNodeMap;

  final double borderRadius;
  final Color backgroundColor;

  /// Inside the empty space between the layout container and the keys.
  final EdgeInsetsGeometry padding;

  /// Empty space outside the layout.
  final EdgeInsetsGeometry margin;

  /// Initial language setting.
  final KeyboardLanguage initialLanguage;

  /// Do actions when the any key other than a special key
  /// such as enter, backspace, etc. is pressed.
  final Function(String inputText)? onNormalKeyPressed;

  /// Do actions when the Enter key is pressed.
  ///
  /// char: add, back: remove, enter: onEnterPressed.
  final Function(String inputText) onEnterPressed;

  final String enterKeyName;
  final bool autoSubmitOnMaxLength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetFSN = keyboardFSN ?? useFocusScopeNode();

    if (layoutType == VirtualKeyboardLayoutType.numeric) {
      return RoundedContainer(
        margin: margin,
        padding: padding,
        child: FocusScope(
          node: widgetFSN,
          child: _NumericKeyboardGridView(
            routeName: routeName,
            dpadKeyNodeMap: dpadKeyNodeMap,
            bindings: (index) => bindings?.call(index) ?? {},
            keyboardKeys: getNumericKeyboardKeys(),
            maxInputLength: maxInputLength,
            autoSubmitOnMaxLength: autoSubmitOnMaxLength,
            onKey: onNormalKeyPressed,
            onEnterPressed: onEnterPressed,
            enterKeyName: enterKeyName,
          ),
        ),
      );
    }

    final keyboardCaseState = useState<KeyboardCase>(KeyboardCase.lower);
    final keyboardLanguageState = useState<KeyboardLanguage>(initialLanguage);

    final keyboardKeys = getQwertyKeyboardKeys(
      keyboardCaseState.value,
      keyboardLanguageState.value,
    );

    return RoundedContainer(
      margin: margin,
      padding: padding,
      child: FocusScope(
        node: widgetFSN,
        child: _QwertyKeyboardGridView(
          routeName: routeName,
          dpadKeyNodeMap: dpadKeyNodeMap,
          bindings: (index) {
            return bindings?.call(index) ?? {};
          },
          keyboardCaseState: keyboardCaseState,
          keyboardLanguageState: keyboardLanguageState,
          keyboardKeys: keyboardKeys,
          onKey: onNormalKeyPressed,
          onEnterPressed: onEnterPressed,
          enterKeyName: enterKeyName,
        ),
      ),
    );
  }
}

class _NumericKeyboardGridView extends HookConsumerWidget
    with VirtualKeyboardEvent {
  const _NumericKeyboardGridView({
    required this.routeName,
    required this.keyboardKeys,
    this.maxInputLength,
    this.autoSubmitOnMaxLength = false,
    this.enterKeyName = 'ENTER',
    this.onKey,
    required this.onEnterPressed,
    this.bindings,
    this.dpadKeyNodeMap,
  });

  static const int _backIndex = 9;
  static const int _enterIndex = 11;

  final String routeName;
  final List<String> keyboardKeys;
  final int? maxInputLength;
  final bool autoSubmitOnMaxLength;
  final String enterKeyName;
  final void Function(String text)? onKey;
  final void Function(String text) onEnterPressed;
  final ShortcutsBindings Function(int index)? bindings;
  final DpadKeyNodeMap? dpadKeyNodeMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enterFocusNode = useFocusNode();

    ref.listen(
      virtualKeyboardControllerProvider(routeName: routeName),
      (previous, next) {
        if (maxInputLength == null) return;
        if (next.length == maxInputLength &&
            previous?.length != maxInputLength) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (autoSubmitOnMaxLength) {
              onEnterPressed(next);
              return;
            }
            if (enterFocusNode.canRequestFocus) {
              enterFocusNode.requestFocus();
            }
          });
        }
      },
    );

    final customKeyboardKeys = keyboardKeys.toList()
      ..[_backIndex] = '지움'
      ..[_enterIndex] = enterKeyName;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 2.2,
      ),
      itemCount: customKeyboardKeys.length,
      itemBuilder: (context, index) {
        return DpadCallbackShortcuts(
          dpadKeyNodeMap: dpadKeyNodeMap,
          bindings: bindings != null ? bindings!(index) : null,
          child: VirtualKeyboardKey(
            autofocus: index == 0,
            focusNode: index == _enterIndex ? enterFocusNode : null,
            fontSize: 18.0,
            keyboardKey: customKeyboardKeys[index],
            onPressed: (keyboardKey) {
              switch (index) {
                case _backIndex:
                  removeLastCharacter(
                    ref,
                    routeName: routeName,
                    onKeyPressed: onKey,
                  );
                case _enterIndex:
                  enter(ref, routeName, onEnterPressed);
                default:
                  final currentInput = ref.read(
                    virtualKeyboardControllerProvider(routeName: routeName),
                  );
                  if (maxInputLength != null &&
                      currentInput.length >= maxInputLength!) {
                    return;
                  }
                  onKeyPressed(
                    ref,
                    routeName: routeName,
                    char: keyboardKey,
                    language: KeyboardLanguage.english,
                    onKeyPressed: onKey,
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class _QwertyKeyboardGridView extends ConsumerWidget with VirtualKeyboardEvent {
  const _QwertyKeyboardGridView({
    required this.routeName,
    required this.keyboardCaseState,
    required this.keyboardLanguageState,
    required this.keyboardKeys,
    this.enterKeyName = 'ENTER',
    this.onKey,
    required this.onEnterPressed,
    this.bindings,
    this.dpadKeyNodeMap,
  });

  final String routeName;
  final ValueNotifier<KeyboardCase> keyboardCaseState;
  final ValueNotifier<KeyboardLanguage> keyboardLanguageState;
  final List<String> keyboardKeys;
  final String enterKeyName;
  final void Function(String text)? onKey;
  final void Function(String text) onEnterPressed;
  final ShortcutsBindings Function(int index)? bindings;
  final DpadKeyNodeMap? dpadKeyNodeMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      // Set this to true to adjust the size of [GridView] to the size of the children.
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12, // max row count
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
        childAspectRatio: 1 / 1,
      ),
      itemCount: keyboardKeys.length,
      itemBuilder: (context, index) {
        /* 
        35: Backspace => remove
        36: Shift => change case
        47: Enter => onEnterPressed
        48: KOR/ENG => change language
        default: Normal Keys => add character
        */

        // highlight shift
        final keyColor =
            index == 36 && keyboardCaseState.value == KeyboardCase.upper
                ? AppColors.chzzkColor
                : AppColors.whiteColor;

        final customKeyboardKeys = keyboardKeys.toList()..[47] = enterKeyName;

        return DpadCallbackShortcuts(
          dpadKeyNodeMap: dpadKeyNodeMap,
          bindings: bindings != null ? bindings!(index) : null,
          child: VirtualKeyboardKey(
            autofocus: index == 0,
            fontColor: keyColor,
            keyboardKey: customKeyboardKeys[index],
            onPressed: (keyboardKey) {
              switch (index) {
                case 35: // Backspace: remove
                  removeLastCharacter(
                    ref,
                    routeName: routeName,
                    onKeyPressed: onKey,
                  );
                case 36: // Shift: change case
                  changeCase(keyboardCaseState);
                case 47: // Enter: onEnterPressed
                  enter(ref, routeName, onEnterPressed);
                case 48: // KOR/ENG:
                  changeLanguage(keyboardLanguageState);
                default:
                  onKeyPressed(
                    ref,
                    routeName: routeName,
                    char: keyboardKey,
                    language: keyboardLanguageState.value,
                    onKeyPressed: onKey,
                  );
              }
            },
          ),
        );
      },
    );
  }
}
