import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../models/complaint.dart';

class ComplaintsSalesScreen extends StatefulWidget {
  const ComplaintsSalesScreen({super.key});

  @override
  State<ComplaintsSalesScreen> createState() => ComplaintsSalesScreenState();
}

class ComplaintsSalesScreenState extends State<ComplaintsSalesScreen> {
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
      length: 3,
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
              Tab(text: 'Closed'),
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
                _buildClosedComplaints(complaintProvider),
              ],
            );
          },
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
                if (complaint.priority != null && complaint.status != 'closed')
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
                    'Order #${complaint.orderId}',
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

            // Action button for open and resolved complaints (Manage)
            if (complaint.status == 'open' || complaint.status == 'in_progress' || complaint.status == 'resolved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _openManageSheet(context, complaint);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B8E23)),
                  ),
                  child: const Text(
                    'Manage',
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

  Widget _buildClosedComplaints(ComplaintProvider complaintProvider) {
    if (complaintProvider.closedComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No closed complaints',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaintProvider.closedComplaints.length,
      itemBuilder: (context, index) {
        final complaint = complaintProvider.closedComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  void _openManageSheet(BuildContext context, Complaint complaint) {
    final statusOptions = ['open', 'in_progress', 'resolved', 'closed'];
    final priorityOptions = ['critical', 'high', 'medium', 'low'];

    String selectedStatus = complaint.status;
    String? selectedPriority = complaint.priority;
    final resolutionController = TextEditingController(text: complaint.resolution ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedStatus,
                  items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedStatus = v;
                        // if switching to closed, clear selected priority
                        if (selectedStatus == 'closed') selectedPriority = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text('Priority', style: TextStyle(fontSize: 12, color: Colors.grey)),
                AbsorbPointer(
                  absorbing: selectedStatus == 'closed',
                  child: Opacity(
                    opacity: selectedStatus == 'closed' ? 0.5 : 1.0,
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: selectedPriority,
                      items: [null, ...priorityOptions].map((p) {
                        return DropdownMenuItem<String?>(
                          value: p,
                          child: Text(p == null ? 'None' : p.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => selectedPriority = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Resolution / Action', style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: resolutionController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'E.g. Give 20% discount on next order'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Apply changes
                          final provider = Provider.of<ComplaintProvider>(context, listen: false);
                          final success = await provider.updateComplaint(
                            id: complaint.id,
                            status: selectedStatus,
                            priority: selectedPriority,
                            resolution: resolutionController.text.isNotEmpty ? resolutionController.text : null,
                          );
                          Navigator.of(ctx2).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? 'Complaint updated' : 'Update failed'),
                          ));
                        },
                        child: const Text('Save',),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B8E23),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () {
                        // Quick close
                        Provider.of<ComplaintProvider>(context, listen: false).updateComplaint(
                          id: complaint.id,
                          status: 'closed',
                        );
                        Navigator.of(ctx2).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint closed')));
                      },
                      child: const Text('Close', style: TextStyle(color: Colors.white)),

                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
