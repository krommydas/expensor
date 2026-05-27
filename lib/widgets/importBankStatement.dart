import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/bankStatementService.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/progressBar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'dart:io' show File;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImportBankStatement extends StatefulWidget {
  const ImportBankStatement({Key? key}) : super(key: key);

  @override
  State<ImportBankStatement> createState() => _ImportBankStatementState();
}

class _ImportBankStatementState extends State<ImportBankStatement> {
  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      onTap: () => _startImportFlow(context),
      title: 'Import Bank Statement',
      description: 'PDF · OCR · AI Categorization',
      icon: appStateSettings['outlinedIcons'] == true
          ? Icons.account_balance_outlined
          : Icons.account_balance_rounded,
    );
  }

  Future<void> _startImportFlow(BuildContext context) async {
    // ── Step 1: Pick PDF ──────────────────────────────────────────────────
    FilePickerResult? pickerResult;
    await openLoadingPopupTryCatch(
      () async {
        pickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          // withData ensures bytes are available on web
          withData: kIsWeb,
        );
        if (pickerResult == null) throw 'no-file-selected';
      },
      onError: (e) {
        if (e.toString() != 'no-file-selected') {
          _showError(context, e.toString());
        }
      },
    );
    if (pickerResult == null) return;

    // Read bytes on all platforms: web has them directly, others read from path
    Uint8List? pdfBytes;
    final picked = pickerResult!.files.single;
    if (kIsWeb) {
      pdfBytes = picked.bytes;
    } else {
      final path = picked.path;
      if (path != null) pdfBytes = await File(path).readAsBytes();
    }
    if (pdfBytes == null) {
      _showError(context, 'Could not read the selected file.');
      return;
    }

    // ── Step 2: PDF Text Extraction ───────────────────────────────────────
    List<ParsedTransaction>? transactions;
    await openLoadingPopupTryCatch(
      () async {
        final service = BankStatementService();
        final pageTexts = await service.extractTextFromPdf(pdfBytes!);
        transactions = service.parseTransactions(pageTexts);
      },
      onError: (e) => _showError(context, 'PDF parsing failed: $e'),
    );

    if (transactions == null) return;
    if (transactions!.isEmpty) {
      openPopup(
        context,
        title: 'No Transactions Found',
        description:
            'The PDF could not be parsed. Make sure it is a text-based or '
            'clearly-scanned bank statement.',
        onSubmitLabel: 'ok'.tr(),
        onSubmit: () => popRoute(context),
        icon: appStateSettings['outlinedIcons'] == true
            ? Icons.search_off_outlined
            : Icons.search_off_rounded,
      );
      return;
    }

    // ── Step 3: Check / collect API key ──────────────────────────────────
    String? apiKey =
        sharedPreferences.getString('bankStatementApiKey');
    String apiEndpoint =
        sharedPreferences.getString('bankStatementApiEndpoint') ??
            'https://api.openai.com/v1/chat/completions';

    if (apiKey == null || apiKey.isEmpty) {
      final result =
          await _promptForApiCredentials(context, apiEndpoint);
      if (result == null) return;
      apiKey = result['key']!;
      apiEndpoint = result['endpoint']!;
      await sharedPreferences.setString('bankStatementApiKey', apiKey);
      await sharedPreferences.setString(
          'bankStatementApiEndpoint', apiEndpoint);
    }

    // ── Step 4: AI Categorization ─────────────────────────────────────────
    await openLoadingPopupTryCatch(
      () async {
        final service = BankStatementService();
        transactions = await service.categorizeWithAI(
          transactions!,
          apiKey!,
          apiEndpoint,
        );
      },
      onError: (e) {
        // Non-fatal: proceed without categories
        print('Bank statement AI categorization failed: $e');
      },
    );

    // ── Step 5: Preview & confirm ─────────────────────────────────────────
    if (!mounted) return;
    final confirmed = await openBottomSheet(
      context,
      _StatementPreviewSheet(transactions: transactions!),
    );
    if (confirmed != true) return;

    // ── Step 6: Select account ────────────────────────────────────────────
    final walletPk =
        appStateSettings['selectedWalletPk'] as String? ?? '0';

    // ── Step 7: Import with progress ──────────────────────────────────────
    openPopupCustom(
      context,
      title: 'Importing...',
      child: _ImportingStatementPopup(
        transactions: transactions!,
        walletPk: walletPk,
        onDone: (count, skipped) {
          popRoute(context);
          openPopup(
            context,
            title: 'done'.tr() + '!',
            description:
                'Imported $count transaction${count == 1 ? '' : 's'}.'
                '${skipped > 0 ? ' $skipped duplicate${skipped == 1 ? '' : 's'} skipped.' : ''}',
            onSubmitLabel: 'ok'.tr(),
            onSubmit: () => popRoute(context),
            icon: appStateSettings['outlinedIcons'] == true
                ? Icons.check_circle_outline_outlined
                : Icons.check_circle_outline_rounded,
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showError(BuildContext context, String message) {
    openPopup(
      context,
      title: 'Import Error',
      description: message,
      onSubmitLabel: 'ok'.tr(),
      onSubmit: () => popRoute(context),
      icon: appStateSettings['outlinedIcons'] == true
          ? Icons.error_outlined
          : Icons.error_rounded,
    );
  }

  // Opens a bottom sheet to collect the AI API key + endpoint.
  // Returns null if cancelled.
  Future<Map<String, String>?> _promptForApiCredentials(
      BuildContext context, String currentEndpoint) async {
    final result = await openBottomSheet(
      context,
      _ApiKeySheet(currentEndpoint: currentEndpoint),
    );
    if (result is Map) {
      return {
        'key': result['key']?.toString() ?? '',
        'endpoint': result['endpoint']?.toString() ?? '',
      };
    }
    return null;
  }
}

// ─── API Key Collection Sheet ─────────────────────────────────────────────────

class _ApiKeySheet extends StatefulWidget {
  final String currentEndpoint;
  const _ApiKeySheet({required this.currentEndpoint});

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  late String _endpoint;
  String _apiKey = '';

  static const _endpoints = {
    'OpenAI (gpt-4o-mini)':
        'https://api.openai.com/v1/chat/completions',
    'Groq (llama-3.1-8b-instant)':
        'https://api.groq.com/openai/v1/chat/completions',
  };

  @override
  void initState() {
    super.initState();
    _endpoint = _endpoints.values.contains(widget.currentEndpoint)
        ? widget.currentEndpoint
        : _endpoints.values.first;
  }

  @override
  Widget build(BuildContext context) {
    final containerColor = appStateSettings['materialYou'] == true
        ? dynamicPastel(
            context,
            Theme.of(context).colorScheme.secondaryContainer,
            amountDark: 0.2,
            amountLight: 0.35,
          )
        : getColor(context, 'lightDarkAccentHeavyLight').withOpacity(0.6);

    return PopupFramework(
      title: 'AI Categorization',
      subtitle:
          'Enter your API key to auto-categorize merchants. The key is stored locally.',
      hasPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider selector
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadiusDirectional.circular(10),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFont(text: 'Provider', fontSize: 15),
                const SizedBox(height: 8),
                for (final entry in _endpoints.entries)
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsetsDirectional.zero,
                    title: TextFont(text: entry.key, fontSize: 14),
                    value: entry.value,
                    groupValue: _endpoint,
                    onChanged: (v) => setState(() => _endpoint = v!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // API key input
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadiusDirectional.circular(10),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 15, vertical: 10),
            child: TextInput(
              labelText: 'API Key',
              padding: EdgeInsetsDirectional.zero,
              obscureText: true,
              onChanged: (v) => _apiKey = v,
            ),
          ),
          const SizedBox(height: 16),
          Button(
            label: 'Continue',
            onTap: () {
              if (_apiKey.trim().isEmpty) {
                openPopup(
                  context,
                  title: 'API Key Required',
                  description: 'Please enter your API key to continue.',
                  onSubmitLabel: 'ok'.tr(),
                  onSubmit: () => popRoute(context),
                  icon: Icons.warning_rounded,
                );
                return;
              }
              popRoute(context, {
                'key': _apiKey.trim(),
                'endpoint': _endpoint,
              });
            },
          ),
        ],
      ),
    );
  }
}

// ─── Preview Sheet ────────────────────────────────────────────────────────────

class _StatementPreviewSheet extends StatelessWidget {
  final List<ParsedTransaction> transactions;
  const _StatementPreviewSheet({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final rowColor = appStateSettings['materialYou'] == true
        ? dynamicPastel(
            context,
            Theme.of(context).colorScheme.secondaryContainer,
            amountDark: 0.2,
            amountLight: 0.35,
          )
        : getColor(context, 'lightDarkAccentHeavyLight').withOpacity(0.6);

    return PopupFramework(
      hasPadding: false,
      title: 'Review Transactions',
      subtitle:
          '${transactions.length} transaction${transactions.length == 1 ? '' : 's'} detected',
      child: Column(
        children: [
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              itemCount: transactions.length,
              itemBuilder: (context, i) {
                final t = transactions[i];
                final isIncome = t.amount > 0;
                final amountColor = isIncome
                    ? getColor(context, 'incomeAmount')
                    : getColor(context, 'expenseAmount');
                return Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: rowColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              TextFont(
                                text: t.merchantClean,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 3),
                              TextFont(
                                text: DateFormat('dd MMM yyyy')
                                    .format(t.date),
                                fontSize: 11,
                                textColor:
                                    getColor(context, 'textLight'),
                              ),
                              if (t.category != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional
                                          .symmetric(
                                          horizontal: 7,
                                          vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(5),
                                  ),
                                  child: TextFont(
                                    text: t.category!,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextFont(
                          text: '${isIncome ? '+' : ''}${t.amount.toStringAsFixed(2)}',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          textColor: amountColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding:
                const EdgeInsetsDirectional.symmetric(horizontal: 14),
            child: Button(
              label:
                  'Import ${transactions.length} Transaction${transactions.length == 1 ? '' : 's'}',
              onTap: () => popRoute(context, true),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─── Importing Progress Popup ─────────────────────────────────────────────────

class _ImportingStatementPopup extends StatefulWidget {
  final List<ParsedTransaction> transactions;
  final String walletPk;
  final void Function(int imported, int skipped) onDone;

  const _ImportingStatementPopup({
    required this.transactions,
    required this.walletPk,
    required this.onDone,
  });

  @override
  State<_ImportingStatementPopup> createState() =>
      _ImportingStatementPopupState();
}

class _ImportingStatementPopupState
    extends State<_ImportingStatementPopup> {
  double _percent = 0;
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _runImport());
  }

  Future<void> _runImport() async {
    final service = BankStatementService();
    setState(() => _total = widget.transactions.length);

    final imported = await service.importTransactions(
      widget.transactions,
      widget.walletPk,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _current = current;
            _total = total;
            _percent = total > 0 ? current / total * 100 : 0;
          });
        }
      },
    );

    final skipped = widget.transactions.length - imported;
    widget.onDone(imported, skipped);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressBar(
          currentPercent: _percent,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 10),
        TextFont(
          fontSize: 15,
          text: '$_current / $_total',
        ),
      ],
    );
  }
}
