import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/faq_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';

class FaqManagementScreen extends StatefulWidget {
  const FaqManagementScreen({super.key});

  @override
  State<FaqManagementScreen> createState() => _FaqManagementScreenState();
}

class _FaqManagementScreenState extends State<FaqManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildSearchBar(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildFaqList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAQ Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Manage frequently asked questions for Students and Drivers.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showFaqDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add New FAQ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          hintText: 'Search FAQs...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return StreamBuilder<List<FaqModel>>(
      stream: _firebaseService.getFaqs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final faqs = snapshot.data!.where((f) => 
          f.question.toLowerCase().contains(_searchQuery) || 
          f.answer.toLowerCase().contains(_searchQuery) ||
          f.category.toLowerCase().contains(_searchQuery)
        ).toList();

        if (faqs.isEmpty) return _buildEmptyState(isSearch: true);

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: faqs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return _buildFaqCard(faq);
          },
        );
      },
    );
  }

  Widget _buildFaqCard(FaqModel faq) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                faq.category.toUpperCase(),
                style: const TextStyle(color: AppColors.primaryNavy, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(faq.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          ],
        ),
        children: [
          const Divider(height: 32),
          Text(faq.answer, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showFaqDialog(faq: faq),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _confirmDelete(faq.id),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearch ? Icons.search_off_rounded : Icons.quiz_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No matching FAQs found.' : 'No FAQs added yet.',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog({FaqModel? faq}) {
    final questionController = TextEditingController(text: faq?.question);
    final answerController = TextEditingController(text: faq?.answer);
    final categoryController = TextEditingController(text: faq?.category ?? 'General');
    final orderController = TextEditingController(text: faq?.order.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(faq == null ? 'Add New FAQ' : 'Edit FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 16),
              TextField(controller: questionController, decoration: const InputDecoration(labelText: 'Question')),
              const SizedBox(height: 16),
              TextField(controller: answerController, decoration: const InputDecoration(labelText: 'Answer'), maxLines: 4),
              const SizedBox(height: 16),
              TextField(controller: orderController, decoration: const InputDecoration(labelText: 'Display Order'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newFaq = FaqModel(
                id: faq?.id ?? '',
                question: questionController.text,
                answer: answerController.text,
                category: categoryController.text,
                order: int.tryParse(orderController.text) ?? 0,
              );

              if (faq == null) {
                await _firebaseService.addFaq(newFaq);
              } else {
                await _firebaseService.updateFaq(newFaq);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(faq == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ?'),
        content: const Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firebaseService.deleteFaq(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
