# Campus Incident Reporting App

A role-based mobile application built with Flutter, Provider, and Firebase for the African Leadership University (ALU) community. The platform enables students to report campus maintenance and safety issues with photo evidence and track their resolution in real time, while empowering authorized campus staff to review, filter, and resolve incidents across campus.

## Links & Deliverables

Demonstration Video: [Demo Video URL]

GitHub Repository: [GitHub repo](https://github.com/bendoujanna/Formative_assignment2.git)

Technical Report: Submitted via Canvas (BendouJannaVitalinaSoeur_Assignment2.pdf)

## Grader Access & Test Credentials

Access to the application is restricted to verified ALU email domains (@alustudent.com and @alueducation.com).


#### Role Provisioning (Least Privilege)

- **New Registrations:** Every new account registered with a verified ALU email (@alustudent.com or @alueducation.com) starts with the student role by default so any tester signing up can immediately test submitting and tracking incident reports.

- **Staff Accounts:** Authorized staff accounts are promoted in the Firebase Console (users/{uid}.role = 'staff'), and Firestore security rules strictly prevent users from creating or elevating their own role from the client.

#### Pre-Verified Demo Accounts (Immediate Login)

If you prefer to test immediately without registering a new account, use the following pre-verified credentials:

**View the report**

## Key Features

#### Student Experience

ALU Domain Authentication & Email Verification: Enforces institutional email sign-up and blocks unverified accounts behind a dedicated verification gate (VerifyEmailScreen) with instant token refresh (getIdToken(true)).

Categorized Incident Submission: 3-column interactive category grid covering Facilities, Furniture, Water, Electricity, Sanitation, and Safety.


- **Automatic Safety Escalation:** Selecting the Safety category automatically flags the incident as Urgent (isUrgent = true) and notifies the student prior to submission.

- **Standardized Campus Locations:** Curated dropdown of ALU campus zones (Classroom block, Library, Student residence, Cafeteria, Sports facilities, Parking and grounds, Other) paired with optional exact room/spot details.

- **Photo Evidence & Full-Screen Zoom:** Capture a photo via camera or pick from gallery with automatic client-side image compression and full-screen pinch-to-zoom inspection (InteractiveViewer).

- **Real-Time Status Timeline:** Visual 3-stage progress tracker (Submitted → In Progress → Resolved) displaying exact timestamps and staff messages.

- **Scoped Deletion:** Students can delete their own reports while the status is still Submitted.

#### Authorized Staff Experience

- **Staff Dashboard:** Role-adapted home screen displaying the count of reports waiting for review with one-tap queue filtering.

- **Campus-Wide Oversight:** Real-time Firestore stream of all student submissions displaying reporter names and urgency badges.

- **Status & Note Management:** Modal bottom sheet (SegmentedButton<IncidentStatus>) to transition incident statuses, record stage timestamps (inProgressAt, resolvedAt), and send up to 200-character updates to the reporting student.

- **Multi-Faceted Search & Filtering:** Instant keyword search across title, location, category, and reporter name, combined with status chips and category filters.

## Architecture & Tech Stack

- **Framework & UI:** Flutter (Material 3 custom brand theme #734AFB)

- **State Management:** Provider (ChangeNotifier + ChangeNotifierProxyProvider) linking authentication sessions (AuthProvider) to role-scoped Firestore streams (IncidentProvider).

- **Authentication:** Firebase Authentication (email_verified + ALU domain enforcement).

- **Database:** Cloud Firestore (users, incidents, and photos collections) protected by declarative security rules (firestore.rules).

- **Media Storage (Hybrid Architecture):**

   - **Primary:** Cloudinary CDN via unsigned multipart REST upload (StorageService) returning public HTTPS URLs (photoUrl).

   - **Fallback:** Atomic Cloud Firestore WriteBatch fallback storing compressed Base64 payloads in photos/{incidentId} with in-memory future caching (_photoCache) so the app operates reliably without requiring a paid       Firebase Blaze plan.

## Directory Structure

```
Formative_assignment2/
├── lib/
│   ├── main.dart                        # App entry point, Firebase init, MultiProvider setup
│   ├── firebase_options.dart            # Platform-specific Firebase configuration
│   ├── core/
│   │   ├── constants.dart               # Allowed domains, collection names, locations, storage toggle
│   │   ├── date_helpers.dart            # Relative timestamp formatting (timeAgo)
│   │   ├── validators.dart              # Account & incident form validators
│   │   └── theme/
│   │       └── app_theme.dart           # Material 3 color scheme & component styling
│   ├── models/
│   │   ├── app_user.dart                # AppUser model & UserRole enum (student, staff)
│   │   └── incident.dart                # Incident model, category/status enums, serialization
│   ├── providers/
│   │   ├── auth_provider.dart           # Auth state machine, domain & verification checks
│   │   └── incident_provider.dart       # Firestore stream subscriptions, filters, CRUD, photo cache
│   ├── services/
│   │   ├── auth_service.dart            # FirebaseAuth wrapper & forced JWT token refresh
│   │   ├── incident_repository.dart     # Firestore CRUD, atomic batch writes, status timestamps
│   │   ├── storage_service.dart         # Cloudinary REST uploader
│   │   └── user_repository.dart         # User profile lookup & domain-based role assignment
│   ├── screens/
│   │   ├── auth_gate.dart               # Reactive router switching on AuthStatus
│   │   ├── login_screen.dart            # Email/password sign-in screen
│   │   ├── register_screen.dart         # ALU account registration screen
│   │   ├── verify_email_screen.dart     # Verification check & resend gate
│   │   ├── main_shell.dart              # IndexedStack bottom navigation shell
│   │   ├── home_screen.dart             # Role-aware dashboard, summary cards, recent reports
│   │   ├── reports_screen.dart          # Searchable, filterable incident list
│   │   ├── report_form_screen.dart      # New incident report form with category grid & photo picker
│   │   ├── incident_details_screen.dart # Full report view, timeline, delete & staff status sheet
│   │   └── profile_screen.dart          # User profile badge, color-coded stats, logout
│   └── widgets/
│       ├── empty_state.dart             # Reusable empty/error state view
│       ├── incident_photo.dart          # Network/inline photo loader with full-screen zoom
│       ├── incident_style.dart          # Category icons & status color mappings
│       ├── report_card.dart             # Incident summary card with thumbnail & status chip
│       ├── status_chip.dart             # Rounded status pill badge
│       ├── status_timeline.dart         # 3-step visual progress timeline
│       └── summary_card.dart            # Interactive dashboard metric card
├── test/
│   ├── app_user_test.dart               # Unit tests for AppUser role parsing & avatar initials
│   ├── date_helpers_test.dart           # Unit tests for relative time formatting (timeAgo)
│   ├── incident_provider_test.dart      # Unit tests for streams, filters, RBAC & photo caching
│   ├── incident_test.dart               # Unit tests for Incident serialization & Safety urgency
│   ├── validators_test.dart             # Unit tests for ALU email & form field validation
│   └── widgets_test.dart                # Widget tests for StatusChip, StatusTimeline, SummaryCard & EmptyState
├── firestore.rules                      # Cloud Firestore declarative RBAC & schema security rules
├── storage.rules                        # Firebase Storage security rules
├── pubspec.yaml                         # Project dependencies & asset declarations
└── README.md                            # Project documentation & setup guide
```

## Getting Started & Installation

#### Prerequisites

- Flutter SDK (>=3.0.0)

- Android Studio (Android Emulator) or Xcode (iOS Simulator) or a physical mobile device

- Active internet connection for Firebase Auth, Firestore, and Cloudinary

**1. Clone the Repository**

```
git clone <github-repo-url>
cd campus_incident_app
```

**2. Install Dependencies**

```flutter pub get```


**3. Run the Application on a Mobile Emulator or Device**

**Note:** Per assignment requirements, run the application on an Android/iOS emulator or physical mobile device rather than a web browser.

```flutter run```


## Running Automated Tests

The repository includes 46 unit and widget tests across 6 test suites under the test/ directory:

- **test/validators_test.dart:** ALU email domain rules, password validation, and character limits.

- **test/incident_test.dart:** Incident.fromMap deserialization, safe defaults, and automatic Safety urgency.

- **test/app_user_test.dart:** UserRole parsing, least-privilege fallback, and avatar initials.

- **test/date_helpers_test.dart:** timeAgo relative date formatting.

- **test/incident_provider_test.dart:** Role-scoped stream selection, search/filter logic, staff-only update guard, and inline photo caching.

- **test/widgets_test.dart:** Widget tests for StatusChip, StatusTimeline, SummaryCard, and EmptyState.

#### Execute the full test suite with:

```flutter test```


## Security Rules

**firestore.rules:** Enforces verified ALU email domains (@alustudent.com and @alueducation.com), restricts students to reading/creating their own reports, prevents role self-elevation, validates field lengths and server timestamps on report creation, and restricts status/note updates exclusively to staff accounts.

**storage.rules:** Enforces owner-scoped image uploads (< 5 MB, image/* content type) and verified ALU domain access.
