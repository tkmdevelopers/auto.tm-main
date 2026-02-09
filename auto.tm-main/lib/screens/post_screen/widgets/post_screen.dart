// Fixed import paths to match real lib structure under screens/post_screen
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'dart:async'; // for Timer debounce
import 'package:auto_tm/screens/post_screen/widgets/location_selection.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_video_photo_widget.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_form_fields.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_bottom_sheets.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_bottom_bar.dart';
import 'package:auto_tm/screens/post_screen/widgets/post_contact_section.dart';
// upload_progress_screen deprecated
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
              title: Text('post_upload_in_progress'.tr),
              content: Text(
                'post_upload_leaving_note'.tr,
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
          title: Text('post_discard_changes_question'.tr),
          content: Text(
            postController.isFormSaved.value
                ? 'post_revert_and_leave'.tr
                : 'post_leave_without_saving'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(false);
              },
              child: Text('post_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(true);
              },
              child: Text('post_discard'.tr),
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
                'post_create_title'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Obx(() {
                final saved = postController.isFormSaved.value;
                final dirty = postController.isDirty.value;
        final text = !saved
          ? 'post_unsaved_form'.tr
          : (dirty ? 'post_unsaved_changes'.tr : 'post_all_saved'.tr);
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
                                'post_saved_form_loaded'.tr,
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
                                'post_dismiss'.tr,
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
                    PostSectionCard(
                      icon: Icons.perm_media_outlined,
                      title: 'post_photos_video'.tr,
                      child: Column(
                        children: [const PostMediaScrollableSelectionWidget()],
                      ),
                    ),
                    // Vehicle Section (Brand, Model, Condition, Year)
                    Container(
                      key: _vehicleSectionKey,
                      child: PostSectionCard(
                        icon: Icons.directions_car_filled_outlined,
                        title: 'post_vehicle'.tr,
                        child: Column(
                          children: [
                            Obx(
                              () => PostSelectableField(
                                label: 'Brand'.tr,
                                value: postController.selectedBrand.value,
                                hint: 'Select brand'.tr,
                                onTap: () => _openSelection(() async {
                                  await showBrandBottomSheet(
                                    context,
                                    postController: postController,
                                    onBrandSelected: (uuid, name) {
                                      final changed =
                                          postController.selectedBrandUuid.value !=
                                          uuid;
                                      postController.selectedBrand.value = name;
                                      postController.selectedBrandUuid.value = uuid;
                                      if (changed) {
                                        postController.selectedModel.value = '';
                                        postController.selectedModelUuid.value = '';
                                        postController.models.clear();
                                        postController.fetchModels(
                                          uuid,
                                          showLoading: false,
                                        );
                                        setState(() {
                                          _modelError = null;
                                        });
                                      }
                                      setState(() {
                                        _brandError = null;
                                      });
                                      postController.markFieldChanged();
                                    },
                                    onClose: _safeCloseOverlay,
                                  );
                                }),
                                isRequired: true,
                                icon: Icons.factory_outlined,
                                errorText: _brandError,
                              ),
                            ),
                            Obx(
                              () => PostSelectableField(
                                label: 'Model'.tr,
                                value: postController.selectedModel.value,
                                hint:
                                    postController
                                        .selectedBrandUuid
                                        .value
                                        .isEmpty
                                    ? 'post_select_brand_first'.tr
                                    : 'Select model'.tr,
                                enabled: postController
                                    .selectedBrandUuid
                                    .value
                                    .isNotEmpty,
                                onTap: () => _openSelection(() async {
                                  await showModelBottomSheet(
                                    context,
                                    postController: postController,
                                    onModelSelected: (uuid, name) {
                                      postController.selectedModel.value = name;
                                      postController.selectedModelUuid.value = uuid;
                                      setState(() {
                                        _modelError = null;
                                      });
                                      postController.markFieldChanged();
                                    },
                                    onClose: _safeCloseOverlay,
                                  );
                                }),
                                isRequired: true,
                                icon: Icons.directions_car_outlined,
                                errorText: _modelError,
                              ),
                            ),
                            Obx(
                              () => PostSelectableField(
                                label: 'Condition'.tr,
                                value: postController.selectedCondition.value,
                                hint: 'Select condition'.tr,
                                onTap: () => _openSelection(() async {
                                  await showOptionsBottomSheet(
                                    context,
                                    title: 'Condition'.tr,
                                    options: [
                                      {'value': 'New', 'displayKey': 'New'},
                                      {'value': 'Used', 'displayKey': 'Used'},
                                    ],
                                    selectedValue: postController.selectedCondition,
                                    onClose: _safeCloseOverlay,
                                  );
                                }),
                                isRequired: true,
                              ),
                            ),
                            Obx(
                              () => PostSelectableField(
                                label: 'Year'.tr,
                                value: postController.selectedYear.value.isEmpty
                                    ? ''
                                    : postController.selectedYear.value,
                                hint: 'Select year'.tr,
                                onTap: () => _openSelection(() async {
                                  await showYearBottomSheet(
                                    context,
                                    postController: postController,
                                    onClose: _safeCloseOverlay,
                                  );
                                }),
                                isRequired: true,
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PostSectionCard(
                      icon: Icons.price_change_outlined,
                      title: 'post_pricing'.tr,
                      child: Column(
                        children: [
                          PostTextFormField(
                            label: 'Price'.tr,
                            controller: postController.price,
                            keyboardType: TextInputType.number,
                            hint: '0000',
                            isRequired: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            onFieldChanged: () => postController.markFieldChanged(),
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
                    PostSectionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Location'.tr, // post_location_section
                      child: Obx(
                        () => PostSelectableField(
                          label: "Location".tr,
                          value: postController.selectedLocation.value,
                          hint: 'post_select_location'.tr,
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
                    PostSectionCard(
                      icon: Icons.phone_outlined,
                      title: 'post_contact_info'.tr,
                      child: PostContactSection(
                        postController: postController,
                        onFieldChanged: () => postController.markFieldChanged(),
                      ),
                    ),
                    PostSectionCard(
                      icon: Icons.engineering_outlined,
                      title: 'post_technical_details'.tr,
                      child: Column(
                        children: [
                          Obx(
                            () => PostSelectableField(
                              label: 'Engine type'.tr,
                              value: postController.selectedEngineType.value,
                              hint: 'Select engine type'.tr,
                              onTap: () => _openSelection(() async {
                                await showOptionsBottomSheet(
                                  context,
                                  title: 'Engine type'.tr,
                                  options: [
                                    {'value': 'Petrol', 'displayKey': 'Petrol'},
                                    {'value': 'Diesel', 'displayKey': 'Diesel'},
                                    {'value': 'Hybrid', 'displayKey': 'Hybrid'},
                                    {
                                      'value': 'Electric',
                                      'displayKey': 'Electric',
                                    },
                                  ],
                                  selectedValue: postController.selectedEngineType,
                                  onClose: _safeCloseOverlay,
                                );
                              }),
                              isRequired: false, // now optional
                            ),
                          ),
                          Obx(
                            () => PostSelectableField(
                              label: 'Color'.tr,
                              value: postController.selectedColor.value,
                              hint: 'Select color'.tr,
                              onTap: () => _openSelection(() async {
                                await showColorBottomSheet(
                                  context,
                                  postController: postController,
                                  onClose: _safeCloseOverlay,
                                );
                              }),
                              isRequired: false,
                              icon: Icons.color_lens_outlined,
                            ),
                          ),
                          // Engine Power now selection-only (no free text)
                          PostSelectableField(
                            label: 'post_engine_power_l_label'.tr,
                            value: postController.enginePower.text,
                            hint: 'post_select_engine_size'.tr,
                            onTap: () async {
                              await showEnginePowerBottomSheet(
                                context,
                                postController: postController,
                                onClose: _safeCloseOverlay,
                              );
                              setState(() {}); // refresh displayed value
                            },
                            isRequired: false,
                            icon: Icons.speed,
                          ),
                          // Transmission type (moved into Technical Details now instead of Condition/Year)
                          Obx(
                            () => PostSelectableField(
                              label: 'Transmission'.tr,
                              value: postController.selectedTransmission.value,
                              hint: 'Select transmission'.tr,
                              onTap: () => _openSelection(() async {
                                await showOptionsBottomSheet(
                                  context,
                                  title: 'Transmission'.tr,
                                  options: [
                                    {
                                      'value': 'Automatic',
                                      'displayKey': 'Automatic',
                                    },
                                    {'value': 'Manual', 'displayKey': 'Manual'},
                                    {
                                      'value': 'CVT',
                                      'displayKey': 'transmission_cvt', // localized display
                                    },
                                    {
                                      'value': 'Dual-clutch',
                                      'displayKey': 'transmission_dual_clutch', // localized display
                                    },
                                  ],
                                  selectedValue: postController.selectedTransmission,
                                  onClose: _safeCloseOverlay,
                                );
                              }),
                              isRequired: false,
                            ),
                          ),
                          PostTextFormField(
                            label: 'post_mileage_km_label'.tr,
                            controller: postController.milleage,
                            keyboardType: TextInputType.number,
                            hint: 'post_mileage_example'.tr,
                            onFieldChanged: () => postController.markFieldChanged(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                          ),
                          PostTextFormField(
                            label: 'Description'.tr,
                            controller: postController.description,
                            keyboardType: TextInputType.multiline,
                            hint: 'post_description_hint'.tr,
                            maxLines: 5,
                            onFieldChanged: () => postController.markFieldChanged(),
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
        bottomNavigationBar: PostBottomBar(
          postController: postController,
          onPost: () => postController.startManagedUpload(),
          onUploadBlocked: _showUploadBlockedDialog,
          brandError: _brandError,
          modelError: _modelError,
          onValidationFailed: (bErr, mErr) {
            setState(() {
              _brandError = bErr;
              _modelError = mErr;
            });
            _scrollToVehicleSection();
          },
        ),
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
              'post_upload_finish_retry_discard_tip'.tr,
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
            child: Text('post_close'.tr),
          ),
          if (isFailed)
            TextButton(
              onPressed: () {
                if (!NavigationUtils.throttle('dialog_retry')) return;
                _safeCloseOverlay();
                final pc = Get.find<PostController>();
                manager.retryActive(pc);
              },
              child: Text('post_retry'.tr),
            ),
          if (isFailed)
            TextButton(
              onPressed: () {
                manager.discardTerminal();
                if (!NavigationUtils.throttle('dialog_discard')) return;
                _safeCloseOverlay();
              },
              child: Text('post_discard'.tr),
            ),
          TextButton(
            onPressed: () {
              if (!NavigationUtils.throttle('dialog_cancel')) return;
              _safeCloseOverlay();
            },
            child: Text('post_cancel'.tr),
          ),
        ],
      ),
    );
  }

  // --- Extracted to post_form_fields.dart, post_bottom_sheets.dart,
  //     post_bottom_bar.dart, post_contact_section.dart ---
}
