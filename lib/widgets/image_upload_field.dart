import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ImageUploadField extends StatefulWidget {
  const ImageUploadField(
      {super.key, required this.onImagePicked, this.label = "Upload Image"});
  final Function(XFile file) onImagePicked;
  final String label;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final ImagePicker _picker = ImagePicker();
  bool _picked = false;
  XFile? _image;

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: !_picked,
        replacement: InkWell(
          onTap: () {
            setState(() {
              _picked = false;
              _image = null;
            });
          },
          child: Card(
              child: _image != null
                  ? FutureBuilder<Uint8List>(
                      future: _image?.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: LinearProgressIndicator());
                        }
                        return Image.memory(snapshot.requireData);
                      })
                  : SizedBox.shrink()),
        ),
        child: ShadButton.outline(
          leading: Icon(Icons.upload_file),
          width: double.infinity,
          onPressed: () async {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 50,
            );
            if (image != null) {
              widget.onImagePicked(image);
              setState(() {
                _picked = true;
                _image = image;
              });
            }
          },
          child: Text(widget.label),
        ));
  }
}
