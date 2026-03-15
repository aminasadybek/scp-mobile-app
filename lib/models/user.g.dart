part of 'user.dart';

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    return User(
      id: reader.readInt(),
      name: reader.readString(),
      email: reader.readString(),
      password: reader.readString(),
      phone: reader.readString(),
      role: reader.readString(),
      companyId: reader.readInt(),
      createdAt: reader.read() as DateTime?,
      updatedAt: reader.read() as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
    writer.writeString(obj.password);
    writer.writeString(obj.phone);
    writer.writeString(obj.role);
    writer.writeInt(obj.companyId);
    writer.write(obj.createdAt);
    writer.write(obj.updatedAt);
  }
}
