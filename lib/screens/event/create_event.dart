import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youroccasions/controllers/event_category_controller.dart';
import 'package:youroccasions/models/category.dart';
import 'package:youroccasions/models/data.dart';
import 'package:youroccasions/models/event.dart';
import 'package:youroccasions/controllers/event_controller.dart';
import 'package:youroccasions/utilities/places.dart';
import 'package:youroccasions/utilities/secret.dart';
import 'package:youroccasions/utilities/cloudinary.dart';
import 'package:youroccasions/screens/event/event_detail.dart';

final EventController _eventController = EventController();

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreen createState() => _CreateEventScreen();
}

class _CreateEventScreen extends State<CreateEventScreen> {
  GlobalKey<FormState> formKey;
  GlobalKey<ScaffoldState> _scaffoldKey;
  ScrollController _scrollController;
  FocusNode _eventTitleNode;
  FocusNode _descriptionNode;
  FocusNode _locationNameNode;
  FocusNode _addressNode;

  TextEditingController nameController;
  TextEditingController descriptionController;
  TextEditingController categoryController;
  TextEditingController locationNameController;
  TextEditingController addressController;

  GoogleMapController mapController;
  PlaceData _placeData;

  DateTime startDate;
  TimeOfDay startTime;
  DateTime endDate;
  TimeOfDay endTime;

  File _image;
  bool _showMap = false;
  bool _noImageError;

  bool _isCreating;

  bool _invalidStart;
  bool _invalidEnd;
  bool _invalidCategory;

  List<PopupMenuItem<ImageSource>> _selectImageOptions;

  Map<String, ValueNotifier<bool>> _selectCategoryValue;
  List<PopupMenuItem> _selectCategoryOptions;
  List<String> _selectCategoryName;

  double _contentWidth = 0.8;

  @override
  initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _scrollController = ScrollController();
    _eventTitleNode = FocusNode();
    _descriptionNode = FocusNode();
    _locationNameNode = FocusNode();
    _addressNode = FocusNode();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    locationNameController = TextEditingController();
    addressController = TextEditingController();

    _isCreating = false;
    _invalidStart = false;
    _invalidEnd = false;
    _invalidCategory = false;
    _noImageError = false;

    _selectImageOptions = [
      PopupMenuItem<ImageSource>(
        value: ImageSource.gallery,
        child: Text("Choose image from gallery"),
      ),
      PopupMenuItem<ImageSource>(
        value: ImageSource.camera,
        child: Text("Take photo from camera"),
      ),
    ];

    _selectCategoryName = [];
    _selectCategoryOptions = [];
    _selectCategoryValue = Map<String, ValueNotifier<bool>>();

    // Generate check box list tile
    _generateCategoryContent();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    addressController.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
    mapController.clearMarkers();
    mapController.addMarker(MarkerOptions(
        position: LatLng(_placeData.latitude, _placeData.longitude)));
  }

  void _generateCategoryContent() {
    Categories.all.forEach((category) {
      _selectCategoryValue[category.name] = ValueNotifier<bool>(false);

      _selectCategoryOptions.add(PopupMenuItem(
        value: category.name,
        child: AnimatedBuilder(
          animation: _selectCategoryValue[category.name],
          builder: (context, child) {
            return CheckboxListTile(
              title: Text(category.name),
              value: _selectCategoryValue[category.name].value,
              onChanged: (value) {
                print("value changed to $value");
                _selectCategoryValue[category.name].value = value;
                setState(() {
                  if (value) {
                    _selectCategoryName.add(category.name);
                  } else {
                    _selectCategoryName.remove(category.name);
                  }
                });
              },
            );
          },
        ),
      ));
    });
  }

  String _getCategoryInput() {
    String result = "";
    _selectCategoryName.forEach((category) {
      result += category;
      if (_selectCategoryName.indexOf(category) !=
          _selectCategoryName.length - 1) {
        result += ", ";
      }
    });
    return result;
  }

  void _getImage(ImageSource source) {
    ImagePicker.pickImage(source: source).then((image) {
      if (image != null) {
        if (this.mounted) {
          setState(() {
            _image = image;
          });
        }
      }
    });
  }

  bool _validateDateTime() {
    _invalidStart = false;
    _invalidEnd = false;

    if (startDate == null || startTime == null) {
      _invalidStart = true;
      print("false here 4");
      return false;
    }

    // if (endDate == null && endTime == null) {
    //   _invalidEnd = true;
    //   print("false here 3");
    //   return false;
    // }
    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) > 0) {
      _invalidStart = true;
      print("false here");
      return false;
    }
    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) == 0) {
      if (endTime != null &&
          startTime != null &&
          endTime.hour - startTime.hour < 0) {
        _invalidEnd = true;
        print("false here 2");
        return false;
      }
    }

    return true;
  }

  bool _autoValidateDateTime() {
    _invalidStart = false;
    _invalidEnd = false;

    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) > 0) {
      _invalidStart = true;
      print("false here");
      return false;
    }
    if (startDate != null &&
        endDate != null &&
        startDate.compareTo(endDate) == 0) {
      if (endTime != null &&
          startTime != null &&
          endTime.hour - startTime.hour < 0) {
        _invalidEnd = true;
        print("false here 2");
        return false;
      }
    }

    return true;
  }

  String _getDateFormatted(DateTime date) {
    if (date == null) {
      return "MM/DD/YYYY";
    }
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}/${date.year}";
  }

  String _getTimeFormatted(TimeOfDay time) {
    if (time == null) {
      return "HH:MM AM/PM";
    }
    String hour = (time.hour > 12)
        ? (time.hour - 12).toString().padLeft(2, "0")
        : time.hour.toString().padLeft(2, "0");
    String period = (time.hour >= 12) ? 'PM' : 'AM';
    return "$hour:${time.minute.toString().padLeft(2, "0")} $period";
  }

  Future<void> popUpSelectStartDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: startDate == null ? DateTime.now() : startDate,
        firstDate: DateTime.now().subtract(Duration(days: 1)),
        lastDate: DateTime(DateTime.now().year + 2));

    setState(() {
      startDate = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectStartTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
        context: context,
        initialTime: startTime == null ? TimeOfDay.now() : startTime);

    setState(() {
      startTime = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectEndDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: endDate == null ? DateTime.now() : endDate,
        firstDate: DateTime.now().subtract(Duration(days: 1)),
        lastDate: DateTime(DateTime.now().year + 2));

    setState(() {
      endDate = picked;
      _autoValidateDateTime();
    });
  }

  Future<void> selectEndTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
        context: context,
        initialTime: endTime == null ? TimeOfDay.now() : endTime);

    setState(() {
      endTime = picked;
      _autoValidateDateTime();
    });
  }

  void _submit() async {
    String message = "";

    if (_image == null) {
      message += "Please add an image for the event\n";
    }

    if (_selectCategoryName.length == 0) {
      message += "Please select category for the event";
    }

    if (message.isNotEmpty) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(message),
      ));
    }

    print("before validate");
    bool validateTime = _validateDateTime();
    bool validateForm = formKey.currentState.validate();
    // formKey.currentState.validate();
    if (validateForm && validateTime && _selectCategoryName.length != 0) {
      print("inside validate");
      formKey.currentState.save();

      bool result = await create();
      print(result);

      // if(result) {
      //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EventDetailScreen()));
      // }
    } else {
      print("validate fail");
    }

    // setState(() { });
  }

  Future<bool> create() async {
    String url;
    Cloudinary cl = Cloudinary(CLOUDINARY_API_KEY, API_SECRET);

    print("DEBUG: creating event");
    if (!_isCreating) {
      _isCreating = true;

      startDate = DateTime(startDate.year, startDate.month, startDate.day,
          startTime.hour, startTime.minute);

      if (endDate != null) {
        endDate = DateTime(endDate.year, endDate.month, endDate.day,
            endTime.hour, endTime.minute);
      }

      String name = nameController.text;
      String description = descriptionController.text;
      String hostId = Dataset.currentUser.value.id;

      Event newEvent = Event(
        hostId: hostId,
        name: name,
        description: description,
        startTime: startDate,
        endTime: endDate,
        address: _placeData?.address,
        locationName: _placeData?.name,
        placeId: _placeData?.placeId,
      );

      print("DEBUG new event is : $newEvent");
      Event createdEvent = await _eventController.insert(newEvent);

      EventCategoryController ec = EventCategoryController();
      await ec.bulkInsert(_selectCategoryName, createdEvent.id);

      print("DEBUG name is : ${newEvent.name}");
      print("Your event is created successfully!");
      // print("Create failed");

      // Event createdEvent =
      //     (await _eventController.getEvents(hostId: hostId, name: name))[0];
      // print("DEBUG: $createdEvent");

      url = await cl.upload(
          file: toDataURL(file: _image),
          preset: Presets.eventCover,
          path: "${createdEvent.id}/cover");
      print("DEBUG url: $url");
      await _eventController.update(createdEvent.id, picture: url);
      createdEvent.picture = url;

      _isCreating = false;

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => EventDetailScreen(createdEvent)));

      return true;
    }
    _isCreating = false;
    return false;
  }

  Widget createButton() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Material(
          borderRadius: BorderRadius.circular(30.0),
          shadowColor: Colors.lightBlueAccent.shade100,
          elevation: 5.0,
          child: MaterialButton(
            minWidth: 200.0,
            height: 42.0,
            onPressed: _submit,
            // color: Colors.lightBlueAccent,
            child: Text('Create', style: TextStyle(color: Colors.black)),
          ),
        ));
  }

  Widget _buildSelectImageSection() {
    var screen = MediaQuery.of(context).size;
    Widget result;

    if (_image == null) {
      result = Container(
        color: Colors.white,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // MaterialButton(
              //   onPressed: () => _getImage(ImageSource.camera),
              //   child: Text("Take picture from camera"),
              // ),
              // MaterialButton(
              //   onPressed: () => _getImage(ImageSource.gallery),
              //   child: Text("Get picture from gallery"),
              // ),
              PopupMenuButton<ImageSource>(
                onSelected: (item) {
                  print("item selected");
                  print(item.toString());
                  _getImage(item);
                },
                child: Icon(
                  Icons.add_photo_alternate,
                  size: screen.width * 0.4,
                  semanticLabel: "Add image",
                  color: Colors.deepPurpleAccent,
                ),
                itemBuilder: (context) => _selectImageOptions,
              ),
              // Text("Add image"),
            ]),
      );
    } else {
      result = Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: <Widget>[
          SizedBox(
              width: screen.width,
              child: Image.file(
                _image,
                fit: BoxFit.fitWidth,
              )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.all(0),
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: SizedBox(
                  width: 30,
                  height: 30,
                  child: PopupMenuButton<ImageSource>(
                    onSelected: (item) {
                      print("item selected");
                      print(item.toString());
                      _getImage(item);
                    },
                    child: Icon(
                      Icons.edit,
                      semanticLabel: "Change image",
                      color: Colors.black,
                    ),
                    itemBuilder: (context) => _selectImageOptions,
                  )),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: screen.height / 3,
      width: screen.width,
      child: result,
    );
  }

  Widget _buildEventTitleInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
        width: screen.width * _contentWidth,
        child: TextFormField(
          focusNode: _eventTitleNode,
          controller: nameController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.text,
          validator: (name) {
            print("name is $name");
            return (nameController.text.length < 6 ||
                    nameController.text.isEmpty)
                ? "Event title has at least 6 characters"
                : null;
          },
          autofocus: false,
          onFieldSubmitted: (term) {
            _eventTitleNode.unfocus();
            FocusScope.of(context).requestFocus(_descriptionNode);
          },
          decoration: InputDecoration(
              labelText: "Event Title",
              labelStyle: TextStyle(fontWeight: FontWeight.bold)),
        ));
  }

  Widget _buildDescriptionInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
        width: screen.width * _contentWidth,
        child: TextFormField(
          focusNode: _descriptionNode,
          controller: descriptionController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.text,
          validator: (name) => (name.length < 6)
              ? "Please provide a description with at least 6 characters"
              : null,
          autofocus: false,
          maxLines: null,

          /// Extend as type
          onFieldSubmitted: (term) {
            _descriptionNode.unfocus();
          },
          maxLengthEnforced: false,
          decoration: InputDecoration(
              labelText: "Description",
              labelStyle: TextStyle(fontWeight: FontWeight.bold)),
        ));
  }

  Widget _buildStartDateInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: _invalidStart ? Colors.red : Colors.black54,
                        width: 1))),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Start Date",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () {
                          popUpSelectStartDate(context);
                        },
                        child: Text(
                          _getDateFormatted(startDate),
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 14,
                              color: _invalidStart
                                  ? Colors.red
                                  : startDate == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                              fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
                Expanded(
                  child: SizedBox(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Time",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () {
                          selectStartTime(context);
                        },
                        child: Text(
                          _getTimeFormatted(startTime),
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 14,
                              color: _invalidStart
                                  ? Colors.red
                                  : startTime == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                              fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: _invalidEnd ? Colors.red : Colors.black54,
                        width: 1))),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("End Date",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () {
                          selectEndDate(context);
                        },
                        child: Text(
                          _getDateFormatted(endDate),
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 14,
                              color: _invalidEnd
                                  ? Colors.red
                                  : endDate == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                              fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
                Expanded(
                  child: SizedBox(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text("Time",
                            style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () {
                          selectEndTime(context);
                        },
                        child: Text(
                          _getTimeFormatted(endTime),
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 14,
                              color: _invalidEnd
                                  ? Colors.red
                                  : endTime == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                              fontFamily: "Monaco"),
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      width: screen.width * _contentWidth,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
          color: Colors.black54,
          width: 1,
        ))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text("Category",
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.bold)),
            ),
            PopupMenuButton(
              onSelected: (item) {},
              child: Text(
                _selectCategoryName.isEmpty
                    ? "Select the category for this event"
                    : _getCategoryInput(),
                style: TextStyle(
                    fontSize: 15,
                    color: _selectCategoryName.isEmpty
                        ? Colors.black45
                        : Colors.black),
              ),
              itemBuilder: (context) => _selectCategoryOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationNameInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
        width: screen.width * _contentWidth,
        child: TextFormField(
          focusNode: _locationNameNode,
          controller: locationNameController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.text,
          validator: (name) => (name.length < 3)
              ? "Please provide a name with at least 3 characters"
              : null,
          autofocus: false,
          maxLines: null,

          /// Extend as type
          onFieldSubmitted: (term) async {
            _locationNameNode.unfocus();
            if (term.isNotEmpty) {
              PlaceSearch ps = PlaceSearch.instance;
              _placeData = await ps.search(term);
              print(_placeData?.address);
              if (_placeData != null) {
                addressController.text = _placeData.address;
                locationNameController.text = _placeData.name;

                if (mapController == null) {
                  setState(() {
                    _showMap = true;
                  });
                } else if (mapController != null) {
                  mapController.clearMarkers();
                  mapController.addMarker(MarkerOptions(
                      position:
                          LatLng(_placeData.latitude, _placeData.longitude)));
                  mapController.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target:
                              LatLng(_placeData.latitude, _placeData.longitude),
                          zoom: 17)));
                }
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  curve: Curves.easeIn,
                  duration: const Duration(milliseconds: 1000),
                );
              }
            }
          },
          maxLengthEnforced: false,
          decoration: InputDecoration(
              labelText: "Location Name",
              labelStyle: TextStyle(fontWeight: FontWeight.bold)),
        ));
  }

  Widget _buildAddressInput() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
        width: screen.width * _contentWidth,
        child: TextFormField(
          focusNode: _addressNode,
          controller: addressController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.text,
          validator: (name) => (name.length < 3)
              ? "Please provide an address with at least 3 characters"
              : null,
          autofocus: false,
          maxLines: null,

          /// Extend as type
          onFieldSubmitted: (term) async {
            _addressNode.unfocus();
            if (term.length >= 3) {
              PlaceSearch ps = PlaceSearch.instance;
              _placeData = await ps.search(term);
              print(_placeData.address);
              if (_placeData != null) {
                addressController.text = _placeData.address;
                locationNameController.text = _placeData.name;

                if (mapController == null) {
                  setState(() {
                    _showMap = true;
                  });
                } else if (mapController != null) {
                  mapController.clearMarkers();
                  mapController.addMarker(MarkerOptions(
                      position:
                          LatLng(_placeData.latitude, _placeData.longitude)));
                  mapController.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target:
                              LatLng(_placeData.latitude, _placeData.longitude),
                          zoom: 17)));
                }
              }
            }
          },
          maxLengthEnforced: false,
          decoration: InputDecoration(
              labelText: "Address",
              labelStyle: TextStyle(fontWeight: FontWeight.bold)),
        ));
  }

  Widget _buildGoogleMap() {
    final screen = MediaQuery.of(context).size;

    return SizedBox(
      height: 300,
      width: screen.width * 0.8,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        options: GoogleMapOptions(
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: false,
            cameraPosition: CameraPosition(
                target: LatLng(_placeData.latitude, _placeData.longitude),
                zoom: 17)),
      ),
    );
  }

  List<Widget> _buildListViewContent() {
    List<Widget> result = List<Widget>();

    result.add(
      _buildSelectImageSection(),
    );

    if (_noImageError) {
      result.add(Container(
        child: Text(
          "Please add an image for the event!",
          style: TextStyle(color: Colors.red),
        ),
      ));
    }

    result.addAll([
      _buildEventTitleInput(),
      _buildDescriptionInput(),
      _buildStartDateInput(),
      _buildCategoryInput(),
      _buildLocationNameInput(),
      _buildAddressInput(),
      SizedBox(
        height: 30,
      )
    ]);

    if (_showMap &&
        _placeData != null &&
        _placeData.latitude != null &&
        _placeData.longitude != null) {
      result.addAll([
        Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _buildGoogleMap())
      ]);
    }

    if (_invalidCategory) {
      result.add(Container(
        child: Text(
          "Please add at least 1 category for the event!",
          style: TextStyle(color: Colors.red),
        ),
      ));
    }

    // result.add(createButton());

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            "CREATE EVENT",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: _submit,
              child: Text(
                "SAVE",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          ],
          // backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[
                    Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildListViewContent(),
                        )),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
