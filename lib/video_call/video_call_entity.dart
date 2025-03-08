class VideoCallEntity {
  // - - - - - - - - - - - - - - - - - -  STATES - - - - - - - - - - - - - - - - - -  //
  late final bool? isAvailable;
  late final String? id;
  late final String? callerId;
  late final String? calleeId;
  late final String? offer;
  late final String? answer;
  late final List<Map<String, dynamic>>? callerCandidates;
  late final List<Map<String, dynamic>>? calleeCandidates;

  // Constructor
  VideoCallEntity({
    this.isAvailable,
    this.id,
    this.callerId,
    this.calleeId,
    this.offer,
    this.answer,
    this.callerCandidates,
    this.calleeCandidates,
  });

  // From JSON
  factory VideoCallEntity.fromJson(Map<String, dynamic> json) {
    return VideoCallEntity(
      isAvailable: json['isAvailable'] as bool?,
      id: json['id'] as String?,
      callerId: json['callerId'] as String?,
      calleeId: json['calleeId'] as String?,
      offer: json['offer'] as String?,
      answer: json['answer'] as String?,
      callerCandidates: (json['callerCandidates'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      calleeCandidates: (json['calleeCandidates'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'id': id,
      'callerId': callerId,
      'calleeId': calleeId,
      'offer': offer,
      'answer': answer,
      'callerCandidates': callerCandidates,
      'calleeCandidates': calleeCandidates,
    };
  }
}