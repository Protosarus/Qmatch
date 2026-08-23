import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/giphy_gif_model.dart';
import '../services/giphy_service.dart';

class QMatchGifPicker extends StatefulWidget {
  const QMatchGifPicker({
    super.key,
    required this.service,
    required this.languageCode,
    required this.title,
    required this.searchHint,
    required this.emptyText,
    required this.errorText,
    required this.poweredByText,
  });

  final GiphyService service;
  final String languageCode;
  final String title;
  final String searchHint;
  final String emptyText;
  final String errorText;
  final String poweredByText;

  @override
  State<QMatchGifPicker> createState() => _QMatchGifPickerState();
}

class _QMatchGifPickerState extends State<QMatchGifPicker> {
  final TextEditingController _search = TextEditingController();

  Timer? _debounce;
  List<GiphyGifModel> _results = const [];
  bool _loading = true;
  bool _failed = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(value),
    );
  }

  Future<void> _load(String query) async {
    final requestId = ++_requestId;

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final results = await widget.service.search(
        query: query,
        languageCode: widget.languageCode,
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _results = results;
        _loading = false;
      });

      for (final gif in results) {
        unawaited(
          widget.service.registerAnalytics(
            gif.analyticsViewUrl,
          ),
        );
      }
    } catch (_) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _select(GiphyGifModel gif) {
    unawaited(
      widget.service.registerAnalytics(
        gif.analyticsClickUrl,
      ),
    );

    Navigator.of(context).pop(gif);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassSurfaceStrong,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('qmatch-gif-picker-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('qmatch-gif-picker-search'),
                controller: _search,
                onChanged: _onSearchChanged,
                maxLength: 50,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _load('');
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.borderSubtle,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.borderSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.resonanceViolet.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _buildBody(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: widget.poweredByText,
                child: Text(
                  widget.poweredByText,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_failed) {
      return Center(
        child: Text(
          widget.errorText,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          widget.emptyText,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return GridView.builder(
      key: const Key('qmatch-gif-picker-grid'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.15,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final gif = _results[index];

        return Semantics(
          button: true,
          label:
              gif.title?.trim().isNotEmpty == true ? gif.title!.trim() : 'GIF',
          child: InkWell(
            key: Key('qmatch-gif-result-${gif.id}'),
            onTap: () => _select(gif),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: AppColors.surfaceElevated,
                child: Image.network(
                  gif.previewUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
