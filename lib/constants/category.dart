import 'package:flutter/material.dart';

/// Per-category tint for transaction row category chips (dark UI).
class CategoryPillStyle {
  const CategoryPillStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

class Categories {
  // NOTE: Don't change the keys after it has been released to the public
  // Labels can change though

  static IconData iconForKey(String key) {
    switch (key) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'investment':
        return Icons.trending_up_outlined;
      case 'salary':
        return Icons.work_outline;
      case 'savings':
        return Icons.savings_outlined;
      case 'charity':
        return Icons.volunteer_activism_outlined;
      case 'rent':
        return Icons.home_work_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'misc':
        return Icons.receipt_long_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  /// Distinct background / border / label colors per category key.
  static CategoryPillStyle pillStyleForKey(String key) {
    switch (key) {
      case 'food':
        return const CategoryPillStyle(
          background: Color(0x26F59E0B),
          border: Color(0x66D97706),
          foreground: Color(0xFFFCD34D),
        );
      case 'transport':
        return const CategoryPillStyle(
          background: Color(0x260EA5E9),
          border: Color(0x662890B4),
          foreground: Color(0xFF7DD3FC),
        );
      case 'investment':
        return const CategoryPillStyle(
          background: Color(0x2610B981),
          border: Color(0x66059669),
          foreground: Color(0xFF6EE7B7),
        );
      case 'salary':
        return const CategoryPillStyle(
          background: Color(0x2614B8A6),
          border: Color(0x660D9488),
          foreground: Color(0xFF5EEAD4),
        );
      case 'savings':
        return const CategoryPillStyle(
          background: Color(0x266366F1),
          border: Color(0x664F46E5),
          foreground: Color(0xFFC7D2FE),
        );
      case 'charity':
        return const CategoryPillStyle(
          background: Color(0x26F43F5E),
          border: Color(0x66E11D48),
          foreground: Color(0xFFFBCFE8),
        );
      case 'rent':
        return const CategoryPillStyle(
          background: Color(0x26A855F7),
          border: Color(0x667C3AED),
          foreground: Color(0xFFE9D5FF),
        );
      case 'utilities':
        return const CategoryPillStyle(
          background: Color(0x26EAB308),
          border: Color(0x66CA8A04),
          foreground: Color(0xFFFEF08A),
        );
      case 'misc':
        return const CategoryPillStyle(
          background: Color(0x2694A3B8),
          border: Color(0x66475569),
          foreground: Color(0xFFE2E8F0),
        );
      default:
        return const CategoryPillStyle(
          background: Color(0xFF21262D),
          border: Color(0xFF30363D),
          foreground: Color(0xFFF0F6FC),
        );
    }
  }

  static const CATEGORIES = [
    {
      "key": "food",
      "label": "Food",
    },
    {
      "key": "transport",
      "label": "Transport",
    },
    {
      "key": "investment",
      "label": "Investment",
    },
    {
      "key": "salary",
      "label": "Salary",
    },
    {
      "key": "savings",
      "label": "Savings",
    },
    {
      "key": "charity",
      "label": "Charity",
    },
    {
      "key": "rent",
      "label": "Rent",
    },
    {
      "key": "utilities",
      "label": "Utilities (e.g. Subscription, etc)",
    },
    {
      "key": "misc",
      "label": "Miscellaneous",
    },
  ];
}
