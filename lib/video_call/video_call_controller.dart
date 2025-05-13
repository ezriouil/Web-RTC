import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

  late final Rx<RTCVideoRenderer?> localRenderer;
  late final Rx<RTCVideoRenderer?> remoteRenderer;

  late MediaStream? localStream;
  late MediaStream? remoteStream;

  late final RxBool isInitialising;
  late final RxBool isJoined;
  late final RxBool isMeTheCaller;

  late final RxString currentRoomId;

  late final RxBool result;

  final GetStorage _storage = GetStorage();
  String? uid;

  @override
  void onInit() {
    peerConnection = null;

    localRenderer = RTCVideoRenderer().obs;
    remoteRenderer = RTCVideoRenderer().obs;

    currentRoomId = "".obs;

    localStream = null;
    remoteStream = null;

    isInitialising = true.obs;
    isJoined = false.obs;
    isMeTheCaller = false.obs;

    result = true.obs;

    super.onInit();
    init();
  }

  void init() async {
    await localRenderer.value!.initialize();
    await remoteRenderer.value!.initialize();
    final String myUid = await _getUID();
    uid = myUid;
    skip();
  }

  Future<void> createNewRoom() async {

    final newDoc = FirebaseFirestore.instance.collection('ROOMS').doc();
    currentRoomId.value = newDoc.id;
    isMeTheCaller.value = true;

    final VideoCallEntity videoCallEntity = VideoCallEntity(
        id: newDoc.id,
        callerId: uid,
        calleeId: null,
        offer: null,
        answer: null,
        isAvailable: true,
        callerCandidates: null,
        calleeCandidates: null
    );

    try {

      await newDoc.set(videoCallEntity.toJson());

      // ======================== OPEN MEDIA ======================== //
      final MediaStream stream = await mediaDevices.getUserMedia({'video': true, 'audio': true});
      localRenderer.value!.srcObject = stream;
      localStream = stream;
      isInitialising.value = false;
      // ======================== OPEN MEDIA ======================== //

      // ======================== PER CONNECTION ======================== //
      peerConnection = await createPeerConnection(_configuration);
      localStream?.getTracks().forEach((track) { peerConnection?.addTrack(track, localStream!); });
      peerConnection?.onTrack = (RTCTrackEvent event) { event.streams[0].getTracks().forEach((track) { localStream?.addTrack(track); }); };
      peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
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
      peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            printInfo(info: "============ CONNECTION ============");
            printInfo(info: "Connection State: Closed"); // CLOSE 1
            printInfo(info: "========================");
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
            isJoined.value = true;
            break;
        }
      };
      peerConnection?.onSignalingState = (RTCSignalingState state) {
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
      peerConnection?.onAddStream = (MediaStream stream) {
        remoteRenderer.value!.srcObject = stream;
        remoteStream = stream;
      };
      // ======================== PER CONNECTION ======================== //

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

          if (videoCallEntity.answer != null && peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) {
            final answer = RTCSessionDescription(videoCallEntity.answer, 'answer');
            await peerConnection?.setRemoteDescription(answer);
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
        else{
          if(result.value){ next(); }
          else{ hangUp(); }
        }
      });

    } catch (_) {}
  }

  Future<void> joinTheRoom() async {
    try {

      final doc = FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value);
      final callData = await doc.get();
      isMeTheCaller.value = false;

      await doc.update({ 'isAvailable': false });

      final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(callData.data()!);

      // ======================== OPEN MEDIA ======================== //
      final MediaStream stream = await mediaDevices.getUserMedia({ 'video': true, 'audio': true });
      localRenderer.value!.srcObject = stream;
      localStream = stream;
      isInitialising.value = false;
      // ======================== OPEN MEDIA ======================== //

      // ======================== PER CONNECTION ======================== //
      peerConnection = await createPeerConnection(_configuration);
      localStream?.getTracks().forEach((track) { peerConnection?.addTrack(track, localStream!); });
      peerConnection?.onTrack = (RTCTrackEvent event) { event.streams[0].getTracks().forEach((track) { localStream?.addTrack(track); }); };
      peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
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
      peerConnection?.onConnectionState = (RTCPeerConnectionState state) async {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            printInfo(info: "============ CONNECTION ============");
            printInfo(info: "Connection State: Closed"); // CLOSE 1
            printInfo(info: "========================");
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
            isJoined.value = true;
            break;
        }
      };
      peerConnection?.onSignalingState = (RTCSignalingState state) {
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
      peerConnection?.onAddStream = (MediaStream stream) {
        remoteRenderer.value!.srcObject = stream;
        remoteStream = stream;
      };
      // ======================== PER CONNECTION ======================== //

      peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if (candidate == null) return ;
        await doc.update({ 'calleeCandidates': FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      if (peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) {
        await peerConnection?.setRemoteDescription(RTCSessionDescription(videoCallEntity.offer, 'offer'));
      }

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
          }
        }
        else{
          if(result.value){ next(); }
          else{ hangUp(); }
        }
      });


    } catch (_) {}
  }

  Future<void> skip() async {

    isJoined.value = false;

    final QuerySnapshot<Map<String, dynamic>> roomAlreadyExist = await FirebaseFirestore.instance
        .collection('ROOMS')
        .where('isAvailable', isEqualTo: true)
        .where('callerId', isNotEqualTo: uid)
        .limit(1)
        .get();


    if(roomAlreadyExist.size > 0){
      final VideoCallEntity videoCallEntity = VideoCallEntity.fromJson(roomAlreadyExist.docs.first.data());
      currentRoomId.value = videoCallEntity.id!;
      await joinTheRoom();
      return;
    }
    await createNewRoom();

  }

  Future<void> next() async {

    try {
      if(currentRoomId.value != "") {
        await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value).delete();
        currentRoomId.value = "";
        printInfo(info: "--- ROOM ID REMOVED ---");
      }

      result.value = true;
      Get.back(result: { 'result' : true, 'isMeTheCaller' : isMeTheCaller.value });

    } catch (_) {}
  }

  Future<void> hangUp() async {

    try {
      if(currentRoomId.value != "") {
        await FirebaseFirestore.instance.collection('ROOMS').doc(currentRoomId.value).delete();
        currentRoomId.value = "";
        printInfo(info: "--- ROOM ID REMOVED ---");
      }

      result.value = false;
      Get.back(result: { 'result' : false, 'isMeTheCaller' : isMeTheCaller.value });

    } catch (_) {}
  }

  @override
  void onClose() {
    peerConnection?.dispose();
    localStream?.dispose();
    remoteStream?.dispose();
    localRenderer.value?.dispose();
    remoteRenderer.value?.dispose();
    super.onClose();
  }

  Future<String> _getUID() async {
    String? getUid = _storage.read("UID");
    if(getUid == null){
      final String generateRandomUid = Random().nextInt(1000).toString();
      _storage.write("UID", generateRandomUid);
      getUid = generateRandomUid;
    }
    return getUid ;
  }
  
}