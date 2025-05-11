class RoomEntity {
  // - - - - - - - - - - - - - - - - - -  STATES - - - - - - - - - - - - - - - - - -  //
  late final String? id;
  late final String? callerId;
  late final String? calleeId;
  late final String? offer;
  late final String? answer;
  late final List<Map<String, dynamic>>? callerCandidates;
  late final List<Map<String, dynamic>>? calleeCandidates;

  // Constructor
  RoomEntity({
    this.id,
    this.callerId,
    this.calleeId,
    this.offer,
    this.answer,
    this.callerCandidates,
    this.calleeCandidates,
  });

  // From JSON
  factory RoomEntity.fromJson(Map<String, dynamic> json) {
    return RoomEntity(
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