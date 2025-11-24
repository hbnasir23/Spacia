import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

typedef CategoryTap = void Function(String id, String name);

class CategoriesList extends StatelessWidget {
  final CategoryTap onCategorySelected;
  final String? selectedCategoryId;

  const CategoriesList({
    super.key,
    required this.onCategorySelected,
    this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox();
        if (!snap.hasData) {
          return const SizedBox(
            height: 50,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown),
            ),
          );
        }

        final docs = snap.data!.docs;

        return SizedBox(
          height: 38, // 🔥 shorter + cleaner
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString();
              final isSelected = selectedCategoryId == docs[index].id;

              return GestureDetector(
                onTap: () => onCategorySelected(docs[index].id, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.darkBrown : Colors.white,
                    border: Border.all(
                      color: AppColors.darkBrown,
                      width: isSelected ? 2 : 1,
                    ),
                    // 🔥🔥 PURE RECTANGLE → NO RADIUS
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.darkBrown,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
