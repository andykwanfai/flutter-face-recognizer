import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart';
import 'package:sklite/SVM/SVM.dart';
import 'package:sklite/utils/io.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// For development only.
String readFile(String path) {
  return File(path).readAsStringSync();
}

/// For development only.
Map<String, dynamic> readJsonFile(String path) {
  return json.decode(readFile(path));
}

class FaceRecognition {
  // name of the model file
  final _modelFile = 'my_facenet.tflite';

  // TensorFlow Lite Interpreter object
  Interpreter _interpreter;
  FaceDetector _detector;
  var _labels;
  var _svc;

  FaceRecognition() {
    // Load model when the classifier is initialized.
    init();
  }

  void init() async {
    // Creating the interpreter using Interpreter.fromAsset
    _interpreter = await Interpreter.fromAsset(_modelFile);
    print('Interpreter loaded successfully');
    _detector = FirebaseVision.instance.faceDetector(
      const FaceDetectorOptions(mode: FaceDetectorMode.accurate),
    );
    loadModel("assets/labels.json").then((x) {
      _labels = json.decode(x);
    });
    loadModel("assets/svc.json").then((x) {
      _svc = SVC.fromMap(json.decode(x));
    });
  }

  Future<Map> classify(File file) async {
    var faceLabelMap = new Map();

    // print(new DateTime.now());

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(file);

    final List<Face> faces = await _detector.processImage(visionImage);

    faceLabelMap['faces'] = faces;

    // print(new DateTime.now());
    Image image = decodeImage(file.readAsBytesSync());

    // print(new DateTime.now());
    var labels = new List<String>();
    for (var face in faces) {
      Image cropFace = copyCrop(
          image,
          face.boundingBox.left.toInt(),
          face.boundingBox.top.toInt(),
          face.boundingBox.width.toInt(),
          face.boundingBox.height.toInt());
      Image resizeFace = copyResize(cropFace, width: 160, height: 160);

      Uint8List byteData = resizeFace.getBytes();
      List<double> rgbValues = toRgb(byteData);
      var input = prewhiten(rgbValues).reshape([1, 160, 160, 3]);

      var embedding = new List<double>(512).reshape([1, 512]);

      _interpreter.run(input, embedding);

      labels.add(_labels[_svc.predict(embedding[0])].toString());
    }

    faceLabelMap['labels'] = labels;

    return faceLabelMap;
  }

  List<double> toRgb(Uint8List byteData) {
    // image byte to rgb
    List<double> rgbValues = new List(160 * 160 * 3);

    for (int i = 0; i < byteData.length; i = i + 4) {
      //bytedata: rgba
      int j = i ~/ 4 * 3;
      rgbValues[j + 0] = byteData[i + 0].toDouble(); //r
      rgbValues[j + 1] = byteData[i + 1].toDouble(); //g
      rgbValues[j + 2] = byteData[i + 2].toDouble(); //b

    }
    return rgbValues;
  }

  List<double> prewhiten(List<double> rgbValues) {
    double sum = 0;
    for (final e in rgbValues) {
      sum += e;
    }

    double mean = sum / rgbValues.length;

    double variance = 0;

    rgbValues.forEach((element) {
      variance += pow(element - mean, 2);
    });

    variance /= rgbValues.length;

    double std = sqrt(variance);

    double stdAdj = max(std, 1.0 / sqrt(rgbValues.length));

    List<double> prewhiten = new List();

    rgbValues.forEach((element) {
      prewhiten.add((element - mean) / stdAdj);
    });

    return prewhiten;
  }
}
