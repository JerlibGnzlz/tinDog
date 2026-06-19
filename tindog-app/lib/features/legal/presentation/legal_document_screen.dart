import 'package:flutter/material.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../shared/widgets/tindog_back_button.dart';

enum LegalDocumentType { privacy, cookies, terms }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  String get _title => switch (type) {
        LegalDocumentType.privacy => LegalDocuments.privacyTitle,
        LegalDocumentType.cookies => LegalDocuments.cookiesTitle,
        LegalDocumentType.terms => LegalDocuments.termsTitle,
      };

  String get _body => switch (type) {
        LegalDocumentType.privacy => LegalDocuments.privacyBody,
        LegalDocumentType.cookies => LegalDocuments.cookiesBody,
        LegalDocumentType.terms => LegalDocuments.termsBody,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: const TindogBackButton(),
        leadingWidth: 48,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Text(
            _body.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                ),
          ),
        ),
      ),
    );
  }
}
