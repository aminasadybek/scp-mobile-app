part of 'complaint.dart';

class ComplaintAdapter extends TypeAdapter<Complaint> {
  @override
  final int typeId = 1;

  @override
  Complaint read(BinaryReader reader) {
    return Complaint(
      id: reader.readInt(),
      orderId: reader.readInt(),
      consumerId: reader.readInt(),
      supplierId: reader.readInt(),
      description: reader.readString(),
      status: reader.readString(),
      resolution: reader.read(),
      createdAt: reader.read(),
      resolvedAt: reader.read(),
      assignedTo: reader.read(),
      priority: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Complaint obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.orderId);
    writer.writeInt(obj.consumerId);
    writer.writeInt(obj.supplierId);
    writer.writeString(obj.description);
    writer.writeString(obj.status);
    writer.write(obj.resolution);
    writer.write(obj.createdAt);
    writer.write(obj.resolvedAt);
    writer.write(obj.assignedTo);
    writer.write(obj.priority);
  }
}
