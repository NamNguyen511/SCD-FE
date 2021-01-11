import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:src/blocs/authentication/authentication_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:src/models/photo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tflite/tflite.dart';
import 'package:percent_indicator/percent_indicator.dart';

typedef OnSaveCallback = Function(String title, String descript, String userId,
    String photoUrl, double benignRate, double malignantRate);

class AddEditScreen extends StatefulWidget {
  final OnSaveCallback onSave;
  final bool isEditing;
  final Photo photo;

  AddEditScreen(
      {Key key, @required this.onSave, @required this.isEditing, this.photo})
      : super(key: key);

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

final Color yellow = Color(0xfffbc31b);
final Color orange = Color(0xfffb6900);

class _AddEditScreenState extends State<AddEditScreen> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _title;
  String _descript;
  File _imageFile;
  FirebaseStorage storage = FirebaseStorage.instance;
  ProgressDialog progressDialog;
  List _outputs;
  double _beConfidence = 0;
  double _maConfidence = 0;

  Future pickImage() async {
    try {
      final pickedImage =
          await ImagePicker().getImage(source: ImageSource.gallery);
      setState(() {
        _imageFile = File(pickedImage.path);
        print(_imageFile.path);
      });
    } catch (e) {
      print(e.toString());
    }
  }

  loadTfliteModel() async {
    var res = await Tflite.loadModel(
        model: 'assets/model_tflite/model_unquant.tflite',
        labels: 'assets/model_tflite/labels.txt');

    print('\n Load Model Result: $res');
  }

  @override
  void initState() {
    super.initState();
    loadTfliteModel();
  }

  applyModelOnImage() async {
    var result = await Tflite.runModelOnImage(
      path: _imageFile.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5);
    print(result);
    setState(() {
      // _beConfidence = res[0]["confidence"] * 100;
      // _maConfidence = res[1]["confidence"] * 100;
      _outputs = result;
    });
    // Directory appDocDir = await getTemporaryDirectory();
    // File downloadToFile = File('${appDocDir.path}/$title.jpg');
    // try {
    //   await storage.ref('images/$id/$title').writeToFile(downloadToFile);
    //   print(downloadToFile.path);
    //   var res = await Tflite.runModelOnImage(path: _imageFile.path);
    //   setState(() {
    //     _beConfidence = res[0]["confidence"] * 100;
    //     _maConfidence = res[1]["confidence"] * 100;
    //     _result = _beConfidence > _maConfidence ? _beConfidence : _maConfidence;
    //   });
    //   Tflite.close();
    //   downloadToFile.delete();
    //   print('Predict Result: $res');
    // } catch (_) {
    //   print(_.toString());
    // }
  }

  bool get isEditing => widget.isEditing;
  @override
  Widget build(BuildContext context) {
    progressDialog = ProgressDialog(context, type: ProgressDialogType.Normal);
    progressDialog.style(message: 'Uploading...');

    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: orange,
        elevation: 0.0,
        bottomOpacity: 0.0,
      ),
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50.0),
                    bottomRight: Radius.circular(50.0)),
                gradient: LinearGradient(
                    colors: [orange, orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Text(
              'Choose Your Image',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  SizedBox(
                    height: 80,
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 10.0, bottom: 30),
                    child: !isEditing
                        ? ClipRRect(
                            child: _imageFile != null
                                ? Image.file(_imageFile)
                                : FlatButton(
                                    onPressed: pickImage,
                                    child: Icon(Icons.add_a_photo)))
                        : Image.network(widget.photo.photoUrl),
                    width: 200,
                    height: 200,
                  ),
                  Visibility(
                      child: FlatButton(
                        onPressed: pickImage,
                        child: Text('Change Image'),
                      ),
                      visible: _imageFile != null ? true : false),
                  TextFormField(
                    decoration: InputDecoration(hintText: "Title"),
                    initialValue: isEditing ? widget.photo.title : '',
                    autofocus: !isEditing,
                    validator: (val) {
                      return val.trim().isEmpty
                          ? 'Please enter some text'
                          : null;
                    },
                    onSaved: (value) => _title = value,
                  ),
                  // TextFormField(
                  //   decoration: InputDecoration(hintText: "Description"),
                  //   initialValue: isEditing ? widget.photo.descript : '',
                  //   onSaved: (value) => _descript = value,
                  // ),
                  Visibility(
                    child: Column(
                      children: _outputs != null
                          ? _outputs.map((result) {
                          return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: 
                              [
                                new CircularPercentIndicator(
                                  radius: 180.0,
                                  animation: true,
                                  animationDuration: 1200,
                                  lineWidth: 15.0,
                                  percent: result['confidence'] ,
                                  center: 
                                  new Text(
                                    "${result["label"]}",
                                    style: new TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0),
                                  ),
                                  
                                  circularStrokeCap: CircularStrokeCap.round,
                                  backgroundColor: Colors.green[600],
                                  progressColor: Colors.red[700],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    new LinearPercentIndicator(
                                      width: 60.0,
                                      lineHeight: 8.0,
                                      percent: 1.0 - result['confidence'] ,
                                      trailing: const Text('Percent Wrong'),
                                      progressColor: Colors.green[600],
                                    ),
                                    new LinearPercentIndicator(
                                      width: 60.0,
                                      lineHeight: 8.0,
                                      percent: result['confidence'],
                                      trailing: const Text('Percent Right'),
                                      progressColor: Colors.red[700],
                                    ),
                                  ],
                                )
                              ],
                            );
                          }).toList() 
                          : [
                        RaisedButton(
                          color: Colors.orange[700],
                          onPressed: () {
                            if (_imageFile != null) {
                              applyModelOnImage();
                            }
                          },
                          child: Text(
                            'Predict',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    visible: true,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: isEditing ? 'Save changes' : 'Add Photo',
        backgroundColor: orange,
        child: Icon(isEditing ? Icons.check : Icons.add),
        onPressed: () async {
          if (_formKey.currentState.validate() && _imageFile != null) {
            _formKey.currentState.save();
            String path = 'images/${user.id}/$_title';
            await storage.ref(path).putFile(_imageFile).then((e) {
              print('Debug firestorage: ' + e.toString());
            }).catchError((e) {
              print('Debug firestorage: ' + e.toString());
              return;
            });
            String downloadURL =
                await storage.ref(path).getDownloadURL().catchError((e) {
              return;
            });
            widget.onSave(_title, _descript, user.id, downloadURL,
                _beConfidence, _maConfidence);

            // widget.onSave(_title, _descript, user.id, widget.photo.photoUrl,
            //     _beConfidence, _maConfidence);

            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
