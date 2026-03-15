import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../models/complaint.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _descriptionController = TextEditingController();
  int? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComplaintProvider>(context, listen: false).loadComplaints();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complaints'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          backgroundColor: const Color(0xFF6B8E23),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Open'),
              Tab(text: 'Resolved'),
            ],
            labelColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
          ),
        ),
        body: Consumer<ComplaintProvider>(
          builder: (context, complaintProvider, _) {
            return TabBarView(
              children: [
                _buildOpenComplaints(complaintProvider),
                _buildResolvedComplaints(complaintProvider),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateComplaintDialog,
          backgroundColor: const Color(0xFF6B8E23),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOpenComplaints(ComplaintProvider complaintProvider) {
    if (complaintProvider.openComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No open complaints',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaintProvider.openComplaints.length,
      itemBuilder: (context, index) {
        final complaint = complaintProvider.openComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildResolvedComplaints(ComplaintProvider complaintProvider) {
    if (complaintProvider.resolvedComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No resolved complaints',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaintProvider.resolvedComplaints.length,
      itemBuilder: (context, index) {
        final complaint = complaintProvider.resolvedComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    Color statusColor;
    IconData statusIcon;

    switch (complaint.status) {
      case 'open':
        statusColor = Colors.red;
        statusIcon = Icons.circle;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    Color priorityColor;
    switch (complaint.priority) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Color(0xFFD5AF17);
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status (replace your existing Row block)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            complaint.status.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (complaint.priority != null)
                  Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        complaint.priority!.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              complaint.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Order ID and Date
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'No. #${complaint.orderId}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: Text(
                    _formatDate(complaint.createdAt),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),


            // Resolution if available
            if (complaint.resolution != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resolution',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.resolution!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action button for open complaints
            if (complaint.status == 'open' || complaint.status == 'in_progress') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact support for this complaint'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B8E23)),
                  ),
                  child: const Text(
                    'Add Comment',
                    style: TextStyle(color: Color(0xFF6B8E23)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateComplaintDialog() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Complaint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Report an issue with your order',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Order selection
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Select Order',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                items: orderProvider.orders
                    .map((order) => DropdownMenuItem(
                  value: order.id,
                  child: Text('No. #${order.id}'),
                ))
                    .toList(),
                onChanged: (value) {
                  _selectedOrderId = value;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF6B8E23),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E23),
            ),
            onPressed: () {
              if (_selectedOrderId != null && _descriptionController.text.isNotEmpty) {
                try {
                  Provider.of<ComplaintProvider>(context, listen: false)
                      .createComplaint(
                    orderId: _selectedOrderId!,
                    description: _descriptionController.text.trim(),
                  )
                      .then((success) {
                    if (success) {
                      _descriptionController.clear();
                      _selectedOrderId = null;
                      Navigator.pop(context);
                      ErrorHandler.showSuccessSnackBar(
                        context,
                        'Complaint submitted successfully',
                      );
                    } else {
                      ErrorHandler.showErrorSnackBar(
                        context,
                        'Failed to submit complaint. Please try again.',
                      );
                    }
                  });
                } catch (e) {
                  ErrorHandler.showErrorSnackBar(context, e);
                }
              } else {
                ErrorHandler.showInfoSnackBar(
                  context,
                  'Please select an order and describe the issue',
                );
              }
            },
            child: const Text(
              'Submit Complaint',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
