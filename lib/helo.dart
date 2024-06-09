// Fill in the app ID of your project, generated from Agora Console
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'components/remote_video_views_widget.dart';
import 'ids.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({super.key});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  late bool _localUserJoined = false;
  late int? _remoteUid = 0;
  late final RtcEngineEx _engine;
  bool _isScreenShared = false;

  Future<void> initAgora() async {
    // Create RtcEngine instance
    await [Permission.microphone, Permission.camera].request();
    _engine = await createAgoraRtcEngineEx();

// Initialize RtcEngine and set the channel profile to communication
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    // Enable the video module
    await _engine.enableVideo();
// Enable local video preview
    await _engine.startPreview();

    // Add an event handler
    // Add an event handler
    await _engine
        .setScreenCaptureScenario(ScreenScenarioType.screenScenarioVideo);
    _engine.registerEventHandler(
      RtcEngineEventHandler(
          // Occurs when the local user joins the channel successfully
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("local user ${connection.localUid} joined");
        setState(() {
          _localUserJoined = true;
        });
      },
          // Occurs when a remote user join the channel
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("remote user $remoteUid joined");
        setState(() {
          _remoteUid = remoteUid;
        });
      },
          // Occurs when a remote user leaves the channel
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
        debugPrint("remote user $remoteUid left channel");
        setState(() {
          _remoteUid = null;
        });
      }, onLocalVideoStateChanged: (VideoSourceType source,
              LocalVideoStreamState state, LocalVideoStreamReason error) {
        // logSink.log(
        //     '[onLocalVideoStateChanged] source: $source, state: $state, error: $error');
        if (!(source == VideoSourceType.videoSourceScreen ||
            source == VideoSourceType.videoSourceScreenPrimary)) {
          return;
        }

        switch (state) {
          case LocalVideoStreamState.localVideoStreamStateCapturing:
          case LocalVideoStreamState.localVideoStreamStateEncoding:
            setState(() {
              _isScreenShared = true;
            });
            break;
          case LocalVideoStreamState.localVideoStreamStateStopped:
          case LocalVideoStreamState.localVideoStreamStateFailed:
            setState(() {
              _isScreenShared = false;
            });
            break;
          default:
            break;
        }
      }),
    );
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    _joinChannel();
    setState(() {});
  }

  void _joinChannel() async {
    final localUid = int.tryParse("5");
    if (localUid != null) {
      await _engine.joinChannelEx(
          token: token,
          connection: RtcConnection(channelId: channel, localUid: localUid),
          options: const ChannelMediaOptions(
            autoSubscribeVideo: true,
            autoSubscribeAudio: true,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ));
    }

    final shareShareUid = int.tryParse("3");
    if (shareShareUid != null) {
      await _engine.joinChannelEx(
          token: token,
          connection:
              RtcConnection(channelId: channel, localUid: shareShareUid),
          options: const ChannelMediaOptions(
            autoSubscribeVideo: false,
            autoSubscribeAudio: false,
            publishScreenTrack: true,
            publishSecondaryScreenTrack: true,
            publishCameraTrack: false,
            publishMicrophoneTrack: false,
            publishScreenCaptureAudio: true,
            publishScreenCaptureVideo: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ));
    }
  }

  // Widget to display remote video
  Widget _remoteVideo() {
    if (_remoteUid != null && _remoteUid != 0) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel(); // Leave the channel
    await _engine.release(); // Release resources
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initAgora();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Center(
                  child: _remoteVideo(),
                ),
              ),
              SizedBox(
                width: 100,
                height: 150,
                child: Center(
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: RemoteVideoViewsWidget(
                  // key: keepRemoteVideoViewsKey,
                  rtcEngine: _engine,
                  channelId: channel,
                  connectionUid: int.tryParse("4"),
                ),
              ),
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _isScreenShared
                      ? AgoraVideoView(
                          controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(
                            uid: 0,
                            sourceType: VideoSourceType.videoSourceScreen,
                          ),
                        ))
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Screen Sharing View'),
                          ),
                        ),
                ),
              ),
            ],
          ),
          Center(
              child: ElevatedButton(
                  onPressed: sharedScreen, child: Text("njwnrgoier")))
        ],
      ),
    );
  }

  Future<void> sharedScreen() async {
    try {
      if (_isScreenShared) return;
      await _engine.startScreenCapture(const ScreenCaptureParameters2(
          captureAudio: true,
          captureVideo: true,
          videoParams: ScreenVideoParameters(bitrate: 400, frameRate: 30)));
      await _engine.enableInstantMediaRendering();
      // await _engine.updateScreenCapture(const ScreenCaptureParameters2(
      //     captureAudio: true,
      //     captureVideo: true,
      //     videoParams: ScreenVideoParameters(bitrate: 400, frameRate: 30)));
      await _engine.startPreview(sourceType: VideoSourceType.videoSourceScreen);
      _updateScreenShareChannelMediaOptions();
      // await _engine.updateChannelMediaOptions(
      //     ChannelMediaOptions(publishScreenCaptureVideo: true));

      print("njkgnekjgne");
      setState(() {});
    } catch (e, s) {
      print(s);
      print(e);
      print("gnekjabjba");
    }
  }

  Future<void> _updateScreenShareChannelMediaOptions() async {
    final shareShareUid = int.tryParse("3");
    if (shareShareUid == null) return;
    await _engine.updateChannelMediaOptionsEx(
      options: const ChannelMediaOptions(
        publishScreenTrack: true,
        publishSecondaryScreenTrack: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        publishScreenCaptureAudio: true,
        publishScreenCaptureVideo: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      connection: RtcConnection(channelId: channel, localUid: shareShareUid),
    );
  }
}

// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:flutter/material.dart';
//
//
//
// class VideoCall extends StatefulWidget {
//   const VideoCall({super.key});
//
//   @override
//   State<VideoCall> createState() => _VideoCallState();
// }
//
// class _VideoCallState extends State<VideoCall> {
//   final AgoraClient client = AgoraClient(
//     agoraConnectionData: AgoraConnectionData(
//       appId: appId,
//       channelName: "test",
//       tempToken: token,
//     ),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }
//
//   void initAgora() async {
//     await client.initialize();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Agora VideoUIKit'),
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: Stack(
//             children: [
//               AgoraVideoViewer(
//                 client: client,
//                 layoutType: Layout.floating,
//                 enableHostControls: true, // Add this to enable host controls
//               ),
//               AgoraVideoButtons(
//                 client: client,
//                 addScreenSharing: true, // Add this to enable screen sharing
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
