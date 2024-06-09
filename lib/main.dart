// import 'package:agora/helo.dart';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const VideoCall(),
//     );
//   }
// }
import 'dart:io';

import 'package:agora/helo.dart';
import 'package:agora/ids.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'components/android_foreground_service_widget.dart';
import 'components/config_override.dart';
import 'components/log_sink.dart';
import 'config/agora.config.dart' as config;
import 'examples/advanced/index.dart';
import 'examples/basic/index.dart';

void main() => runApp(const MyApp());

/// This widget is the root of your application.
class MyApp extends StatefulWidget {
  /// Construct the [MyApp]
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _data = [...basic, ...advanced];

  bool _showPerformanceOverlay = false;

  bool _isWebSetup = false;

  bool _isConfigInvalid() {
    return config.appId == appId ||
        config.token == token ||
        config.channelId == channel;
  }

  @override
  void initState() {
    super.initState();

    _isWebSetup = !kIsWeb;

    _requestPermissionIfNeed();
  }

  Future<void> _requestPermissionIfNeed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        showPerformanceOverlay: _showPerformanceOverlay,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: VideoCall()
        // Scaffold(
        //   appBar: AppBar(
        //     title: const Text('APIExample'),
        //     actions: [
        //       ToggleButtons(
        //         color: Colors.grey[300],
        //         selectedColor: Colors.white,
        //         renderBorder: false,
        //         children: const [
        //           Icon(
        //             Icons.data_thresholding_outlined,
        //           )
        //         ],
        //         isSelected: [_showPerformanceOverlay],
        //         onPressed: (index) {
        //           setState(() {
        //             _showPerformanceOverlay = !_showPerformanceOverlay;
        //           });
        //         },
        //       )
        //     ],
        //   ),
        //   body: _body(),
        // ),
        );
  }

  Widget _body() {
    if (!_isWebSetup) {
      return _WebSetupPage(setupCompleted: () {
        setState(() {
          _isWebSetup = true;
        });
      });
    }

    if (_isConfigInvalid()) {
      return const InvalidConfigWidget();
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        return _data[index]['widget'] == null
            ? Ink(
                color: Colors.grey,
                child: ListTile(
                  title: Text(_data[index]['name'] as String,
                      style:
                          const TextStyle(fontSize: 24, color: Colors.white)),
                ),
              )
            : ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    Widget widget = Scaffold(
                      appBar: AppBar(
                        title: Text(_data[index]['name'] as String),
                        // ignore: prefer_const_literals_to_create_immutables
                        actions: [const LogActionWidget()],
                      ),
                      body: _data[index]['widget'] as Widget?,
                    );

                    if (!kIsWeb && Platform.isAndroid) {
                      widget = AndroidForegroundServiceWidget(child: widget);
                    }

                    return widget;
                  }));
                },
                title: Text(
                  _data[index]['name'] as String,
                  style: const TextStyle(fontSize: 24, color: Colors.black),
                ),
              );
      },
    );
  }
}

class _WebSetupPage extends StatefulWidget {
  const _WebSetupPage({Key? key, required this.setupCompleted})
      : super(key: key);

  final VoidCallback setupCompleted;

  @override
  State<_WebSetupPage> createState() => _WebSetupPageState();
}

class _WebSetupPageState extends State<_WebSetupPage> {
  late TextEditingController _appIdController;
  late TextEditingController _channelIdController;
  late TextEditingController _tokenController;

  bool _isValid = false;

  late final ExampleConfigOverride _configOverride;

  @override
  void initState() {
    super.initState();

    _configOverride = ExampleConfigOverride();

    _appIdController = TextEditingController(text: _configOverride.getAppId());
    _channelIdController =
        TextEditingController(text: _configOverride.getChannelId());
    _tokenController = TextEditingController(text: _configOverride.getToken());

    _appIdController.addListener(_validCheck);
    _channelIdController.addListener(_validCheck);
  }

  void _validCheck() {
    _isValid = _appIdController.text.isNotEmpty &&
        _channelIdController.text.isNotEmpty;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Column(
          children: [
            const Text('Input Your APP ID'),
            TextField(
              controller: _appIdController,
              decoration: const InputDecoration(
                labelText: 'APP ID can not be empty',
                // errorText: _appIdValidate ? "Value Can't Be Empty" : null,
              ),
            ),
            const Text('Input Your Channel ID'),
            TextField(
              controller: _channelIdController,
              decoration: const InputDecoration(
                labelText: 'Channel ID can not be empty',
                // errorText: _appIdValidate ? "Value Can't Be Empty" : null,
              ),
            ),
            const Text('Input Your Token (Optional)'),
            TextField(
              controller: _tokenController,
            ),
            ElevatedButton(
              onPressed: !_isValid
                  ? null
                  : () {
                      _configOverride.set(keyAppId, _appIdController.text);
                      _configOverride.set(
                          keyChannelId, _channelIdController.text);
                      _configOverride.set(keyToken, _tokenController.text);

                      widget.setupCompleted();
                    },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _channelIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}

/// This widget is used to indicate the configuration is invalid
class InvalidConfigWidget extends StatelessWidget {
  /// Construct the [InvalidConfigWidget]
  const InvalidConfigWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: const Text(
          'Make sure you set the correct appId, token, channelId, etc.. in the lib/config/agora.config.dart file.'),
    );
  }
}
