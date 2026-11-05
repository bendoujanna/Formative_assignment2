import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_repository.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

/// Holds the incident reports for the signed-in person, plus the search and
/// filters used on the Reports screen. Students get their own reports, staff
/// get all of them. Screens read from here and never call Firestore or
/// Storage directly.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider({
    IncidentRepository? repository,
    StorageService? storageService,
  }) : _repository = repository ?? IncidentRepository(),
       _storage = storageService ?? StorageService();

  final IncidentRepository _repository;
  final StorageService _storage;

  StreamSubscription<List<Incident>>? _subscription;
  AppUser? _user;
  String? _boundKey;

  List<Incident> _incidents = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;

  // ---------------------------------------------------------------------
  // What the screens read
  // ---------------------------------------------------------------------

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _statusFilter != null ||
      _categoryFilter != null;

  int get totalCount => _incidents.length;

  int countFor(IncidentStatus status) =>
      _incidents.where((incident) => incident.status == status).length;

  /// The reports that match the current search and filters.
  List<Incident> get filteredIncidents {
    final query = _searchQuery.trim().toLowerCase();

    return _incidents.where((incident) {
      final matchesStatus =
          _statusFilter == null || incident.status == _statusFilter;
      final matchesCategory =
          _categoryFilter == null || incident.category == _categoryFilter;
      final matchesSearch =
          query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.description.toLowerCase().contains(query) ||
          incident.fullLocation.toLowerCase().contains(query) ||
          incident.category.label.toLowerCase().contains(query);
      return matchesStatus && matchesCategory && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------
  // Search and filters
  // ---------------------------------------------------------------------

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(IncidentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Signing in and out
  // ---------------------------------------------------------------------

  /// Called by ChangeNotifierProxyProvider whenever the sign-in state changes.
  /// It starts listening to the right reports, or stops when signed out.
  void updateAuth(AuthStatus status, AppUser? user) {
    // Only a signed-in, verified person gets reports.
    final activeUser = status == AuthStatus.signedIn ? user : null;
    final key = activeUser == null
        ? null
        : '${activeUser.uid}:${activeUser.role.name}';

    // Nothing changed for this person, so keep the current listener.
    if (key == _boundKey) return;

    _boundKey = key;
    _subscription?.cancel();
    _subscription = null;
    _incidents = const [];
    _errorMessage = null;
    _searchQuery = '';
    _statusFilter = null;
    _categoryFilter = null;
    _user = activeUser;

    if (activeUser == null) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    final stream = activeUser.isStaff
        ? _repository.watchAllIncidents()
        : _repository.watchMyIncidents(activeUser.uid);

    _subscription = stream.listen(
      (list) {
        _incidents = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Loading reports failed: $error');
        _isLoading = false;
        _errorMessage = 'Could not load reports. Please try again later.';
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------

  /// Uploads the photo (if any) and saves the report. Returns true on success.
  Future<bool> submitReport({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String locationDetails = '',
    XFile? photo,
  }) async {
    final user = _user;
    if (user == null) {
      _errorMessage = 'You need to be signed in to send a report.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isSubmitting = true;
    notifyListeners();

    UploadedPhoto? uploaded;
    try {
      if (photo != null) {
        uploaded = await _storage.uploadIncidentPhoto(
          uid: user.uid,
          file: photo,
        );
      }

      final draft = Incident.draft(
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location,
        locationDetails: locationDetails.trim(),
        photoUrl: uploaded?.url,
        photoPath: uploaded?.path,
        reporterId: user.uid,
        reporterName: user.name,
      );
      await _repository.create(draft);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Submit failed: ${e.plugin} ${e.code} ${e.message}');
      // Do not leave an orphan photo behind if the report itself failed.
      if (uploaded != null) await _storage.deletePhoto(uploaded.path);
      _errorMessage = _messageForError(e);
      return false;
    } catch (e) {
      debugPrint('Submit failed: $e');
      if (uploaded != null) await _storage.deletePhoto(uploaded.path);
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// A student can delete their own report while it is still Submitted.
  Future<bool> deleteReport(Incident incident) async {
    try {
      await _repository.delete(incident.id);
      final photoPath = incident.photoPath;
      if (photoPath != null) await _storage.deletePhoto(photoPath);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Delete failed: ${e.plugin} ${e.code} ${e.message}');
      _errorMessage = _messageForError(e);
      notifyListeners();
      return false;
    }
  }

  String _messageForError(FirebaseException e) {
    if (e.plugin == 'firebase_storage') {
      return 'Could not upload the photo. You can remove it and send the report without a photo.';
    }
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'unavailable':
        return 'No connection to the server. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
