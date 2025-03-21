import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';

void main() {
  runApp(ARJoystickApp());
}

class ARJoystickApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Joystick App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ARHomePage(),
    );
  }
}

class ARHomePage extends StatefulWidget {
  @override
  _ARHomePageState createState() => _ARHomePageState();
}

class _ARHomePageState extends State<ARHomePage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARNode? placedObject;

  // Joystick values that represent movement offsets.
  double joystickX = 0.0;
  double joystickY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AR Joystick App')),
      body: Stack(
        children: [
          // AR view that detects horizontal planes.
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          // Joystick overlay at the bottom left.
          Positioned(
            left: 20,
            bottom: 20,
            child: Joystick(
              onChanged: (offset) {
                setState(() {
                  joystickX = offset.dx;
                  joystickY = offset.dy;
                });
                movePlacedObject();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Callback when the AR view is created.
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    this.arSessionManager = sessionManager;
    this.arObjectManager = objectManager;

    // When a plane is tapped, try to place an object.
    arSessionManager!.onPlaneOrPointTapped = onPlaneTapped;

    arSessionManager!.init();
    arObjectManager!.init();
  }

  // Places an object at the tapped location.
  Future<void> onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) return;
    // Use the first hit result.
    var hit = hitTestResults.first;
    if (placedObject == null) {
      var newNode = ARNode(
        type: NodeType.webGLB,
        uri: "assets/model.glb",
        scale: vector.Vector3(0.2, 0.2, 0.2),
        position: hit.worldTransform.translation,
        rotation: hit.worldTransform.rotation,
      );
      bool didAdd = await arObjectManager!.addNode(newNode);
      if (didAdd) {
        placedObject = newNode;
      }
    }
  }

  // Updates the object position based on joystick input.
  void movePlacedObject() {
    if (placedObject == null) return;
    // Calculate a new position increment based on joystick offset.
    // Here we use a small multiplier to adjust sensitivity.
    final delta = vector.Vector3(joystickX * 0.01, 0.0, joystickY * 0.01);
    placedObject!.position += delta;
    arObjectManager!.updateNode(placedObject!);
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}

// A simple virtual joystick widget.
typedef JoystickCallback = void Function(Offset offset);

class Joystick extends StatefulWidget {
  final JoystickCallback onChanged;

  Joystick({required this.onChanged});

  @override
  _JoystickState createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _dragOffset = Offset.zero;
  Offset _startDragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _startDragOffset = details.localPosition;
      },
      onPanUpdate: (details) {
        setState(() {
          _dragOffset = details.localPosition - _startDragOffset;
        });
        widget.onChanged(_dragOffset);
      },
      onPanEnd: (details) {
        setState(() {
          _dragOffset = Offset.zero;
        });
        widget.onChanged(_dragOffset);
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
