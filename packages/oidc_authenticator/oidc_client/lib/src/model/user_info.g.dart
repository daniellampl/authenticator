// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      subject: json['subject'] as String,
      name: json['name'] as String?,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      middleName: json['middle_name'] as String?,
      nickname: json['nickname'] as String?,
      preferredUsername: json['preferred_username'] as String?,
      profile:
          json['profile'] == null ? null : Uri.parse(json['profile'] as String),
      picture:
          json['picture'] == null ? null : Uri.parse(json['picture'] as String),
      website:
          json['website'] == null ? null : Uri.parse(json['website'] as String),
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool?,
      gender: json['gender'] as String?,
      birthdate: json['birthdate'] as String?,
      zoneinfo: json['zoneinfo'] as String?,
      locale: json['locale'] as String?,
      phoneNumber: json['phone_number'] as String?,
      phoneNumberVerified: json['phone_number_verified'] as bool?,
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'subject': instance.subject,
      'name': instance.name,
      'given_name': instance.givenName,
      'family_name': instance.familyName,
      'middle_name': instance.middleName,
      'nickname': instance.nickname,
      'preferred_username': instance.preferredUsername,
      'profile': instance.profile?.toString(),
      'picture': instance.picture?.toString(),
      'website': instance.website?.toString(),
      'email': instance.email,
      'email_verified': instance.emailVerified,
      'gender': instance.gender,
      'birthdate': instance.birthdate,
      'zoneinfo': instance.zoneinfo,
      'locale': instance.locale,
      'phone_number': instance.phoneNumber,
      'phone_number_verified': instance.phoneNumberVerified,
      'address': instance.address,
    };
