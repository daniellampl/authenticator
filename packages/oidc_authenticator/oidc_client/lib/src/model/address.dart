import 'package:json_annotation/json_annotation.dart';

part 'address.g.dart';

@JsonSerializable()
class Address {
  const Address({
    this.formatted,
    this.streetAddress,
    this.locality,
    this.region,
    this.postalCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  /// Full mailing address, formatted for display or use on a mailing label.
  @JsonKey(name: 'formatted')
  final String? formatted;

  /// Full street address component.
  @JsonKey(name: 'street_address')
  final String? streetAddress;

  /// City or locality component.
  @JsonKey(name: 'locality')
  final String? locality;

  /// State, province, prefecture, or region component.
  @JsonKey(name: 'region')
  final String? region;

  /// Zip code or postal code component.
  @JsonKey(name: 'postal_code')
  final String? postalCode;

  /// Country name component.
  @JsonKey(name: 'country')
  final String? country;

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}
