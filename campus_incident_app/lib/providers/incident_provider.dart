import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_repository.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider({IncidentRepository? repository, StorageService? storage})
    : _repository = repository ?? IncidentRepository(),
      _storage = storage ?? StorageService();

  final IncidentRepository _repository;
  final StorageService _storage;

  StreamSubscription<List<Incident>>? _subscription;
  String? _listeningUid;
  bool? _listeningAsStaff;

  AppUser? _currentUser;
  List<Incident> _incidents = const [];
  final Map<String, Future<Uint8List?>> _photoCache = {};

  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  String _searchQuery = '';

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  List<Incident> get incidents => _incidents;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  int get totalCount => _incidents.length;

  int countFor(IncidentStatus status) =>
      _incidents.where((i) => i.status == status).length;

  Incident? findById(String id) {
    for (final incident in _incidents) {
      if (incident.id == id) return incident;
    }
    return null;
  }

  List<Incident> get filteredIncidents {
    final query = _searchQuery.trim().toLowerCase();

    return _incidents.where((incident) {
      if (_statusFilter != null && incident.status != _statusFilter) {
        return false;
      }
      if (_categoryFilter != null && incident.category != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      return incident.title.toLowerCase().contains(query) ||
          incident.fullLocation.toLowerCase().contains(query) ||
          incident.category.label.toLowerCase().contains(query) ||
          incident.reporterName.toLowerCase().contains(query);
    }).toList();
  }

  void updateAuth(AuthStatus status, AppUser? profile) {
    _currentUser = profile;

    if (status != AuthStatus.signedIn || profile == null) {
      _stopListening();
      _incidents = const [];
      _photoCache.clear();
      _statusFilter = null;
      _categoryFilter = null;
      _searchQuery = '';
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_listeningUid == profile.uid && _listeningAsStaff == profile.isStaff) {
      return;
    }

    _startListening(profile);
  }

  void _startListening(AppUser user) {
    _stopListening();
    _listeningUid = user.uid;
    _listeningAsStaff = user.isStaff;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final stream = user.isStaff
        ? _repository.watchAllIncidents()
        : _repository.watchMyIncidents(user.uid);

    _subscription = stream.listen(
      (items) {
        _incidents = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _listeningUid = null;
    _listeningAsStaff = null;
    _isLoading = false;
  }

  void setStatusFilter(IncidentStatus? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> submitReport({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String locationDetails = '',
    XFile? photo,
  }) async {
    final user = _currentUser;
    if (user == null) return false;

    _isSubmitting = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      UploadedPhoto? uploaded;
      Uint8List? inlineBytes;

      if (photo != null) {
        if (AppConstants.useFirebaseStorage) {
          uploaded = await _storage.uploadIncidentPhoto(
            uid: user.uid,
            file: photo,
          );
        } else {
          inlineBytes = await File(photo.path).readAsBytes();
          if (inlineBytes.lengthInBytes > AppConstants.maxInlinePhotoBytes) {
            _actionErrorMessage =
                'That photo is too large. Please pick a smaller image.';
            _isSubmitting = false;
            notifyListeners();
            return false;
          }
        }
      }

      final draft = Incident.draft(
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location.trim(),
        locationDetails: locationDetails.trim(),
        photoUrl: uploaded?.url,
        photoPath: uploaded?.path,
        hasInlinePhoto: inlineBytes != null,
        reporterId: user.uid,
        reporterName: user.name,
      );

      await _repository.create(draft, inlinePhoto: inlineBytes);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (_) {
      _actionErrorMessage = 'Could not submit the report. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(
    Incident incident,
    IncidentStatus status, {
    String? note,
  }) async {
    final user = _currentUser;
    if (user == null || !user.isStaff) return false;

    _actionErrorMessage = null;
    try {
      await _repository.updateStatus(
        incidentId: incident.id,
        status: status,
        staffName: user.name,
        note: note,
      );
      return true;
    } catch (_) {
      _actionErrorMessage = 'Could not update the status. Please try again.';
      return false;
    }
  }

  Future<bool> deleteReport(Incident incident) async {
    _actionErrorMessage = null;
    try {
      await _repository.delete(incident);
      if (incident.photoPath != null) {
        await _storage.deletePhoto(incident.photoPath!);
      }
      _photoCache.remove(incident.id);
      return true;
    } catch (_) {
      _actionErrorMessage = 'Could not delete the report. Please try again.';
      return false;
    }
  }

  /// Caches the future so scrolling through report cards does not re-fetch
  Future<Uint8List?> loadInlinePhoto(String incidentId) {
    return _photoCache.putIfAbsent(
      incidentId,
      () => _repository.getInlinePhoto(incidentId),
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
