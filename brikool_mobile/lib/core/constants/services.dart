import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String title;
  final IconData icon;

  const ServiceCategory({
    required this.id,
    required this.title,
    required this.icon,
  });
}

const List<ServiceCategory> serviceCategories = [
  ServiceCategory(
    id: 'electrician',
    title: 'Electrician',
    icon: Icons.electrical_services,
  ),
  ServiceCategory(
    id: 'plumber',
    title: 'Plumber',
    icon: Icons.plumbing,
  ),
  ServiceCategory(
    id: 'carpenter',
    title: 'Carpenter',
    icon: Icons.handyman,
  ),
  ServiceCategory(
    id: 'painter',
    title: 'Painter',
    icon: Icons.format_paint,
  ),
  ServiceCategory(
    id: 'cleaner',
    title: 'Cleaning',
    icon: Icons.cleaning_services,
  ),
];
