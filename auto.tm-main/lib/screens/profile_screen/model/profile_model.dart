                                          class ProfileModel {
                                            final String uuid;
                                            final String name;
                                            final String email;
                                            final String phone;
                                            final String? location; // optional
                                            final String? avatar; // chosen single path (medium > large > small)
                                            final Map<String, String>? avatarVariants; // full size map if needed later
                                            final DateTime createdAt;
                                            final List<String>? brandUuid;

                                            ProfileModel({
                                              required this.uuid,
                                              required this.name,
                                              required this.email,
                                              required this.phone,
                                              this.location,
                                              this.avatar,
                                              this.avatarVariants,
                                              required this.createdAt,
                                              this.brandUuid,
                                            });

                                            factory ProfileModel.fromJson(Map<String, dynamic> json) {
                                              String? selectedAvatar;
                                              Map<String, String>? variants;
                                              final avatarObj = json['avatar'];
                                              if (avatarObj is Map) {
                                                final pathObj = avatarObj['path'];
                                                if (pathObj is Map) {
                                                  // Normalize keys to String->String
                                                  variants = {
                                                    for (final entry in pathObj.entries)
                                                      if (entry.value != null) entry.key.toString(): entry.value.toString(),
                                                  };
                                                  selectedAvatar = variants['medium'] ?? variants['large'] ?? variants['small'];
                                                }
                                              }

                                              return ProfileModel(
                                                uuid: json['uuid']?.toString() ?? '',
                                                name: json['name']?.toString() ?? '',
                                                email: json['email']?.toString() ?? '',
                                                phone: json['phone']?.toString() ?? '',
                                                location: json['location']?.toString(),
                                                avatar: selectedAvatar,
                                                avatarVariants: variants,
                                                createdAt: json['createdAt'] != null
                                                    ? DateTime.parse(json['createdAt'].toString())
                                                    : DateTime.now(),
                                                brandUuid: const [],
                                              );
                                            }
                                          }
