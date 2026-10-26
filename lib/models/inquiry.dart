/// Represents the lifecycle status of a tire customer inquiry
enum InquiryStatus {
  unpaid,
  submitted,
  responded,
  completed,
  cancelled;

  // Backward compatibility getters
  static InquiryStatus get inquiring => InquiryStatus.submitted;
  static InquiryStatus get confirmed => InquiryStatus.responded;
  static InquiryStatus get reserved => InquiryStatus.completed;
}

extension InquiryStatusX on InquiryStatus {
  String get value {
    switch (this) {
      case InquiryStatus.unpaid:
        return 'unpaid';
      case InquiryStatus.submitted:
        return 'submitted';
      case InquiryStatus.responded:
        return 'responded';
      case InquiryStatus.completed:
        return 'completed';
      case InquiryStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case InquiryStatus.unpaid:
        return 'Unpaid';
      case InquiryStatus.submitted:
        return 'Placed';
      case InquiryStatus.responded:
        return 'Confirmed';
      case InquiryStatus.completed:
        return 'Installed';
      case InquiryStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// 1-based stage index for the visual connected stepper (1 to 3)
  int get stageStep {
    switch (this) {
      case InquiryStatus.unpaid:
        return 0;
      case InquiryStatus.submitted:
        return 1;
      case InquiryStatus.responded:
        return 2;
      case InquiryStatus.completed:
        return 3;
      case InquiryStatus.cancelled:
        return 0;
    }
  }

  static InquiryStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'unpaid':
        return InquiryStatus.unpaid;
      case 'responded':
      case 'confirmed':
      case 'prepped in bay':
        return InquiryStatus.responded;
      case 'completed':
      case 'installed':
      case 'reserved':
      case 'ready':
      case 'ready_for_pickup':
        return InquiryStatus.completed;
      case 'cancelled':
        return InquiryStatus.cancelled;
      case 'submitted':
      case 'placed':
      case 'order placed':
      case 'inquiring':
      case 'pending':
      default:
        return InquiryStatus.submitted;
    }
  }
}

/// Represents a message in the inquiry conversation between customer and staff
class InquiryMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' or 'staff'
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const InquiryMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isStaff => senderRole == 'staff';

  InquiryMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return InquiryMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
      };

  factory InquiryMessage.fromJson(Map<String, dynamic> json) {
    return InquiryMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'User',
      senderRole: json['sender_role'] as String? ?? 'customer',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

/// Represents a customer tire stock inquiry and reservation for shop visit
class TireInquiry {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String tireId;
  final String tireBrand;
  final String tireModel;
  final String tireSize;
  final String tireImage;
  final double unitPrice;
  final int quantity;
  final bool isSetOfFour;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String vehicleModel;
  final String preferredDate;
  final String notes;
  final InquiryStatus status;
  final List<InquiryMessage> messages;
  final bool isCustomerViewed;
  final bool isStaffViewed;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TireInquiry({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.tireId,
    required this.tireBrand,
    required this.tireModel,
    required this.tireSize,
    required this.tireImage,
    required this.unitPrice,
    required this.quantity,
    this.isSetOfFour = false,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    required this.vehicleModel,
    required this.preferredDate,
    this.notes = '',
    this.status = InquiryStatus.submitted,
    this.messages = const [],
    this.isCustomerViewed = true,
    this.isStaffViewed = false,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalPrice => unitPrice * (isSetOfFour ? quantity * 4 : quantity);
  int get totalTiresCount => isSetOfFour ? quantity * 4 : quantity;

  String get orderNumber {
    final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanId.length >= 5) {
      return 'TRD-${cleanId.substring(cleanId.length - 5)}';
    }
    return 'TRD-$cleanId';
  }

  bool get isClosed => status == InquiryStatus.completed || status == InquiryStatus.cancelled;

  bool get hasUnreadStaffMessage => !isClosed && messages.any((m) => m.isStaff && !m.isRead);
  bool get hasUnreadCustomerMessage => !isClosed && messages.any((m) => !m.isStaff && !m.isRead);
  int get unreadCountForCustomer => isClosed ? 0 : messages.where((m) => m.isStaff && !m.isRead).length;
  int get unreadCountForStaff => isClosed ? 0 : messages.where((m) => !m.isStaff && !m.isRead).length;

  bool get hasCustomerUnread => !isClosed && (unreadCountForCustomer > 0 || !isCustomerViewed);
  bool get hasStaffUnread => !isClosed && (unreadCountForStaff > 0 || !isStaffViewed);

  /// Returns the ID of the staff member who responded to or claimed this inquiry.
  String? get effectiveAssignedStaffId {
    if (assignedStaffId != null && assignedStaffId!.isNotEmpty) {
      return assignedStaffId;
    }
    for (final m in messages) {
      if (m.isStaff && m.senderId.isNotEmpty && m.senderId != 'guest') {
        return m.senderId;
      }
    }
    return null;
  }

  /// Whether any staff member has already replied to this inquiry.
  bool get hasStaffReplied =>
      (assignedStaffId != null && assignedStaffId!.isNotEmpty) ||
      messages.any((m) => m.isStaff);

  /// Checks whether this inquiry is visible to the given staff user.
  /// - An inquiry with NO staff replies is visible to ALL staff (so any staff can pick it up).
  /// - An inquiry that HAS a staff reply is ONLY visible to the staff who replied/claimed it.
  bool isVisibleToStaff(
    String currentStaffId, {
    String? currentStaffEmail,
    String? currentStaffName,
  }) {
    if (!hasStaffReplied) {
      return true; // Available for any staff to pick up and reply
    }

    final staffId = effectiveAssignedStaffId;
    final cleanStaffEmail = (currentStaffEmail ?? '').trim().toLowerCase();
    final cleanStaffName = (currentStaffName ?? '').trim().toLowerCase();
    final emailUsername = cleanStaffEmail.contains('@') ? cleanStaffEmail.split('@').first : '';

    // 1. Exact Staff ID match
    if (staffId != null && staffId.isNotEmpty && staffId == currentStaffId) {
      return true;
    }

    // 2. Staff Email match
    if (cleanStaffEmail.isNotEmpty) {
      if (staffId != null && staffId.toLowerCase() == cleanStaffEmail) return true;
      if (assignedStaffId != null && assignedStaffId!.toLowerCase() == cleanStaffEmail) return true;
    }

    // 3. Staff Display Name match (e.g. 'jhon')
    if (cleanStaffName.isNotEmpty && cleanStaffName != 'staff') {
      if (assignedStaffName != null && assignedStaffName!.trim().toLowerCase() == cleanStaffName) {
        return true;
      }
      if (messages.any((m) => m.isStaff && m.senderName.trim().toLowerCase() == cleanStaffName)) {
        return true;
      }
    }

    // 4. Staff Email Username match (e.g. 'jhon' from jhon@treadly.com)
    if (emailUsername.isNotEmpty && emailUsername != 'staff') {
      if (assignedStaffName != null && assignedStaffName!.trim().toLowerCase() == emailUsername) {
        return true;
      }
      if (messages.any((m) => m.isStaff && m.senderName.trim().toLowerCase() == emailUsername)) {
        return true;
      }
    }

    // 5. Message Sender ID Match
    final matchingMsg = messages.any((m) =>
        m.isStaff &&
        (m.senderId == currentStaffId ||
            (cleanStaffEmail.isNotEmpty && m.senderId.toLowerCase() == cleanStaffEmail)));
    if (matchingMsg) return true;

    // 6. Generic legacy fallback: if staffId was literally 'staff' or unassigned
    // and no other staff claimed it specifically, allow the staff desk
    if ((staffId == null || staffId.isEmpty || staffId == 'staff') &&
        (assignedStaffName == null || assignedStaffName!.isEmpty || assignedStaffName!.toLowerCase() == 'staff')) {
      return true;
    }

    return false;
  }

  String get orderId {
    if (id.startsWith('INQ-')) {
      return id.replaceFirst('INQ-', 'ORD-');
    }
    if (!id.startsWith('ORD-')) {
      return 'ORD-$id';
    }
    return id;
  }

  /// Formats the initial introductory order message
  /// containing tire specs, quantity, total amount, workshop, and customer note.
  String get startingInquiryMessageText {
    final buffer = StringBuffer();
    buffer.writeln('Treadly Order Details:');
    buffer.writeln('• Order ID: $orderId');
    buffer.writeln('• Product: $tireBrand $tireModel ($tireSize)');
    final qtyText = isSetOfFour
        ? 'Set of 4 (${quantity * 4} pcs)'
        : '$quantity Tire${quantity > 1 ? 's' : ''}';
    buffer.writeln('• Quantity: $qtyText');
    buffer.writeln('• Total Amount: $formattedTotalPrice');
    buffer.writeln('• Workshop: $branchName');
    buffer.writeln('• Bay Service: Drive-in Installation & Wheel Balancing');
    buffer.writeln('• Status: ${status.label}');
    if (notes.isNotEmpty) {
      buffer.writeln('\nCustomer Note: $notes');
    }
    return buffer.toString().trim();
  }

  /// Returns the effective messages list. If messages is empty, automatically provides
  /// the customer starting inquiry conversation message so staff has immediate context.
  List<InquiryMessage> get effectiveMessages {
    if (messages.isNotEmpty) return messages;
    return [
      InquiryMessage(
        id: 'INIT-$id',
        senderId: userId,
        senderName: customerName,
        senderRole: 'customer',
        text: startingInquiryMessageText,
        timestamp: createdAt,
        isRead: false,
      ),
    ];
  }

  InquiryMessage? get latestMessage => effectiveMessages.isNotEmpty ? effectiveMessages.last : null;

  String get formattedTotalPrice {
    final php = totalPrice.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  TireInquiry copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerPhone,
    String? tireId,
    String? tireBrand,
    String? tireModel,
    String? tireSize,
    String? tireImage,
    double? unitPrice,
    int? quantity,
    bool? isSetOfFour,
    String? branchId,
    String? branchName,
    String? branchAddress,
    String? vehicleModel,
    String? preferredDate,
    String? notes,
    InquiryStatus? status,
    List<InquiryMessage>? messages,
    bool? isCustomerViewed,
    bool? isStaffViewed,
    String? assignedStaffId,
    String? assignedStaffName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TireInquiry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tireId: tireId ?? this.tireId,
      tireBrand: tireBrand ?? this.tireBrand,
      tireModel: tireModel ?? this.tireModel,
      tireSize: tireSize ?? this.tireSize,
      tireImage: tireImage ?? this.tireImage,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isSetOfFour: isSetOfFour ?? this.isSetOfFour,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchAddress: branchAddress ?? this.branchAddress,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      preferredDate: preferredDate ?? this.preferredDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isCustomerViewed: isCustomerViewed ?? this.isCustomerViewed,
      isStaffViewed: isStaffViewed ?? this.isStaffViewed,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'user_id': userId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'tire_id': tireId,
        'tire_brand': tireBrand,
        'tire_model': tireModel,
        'tire_size': tireSize,
        'tire_image': tireImage,
        'unit_price': unitPrice,
        'quantity': quantity,
        'is_set_of_four': isSetOfFour,
        'branch_id': branchId,
        'branch_name': branchName,
        'branch_address': branchAddress,
        'vehicle_model': vehicleModel,
        'preferred_date': preferredDate,
        'notes': notes,
        'status': status.value,
        'messages': messages.map((m) => m.toJson()).toList(),
        'is_customer_viewed': isCustomerViewed,
        'is_staff_viewed': isStaffViewed,
        'assigned_staff_id': assignedStaffId,
        'assigned_staff_name': assignedStaffName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TireInquiry.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>?;
    final List<InquiryMessage> parsedMessages = rawMessages != null
        ? rawMessages
            .whereType<Map<String, dynamic>>()
            .map((m) => InquiryMessage.fromJson(m))
            .toList()
        : [];

    final rawId = json['id'] as String? ?? '';
    final rawOrderId = json['order_id'] as String?;
    final resolvedId = (rawOrderId != null && rawOrderId.isNotEmpty) ? rawOrderId : rawId;

    return TireInquiry(
      id: resolvedId,
      userId: json['user_id'] as String? ?? 'guest',
      customerName: json['customer_name'] as String? ?? 'Driver',
      customerPhone: json['customer_phone'] as String? ?? '',
      tireId: json['tire_id'] as String? ?? '',
      tireBrand: json['tire_brand'] as String? ?? '',
      tireModel: json['tire_model'] as String? ?? '',
      tireSize: json['tire_size'] as String? ?? '',
      tireImage: json['tire_image'] as String? ?? 'assets/images/tires/michelin_pilot_sport_5.webp',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isSetOfFour: json['is_set_of_four'] as bool? ?? false,
      branchId: json['branch_id'] as String? ?? 'branch-qc-main',
      branchName: json['branch_name'] as String? ?? 'Treadly Auto Hub (Main Flagship)',
      branchAddress: json['branch_address'] as String? ?? '108 Quezon Avenue, QC',
      vehicleModel: json['vehicle_model'] as String? ?? 'Not specified',
      preferredDate: json['preferred_date'] as String? ?? 'As soon as available',
      notes: json['notes'] as String? ?? '',
      status: InquiryStatusX.fromString(json['status'] as String?),
      messages: parsedMessages,
      isCustomerViewed: json['is_customer_viewed'] as bool? ?? true,
      isStaffViewed: json['is_staff_viewed'] as bool? ?? false,
      assignedStaffId: json['assigned_staff_id'] as String?,
      assignedStaffName: json['assigned_staff_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
