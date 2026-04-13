import 'package:flutter/material.dart';
import 'screen5_1_select_user.dart';

class Screen6ViewSession extends StatelessWidget {
  const Screen6ViewSession({super.key});

  @override
  Widget build(BuildContext context) {
    return const Screen51SelectUser(mode: SelectUserMode.viewSession);
  }
}