import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';

class SupportViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  List<SupportTicketModel> _tickets = [];
  bool _isLoading = false;

  List<SupportTicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;

  SupportViewModel(this._firebaseService) {
    _listenToTickets();
  }

  void _listenToTickets() {
    _isLoading = true;
    notifyListeners();

    _firebaseService.getTickets().listen((ticketList) {
      _tickets = ticketList;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStatus(String ticketId, String status, {String? reply}) async {
    try {
      // In FirebaseService, we'll need to handle String status now
      await _firebaseService.updateTicketStatus(ticketId, status, reply: reply);
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
    }
  }

  List<SupportTicketModel> get pendingTickets => 
      _tickets.where((t) => t.status.toLowerCase() == 'pending').toList();

  List<SupportTicketModel> get resolvedTickets => 
      _tickets.where((t) => t.status.toLowerCase() == 'resolved' || t.status.toLowerCase() == 'closed').toList();
}
