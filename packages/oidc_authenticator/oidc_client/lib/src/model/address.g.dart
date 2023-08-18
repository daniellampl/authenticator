// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      formatted: json['formatted'] as String?,
      streetAddress: json['street_address'] as String?,
      locality: json['locality'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'formatted': instance.formatted,
      'street_address': instance.streetAddress,
      'locality': instance.locality,
      'region': instance.region,
      'postal_code': instance.postalCode,
      'country': instance.country,
    };
