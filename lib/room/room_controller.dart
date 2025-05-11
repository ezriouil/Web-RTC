import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:web_rtc/video_call/video_call_entity.dart';

class RoomController extends GetxController{

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };
  late RTCPeerConnection? _peerConnection;
  late MediaStream? _localStream;
  late MediaStream? _remoteStream;
  late final Rx<RTCVideoRenderer?> localRenderer;
  late final Rx<RTCVideoRenderer?> remoteRenderer;
  late final RxBool isInitializing;
  String currentRoomId = "";
  String uid = "";
  GetStorage getStorage = GetStorage();

  @override
  void onInit() {
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    localRenderer = RTCVideoRenderer().obs;
    remoteRenderer = RTCVideoRenderer().obs;
    isInitializing = true.obs;
    super.onInit();
    _init();
  }

  void _init() async {
    uid = getStorage.read('UID');
    await localRenderer.value!.initialize();
    await remoteRenderer.value!.initialize();
    await _openUserMedia();
    isInitializing.value = false;
  }

  Future<void> _openUserMedia() async {
    try {
      final MediaStream stream = await mediaDevices.getUserMedia({'video': true, 'audio': true});
      localRenderer.value!.srcObject = stream;
      _localStream = stream;
      remoteRenderer.value!.srcObject = await createLocalMediaStream('key');
    } catch (_) {}
  }

  Future<void> _setupPeerConnection() async {

    _peerConnection = await createPeerConnection(_configuration);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        _localStream?.addTrack(track);
      });

    };

  }

  void _registerPeerConnectionListeners() {

    _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      switch (state) {
        case RTCIceGatheringState.RTCIceGatheringStateNew:
          printInfo(info: "============ ICE ============");
          printInfo(info: "Ice Gathering State: New");
          printInfo(info: "========================");
          break;
        case RTCIceGatheringState.RTCIceGatheringStateGathering:
          printInfo(info: "============ ICE ============");
          printInfo(info: "Ice Gathering State: Gathering"); // CREATE 1  // JOIN 3
          printInfo(info: "========================");
          break;
        case RTCIceGatheringState.RTCIceGatheringStateComplete:
          printInfo(info: "============ ICE ============");
          printInfo(info: "Ice Gathering State: Complete"); // CREATE 3  // JOIN 5
          printInfo(info: "========================");
          break;
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: Closed"); // CLOSE 1
          printInfo(info: "========================");
          skip();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: Failed");
          printInfo(info: "========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: Disconnected");
          printInfo(info: "========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: New");
          printInfo(info: "========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: Connecting"); // JOIN 4
          printInfo(info: "========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          printInfo(info: "============ CONNECTION ============");
          printInfo(info: "Connection State: Connected"); // JOIN 6
          printInfo(info: "========================");
          break;
      }
    };

    _peerConnection?.onSignalingState = (RTCSignalingState state) {
      switch (state) {
        case RTCSignalingState.RTCSignalingStateStable:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Stable"); // JOIN 2
          printInfo(info: "========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveLocalOffer:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Have Local Offer"); // CREATE 2
          printInfo(info: "========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Have Remote Offer"); // JOIN 1
          printInfo(info: "========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Have Local PrAnswer");
          printInfo(info: "========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Have Remote PrAnswer");
          printInfo(info: "========================");
          break;
        case RTCSignalingState.RTCSignalingStateClosed:
          printInfo(info: "============ SIGNAL ============");
          printInfo(info: "Signaling State: Closed"); // CLOSE 2
          printInfo(info: "========================");
          break;
      }
    };

    _peerConnection?.onAddStream = (MediaStream? stream) {
      remoteRenderer.value!.srcObject = stream;
      _remoteStream = stream;
    };

  }

  Future<void> _createNewRoom() async {

    final newDoc = FirebaseFirestore.instance.collection('ROOMS').doc();
    currentRoomId = newDoc.id;

    final VideoCallEntity videoCallEntity = VideoCallEntity(
        id: newDoc.id,
        callerId: 'MOHAMED-2003',
        calleeId: uid,
        offer: null,
        answer: null,
        callerCandidates: null,
        calleeCandidates: null
    );

    try {

      await newDoc.set(videoCallEntity.toJson());

      remoteRenderer.value!.srcObject = await createLocalMediaStream('key');
      await _setupPeerConnection();

      _registerPeerConnectionListeners();

      _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if(candidate == null) return;
        await newDoc.update({ 'callerCandidates' : FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      RTCSessionDescription offer = await _peerConnection!.createOffer();

      await _peerConnection?.setLocalDescription(offer);

      await newDoc.update({ 'offer': offer.sdp });

      newDoc.snapshots().listen((snapshot) async {
        if(snapshot.exists && snapshot.data() != null){
          final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(snapshot.data()!);
          if (videoCallEntity.answer != null && _peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) {
            final answer = RTCSessionDescription(videoCallEntity.answer, 'answer');
            await _peerConnection?.setRemoteDescription(answer);
          }
          if (videoCallEntity.calleeCandidates != null) {
            List<Map<String, dynamic>> calleeCandidates = videoCallEntity.calleeCandidates!;
            for (Map<String, dynamic> item in calleeCandidates) {
              _peerConnection!.addCandidate(
                RTCIceCandidate(
                  item['candidate'],
                  item['sdpMid'],
                  item['sdpMLineIndex'],
                ),
              );
            }
          }
        }

      });

    } catch (_) {}
  }

  Future<void> _joinTheRoom() async {
    try {

      final doc = FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId);
      final callData = await doc.get();

      if(!(callData.exists)) { return; }

      final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(callData.data()!);

      remoteRenderer.value!.srcObject = await createLocalMediaStream('key');
      await _setupPeerConnection();

      _registerPeerConnectionListeners();

      _peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if (candidate == null) return ;
        await doc.update({ 'calleeCandidates': FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      if (_peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(videoCallEntity.offer, 'offer'));
      }

      final answer = await _peerConnection?.createAnswer();

      await _peerConnection?.setLocalDescription(answer!);

      await doc.update({ 'answer': answer!.sdp });

      doc.snapshots().listen((snapshot) async {
        if(snapshot.exists && snapshot.data() != null){
          final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(snapshot.data()!);
          if (videoCallEntity.callerCandidates != null) {
            List<Map<String, dynamic>> callerCandidates = videoCallEntity.callerCandidates!;
            for (Map<String, dynamic> item in callerCandidates) {
              _peerConnection!.addCandidate(
                RTCIceCandidate(
                  item['candidate'],
                  item['sdpMid'],
                  item['sdpMLineIndex'],
                ),
              );
            }
          }
        }
      });
    } catch (_) {}
  }

  Future<void> skip() async {

    if(currentRoomId != "") {
      await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId).delete();
      currentRoomId = "";
    }

    final QuerySnapshot<Map<String, dynamic>> roomAlreadyExist = await FirebaseFirestore.instance
        .collection('ROOMS')
        .where('answer', isEqualTo: null)
        .where('callerId', isNotEqualTo: uid)
        .limit(1)
        .get();

    if (_remoteStream != null) {
      for (final track in _remoteStream!.getTracks()) { track.stop(); track.dispose(); }
      _remoteStream!.dispose();
      _remoteStream = null;
    }

    if(roomAlreadyExist.size > 0){
      final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(roomAlreadyExist.docs.first.data());
      currentRoomId = videoCallEntity.id!;
      _joinTheRoom();
      return;
    }

    _createNewRoom();

  }

  Future<void> hangUpTheRoom() async {
    try {

      if(currentRoomId != "") {
        await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId).delete();
        currentRoomId = "";
      }

      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) { track.stop(); track.dispose(); }
        _remoteStream!.dispose();
        _remoteStream = null;
      }

      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) { track.stop(); track.dispose(); }
        _localStream!.dispose();
        _localStream = null;
      }

      if (_peerConnection != null) {
        _peerConnection!.close();
        _peerConnection = null;
      }

      Get.back();

    } catch (_) {}
  }

  @override
  void onClose() {
    _peerConnection?.dispose();
    _remoteStream?.dispose();
    _localStream?.dispose();
    localRenderer.value?.dispose();
    remoteRenderer.value?.dispose();
    super.onClose();
  }

}