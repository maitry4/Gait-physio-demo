import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main()  {
  runApp(
    const ProviderScope(
      child: GaitPhysioApp(),
    ),
  );
}

class GaitPhysioApp extends ConsumerWidget {
  const GaitPhysioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final router = ref.watch(routerProvider);

    return MaterialApp(
      title: 'Gait Physio',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.light,
      // routerConfig: router,
    );
  }
}