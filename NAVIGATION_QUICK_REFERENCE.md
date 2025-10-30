# Navigation Quick Reference

## Common Navigation Patterns

### ✅ DO - Professional Patterns

```dart
// 1. Use ensure pattern for controllers that might not exist
final controller = RegisterPageController.ensure();

// 2. Use NavigationService for consistent routing
NavigationService.toRegister();
NavigationService.toOtp();
NavigationService.back();

// 3. Check before using Get.find()
if (Get.isRegistered<SomeController>()) {
  final controller = Get.find<SomeController>();
}

// 4. Use named routes
Get.toNamed('/profile');
Get.offAllNamed('/navView');

// 5. Proper error handling
try {
  await someAction();
} catch (e, st) {
  AppLogger.e('Action failed', error: e, stackTrace: st);
  _showError('Error', 'Action failed');
}

// 6. Clean up in onClose
@override
void onClose() {
  myController.dispose();
  myFocusNode.dispose();
  super.onClose();
}
```

### ❌ DON'T - Anti-patterns

```dart
// 1. DON'T use Get.find() without checking
final controller = Get.find<SomeController>(); // Can crash!

// 2. DON'T create controllers in widgets
final controller = Get.put(SomeController()); // Memory leak risk

// 3. DON'T mix navigation styles
Get.to(() => SomePage());
Get.toNamed('/some');
Navigator.push(...); // Inconsistent!

// 4. DON'T manually count pops
int count = 0;
while (count < 5 && canPop) {
  Get.back();
  count++;
} // Fragile!

// 5. DON'T ignore errors
try {
  await something();
} catch (e) {
  // Ignored - BAD!
}

// 6. DON'T forget to dispose
// No onClose() = memory leak!
```

## Quick Fixes for Common Issues

### Issue: "Controller not found"
```dart
// Before
final controller = Get.find<MyController>();

// After
final controller = MyController.ensure();

// Or
if (Get.isRegistered<MyController>()) {
  final controller = Get.find<MyController>();
} else {
  // Handle missing controller
}
```

### Issue: Navigation stack confusion
```dart
// Before
Get.back();
Get.back();
Get.offAll(() => HomePage());

// After
NavigationService.clearStackAndGoTo('/navView');
```

### Issue: Screen not closing
```dart
// Before
Get.back();

// After
NavigationUtils.close(context);
// or
NavigationUtils.closeGlobal();
```

### Issue: User stuck on auth screens
```dart
// Before
Get.until((route) => route.settings.name == '/home');

// After
void _navigateAfterSuccess() {
  // Try origin route
  if (_originRoute != null) {
    try {
      Get.until((route) => route.settings.name == _originRoute);
      return;
    } catch (_) {}
  }
  
  // Fallback
  Get.offAllNamed('/navView');
}
```

## Controller Lifecycle Checklist

```dart
class MyController extends GetxController {
  // ✅ 1. Add ensure pattern
  static MyController ensure() {
    if (Get.isRegistered<MyController>()) {
      return Get.find<MyController>();
    }
    return Get.put(MyController(), permanent: false);
  }

  // ✅ 2. Initialize resources
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  
  // ✅ 3. Add onInit if needed
  @override
  void onInit() {
    super.onInit();
    AppLogger.d('MyController initialized');
    // Setup listeners, fetch data, etc.
  }
  
  // ✅ 4. ALWAYS add onClose
  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    AppLogger.d('MyController disposed');
    super.onClose();
  }
}
```

## Navigation Service Usage

```dart
// Auth flow
NavigationService.toRegister(from: '/profile');
NavigationService.toOtp();

// Main app
NavigationService.toHome(clearStack: true);
NavigationService.toProfile();
NavigationService.toFilter();
NavigationService.toSearch();

// Utilities
NavigationService.back<String>(result: 'data');
NavigationService.popUntil('/home');
NavigationService.clearStackAndGoTo('/navView');

// Checks
if (NavigationService.canPop) {
  NavigationService.back();
}

String current = NavigationService.currentRoute;
```

## Error Handling Template

```dart
Future<void> myAction() async {
  if (isLoading.value) return; // Prevent double-tap
  
  isLoading.value = true;
  
  try {
    AppLogger.d('Starting myAction');
    
    // Your code here
    final result = await someApiCall();
    
    if (result.success) {
      AppLogger.i('myAction succeeded');
      _showSuccess('Success', 'Action completed');
    } else {
      AppLogger.w('myAction failed: ${result.message}');
      _showError('Error', result.message ?? 'Action failed');
    }
    
  } on SocketException catch (e) {
    AppLogger.e('Network error', error: e);
    _showError('Network Error', 'Check your connection');
    
  } on TimeoutException catch (e) {
    AppLogger.e('Timeout', error: e);
    _showError('Timeout', 'Request took too long');
    
  } catch (e, st) {
    AppLogger.e('Unexpected error', error: e, stackTrace: st);
    _showError('Error', 'Something went wrong');
    
  } finally {
    isLoading.value = false;
  }
}
```

## Testing Shortcuts

```dart
// Print current navigation state
NavigationService.debugPrintStack();

// Check if route exists
if (NavigationService.isRouteInStack('/profile')) {
  // Route exists in stack
}

// Safe navigation with error handling
final success = await NavigationService.safeNavigate(() async {
  return Get.toNamed('/profile');
});

if (!success) {
  // Navigation failed
}
```

## Common Gotchas

1. **GetX context**: Use `Get.context` or `Get.key.currentContext`
2. **Named routes**: Must be defined in GetPages
3. **Arguments**: Pass via `Get.toNamed('/route', arguments: data)`
4. **Back button**: Override with WillPopScope or PopScope
5. **Bindings**: Best practice but optional (we use ensure pattern)

## When to Use What

| Scenario | Solution |
|----------|----------|
| Simple page navigation | `Get.toNamed('/route')` |
| Replace current page | `Get.offNamed('/route')` |
| Clear stack + navigate | `Get.offAllNamed('/route')` |
| Go back | `NavigationUtils.close(context)` |
| Pop until route | `NavigationService.popUntil('/route')` |
| Controller might not exist | `MyController.ensure()` |
| Need guaranteed controller | `Get.put(MyController())` |
| Lazy loading | Bindings or `Get.lazyPut()` |
| Global controller | `permanent: true` |
| Screen-specific controller | `permanent: false` |
