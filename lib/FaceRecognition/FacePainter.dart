import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class FacePainter extends CustomPainter {
  final ui.Image image;
  final Map faceLabelMap;
  List<Face> faces;
  final List<Rect> rects = [];
  List<String> labels;

  FacePainter(this.image, this.faceLabelMap) {
    faces = faceLabelMap['faces'];
    labels = faceLabelMap['labels'];
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  void drawText(Canvas canvas) {
    final textStyle = ui.TextStyle(
        color: Colors.black,
        fontSize: 30,
        background: Paint()..color = Colors.white54);
    final paragraphStyle = ui.ParagraphStyle(
        textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    for (int i = 0; i < labels.length; i++) {
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(labels[i]);
      final constraints =
          ui.ParagraphConstraints(width: faces[i].boundingBox.width);
      final paragraph = paragraphBuilder.build();
      paragraph.layout(constraints);
      final offset = faces[i].boundingBox.bottomLeft;
      canvas.drawParagraph(paragraph, offset);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
    drawText(canvas);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
