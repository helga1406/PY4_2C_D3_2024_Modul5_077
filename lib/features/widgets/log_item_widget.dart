import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:intl/intl.dart'; 

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  final bool canEdit;
  final bool canDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    required this.canEdit,   
    required this.canDelete, 
  });

  String _formatDateTime(String dateStr) {
    try {
      DateTime logTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(logTime);
    } catch (e) {
      return dateStr; 
    }
  }

  Color _getCategoryColor() {
    switch (log.category) {
      case "Urgent":
        return const Color.fromARGB(255, 255, 240, 240);
      case "Pekerjaan":
        return const Color.fromARGB(255, 232, 244, 253);
      case "Pribadi":
        return const Color.fromARGB(255, 243, 229, 245);
      default:
        return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 158, 101, 140);

    final bool isTemp = log.id?.contains('temp') ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        log.category,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
    
                    // Baris Tanggal + INDIKATOR AWAN (TASK 4)
                    Row(
                      children: [
                        Text(
                          _formatDateTime(log.date), 
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.grey,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isTemp ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                          size: 14,
                          color: isTemp ? Colors.orangeAccent : Colors.blueAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    // Judul
                    Text(
                      log.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    // Deskripsi
                    Text(
                      log.description,
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              
              // Tombol Aksi (Edit/Delete)
              Row(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  if (canEdit)
                    _buildCircularButton(
                      icon: Icons.edit_rounded,
                      iconColor: primaryColor,
                      onTap: onEdit,
                    ),

                  if (canEdit && canDelete) const SizedBox(width: 10), 

                  if (canDelete)
                    _buildCircularButton(
                      icon: Icons.delete_rounded,
                      iconColor: Colors.redAccent,
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}