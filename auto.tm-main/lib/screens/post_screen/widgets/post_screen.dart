// Fixed import paths to match real lib structure under screens/post_screen
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'dart:async'; // for Timer debounce
import 'package:auto_tm/screens/post_screen/widgets/location_selection.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_video_photo_widget.dart';
// upload_progress_screen deprecated
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removed design primitive imports (AppCard/AppSection) since they don't exist in project; using local _buildSectionCard.
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:auto_tm/utils/navigation_utils.dart';
import 'package:get_storage/get_storage.dart';
import '../controller/upload_manager.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  late final PostController postController;
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'post_screen_root');
  final FocusNode _focusSinkNode = FocusNode(debugLabel: 'post_screen_sink');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _vehicleSectionKey = GlobalKey();
  // Scroll persistence
  static const _scrollOffsetKey = 'post_screen_scroll_offset_v1';
  bool _restoredScroll = false;
  Timer? _scrollDebounce; // debounce timer for scroll persistence
  // Inline validation errors (local UI state)
  String? _brandError;
  String? _modelError;
  // Expansion removed – sections always expanded now
  bool _showingExitDialog =
      false; // prevents multiple dialogs / rapid double back

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    postController = Get.isRegistered<PostController>()
        ? Get.find<PostController>()
        : Get.put(PostController());
    // Restore scroll offset after first frame
    _scrollController.addListener(() {
      // Debounce writes to storage to reduce IO + main thread overhead during fast scrolls
      _scrollDebounce?.cancel();
      _scrollDebounce = Timer(const Duration(milliseconds: 250), () {
        try {
          GetStorage().write(_scrollOffsetKey, _scrollController.offset);
        } catch (_) {}
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_restoredScroll) return;
      final stored = GetStorage().read(_scrollOffsetKey);
      if (stored is double) {
        _scrollController.jumpTo(
          stored.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
      _restoredScroll = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rootFocusNode.dispose();
    _focusSinkNode.dispose();
    _scrollController.dispose();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  // Lifecycle autosave removed (draft feature removed).

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  void _parkFocus() {
    // Move focus to a sink node so Flutter won't restore last text field automatically
    if (!_focusSinkNode.hasFocus) {
      _focusSinkNode.requestFocus();
    }
  }

  Future<void> _openSelection(Future<void> Function() action) async {
    // Clear current text field focus and park into sink to avoid automatic restoration.
    _unfocus();
    _parkFocus();
    await action();
    // Re-park once more in case the bottom sheet/pop pushed focus changes.
    _parkFocus();
  }

  void _safeCloseOverlay([dynamic result]) =>
      NavigationUtils.safePop(context, result: result);

  // Unified closing now handled via NavigationUtils.close

  @override
  Widget build(BuildContext context) {
    // Avoid re-fetching brands every build; fetch only if empty
    if (postController.brands.isEmpty && !postController.isLoadingB.value) {
      postController.fetchBrands();
    }
    final theme = Theme.of(context);

    Future<void> _handleExit() async {
      if (_showingExitDialog || Get.isDialogOpen == true) return;
      // Active upload? show limited options
      try {
        final mgr = Get.find<UploadManager>();
        final t = mgr.currentTask.value;
        final active =
            t != null &&
            !t.isCompleted.value &&
            !t.isFailed.value &&
            !t.isCancelled.value;
        if (active) {
          _showingExitDialog = true;
          final result = await Get.dialog<String>(
            AlertDialog(
              title: Text('Upload in progress'.tr),
              content: Text(
                'A post is still uploading. Leaving will not stop it.'.tr,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Use Navigator.pop to avoid Get.back() snackbar interaction
                    Navigator.of(context, rootNavigator: true).pop('leave');
                  },
                  child: Text('Leave'.tr),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('stay');
                  },
                  child: Text('Stay'.tr),
                ),
              ],
            ),
          );
          _showingExitDialog = false;
          // 'view' no longer a path (deprecated)
          if (result == 'leave') {
            NavigationUtils.close(context);
            return;
          }
          return; // stay
        }
      } catch (_) {}
      // NEW LOGIC: If a saved snapshot exists (partial or complete) we exit immediately, even if incomplete.
      if (postController.isFormSaved.value && !postController.isDirty.value) {
        NavigationUtils.close(context);
        return;
      }
      // If form never saved and empty -> just leave silently
      if (!postController.isFormSaved.value && !postController.hasAnyInput) {
        NavigationUtils.close(context);
        return;
      }
      // If form is saved but dirty OR unsaved with some input -> show discard dialog
      _showingExitDialog = true;
      final discard = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Discard changes?'.tr),
          content: Text(
            postController.isFormSaved.value
                ? 'Revert to last saved form and leave?'.tr
                : 'Leave without saving the form?'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(false);
              },
              child: Text('Cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(true);
              },
              child: Text('Discard'.tr),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      _showingExitDialog = false;
      if (discard == true) {
        try {
          if (postController.isFormSaved.value) {
            // Revert to last saved snapshot (without resetting saved state)
            postController.revertToSavedSnapshot();
          } else {
            postController.disposeVideo();
            postController.reset();
          }
        } catch (_) {}
        NavigationUtils.close(context);
      }
    }

    // Use WillPopScope for broad compatibility; delegate logic to _handleExit
    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        // _handleExit decides whether to actually pop. Always return false to prevent double pop.
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              if (!NavigationUtils.throttle('post_back')) return;
              await _handleExit();
            },
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Post'.tr, // Already mapped to post_create_title in translations; keep legacy key usage for now
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Obx(() {
                final saved = postController.isFormSaved.value;
                final dirty = postController.isDirty.value;
                final text = !saved
                    ? 'Unsaved form'.tr // post_unsaved_form
                    : (dirty ? 'Unsaved changes'.tr // post_unsaved_changes
                        : 'All changes saved'.tr); // post_all_saved
                final color = dirty
                    ? theme.colorScheme.error
                    : (saved
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6));
                return Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                );
              }),
            ],
          ),
        ),
        body: FocusTraversalGroup(
          child: Focus(
            focusNode: _rootFocusNode,
            child: GestureDetector(
              onTap: _unfocus,
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      if (!postController.hydratedFromStorage.value) {
                        return const SizedBox.shrink();
                      }
                      final c = Theme.of(context).colorScheme;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: c.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: c.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restore_rounded,
                              size: 20,
                              color: c.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saved form loaded'.tr, // post_saved_form_loaded
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.onPrimaryContainer,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                postController.dismissHydratedIndicator();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              child: Text(
                                'Dismiss'.tr, // post_dismiss
                                style: TextStyle(color: c.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Hidden focus sink
                    Offstage(
                      child: Focus(
                        focusNode: _focusSinkNode,
                        canRequestFocus: true,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.perm_media_outlined,
                      title: 'Photos and Video'.tr, // post_photos_video
                      child: Column(
                        children: [const PostMediaScrollableSelectionWidget()],
                      ),
                    ),
                    // Vehicle Section (Brand, Model, Condition, Year)
                    Container(
                      key: _vehicleSectionKey,
                      child: _buildSectionCard(
                        context,
                        icon: Icons.directions_car_filled_outlined,
                        title: 'Vehicle'.tr, // post_vehicle
                        child: Column(
                          children: [
                            Obx(
                              () => _buildSelectableField(
                                context,
                                label: 'Brand'.tr,
                                value: postController.selectedBrand.value,
                                hint: 'Select brand'.tr,
                                onTap: () => _openSelection(() async {
                                  await _showBrandBottomSheet(context);
                                }),
                                isRequired: true,
                                icon: Icons.factory_outlined,
                                errorText: _brandError,
                              ),
                            ),
                            Obx(
                              () => _buildSelectableField(
                                context,
                                label: 'Model'.tr,
                                value: postController.selectedModel.value,
                                hint:
                                    postController
                                        .selectedBrandUuid
                                        .value
                                        .isEmpty
                                    ? 'Select brand first'.tr // post_select_brand_first
                                    : 'Select model'.tr,
                                enabled: postController
                                    .selectedBrandUuid
                                    .value
                                    .isNotEmpty,
                                onTap: () => _openSelection(() async {
                                  await _showModelBottomSheet(context);
                                }),
                                isRequired: true,
                                icon: Icons.directions_car_outlined,
                                errorText: _modelError,
                              ),
                            ),
                            Obx(
                              () => _buildSelectableField(
                                context,
                                label: 'Condition'.tr,
                                value: postController.selectedCondition.value,
                                hint: 'Select condition'.tr,
                                onTap: () => _openSelection(() async {
                                  await _showOptionsBottomSheet(
                                    context,
                                    'Condition'.tr,
                                    [
                                      {'value': 'New', 'displayKey': 'New'},
                                      {'value': 'Used', 'displayKey': 'Used'},
                                    ],
                                    postController.selectedCondition,
                                  );
                                }),
                                isRequired: true,
                              ),
                            ),
                            Obx(
                              () => _buildSelectableField(
                                context,
                                label: 'Year'.tr,
                                value: postController.selectedYear.value.isEmpty
                                    ? ''
                                    : postController.selectedYear.value,
                                hint: 'Select year'.tr,
                                onTap: () => _openSelection(() async {
                                  await _showYearBottomSheet(context);
                                }),
                                isRequired: true,
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.price_change_outlined,
                      title: 'Pricing'.tr, // post_pricing
                      child: Column(
                        children: [
                          _buildTextFormField(
                            context,
                            label: 'Price'.tr,
                            controller: postController.price,
                            keyboardType: TextInputType.number,
                            hint: '0000',
                            isRequired: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validatorFn: (value) {
                              // Remove leading zeros
                              final trimmed = value.replaceAll(
                                RegExp(r'^0+'),
                                '',
                              );
                              if (trimmed != value) {
                                postController.price.text = trimmed;
                                postController
                                    .price
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: postController.price.text.length,
                                  ),
                                );
                              }
                              return null;
                            },
                            suffix: SizedBox(
                              width: 100,
                              child: DropdownButtonFormField<String>(
                                value: postController.selectedCurrency.value,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                dropdownColor: theme.colorScheme.surface,
                                items: ['TMT', 'USD', 'EUR', 'RUB', 'TRY'].map((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    postController.selectedCurrency.value =
                                        newValue;
                                    postController.markFieldChanged();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Location'.tr, // post_location_section
                      child: Obx(
                        () => _buildSelectableField(
                          context,
                          label: "Location".tr,
                          value: postController.selectedLocation.value,
                          hint: 'Select location'.tr,
                          onTap: () async {
                            await _openSelection(() async {
                              final res = await Get.to(
                                () => SLocationSelection(),
                              );
                              if (res is String && res.isNotEmpty) {
                                postController.selectedLocation.value = res;
                                postController.markFieldChanged();
                              }
                            });
                          },
                          isRequired: true,
                        ),
                      ),
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.phone_outlined,
                      title: 'Contact Information'.tr, // post_contact_info
                      child: Obx(() {
                        return Column(
                          children: [
                            _buildTextFormField(
                              context,
                              label: 'Phone number'.tr,
                              controller: postController.phoneController,
                              keyboardType: TextInputType.phone,
                              hint: '61234567',
                              prefixText: '+993 ',
                              // Enforce subscriber-only 8 digits
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                              ],
                              isRequired: true,
                              // Add a suffix with a verified chip when applicable
                              // Suffix shows a small 'Verified' chip when phone matches trusted original & no OTP needed
                              suffix: Obx(() {
                                final showChip =
                                    postController.isPhoneVerified.value &&
                                    !postController.needsOtp.value;
                                if (!showChip) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified'.tr, // post_verified
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            if (!postController.isPhoneVerified.value &&
                                postController.needsOtp.value)
                              Column(
                                children: [
                                  const SizedBox(height: 8),
                                  if (postController.showOtpField.value)
                                    Pinput(
                                      length: 5,
                                      defaultPinTheme: PinTheme(
                                        width: 48,
                                        height: 56,
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      focusedPinTheme: PinTheme(
                                        width: 48,
                                        height: 56,
                                        textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      focusNode: postController.otpFocus,
                                      controller: postController.otpController,
                                      onCompleted: (pin) =>
                                          postController.verifyOtp(),
                                    ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      icon: postController.showOtpField.value
                                          ? const Icon(
                                              Icons.check_circle_outline,
                                            )
                                          : const Icon(Icons.send_outlined),
                                      label: Text(
                                        postController.showOtpField.value
                                            ? 'Verify OTP'.tr // post_verify_otp
                                            : 'Send OTP'.tr, // post_send_otp
                                      ),
                                      onPressed:
                                          postController.showOtpField.value
                                          ? () => postController.verifyOtp()
                                          : (postController.isSendingOtp.value
                                                ? null
                                                : () =>
                                                      postController.sendOtp()),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    if (postController.countdown.value > 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'post_resend_code_in'.trParams({'seconds': postController.countdown.value.toString()}),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      );
                                    } else if (postController
                                        .showOtpField
                                        .value) {
                                      return TextButton(
                                        onPressed: () =>
                                            postController.sendOtp(),
                                        child: Text('Resend Code'.tr), // post_resend_code
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  }),
                                ],
                              ),
                          ],
                        );
                      }),
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.engineering_outlined,
                      title: 'Technical Details'.tr, // post_technical_details
                      child: Column(
                        children: [
                          Obx(
                            () => _buildSelectableField(
                              context,
                              label: 'Engine type'.tr,
                              value: postController.selectedEngineType.value,
                              hint: 'Select engine type'.tr,
                              onTap: () => _openSelection(() async {
                                await _showOptionsBottomSheet(
                                  context,
                                  'Engine type'.tr,
                                  [
                                    {'value': 'Petrol', 'displayKey': 'Petrol'},
                                    {'value': 'Diesel', 'displayKey': 'Diesel'},
                                    {'value': 'Hybrid', 'displayKey': 'Hybrid'},
                                    {
                                      'value': 'Electric',
                                      'displayKey': 'Electric',
                                    },
                                  ],
                                  postController.selectedEngineType,
                                );
                              }),
                              isRequired: false, // now optional
                            ),
                          ),
                          // Engine Power now selection-only (no free text)
                          _buildSelectableField(
                            context,
                            label: 'Engine Power (L)'.tr,
                            value: postController.enginePower.text,
                            hint: 'Select engine size'.tr, // post_select_engine_size
                            onTap: () async {
                              await _showEnginePowerBottomSheet(context);
                              setState(() {}); // refresh displayed value
                            },
                            isRequired: false,
                            icon: Icons.speed,
                          ),
                          // Transmission type (moved into Technical Details now instead of Condition/Year)
                          Obx(
                            () => _buildSelectableField(
                              context,
                              label: 'Transmission'.tr,
                              value: postController.selectedTransmission.value,
                              hint: 'Select transmission'.tr,
                              onTap: () => _openSelection(() async {
                                await _showOptionsBottomSheet(
                                  context,
                                  'Transmission'.tr,
                                  [
                                    {
                                      'value': 'Automatic',
                                      'displayKey': 'Automatic',
                                    },
                                    {'value': 'Manual', 'displayKey': 'Manual'},
                                    {'value': 'CVT', 'displayKey': 'CVT'},
                                    {
                                      'value': 'Dual-clutch',
                                      'displayKey': 'Dual-clutch',
                                    },
                                  ],
                                  postController.selectedTransmission,
                                );
                              }),
                              isRequired: false,
                            ),
                          ),
                          _buildTextFormField(
                            context,
                            label: 'Mileage (km)'.tr,
                            controller: postController.milleage,
                            keyboardType: TextInputType.number,
                            hint: 'e.g. 120000',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                          ),
                          _buildTextFormField(
                            context,
                            label: 'Description'.tr,
                            controller: postController.description,
                            keyboardType: TextInputType.multiline,
                            hint: "Highlight the car's features and condition...".tr,
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(theme),
      ),
    );
  }

  Future<void> _scrollToVehicleSection() async {
    final ctx = _vehicleSectionKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  void _showUploadBlockedDialog(
    BuildContext context,
    UploadManager manager,
    UploadTask task,
  ) {
    final theme = Theme.of(context);
    final isFailed = task.isFailed.value && !task.isCompleted.value;
    Get.dialog(
      AlertDialog(
        title: Text('Upload in progress'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have a post being uploaded.'.tr,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Finish, retry or discard it before starting a new one.'.tr,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: .7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!NavigationUtils.throttle('dialog_close')) return;
              _safeCloseOverlay();
            },
            child: Text('Close'.tr),
          ),
          if (isFailed)
            TextButton(
              onPressed: () {
                if (!NavigationUtils.throttle('dialog_retry')) return;
                _safeCloseOverlay();
                final pc = Get.find<PostController>();
                manager.retryActive(pc);
              },
              child: Text('Retry'.tr),
            ),
          if (isFailed)
            TextButton(
              onPressed: () {
                manager.discardTerminal();
                if (!NavigationUtils.throttle('dialog_discard')) return;
                _safeCloseOverlay();
              },
              child: Text('Discard'.tr),
            ),
          TextButton(
            onPressed: () {
              if (!NavigationUtils.throttle('dialog_cancel')) return;
              _safeCloseOverlay();
            },
            child: Text('Cancel'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurface, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Obx(() {
        final isPosting = postController.isPosting.value;
        final manager = Get.find<UploadManager>();
        final task = manager.currentTask.value;
        final locked = manager.isLocked.value;
        final failedOrCancelled = task != null && task.isFailed.value;
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                // Enable save if there is any input; internally validate requirements.
                onPressed: postController.hasAnyInput
                    ? () {
                        // If nothing changed and already saved, give feedback.
                        if (postController.isFormSaved.value &&
                            !postController.isDirty.value) {
                          Get.rawSnackbar(
                            message: 'No changes to save'.tr,
                            duration: const Duration(seconds: 2),
                          );
                          return;
                        }
                        final wasCompleteBefore = postController.hasMinimumData;
                        postController.saveForm();
                        final nowComplete = postController.hasMinimumData;
                        final msg = nowComplete
                            ? 'Form saved'.tr // post_form_saved
                            : (wasCompleteBefore
                                ? 'Form saved (still complete)'.tr // post_form_saved_still_complete
                                : 'Partial form saved'.tr); // post_partial_form_saved
                        Get.rawSnackbar(
                          message: msg,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Obx(() {
                  final saved = postController.isFormSaved.value;
                  final dirty = postController.isDirty.value;
                  final label = saved
                      ? (dirty ? 'Save Form'.tr : 'Saved'.tr) // post_save_form, post_saved
                      : 'Save Form'.tr;
                  return Text(label);
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: isPosting
                    ? null
                    : () async {
                        setState(() {
                          _brandError =
                              postController.selectedBrandUuid.value.isEmpty
                              ? 'Brand required'.tr // post_brand_required
                              : null;
                          _modelError = postController.selectedModelUuid.value.isEmpty
                              ? 'Model required'.tr // post_model_required
                              : null;
                        });
                        if (_brandError != null || _modelError != null) {
                          _scrollToVehicleSection();
                          return;
                        }
                        if (locked && task != null) {
                          _showUploadBlockedDialog(context, manager, task);
                          return;
                        }
                        if (!postController.isPhoneVerified.value) {
                          Get.snackbar(
                            'Error',
                            'You have to go through OTP verification.'.tr, // post_error_otp_required
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        await postController.startManagedUpload();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  disabledBackgroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isPosting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Posting...'.tr, // post_posting
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : (locked && failedOrCancelled
                          ? Text(
                              'Resolve pending upload'.tr, // post_resolve_pending_upload
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              'Post'.tr, // post_post_action
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Reset form'.tr, // post_reset_form
              onPressed:
                  (postController.hasAnyInput ||
                      postController.isFormSaved.value ||
                      postController.isDirty.value)
                  ? () {
                      final hadSaved = postController.isFormSaved.value;
                      postController.clearSavedForm();
                      postController.reset();
                      Get.rawSnackbar(
                        message: hadSaved ? 'Form cleared'.tr : 'Form reset'.tr, // post_form_cleared / post_form_reset
                        duration: const Duration(seconds: 2),
                      );
                    }
                  : null,
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSelectableField(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
    bool isRequired = false,
    IconData? icon,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(context, label, isRequired: isRequired),
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: enabled ? 0.05 : 0.03,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText == null
                      ? (enabled
                            ? theme.colorScheme.outline.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.15))
                      : theme.colorScheme.error,
                ),
              ),
              child: Row(
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      color: !enabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                          : (errorText == null
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  )
                                : theme.colorScheme.error),
                      size: 20,
                    ),
                  if (icon != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value.isEmpty ? hint : value,
                      style: TextStyle(
                        color: !enabled
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                            : (value.isEmpty
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    )
                                  : theme.colorScheme.onSurface),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: !enabled
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                        : (errorText == null
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                )
                              : theme.colorScheme.error),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                errorText,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context,
    String label, {
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    String? prefixText,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? validatorFn,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(context, label, isRequired: isRequired),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
              ),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) {
              if (validatorFn != null) {
                validatorFn(v.trim());
              }
              postController.markFieldChanged();
            },
          ),
        ],
      ),
    );
  }

  // _buildCheckbox removed (unused after UI simplification).

  Future<void> _showBrandBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final postController = Get.find<PostController>();
    // Reset brand search query each time sheet opens
    postController.brandSearchQuery.value = '';

    return Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Select Brand".tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search brand...'.tr, // post_brand_search_hint
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  postController.brandSearchQuery.value = value;
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (postController.isLoadingB.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final brands = postController.filteredBrands;
                if (brands.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("No brands found".tr), // post_no_brands_found
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            postController.fetchBrands(forceRefresh: true),
                        icon: const Icon(Icons.refresh),
                        label: Text('Retry'.tr),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return RadioListTile(
                      // TODO(RadioGroup-migration): Replace individual RadioListTile usages
                      // with a parent RadioGroup widget once refactor begins.
                      // Plan:
                      // 1. Introduce a StatelessWidget wrapping RadioGroup<String> providing
                      //    options + selectedValue + onChanged.
                      // 2. Migrate this builder to emit RadioMenuButton or custom
                      //    list tiles inside RadioGroup.
                      // 3. Remove deprecated groupValue/onChanged parameters.
                      // 4. Add semantic labels for accessibility.
                      title: Text(
                        brand.name,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      value: brand.uuid,
                      groupValue: postController.selectedBrandUuid.value,
                      onChanged: (newValue) {
                        if (!NavigationUtils.throttle('brand_select')) return;
                        final changed =
                            postController.selectedBrandUuid.value !=
                            brand.uuid;
                        postController.selectedBrand.value = brand.name;
                        postController.selectedBrandUuid.value = brand.uuid;
                        if (changed) {
                          // Clear any previously selected model when brand changes
                          postController.selectedModel.value = '';
                          postController.selectedModelUuid.value = '';
                          postController.models.clear();
                          // Prefetch models silently for new brand
                          postController.fetchModels(
                            brand.uuid,
                            showLoading: false,
                          );
                          setState(() {
                            _modelError =
                                null; // clear stale model error if any
                          });
                        }
                        setState(() {
                          _brandError = null; // clear brand validation error
                        });
                        postController.markFieldChanged();
                        if (!mounted) return;
                        if (Get.isBottomSheetOpen == true) _safeCloseOverlay();
                      },
                      activeColor: theme.colorScheme.onSurface,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showModelBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final postController = Get.find<PostController>();
    // Reset model search query each open
    postController.searchModel.value = '';

    return Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Select Model".tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search model...'.tr, // post_model_search_hint
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.05,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  postController.searchModel.value = value;
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (postController.isLoadingM.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final models = postController.filteredModels;
                if (models.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("No models found".tr), // post_no_models_found
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => postController.fetchModels(
                          postController.selectedBrandUuid.value,
                          forceRefresh: true,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text('Retry'.tr),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return ListTile(
                      title: Text(
                        model.name,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      onTap: () {
                        if (!NavigationUtils.throttle('model_select')) return;
                        postController.selectedModel.value = model.name;
                        postController.selectedModelUuid.value = model.uuid;
                        setState(() {
                          _modelError = null;
                        });
                        postController.markFieldChanged();
                        if (!mounted) return;
                        if (Get.isBottomSheetOpen == true) _safeCloseOverlay();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showOptionsBottomSheet(
    BuildContext context,
    String title,
    List<Map<String, String>> options,
    RxString selectedValue,
  ) async {
    final theme = Theme.of(context);
    return Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final optionData = options[index];
                  final String englishValue = optionData['value']!;
                  final String displayKey = optionData['displayKey']!;
                  bool isSelected = selectedValue.value == englishValue;

                  return ListTile(
                    title: Text(
                      displayKey.tr,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.onSurface,
                          )
                        : null,
                    onTap: () {
                      if (!NavigationUtils.throttle('option_select')) return;
                      selectedValue.value = englishValue;
                      // Mark form dirty / changed for partial save logic
                      try {
                        final pc = Get.find<PostController>();
                        pc.markFieldChanged();
                      } catch (_) {}
                      _safeCloseOverlay();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> _showEnginePowerBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final sizes = <double>[];
    // Common engine displacements from 0.6L to 10.0L
    for (double v = 0.6; v <= 2.0; v += 0.1)
      sizes.add(
        double.parse(v.toStringAsFixed(1)),
      ); // finer granularity for small engines
    for (double v = 2.0; v <= 6.0; v += 0.2)
      sizes.add(double.parse(v.toStringAsFixed(1))); // mid-range
    for (double v = 6.5; v <= 10.0; v += 0.5)
      sizes.add(double.parse(v.toStringAsFixed(1))); // large engines
    // Deduplicate (2.0 added twice) then sort
    final setSizes = sizes.toSet().toList()..sort();
    final selectedRaw = postController.enginePower.text;
    await Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Engine Size (L)'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: setSizes.length,
                itemBuilder: (context, index) {
                  final v = setSizes[index];
                  final label = v
                      .toStringAsFixed(1)
                      .replaceAll(RegExp(r'\.0'), '.0');
                  final isSelected =
                      selectedRaw == label ||
                      selectedRaw == label.replaceAll('.0', '');
                  return ListTile(
                    title: Text(
                      '$label L',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.onSurface,
                          )
                        : null,
                    onTap: () {
                      if (!NavigationUtils.throttle('engine_size_select'))
                        return;
                      postController.enginePower.text = v.toStringAsFixed(1);
                      postController.markFieldChanged();
                      _safeCloseOverlay();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showYearBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    // Generate descending list of years (e.g., 2025 .. 1980)
    final years = [for (int y = currentYear; y >= 1980; y--) y];
    await Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Year'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isSelected =
                      postController.selectedYear.value == year.toString();
                  return ListTile(
                    title: Text(
                      year.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.onSurface,
                          )
                        : null,
                    onTap: () {
                      if (!NavigationUtils.throttle('year_select')) return;
                      postController.selectedYear.value = year.toString();
                      // Also normalize selectedDate to Jan 1 of that year for downstream logic.
                      postController.selectedDate.value = DateTime(year, 1, 1);
                      postController.markFieldChanged();
                      _safeCloseOverlay();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
