# odoo_sales_app

# Odoo Sales App

A Flutter mobile application for sales teams integrated with Odoo ERP.

## Features

- Odoo username and password login
- Odoo JSON-RPC / HTTP session authentication
- XML-RPC fallback authentication
- Customer list from `res.partner`
- Filters customers using `customer_rank > 0`
- Customer search by name
- Customer details:
  - Name
  - Phone
  - Email
  - Address
- Update customer phone number directly in Odoo
- Offline customer caching using SQLite
- Offline phone edits stored locally
- Automatic synchronization when internet connection returns
- Internal user detection using `base.group_user`
- Sales Orders screen for internal users
- Sale order details:
  - Order number
  - Customer
  - Order date
  - Status
  - Products
  - Quantities
  - Unit prices
  - Subtotals
  - Total amount
- Confirm draft quotations from the mobile app

## Technologies

- Flutter
- Dart
- Odoo ERP
- `odoo_rpc`
- XML-RPC
- SQLite / `sqflite`
- `connectivity_plus`

## Project Structure

```text
lib/
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── customer_list_screen.dart
│   ├── customer_details_screen.dart
│   ├── sales_orders_screen.dart
│   └── sales_order_details_screen.dart
└── services/
    ├── odoo_service.dart
    └── local_database.dart

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
