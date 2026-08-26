import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _activeFilter = "All";

  final List<Map<String, dynamic>> _logs = [
    {
      "timestamp": "2 hours ago",
      "type": "Payment",
      "description": "Payment received from Mohammed Ali — ₹1,500",
      "actor": "System (AutoPay)",
    },
    {
      "timestamp": "1 day ago",
      "type": "Member",
      "description": "Member added: Rashid (94321 09876)",
      "actor": "Admin",
    },
    {
      "timestamp": "3 days ago",
      "type": "System",
      "description": "AutoPay enabled for Muhammed",
      "actor": "System",
    },
    {
      "timestamp": "1 week ago",
      "type": "System",
      "description": "Monthly dues reminder sent to 24 members",
      "actor": "System",
    },
    {
      "timestamp": "2 weeks ago",
      "type": "Member",
      "description": "Excel import completed: 15 members added",
      "actor": "Admin",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/admin/dashboard');
            }
          },
        ),
        title: Text(
          "Audit Logs",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: ["All", "Payment", "Member", "System"].map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    onSelected: (selected) {
                      setState(() => _activeFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                if (_activeFilter != "All" && log["type"] != _activeFilter) {
                  return const SizedBox.shrink();
                }
                return _buildLogEntry(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final type = log["type"] as String;
    Color typeColor;
    Color typeBg;

    if (type == "Payment") {
      typeColor = AppColors.success;
      typeBg = AppColors.successBg;
    } else if (type == "Member") {
      typeColor = AppColors.info;
      typeBg = AppColors.infoBg;
    } else {
      typeColor = AppColors.textSecondary;
      typeBg = AppColors.background;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log["timestamp"],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log["description"],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "By ${log["actor"]}",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
