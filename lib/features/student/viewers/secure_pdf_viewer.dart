import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/material_security_service.dart';
import '../../../core/services/material_cache_service.dart';
import '../../../shared/widgets/widgets.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// Secure PDF Viewer
// In-app PDF viewing with screenshot blocking and offline support
// ─────────────────────────────────────────────────────────────────────────────

class SecurePDFViewer extends StatefulWidget {
  final String materialId;
  final String materialName;
  final String? filePath; // Local file path if cached
  final String? url; // Remote URL if not cached

  const SecurePDFViewer({
    super.key,
    required this.materialId,
    required this.materialName,
    this.filePath,
    this.url,
  });

  @override
  State<SecurePDFViewer> createState() => _SecurePDFViewerState();
}

class _SecurePDFViewerState extends State<SecurePDFViewer> {
  final _securityService = MaterialSecurityService();
  final _cacheService = MaterialCacheService();
  final _pdfController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Enable screenshot blocking
    await _securityService.protectScreen();

    // Preload file if cached for faster loading
    if (widget.filePath != null) {
      await _cacheService.preloadFile(widget.materialId);
    }

    // Load last viewed page
    final lastViewed = await _cacheService.getLastViewedPosition(widget.materialId);
    if (lastViewed != null && lastViewed['page'] != null) {
      final page = lastViewed['page'] as int;
      // Jump to page after a short delay to ensure PDF is loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _pdfController.jumpToPage(page);
        }
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    // Disable screenshot blocking
    _securityService.unprotectScreen();

    // Save current page
    if (_currentPage > 0) {
      _cacheService.saveLastViewedPosition(
        materialId: widget.materialId,
        page: _currentPage,
      );
    }

    _pdfController.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() {
      _error = details.error;
      _isLoading = false;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            height: 72 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1240), AppColors.bg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const AppBackButton(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.materialName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_totalPages > 0)
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Security indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.lock,
                        color: AppColors.error,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Secure',
                        style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PDF Viewer
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Symbols.error,
                                color: AppColors.error,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load PDF',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : widget.filePath != null
                        ? SfPdfViewer.file(
                            File(widget.filePath!),
                            controller: _pdfController,
                            onDocumentLoaded: _onDocumentLoaded,
                            onDocumentLoadFailed: _onDocumentLoadFailed,
                            onPageChanged: _onPageChanged,
                            enableDoubleTapZooming: true,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            pageLayoutMode: PdfPageLayoutMode.single,
                          )
                        : widget.url != null
                            ? SfPdfViewer.network(
                                widget.url!,
                                controller: _pdfController,
                                onDocumentLoaded: _onDocumentLoaded,
                                onDocumentLoadFailed: _onDocumentLoadFailed,
                                onPageChanged: _onPageChanged,
                                enableDoubleTapZooming: true,
                                canShowScrollHead: true,
                                canShowScrollStatus: true,
                                pageLayoutMode: PdfPageLayoutMode.single,
                              )
                            : Center(
                                child: Text(
                                  'No file path or URL provided',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
          ),

          // Bottom toolbar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous page
                IconButton(
                  onPressed: _currentPage > 1
                      ? () => _pdfController.previousPage()
                      : null,
                  icon: const Icon(Symbols.arrow_back),
                  color: _currentPage > 1 ? Colors.white : AppColors.textMuted,
                ),

                // Page indicator
                Text(
                  '$_currentPage / $_totalPages',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Next page
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfController.nextPage()
                      : null,
                  icon: const Icon(Symbols.arrow_forward),
                  color: _currentPage < _totalPages ? Colors.white : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
