import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {

  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  StreamStateCallback? onAddRemoteStream;

  Future<void> openUserMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    try {
      final MediaStream stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
      localVideo.srcObject = stream;
      localStream = stream;
      remoteVideo.srcObject = await createLocalMediaStream('key');
    } catch (_) {}
  }

  void registerPeerConnectionListeners({ required RTCPeerConnection? peerConnection }) {

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      // switch (state) {
      //   case RTCIceGatheringState.RTCIceGatheringStateNew:
      //     printInfo(info: "============ ICE ============");
      //     printInfo(info: "Ice Gathering State: New");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCIceGatheringState.RTCIceGatheringStateGathering:
      //     printInfo(info: "============ ICE ============");
      //     printInfo(info: "Ice Gathering State: Gathering");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCIceGatheringState.RTCIceGatheringStateComplete:
      //     printInfo(info: "============ ICE ============");
      //     printInfo(info: "Ice Gathering State: Complete");
      //     printInfo(info: "========================");
      //     break;
      // }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      // switch (state) {
      //   case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: Closed");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: Failed");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: Disconnected");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: New");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: Connecting");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
      //     printInfo(info: "============ CONNECTION ============");
      //     printInfo(info: "Connection State: Connected");
      //     printInfo(info: "========================");
      //     break;
      // }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      // switch (state) {
      //   case RTCSignalingState.RTCSignalingStateStable:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Stable");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveLocalOffer:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Have Local Offer");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Have Remote Offer");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Have Local PrAnswer");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Have Remote PrAnswer");
      //     printInfo(info: "========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateClosed:
      //     printInfo(info: "============ SIGNAL ============");
      //     printInfo(info: "Signaling State: Closed");
      //     printInfo(info: "========================");
      //     break;
      // }
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

  }

  // ---------- CREATE NEW VIDEO CALL ---------- //
  Future<void> createNewCall(RTCVideoRenderer remoteRenderer) async {
    try {

      final newDoc = FirebaseFirestore.instance.collection('CALLS').doc("10");
      newDoc.set({
        'id': newDoc.id,
        'callerId': 'MOHAMED-2003',
        'calleeId': 'EZRIOUIL-2003',
        'isAvailable': true,
        'offer': null,
        'answer': null,
        'callerCandidates': null,
        'calleeCandidates': null
      });

      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners(peerConnection: peerConnection);

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
        if(candidate == null) return;
        await newDoc.update({ 'callerCandidates' : FieldValue.arrayUnion([ candidate.toMap() ]) });
      };

      RTCSessionDescription offer = await peerConnection!.createOffer();

      await peerConnection!.setLocalDescription(offer);

      await newDoc.update({ 'offer': offer.sdp });

      peerConnection?.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          remoteStream?.addTrack(track);
        });
      };

      newDoc.snapshots().listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null && snapshot.data()?['answer'] != null && peerConnection?.getRemoteDescription() != null) {
          final answer = RTCSessionDescription(snapshot.data()!['answer'], 'answer');
          await peerConnection?.setRemoteDescription(answer);
        }
      });

      newDoc.snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null && snapshot.data()?['calleeCandidates'] != null) {
          var calleeCandidates = snapshot.data()!['calleeCandidates'];
          for (var item in calleeCandidates) {
            peerConnection!.addCandidate(
              RTCIceCandidate(
                item['candidate'],
                item['sdpMid'],
                item['sdpMLineIndex'],
              ),
            );
          }
        }
      });

    } catch (_) {}
  }

  // ---------- JOIN THE VIDEO CALL ---------- //
  Future<void> joinTheCall(RTCVideoRenderer remoteVideo) async {
    try {

      final doc = FirebaseFirestore.instance.collection('CALLS').doc("10");

      final callData = await doc.get();

      if (callData.exists) {

        peerConnection = await createPeerConnection(configuration);

        registerPeerConnectionListeners(peerConnection: peerConnection);

        localStream?.getTracks().forEach((track) {
          peerConnection?.addTrack(track, localStream!);
        });

        peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) async {
          if (candidate == null) return;
          await doc.update({ 'calleeCandidates': FieldValue.arrayUnion([ candidate.toMap() ]) });
        };

        peerConnection?.onTrack = (RTCTrackEvent event) {
          event.streams[0].getTracks().forEach((track) {
            remoteStream?.addTrack(track);
          });
        };

        await peerConnection?.setRemoteDescription(RTCSessionDescription(callData['offer'], 'offer'))
        ;
        final answer = await peerConnection!.createAnswer();

        await peerConnection!.setLocalDescription(answer);

        await doc.update({ 'answer': answer.sdp });

        doc.snapshots().listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null && snapshot.data()?['callerCandidates'] != null) {
            var calleeCandidates = snapshot.data()!['callerCandidates'];
            for (var item in calleeCandidates) {
              peerConnection!.addCandidate(
                RTCIceCandidate(
                  item['candidate'],
                  item['sdpMid'],
                  item['sdpMLineIndex'],
                ),
              );
            }
          }
        });
      }

    } catch (_) {}
  }

  // ---------- HANG UP THE VIDEO CALL ---------- //
  Future<void> hangUpTheCall() async {
    try {

      if (remoteStream != null) {
        for (final track in remoteStream!.getTracks()) {
          track.stop();
          track.dispose();
        }
        remoteStream!.dispose();
        remoteStream = null;
      }

      if (peerConnection != null) {
        peerConnection!.close();
        peerConnection = null;
      }

      await FirebaseFirestore.instance.collection('CALLS').doc("10").delete();

    } catch (e) {
      print("Error ending call: ${e.toString()}");
    }
  }

}