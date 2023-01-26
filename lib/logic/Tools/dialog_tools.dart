import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';

void showSimpleDialog(BuildContext context, String caption, String message, bool okButton, bool koButton, Function? okHandler) {
  showPlatformDialog(
    context: context,
    builder: (context) => BasicDialogAlert(
      title: Text(caption),
      content: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(
              Icons.warning,
              color: Colors.red,
              size: 100,
            ),
          ),
          Expanded(child: Text(message))
        ],
      ),
      actions: <Widget>[
        if (okButton)
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () {
              if(okHandler!=null) {
                okHandler();
              }
              Navigator.pop(context);
            },
          ),
        if (koButton)
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}