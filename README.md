# Quick Ticket Maker

Flutter rewrite of the FlutterFlow **Quick Ticket Maker** prototype — generate styled event tickets with customizable QR codes.

## Features

- Ticket preview with QR code (eye/module color + square/circle shape)
- Background gradient cycling
- Generate a fresh ticket code / QR payload
- Event image refresh
- Tickets list tab

## Run

```bash
flutter pub get
flutter run
```

## Structure

```
lib/
  core/           # theme, router, shared widgets
  features/
    generate/     # ticket generator (Cubit + UI)
    tickets/      # tickets list
```

No FlutterFlow runtime — plain Flutter + `flutter_bloc`, `go_router`, `qr_flutter`, and `google_fonts`.
