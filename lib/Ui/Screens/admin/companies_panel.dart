import 'package:flutter/material.dart';
import '../../../models/company.dart';
import '../../../models/page_response.dart';
import '../../../services/company_service.dart';
import '../../Widgets/custom_text_field.dart';
import '../../Widgets/custom_button.dart';
import '../../../utils/error_handler.dart';

class CompaniesPanel extends StatefulWidget {
  final int refreshToken;
  final VoidCallback onRefreshRequested;

  const CompaniesPanel({super.key, required this.refreshToken, required this.onRefreshRequested});

  @override
  State<CompaniesPanel> createState() => _CompaniesPanelState();
}

class _CompaniesPanelState extends State<CompaniesPanel> {
  final CompanyService _service = CompanyService();
  Future<PageResponse<CompanyResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getList();
  }

  @override
  void didUpdateWidget(covariant CompaniesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _future = _service.getList();
    }
  }

  Future<void> _createOrEdit({CompanyResponse? company}) async {
    final nameController = TextEditingController(text: company?.companyName ?? '');
    final addressController = TextEditingController(text: company?.companyAddress ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  company == null ? 'Create Company' : 'Edit Company',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: nameController,
                  label: 'Company Name',
                  prefixIcon: Icons.business,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Company name is required' : null,
                ),
                CustomTextField(
                  controller: addressController,
                  label: 'Company Address',
                  prefixIcon: Icons.location_on,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: 'Save',
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            try {
                              if (company == null) {
                                await _service.createCompany(
                                  companyName: nameController.text.trim(),
                                  companyAddress: addressController.text.trim(),
                                );
                                if (mounted) {
                                  ErrorHandler.showSuccess(context, 'Company created successfully!');
                                }
                              } else {
                                await _service.updateCompany(
                                  id: company.id,
                                  companyName: nameController.text.trim(),
                                  companyAddress: addressController.text.trim(),
                                );
                                if (mounted) {
                                  ErrorHandler.showSuccess(context, 'Company updated successfully!');
                                }
                              }
                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              widget.onRefreshRequested();
                            } catch (e) {
                              if (mounted) {
                                ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<PageResponse<CompanyResponse>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final companies = snapshot.data?.content ?? [];
          if (companies.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _createOrEdit(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Company'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _service.getList());
                    widget.onRefreshRequested();
                  },
                  child: ListView.builder(
                    itemCount: companies.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(
                            company.companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    company.companyAddress ?? '-',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                              onPressed: () => _createOrEdit(company: company),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.business, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No Companies Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _createOrEdit(),
          child: const Text('Add First Company'),
        ),
      ],
    );
  }
}
