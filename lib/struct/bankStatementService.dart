import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:drift/drift.dart' hide Column, Table;

import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';

class ParsedTransaction {
  final DateTime date;
  final String merchantRaw;
  final String merchantClean;
  final double amount;
  final String? category;
  final String hash;

  const ParsedTransaction({
    required this.date,
    required this.merchantRaw,
    required this.merchantClean,
    required this.amount,
    this.category,
    required this.hash,
  });

  ParsedTransaction copyWithCategory(String? category) => ParsedTransaction(
        date: date,
        merchantRaw: merchantRaw,
        merchantClean: merchantClean,
        amount: amount,
        category: category,
        hash: hash,
      );
}

class BankStatementService {
  // ─── Step 1: PDF → Text ───────────────────────────────────────────────────

  Future<List<String>> extractTextFromPdf(Uint8List pdfBytes) async {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final List<String> pageTexts = [];

    try {
      for (int i = 0; i < document.pages.count; i++) {
        final lines =
            extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        pageTexts.add(_reconstructRowsFromPdf(lines));
      }
    } finally {
      document.dispose();
    }

    return pageTexts;
  }

  // Groups Syncfusion TextLines (which may represent individual column cells)
  // into tab-separated row strings ordered by X, rows separated by newlines.
  String _reconstructRowsFromPdf(List<TextLine> lines) {
    const double rowThreshold = 4.0;

    lines.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

    final rows = <List<TextLine>>[];
    List<TextLine> currentRow = [];
    double currentRowY = -1;

    for (final line in lines) {
      final midY = line.bounds.top + line.bounds.height / 2;
      if (currentRow.isEmpty || (midY - currentRowY).abs() <= rowThreshold) {
        if (currentRow.isEmpty) currentRowY = midY;
        currentRow.add(line);
      } else {
        currentRow
            .sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
        rows.add(List.from(currentRow));
        currentRow = [line];
        currentRowY = midY;
      }
    }
    if (currentRow.isNotEmpty) {
      currentRow.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
      rows.add(currentRow);
    }

    return rows
        .map((row) => row.map((l) => l.text.trim()).join('\t'))
        .join('\n');
  }

  // ─── Step 2: Parse Rows → Transactions ───────────────────────────────────

  List<ParsedTransaction> parseTransactions(List<String> pageTexts) {
    final transactions = <ParsedTransaction>[];

    for (final pageText in pageTexts) {
      for (final line in pageText.split('\n')) {
        final parsed = _parseLine(line);
        if (parsed != null) transactions.add(parsed);
      }
    }

    // Deduplicate by hash within this batch
    final seen = <String>{};
    return transactions.where((t) => seen.add(t.hash)).toList();
  }

  ParsedTransaction? _parseLine(String line) {
    // Normalize tabs (from PDF column reconstruction) to spaces, then tokenize
    final parts = line
        .replaceAll('\t', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    // Minimum: date token + at least one merchant word + amount token
    if (parts.length < 3) return null;

    final date = _tryParseDate(parts.first);
    if (date == null) return null;

    // Rightmost token must carry exactly 2 decimal places
    final rightToken = parts.last;
    if (!_hasExactTwoDecimals(rightToken)) return null;
    final amount = _tryParseAmount(rightToken);
    if (amount == null) return null;

    // Everything between the date token and amount token is the merchant
    final merchantRaw = parts.sublist(1, parts.length - 1).join(' ').trim();
    if (merchantRaw.isEmpty) return null;

    final merchantClean = sanitizeMerchant(merchantRaw);
    return ParsedTransaction(
      date: date,
      merchantRaw: merchantRaw,
      merchantClean: merchantClean,
      amount: amount,
      hash: _computeHash(date, merchantClean, amount),
    );
  }

  // Returns true only when the token ends with exactly two decimal digits
  // (e.g. "12.50", "-1.234,00", "1.500,00 CR").
  bool _hasExactTwoDecimals(String s) {
    final stripped = s.replaceAll(RegExp(r'[A-Za-z€$£¥()\s]'), '');
    return RegExp(r'[.,]\d{2}$').hasMatch(stripped);
  }

  // ─── Sanitization ─────────────────────────────────────────────────────────

  String sanitizeMerchant(String raw) {
    String s = raw;
    s = s.replaceAll(RegExp(r'\b\d{16}\b'), '');
    s = s.replaceAll(RegExp(r'\b\d{12,15}\b'), '');
    s = s.replaceAll(
        RegExp(r'\b(?:REF|TXN|REF#|ID|NO)[:\s]*\w+', caseSensitive: false),
        '');
    s = s.replaceAll(RegExp(r'\b[A-Z]{2,3}\d{6,}\b'), '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return s;
  }

  String _computeHash(DateTime date, String merchant, double amount) {
    final key = '${date.year}-${date.month}-${date.day}|$merchant|$amount';
    return sha256
        .convert(utf8.encode(key))
        .toString()
        .substring(0, 20);
  }

  DateTime? _tryParseDate(String s) {
    s = s.trim();
    final slashDot =
        RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$');
    final isoLike =
        RegExp(r'^(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})$');

    var m = slashDot.firstMatch(s);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      int c = int.parse(m.group(3)!);
      if (c < 100) c += 2000;
      if (a <= 31 && b <= 12 && c >= 2000 && c <= 2100) return DateTime(c, b, a);
      if (b <= 31 && a <= 12 && c >= 2000 && c <= 2100) return DateTime(c, a, b);
    }

    m = isoLike.firstMatch(s);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      if (y >= 2000 && y <= 2100 && mo <= 12 && d <= 31) return DateTime(y, mo, d);
    }

    try { return DateFormat('d MMM yyyy').parse(s); } catch (_) {}
    try { return DateFormat('d MMMM yyyy').parse(s); } catch (_) {}
    try { return DateTime.parse(s); } catch (_) {}
    return null;
  }

  double? _tryParseAmount(String s) {
    s = s.trim().replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return null;

    final isDebit = s.toUpperCase().contains('DR');
    final isCredit = s.toUpperCase().contains('CR');
    s = s.replaceAll(RegExp(r'[A-Za-z€\$£¥()]'), '');

    if (s.isEmpty) return null;

    if (s.contains(',') && s.contains('.')) {
      s = s.indexOf(',') < s.indexOf('.')
          ? s.replaceAll(',', '')
          : s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',') && !s.contains('.')) {
      final parts = s.split(',');
      s = (parts.length == 2 && parts[1].length <= 2)
          ? s.replaceAll(',', '.')
          : s.replaceAll(',', '');
    }

    final amount = double.tryParse(s);
    if (amount == null) return null;

    if (isDebit) return -amount.abs();
    if (isCredit) return amount.abs();
    return amount;
  }

  // ─── Step 3: AI Categorization ───────────────────────────────────────────

  Future<List<ParsedTransaction>> categorizeWithAI(
    List<ParsedTransaction> transactions,
    String apiKey,
    String apiEndpoint, {
    void Function(String status)? onProgress,
  }) async {
    if (transactions.isEmpty) return transactions;

    onProgress?.call('Loading personalization examples...');
    final titles = await database.getAllAssociatedTitles(limit: 20);
    final fewShot = <String>[];
    for (final t in titles) {
      try {
        final cat = await database.getCategoryInstance(t.categoryFk);
        fewShot.add('"${t.title}" → ${cat.name}');
      } catch (_) {}
    }

    final allCategories =
        await database.getAllCategories(includeSubCategories: true);
    final categoryNames = allCategories.map((c) => c.name).toSet().toList();
    if (categoryNames.isEmpty) return transactions;

    final merchantSet = <String>{};
    for (final t in transactions) {
      if (t.merchantClean.isNotEmpty) merchantSet.add(t.merchantClean);
    }

    onProgress?.call('Requesting AI categorization...');

    final systemPrompt =
        'You are a financial transaction categorizer. Assign each merchant '
        'to exactly one of these categories: ${categoryNames.join(', ')}.\n'
        'Return ONLY a JSON object: {"categorizations": [{"merchant":"...","category":"..."}]}\n'
        'Use only the listed category names.';

    final fewShotSection = fewShot.isNotEmpty
        ? '\n\nUser history (for context):\n${fewShot.join('\n')}'
        : '';

    final userMessage =
        'Categorize these merchants:$fewShotSection\n\n${merchantSet.join('\n')}';

    final isOpenAI = apiEndpoint.contains('openai.com');
    final model = isOpenAI ? 'gpt-4o-mini' : 'llama-3.1-8b-instant';

    final response = await http
        .post(
          Uri.parse(apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userMessage},
            ],
            'response_format': {'type': 'json_object'},
            'max_tokens': 1500,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw 'AI API error (${response.statusCode}): ${response.body}';
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        decoded['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final cats =
        (parsed['categorizations'] as List).cast<Map<String, dynamic>>();

    final categoryMap = <String, String>{
      for (final c in cats)
        (c['merchant'] as String): (c['category'] as String),
    };

    return transactions
        .map((t) => t.copyWithCategory(categoryMap[t.merchantClean]))
        .toList();
  }

  // ─── Step 4: Persist with Dedup ──────────────────────────────────────────

  Future<int> importTransactions(
    List<ParsedTransaction> transactions,
    String walletPk, {
    void Function(int current, int total)? onProgress,
  }) async {
    int imported = 0;
    final total = transactions.length;
    final toInsert = <TransactionsCompanion>[];

    for (int i = 0; i < total; i++) {
      final t = transactions[i];
      onProgress?.call(i + 1, total);

      final isDuplicate = await database.bankStatementTransactionExists(
          t.date, t.amount, t.merchantClean);
      if (isDuplicate) continue;

      String categoryFk;
      String? subCategoryFk;

      try {
        if (t.category != null && t.category!.isNotEmpty) {
          final cat =
              await database.getCategoryInstanceGivenName(t.category!);
          categoryFk = cat.mainCategoryPk ?? cat.categoryPk;
          subCategoryFk =
              cat.mainCategoryPk != null ? cat.categoryPk : null;
        } else {
          throw 'no-category';
        }
      } catch (_) {
        try {
          final cats = await database.getAllCategories();
          if (cats.isEmpty) continue;
          categoryFk = cats.first.categoryPk;
          subCategoryFk = null;
        } catch (_) {
          continue;
        }
      }

      toInsert.add(TransactionsCompanion.insert(
        name: t.merchantClean,
        amount: t.amount,
        note: '',
        categoryFk: categoryFk,
        subCategoryFk: Value(subCategoryFk),
        walletFk: Value(walletPk),
        dateCreated: Value(t.date),
        dateTimeModified: Value(DateTime.now()),
        income: Value(t.amount > 0),
        paid: const Value(true),
        skipPaid: const Value(false),
        methodAdded: const Value(MethodAdded.csv),
      ));
      imported++;
    }

    if (toInsert.isNotEmpty) {
      await database.createBatchTransactionsOnly(toInsert);
    }

    return imported;
  }
}
