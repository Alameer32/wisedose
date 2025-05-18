import 'package:flutter/material.dart';
import 'package:wisedose/services/medicine_service.dart';
import 'package:wisedose/utils/app_theme.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback? onSetReminder;
  final VoidCallback? onTakeDose;

  const MedicineCard({
    Key? key,
    required this.medicine,
    required this.onTap,
    this.onSetReminder,
    this.onTakeDose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLowSupply = medicine.remainingDoses <= 3;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          medicine.dosage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${medicine.remainingDoses}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isLowSupply ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.timing,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (onSetReminder != null)
                    TextButton.icon(
                      onPressed: onSetReminder,
                      icon: const Icon(Icons.alarm),
                      label: const Text('Reminder'),
                    ),
                  if (onTakeDose != null)
                    TextButton.icon(
                      onPressed: medicine.remainingDoses > 0 ? onTakeDose : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Take'),
                    ),
                ],
              ),
              if (isLowSupply)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Low supply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
