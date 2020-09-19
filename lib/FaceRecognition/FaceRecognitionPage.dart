import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:prototype/FaceRecognition/FaceRecognition.dart';
import 'package:prototype/FaceRecognition/FacePainter.dart';

class FaceRecognitionPage extends StatefulWidget {
  FaceRecognitionPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FaceRecPageState createState() => _FaceRecPageState();
}

class _FaceRecPageState extends State<FaceRecognitionPage> {
  FaceRecognition _classifier = FaceRecognition();
  Map _data;
  ui.Image _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('face recognition example app'),
      ),
      body: Container(
          child: _data != null
              ? FittedBox(
                  child: SizedBox(
                      width: _image.width.toDouble(),
                      height: _image.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(_image, _data),
                      )))
              : null),
      floatingActionButton: FloatingActionButton(
        onPressed: predictImagePicker,
        tooltip: 'Pick Image',
        child: Icon(Icons.image),
      ),
    );
  }

  Future predictImagePicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    var faceLabelMap = await _classifier.classify(image);
    setState(() {
      _data = faceLabelMap;
      _loadImage(image);
    });
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image = value;
      }),
    );
  }
}
