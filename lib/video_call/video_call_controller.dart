import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_rtc/video_call/video_call_entity.dart';

class VideoCallController extends GetxController{

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

  late RTCPeerConnection? peerConnection;

  late MediaStream? localStream;
  late MediaStream? remoteStream;

  late final RxString currentRoomId;

  late final RxBool isLoading;
  late final RxBool isJoined;

  late final RxBool isWantedToClose;
  late final RxBool isMeTheCaller;

  //late final RxBool isAlreadyCreated;

  late final Rx<RTCVideoRenderer?> localRenderer;
  late final Rx<RTCVideoRenderer?> remoteRenderer;

  @override
  void onInit() {
    peerConnection = null;

    localRenderer = RTCVideoRenderer().obs;
    remoteRenderer = RTCVideoRenderer().obs;

    currentRoomId = "".obs;

    localStream = null;
    remoteStream = null;

    isLoading = true.obs;
    isJoined = false.obs;

    isMeTheCaller = false.obs;

    isWantedToClose = false.obs;

    super.onInit();
    init();
  }

  void init() async {
    await localRenderer.value!.initialize();
    await remoteRenderer.value!.initialize();
    await openUserMedia();
    isLoading.value = false;
    await initPeerConnection();
    skip();
  }

  Future<void> openUserMedia() async {
    try {
      final MediaStream stream = await mediaDevices.getUserMedia({'video': true, 'audio': true});
      localRenderer.value!.srcObject = stream;
      localStream = stream;
      remoteRenderer.value!.srcObject = await createLocalMediaStream('key');
    } catch (_) {}
  }

  Future<void> initPeerConnection() async {

    peerConnection = await createPeerConnection(_configuration);

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        localStream?.addTrack(track);
      });
    };

  }

  void registerPeerConnectionListeners() {

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      switch (state) {
        case RTCIceGatheringState.RTCIceGatheringStateNew:
          print("============ ICE ============");
          print("Ice Gathering State: New");
          print("========================");
          break;
        case RTCIceGatheringState.RTCIceGatheringStateGathering:
          print("============ ICE ============");
          print("Ice Gathering State: Gathering"); // CREATE 1  // JOIN 3
          print("========================");
          break;
        case RTCIceGatheringState.RTCIceGatheringStateComplete:
          print("============ ICE ============");
          print("Ice Gathering State: Complete"); // CREATE 3  // JOIN 5
          print("========================");
          break;
      }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          print("============ CONNECTION ============");
          print("Connection State: Closed"); // CLOSE 1
          print("========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print("============ CONNECTION ============");
          print("Connection State: Failed");
          print("========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print("============ CONNECTION ============");
          print("Connection State: Disconnected");
          print("========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
          print("============ CONNECTION ============");
          print("Connection State: New");
          print("========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          print("============ CONNECTION ============");
          print("Connection State: Connecting"); // JOIN 4
          print("========================");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print("============ CONNECTION ============");
          print("Connection State: Connected"); // JOIN 6
          print("========================");
          break;
      }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      switch (state) {
        case RTCSignalingState.RTCSignalingStateStable:
          print("============ SIGNAL ============");
          print("Signaling State: Stable"); // JOIN 2
          print("========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveLocalOffer:
          print("============ SIGNAL ============");
          print("Signaling State: Have Local Offer"); // CREATE 2
          print("========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
          print("============ SIGNAL ============");
          print("Signaling State: Have Remote Offer"); // JOIN 1
          print("========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer:
          print("============ SIGNAL ============");
          print("Signaling State: Have Local PrAnswer");
          print("========================");
          break;
        case RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer:
          print("============ SIGNAL ============");
          print("Signaling State: Have Remote PrAnswer");
          print("========================");
          break;
        case RTCSignalingState.RTCSignalingStateClosed:
          print("============ SIGNAL ============");
          print("Signaling State: Closed"); // CLOSE 2
          print("========================");
          isJoined.value = false;
          break;
      }
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      remoteRenderer.value!.srcObject = stream;
      remoteStream = stream;
    };

  }

  Future<void> createNewRoom() async {

    final newDoc = FirebaseFirestore.instance.collection('ROOMS').doc();
    currentRoomId.value = newDoc.id;

    final VideoCallEntity videoCallEntity = VideoCallEntity(
        id: newDoc.id,
        callerId: 'MOHAMED-2003',
        calleeId: 'EZRIOUIL-2003',
        isAvailable: true,
        offer: null,
        answer: null,
        callerCandidates: null,
        calleeCandidates: null
    );

    try {

      await newDoc.set(videoCallEntity.toJson());
      isMeTheCaller.value = true;

     registerPeerConnectionListeners();

      peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if(candidate == null) return;
        await newDoc.update({ 'callerCandidates' : FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      RTCSessionDescription offer = await peerConnection!.createOffer();

      await peerConnection?.setLocalDescription(offer);

      await newDoc.update({ 'offer': offer.sdp });

      newDoc.snapshots().listen((snapshot) async {
        if(snapshot.exists && snapshot.data() != null){
          final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(snapshot.data()!);

          if (videoCallEntity.answer != null && peerConnection?.getRemoteDescription() != null) {
            final answer = RTCSessionDescription(videoCallEntity.answer, 'answer');
            await peerConnection?.setRemoteDescription(answer);
            if(isMeTheCaller.value) isJoined.value = true;
          }

          if (videoCallEntity.calleeCandidates != null) {
            List<Map<String, dynamic>> calleeCandidates = videoCallEntity.calleeCandidates!;
            for (Map<String, dynamic> item in calleeCandidates) {
              peerConnection!.addCandidate(
                RTCIceCandidate(
                  item['candidate'],
                  item['sdpMid'],
                  item['sdpMLineIndex'],
                ),
              );
            }
          }

        }
        else {
          if(!isWantedToClose.value) skip();
          isJoined.value = false;
        }
      });

    } catch (_) {}
  }

  Future<void> joinTheRoom() async {
    try {

      final doc = FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value);
      final callData = await doc.get();

      if(!(callData.exists) && callData.data() == null) {
        skip();
        return;
      }

      await doc.update({ 'isAvailable': false });

      final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(callData.data()!);

      registerPeerConnectionListeners();

      peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if (candidate == null) return ;
        await doc.update({ 'calleeCandidates': FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      await peerConnection?.setRemoteDescription(RTCSessionDescription(videoCallEntity.offer, 'offer'));

      final answer = await peerConnection!.createAnswer();

      await peerConnection!.setLocalDescription(answer);

      await doc.update({ 'answer': answer.sdp });

      doc.snapshots().listen((snapshot) async {
        if(snapshot.exists && snapshot.data() != null){
          final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(snapshot.data()!);
          if (videoCallEntity.callerCandidates != null) {
            List<Map<String, dynamic>> callerCandidates = videoCallEntity.callerCandidates!;
            for (Map<String, dynamic> item in callerCandidates) {
              peerConnection!.addCandidate(
                RTCIceCandidate(
                  item['candidate'],
                  item['sdpMid'],
                  item['sdpMLineIndex'],
                ),
              );
            }
            if(!isMeTheCaller.value) isJoined.value = true;
          }
        }
        else {
          if(!isWantedToClose.value) skip();
          isJoined.value = false;
        }
      });

    } catch (_) {}
  }

  Future<void> skip() async {

    isJoined.value = false;
    isMeTheCaller.value = false;

    try{
      if(currentRoomId.value != "") {
        await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value).delete();
        currentRoomId.value = "";
      }
    }
    catch (_) {}

    await Future.delayed(Duration(milliseconds: 300));

    try{

      final QuerySnapshot<Map<String, dynamic>> roomAlreadyExist = await FirebaseFirestore.instance.collection('ROOMS').where('isAvailable', isEqualTo: true).limit(1).get();

      if(roomAlreadyExist.size > 0){
        final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(roomAlreadyExist.docs.first.data());
        currentRoomId.value = videoCallEntity.id!;
        joinTheRoom();
      }
      else {
        await Future.delayed(Duration(milliseconds: 300));
        createNewRoom();
      }
    }
    catch (_) {}

  }

  Future<void> hangUpTheRoom() async {
    try {

      isWantedToClose.value = true;
      if(!isJoined.value) isJoined.value = false;

      if(currentRoomId.value != "") {
        await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value).delete();
        currentRoomId.value = "";
      }

      if (remoteStream != null) {
        for (final track in remoteStream!.getTracks()) { track.stop(); track.dispose(); }
        remoteStream!.dispose();
        remoteStream = null;
      }

      if (peerConnection != null) {
        peerConnection!.close();
        peerConnection = null;
      }

      Get.back();

    } catch (_) {}
  }

  @override
  void onClose() {
    peerConnection?.dispose();
    localStream?.dispose();
    localStream?.dispose();
    localRenderer.value?.dispose();
    remoteRenderer.value?.dispose();
    super.onClose();
  }

}