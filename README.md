# LeaveEase

**Digital Outpass & Leave Management System for hostels.**

LeaveEase replaces the paper outpass register with a mobile app. Students request an outpass or home leave from their phone, wardens approve or reject with a tap, and every movement is logged with timestamps.

---

## Why LeaveEase?

Paper registers are slow, easy to lose, and impossible to search. LeaveEase gives hostels:

- A single source of truth for who is in and who is out
- Instant approvals instead of waiting at the warden's door
- A timestamped paper trail for attendance and discipline records
- Automatic flagging of late returners

---

## Features

### Student
- Sign up with profile details (name, register number, year, room number, phone, parent's phone)
- Submit two kinds of requests:
  - **Outpass**: short, same-day (reason, expected out time, expected return time)
  - **Home Leave**: multi-day (reason, address/contact while away, start date, return date, parent's phone)
- Date and time pickers for quick form filling
- Live request status: Pending, Approved or Rejected
- **Active Pass screen**: tap "I'm out" and "I'm back" to log departure and return

### Warden
- Dashboard of pending requests with one-tap approve / reject
- Tap-to-call the student's parent for verification
- Per-student history with a late-returner flag toggle
- Records view with filters (date, student, leave type)
- Overdue detection with automatic flagging and dismissible banners

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| Backend | Supabase |
| Database | PostgreSQL with Row Level Security |
| Realtime | Supabase Realtime subscriptions |
| Server logic | Supabase Edge Functions |
| Auth | Supabase Auth with role-based access (student / warden) |

> The project started in React Native (Expo) and was rewritten in Flutter for a more stable build and release flow.

---

## Project Structure

```
lib/
├── main.dart
├── theme.dart                  # Design system (colors, typography, shared styles)
├── widgets/                    # AppCard, StatusChip, SectionTitle, EmptyState
└── screens/
    ├── login_screen.dart
    ├── student_home.dart
    ├── new_outpass_form.dart
    ├── new_home_leave_form.dart
    ├── active_pass_screen.dart
    ├── warden_dashboard.dart
    ├── student_history_screen.dart
    └── records_view.dart
```

---

## Database

Two primary tables:

- **`profiles`**: user details and role (student or warden)
- **`requests`**: outpass and home leave requests, status, timestamps, and out/in logs

Row Level Security keeps data scoped correctly:

- Students can only read and create their own requests
- Wardens can read and update all requests, checked through an `is_warden()` security-definer function

---

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- A Supabase project with the `profiles` and `requests` tables and RLS policies in place

### Setup
1. Clone the repository.
2. Add your Supabase project URL and anon key where the app initialises Supabase in `main.dart`.
3. Run `flutter pub get`, then `flutter run` on an emulator or a connected device.

To build a release APK, use `flutter build apk --release`.

---

## Roles at a Glance

| Action | Student | Warden |
|---|:---:|:---:|
| Submit outpass / home leave | ✅ | |
| View own request status | ✅ | |
| Log "I'm out" / "I'm back" | ✅ | |
| Approve / reject requests | | ✅ |
| View student history | | ✅ |
| Flag late returners | | ✅ |
| Filter and view all records | | ✅ |

---

## Roadmap

- Push notifications for approval, rejection and overdue alerts
- SMS / notification to parents when a home leave is approved
- Export records as CSV / PDF
- Analytics for frequent late returners

---
