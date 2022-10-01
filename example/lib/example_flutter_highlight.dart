import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

import 'code_samples.dart';

class FlutterHighlightExample extends StatelessWidget {
  const FlutterHighlightExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HighlightView(
      codeString4,
      language: 'dart',
      theme: highlighterDarcula,
      textStyle: const TextStyle(
        fontFamily: 'My awesome monospace font',
        fontSize: 16,
      ),
    );
  }
}

const highlighterDarcula = {
  'root': TextStyle(backgroundColor: Color(0xff2b2b2b), color: Color(0xffbababa)),
  'strong': TextStyle(color: Color(0xffa8a8a2)),
  'emphasis': TextStyle(color: Color(0xffa8a8a2), fontStyle: FontStyle.italic),
  'bullet': TextStyle(color: Color(0xff6896ba)),
  'quote': TextStyle(color: Color(0xff6896ba)),
  'link': TextStyle(color: Color(0xff6896ba)),
  'number': TextStyle(color: Color(0xff6896ba)),
  'regexp': TextStyle(color: Color(0xff6896ba)),
  'literal': TextStyle(color: Color(0xff6896ba)),
  'code': TextStyle(color: Color(0xffa6e22e)),
  'selector-class': TextStyle(color: Color(0xffa6e22e)),
  'keyword': TextStyle(color: Color(0xffcb7832)),
  'selector-tag': TextStyle(color: Color(0xffcb7832)),
  'section': TextStyle(color: Color(0xffcb7832)),
  'attribute': TextStyle(color: Color(0xffcb7832)),
  'name': TextStyle(color: Color(0xffcb7832)),
  'variable': TextStyle(color: Color(0xffcb7832)),
  'params': TextStyle(color: Color(0xffb9b9b9)),
  'string': TextStyle(color: Color(0xff6a8759)),
  'subst': TextStyle(color: Color(0xffe0c46c)),
  'type': TextStyle(color: Color(0xffe0c46c)),
  'built_in': TextStyle(color: Color(0xffe0c46c)),
  'builtin-name': TextStyle(color: Color(0xffe0c46c)),
  'symbol': TextStyle(color: Color(0xffe0c46c)),
  'selector-id': TextStyle(color: Color(0xffe0c46c)),
  'selector-attr': TextStyle(color: Color(0xffe0c46c)),
  'selector-pseudo': TextStyle(color: Color(0xffe0c46c)),
  'template-tag': TextStyle(color: Color(0xffe0c46c)),
  'template-variable': TextStyle(color: Color(0xffe0c46c)),
  'addition': TextStyle(color: Color(0xffe0c46c)),
  'comment': TextStyle(color: Color(0xff7f7f7f)),
  'deletion': TextStyle(color: Color(0xff7f7f7f)),
  'meta': TextStyle(color: Color(0xff7f7f7f)),
};
