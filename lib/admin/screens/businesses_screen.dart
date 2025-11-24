import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------------
  // ⭐ DETAILS POPUP (POLISHED)
  // ----------------------------------------------------------------------------

  void _showDetails(BuildContext ctx, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.all(28),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  data?['businessName'] ?? 'Business',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // Info
                _infoRow("Email", data?['email']),
                const SizedBox(height: 10),

                _infoRow("Address",
                    data?['businessAddress'] ?? data?['address'] ?? '—'),
                const SizedBox(height: 10),

                _infoRow("Revenue", "\$${data?['revenue'] ?? 0}"),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    // Delete button
                    ElevatedButton(
                      onPressed: () => _confirmDelete(ctx, dCtx, doc.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper for info rows
  Widget _infoRow(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? "—",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------------
  // ⭐ DELETE CONFIRMATION POPUP
  // ----------------------------------------------------------------------------

  Future<void> _confirmDelete(
      BuildContext mainCtx, BuildContext dialogCtx, String businessId) async {
    final result = await showDialog<bool>(
      context: mainCtx,
      barrierDismissible: true,
      builder: (cCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Confirm Delete",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Are you sure you want to delete this business?",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel
                  ElevatedButton(
                    onPressed: () => Navigator.pop(cCtx, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),

                  // Delete
                  ElevatedButton(
                    onPressed: () => Navigator.pop(cCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                    ),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .delete();
      Navigator.pop(dialogCtx);
    }
  }

  // ----------------------------------------------------------------------------
  // ⭐ MAIN UI
  // ----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return Column(
      children: [
        // ------------------ Search Bar ------------------
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search businesses by name or email',
              hintStyle:
              const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ------------------ Business List ------------------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs
                .collection('businesses')
                .where('approved', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ));
              }

              final docs = snapshot.data!.docs.where((d) {
                if (_searchCtrl.text.isEmpty) return true;

                final data = d.data() as Map<String, dynamic>;
                final q = _searchCtrl.text.toLowerCase();

                return (data['businessName']
                    ?.toString()
                    .toLowerCase()
                    .contains(q) ??
                    false) ||
                    (data['email']?.toString().toLowerCase().contains(q) ??
                        false);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No matching businesses found",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final d = docs[index];
                  final data = d.data() as Map<String, dynamic>?;
                  final revenue = data?['revenue'] ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => _showDetails(context, d),
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        data?['businessName'] ?? 'Unnamed',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        data?['email'] ?? '',
                        style: const TextStyle(
                            fontFamily: 'Poppins', color: Colors.grey),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Revenue",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$$revenue",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
