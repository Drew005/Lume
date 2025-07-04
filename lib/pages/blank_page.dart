import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlankPage extends StatelessWidget {
  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(child: Text("Em breve")),
    );
  }
}
