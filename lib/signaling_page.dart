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
      //     print("============ ICE ============");
      //     print("Ice Gathering State: New");
      //     print("========================");
      //     break;
      //   case RTCIceGatheringState.RTCIceGatheringStateGathering:
      //     print("============ ICE ============");
      //     print("Ice Gathering State: Gathering");
      //     print("========================");
      //     break;
      //   case RTCIceGatheringState.RTCIceGatheringStateComplete:
      //     print("============ ICE ============");
      //     print("Ice Gathering State: Complete");
      //     print("========================");
      //     break;
      // }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      // switch (state) {
      //   case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
      //     print("============ CONNECTION ============");
      //     print("Connection State: Closed");
      //     print("========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      //     print("============ CONNECTION ============");
      //     print("Connection State: Failed");
      //     print("========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      //     print("============ CONNECTION ============");
      //     print("Connection State: Disconnected");
      //     print("========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      //     print("============ CONNECTION ============");
      //     print("Connection State: New");
      //     print("========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
      //     print("============ CONNECTION ============");
      //     print("Connection State: Connecting");
      //     print("========================");
      //     break;
      //   case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
      //     print("============ CONNECTION ============");
      //     print("Connection State: Connected");
      //     print("========================");
      //     break;
      // }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      // switch (state) {
      //   case RTCSignalingState.RTCSignalingStateStable:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Stable");
      //     print("========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveLocalOffer:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Have Local Offer");
      //     print("========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Have Remote Offer");
      //     print("========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Have Local PrAnswer");
      //     print("========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Have Remote PrAnswer");
      //     print("========================");
      //     break;
      //   case RTCSignalingState.RTCSignalingStateClosed:
      //     print("============ SIGNAL ============");
      //     print("Signaling State: Closed");
      //     print("========================");
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