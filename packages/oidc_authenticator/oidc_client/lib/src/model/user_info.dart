import 'package:json_annotation/json_annotation.dart';
import 'package:oidc_client/src/model/address.dart';

part 'user_info.g.dart';

@JsonSerializable()
class UserInfo {
  const UserInfo({
    required this.subject,
    this.name,
    this.givenName,
    this.familyName,
    this.middleName,
    this.nickname,
    this.preferredUsername,
    this.profile,
    this.picture,
    this.website,
    this.email,
    this.emailVerified,
    this.gender,
    this.birthdate,
    this.zoneinfo,
    this.locale,
    this.phoneNumber,
    this.phoneNumberVerified,
    this.address,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  /// Identifier for the End-User at the Issuer.
  @JsonKey(name: 'subject')
  final String subject;

  /// End-User's full name in displayable form including all name parts,
  /// possibly including titles and suffixes, ordered according to the
  /// End-User's locale and preferences.
  @JsonKey(name: 'name')
  final String? name;

  /// Given name(s) or first name(s) of the End-User.
  ///
  /// Note that in some cultures, people can have multiple given names; all can
  /// be present, with the names being separated by space characters.
  @JsonKey(name: 'given_name')
  final String? givenName;

  /// Surname(s) or last name(s) of the End-User.
  ///
  /// Note that in some cultures, people can have multiple family names or no
  /// family name; all can be present, with the names being separated by space
  /// characters.
  @JsonKey(name: 'family_name')
  final String? familyName;

  /// Middle name(s) of the End-User.
  ///
  /// Note that in some cultures, people can have multiple middle names; all can
  /// be present, with the names being separated by space characters. Also note
  /// that in some cultures, middle names are not used.
  @JsonKey(name: 'middle_name')
  final String? middleName;

  /// Casual name of the End-User that may or may not be the same as the
  /// given name.
  @JsonKey(name: 'nickname')
  final String? nickname;

  /// Shorthand name by which the End-User wishes to be referred to at the RP,
  /// such as janedoe or j.doe. T
  @JsonKey(name: 'preferred_username')
  final String? preferredUsername;

  /// URL of the End-User's profile page.
  @JsonKey(name: 'profile')
  final Uri? profile;

  /// URL of the End-User's profile picture.
  @JsonKey(name: 'picture')
  final Uri? picture;

  /// URL of the End-User's Web page or blog.
  @JsonKey(name: 'website')
  final Uri? website;

  /// End-User's preferred e-mail address.
  @JsonKey(name: 'email')
  final String? email;

  /// `true` if the End-User's e-mail address has been verified.
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;

  /// End-User's gender.
  ///
  /// Values defined by the specification are `female` and `male`. Other values
  /// MAY be used when neither of the defined values are applicable.
  @JsonKey(name: 'gender')
  final String? gender;

  /// End-User's birthday.
  ///
  /// Date represented as an ISO 8601:2004 [ISO8601‑2004] YYYY-MM-DD format.
  /// The year MAY be 0000, indicating that it is omitted. To represent only the
  /// year, YYYY format is allowed.
  @JsonKey(name: 'birthdate')
  final String? birthdate;

  /// The End-User's time zone.
  ///
  /// For example, Europe/Paris or America/Los_Angeles.
  @JsonKey(name: 'zoneinfo')
  final String? zoneinfo;

  /// End-User's locale.
  @JsonKey(name: 'locale')
  final String? locale;

  /// End-User's preferred telephone number.
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  /// `true if the End-User's phone number has been verified`
  @JsonKey(name: 'phone_number_verified')
  final bool? phoneNumberVerified;

  /// End-User's preferred postal address.
  @JsonKey(name: 'address')
  final Address? address;

  // /// Time the End-User's information was last updated.
  // final DateTime? get updatedAt => this['updated_at'] == null
  //     ? null
  //     : DateTime.fromMillisecondsSinceEpoch(this['updated_at'] * 1000);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}
