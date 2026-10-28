import 'dart:io';

class UserData {
  static String _Name = "User";
  static String _Email = "Not Mentioned";
  static String _PhoneNumber = "Not Mentioned";

  // ______________________________________________________________________________________
  static int _Age = 18;
  static String _DateOfBirth = "";
  //___________________________Origin_Country_Page________________________________________
  static String _NationalityCountry = "Not Mentioned";
  static String _NationalityCity = "Not Mentioned";
  static String _NationalityState = "Not Mentioned";

  static String _AbroadCountry = "Not Mentioned";
  static String _AbroadCity = "Not Mentioned";
  static String _AbroadState = "Not Mentioned";

  static String _Residence = "Not Mentioned";
  static String _ResidenceDis = "Not Mentioned";
  //________________________________________________________________________________________
  static String _userDeviceToken = "";
  static String _userID = "";
  // _______________________________________________________________________________________
  static List<String> _ProfileImgs = [];
  static List<String> _UploadedProfileImageUrls = List.filled(5, "");
  static String _ProfileImgsShareWith = "";
  static List<String> _DocumentImgs = [];
  static List<String> _UploadedDocumentImageUrls = [];
  // ______________________________________________________________________________________
  static String _MartialStatus = "";
  static String _HasChilderen = "";
  static int _NoOfChilderens = 0;
  static String _liveWithYou = "";
  // ---------------------------------------------------------------------------------------

  static List<String> _hobbies = [];
  static List<String> get hobbies => _hobbies;
  static set hobbies(List<String> value) {
    _hobbies = value;
    print("The Data is seted as" + value.toString());
  }

  // ---------------------------------------------------------------------------------------

  static String get MartialStatus => _MartialStatus;

  static set MartialStatus(String value) {
    _MartialStatus = value;
    print("The Data is seted as" + value.toString());
  }

  static String get displayHeight => _displayHeight;

  static set displayHeight(String value) {
    _displayHeight = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _ShareMaritalInfoWith = "";

  static String get ShareMaritalInfoWith => _ShareMaritalInfoWith;

  static set ShareMaritalInfoWith(String value) {
    _ShareMaritalInfoWith = value;
    print("The Data is seted as" + value.toString());
  } // _______________________________________________________________________________________

  static double _Height = 0.0;
  static String _Weight = "Not Mentioned";

  static String get Weight => _Weight;

  static set Weight(String value) {
    _Weight = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _displayHeight = "Not Mentioned";
  static String _skinTone = "Not Mentioned";
  static String _bodyType = "Not Mentioned";

  static String get skinTone => _skinTone;

  static set skinTone(String value) {
    _skinTone = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _Gender = "Male";

  static String _FindingFor = "Self";

  static String get FindingFor => _FindingFor;

  static set FindingFor(String value) {
    _FindingFor = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _Religon = "Muslim";
  static String _Sect = "Muslim";

  static List<String> _personaltiychips = [];

  static List<String> get personaltiychips => _personaltiychips;

  static set personaltiychips(List<String> value) {
    _personaltiychips = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  } // __________________________________________________________________________________________

  static String _Disability = "None";

  static String get Disability => _Disability;

  static set Disability(String value) {
    _Disability = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _DisabilityDis = "None";
  static String _DisabilityShareWith = "None";
  //___________________________________________________________________________________________
  static String _Ethicity = "Pakistani";
  static String _Tribe = "Jatt";
  static String _FamilyDis = "Jatt";

  //________________________________________________________________________________________________________________
  // Partner Exception Dataset
  //________________________________________________________________________________________________________________

  static int _partnerAgeMin = 18;
  static int _partnerAgeMax = 28;

  static List<String> _partnerCountries = [];
  static String _partnerSect = "Not Mentioned";
  static String _partnerCast = "Not Mentioned";

  static List<String> _partnerMartialStatus = [];

  static int get partnerAgeMin => _partnerAgeMin;

  static set partnerAgeMin(int value) {
    _partnerAgeMin = value;
    print("The Data is seted as" + value.toString());
  }

  static int get partnerAgeMax => _partnerAgeMax;

  static set partnerAgeMax(int value) {
    _partnerAgeMax = value;
    print("The Data is seted as" + value.toString());
  }

  static List<String> get partnerCountries => _partnerCountries;

  static set partnerCountries(List<String> value) {
    _partnerCountries = value;
    print("The Data is seted as" + value.toString());
  }

  static String get partnerSect => _partnerSect;

  static set partnerSect(String value) {
    _partnerSect = value;
    print("The Data is seted as" + value.toString());
  }

  static String get partnerCast => _partnerCast;

  static set partnerCast(String value) {
    _partnerCast = value;
    print("The Data is seted as" + value.toString());
  }

  static List<String> get partnerMartialStatus => _partnerMartialStatus;

  static set partnerMartialStatus(List<String> value) {
    _partnerMartialStatus = value;

    print("The Data is seted as" + value.toString());
  }

  //________________________________________________________________________________________________
  // ------------------------------------------  ---------------------------------------------------
  //________________________________________________________________________________________________

  static String get FamilyDis => _FamilyDis;

  static set FamilyDis(String value) {
    _FamilyDis = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _Profession = "Engineer";
  static String _JobCountry = "Pakistan";

  static String _Degree = "Not Mentioned";

  static String get Degree => _Degree;

  static set Degree(String value) {
    _Degree = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _Field = "Not Mentioned";
  static String _EducationDiscription = "Not Mentioned";

  static String get Profession => _Profession;

  static set Profession(String value) {
    _Profession = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Tribe => _Tribe;

  static set Tribe(String value) {
    _Tribe = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String _JobTitle = "engineer";
  static String _JobDesc = "I am an engineer";

  static int _Income = 0;

  static String get Name => _Name;

  static set Name(String value) {
    _Name = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get ResidenceDis => _ResidenceDis;

  static set ResidenceDis(String value) {
    _ResidenceDis = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get ProfileImgsShareWith => _ProfileImgsShareWith;

  static set ProfileImgsShareWith(String value) {
    _ProfileImgsShareWith = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Email => _Email;

  static int get Income => _Income;

  static set Income(int value) {
    _Income = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get JobDesc => _JobDesc;

  static set JobDesc(String value) {
    _JobDesc = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get JobTitle => _JobTitle;

  static set JobTitle(String value) {
    _JobTitle = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Ethicity => _Ethicity;

  static set Ethicity(String value) {
    _Ethicity = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Sect => _Sect;

  static set Sect(String value) {
    _Sect = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Religon => _Religon;

  static set Religon(String value) {
    _Religon = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Gender => _Gender;

  static set Gender(String value) {
    _Gender = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static double get Height => _Height;

  static set Height(double value) {
    _Height = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get DateOfBirth => _DateOfBirth;

  static set DateOfBirth(String value) {
    _DateOfBirth = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static int get Age => _Age;

  static set Age(int value) {
    _Age = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static List<String> get DocumentImgs => _DocumentImgs;

  static set DocumentImgs(List<String> value) {
    _DocumentImgs = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static File? _PersonalLiveImgUrl;
  static String _UploadedPersonalLiveImageUrl = "";

  static File? get PersonalLiveImgUrl => _PersonalLiveImgUrl;

  static set PersonalLiveImgUrl(File? value) {
    _PersonalLiveImgUrl = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get UploadedPersonalLiveImageUrl =>
      _UploadedPersonalLiveImageUrl;

  static set UploadedPersonalLiveImageUrl(String value) {
    _UploadedPersonalLiveImageUrl = value;
    print("The Data is seted as" + value.toString());
  }

  static List<String> get ProfileImgs => _ProfileImgs;

  static set ProfileImgs(List<String> value) {
    _ProfileImgs = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static List<String> get UploadedProfileImageUrls => _UploadedProfileImageUrls;

  static set UploadedProfileImageUrls(List<String> value) {
    _UploadedProfileImageUrls = value;
    print("The Data is seted as" + value.toString());
  }

  static List<String> get UploadedDocumentImageUrls =>
      _UploadedDocumentImageUrls;

  static set UploadedDocumentImageUrls(List<String> value) {
    _UploadedDocumentImageUrls = value;
    print("The Data is seted as" + value.toString());
  }

  static String get userID => _userID;

  static set userID(String value) {
    _userID = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get userDeviceToken => _userDeviceToken;

  static set userDeviceToken(String value) {
    _userDeviceToken = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get Residence => _Residence;

  static set Residence(String value) {
    _Residence = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get AbroadState => _AbroadState;

  static set AbroadState(String value) {
    _AbroadState = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get AbroadCity => _AbroadCity;

  static set AbroadCity(String value) {
    _AbroadCity = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get AbroadCountry => _AbroadCountry;

  static set AbroadCountry(String value) {
    _AbroadCountry = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get NationalityState => _NationalityState;

  static set NationalityState(String value) {
    _NationalityState = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get NationalityCity => _NationalityCity;

  static set NationalityCity(String value) {
    _NationalityCity = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get NationalityCountry => _NationalityCountry;

  static set NationalityCountry(String value) {
    _NationalityCountry = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get PhoneNumber => _PhoneNumber;

  static set PhoneNumber(String value) {
    _PhoneNumber = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static set Email(String value) {
    _Email = value;
    print("The Data is seted as" + value.toString());
    print("The Data is seted as" + value.toString());
  }

  static String get JobCountry => _JobCountry;

  static set JobCountry(String value) {
    _JobCountry = value;
    print("The Data is seted as" + value.toString());
  }

  static String get Field => _Field;

  static set Field(String value) {
    _Field = value;
    print("The Data is seted as" + value.toString());
  }

  static String get EducationDiscription => _EducationDiscription;

  static set EducationDiscription(String value) {
    _EducationDiscription = value;
    print("The Data is seted as" + value.toString());
  }

  static String get DisabilityDis => _DisabilityDis;

  static set DisabilityDis(String value) {
    _DisabilityDis = value;
    print("The Data is seted as" + value.toString());
  }

  static String get DisabilityShareWith => _DisabilityShareWith;

  static set DisabilityShareWith(String value) {
    _DisabilityShareWith = value;
    print("The Data is seted as" + value.toString());
  }

  static String get bodyType => _bodyType;

  static set bodyType(String value) {
    _bodyType = value;
    print("The Data is seted as" + value.toString());
  }

  static String get HasChilderen => _HasChilderen;

  static set HasChilderen(String value) {
    _HasChilderen = value;
    print("The Data is seted as" + value.toString());
  }

  static int get NoOfChilderens => _NoOfChilderens;

  static set NoOfChilderens(int value) {
    _NoOfChilderens = value;
    print("The Data is seted as" + value.toString());
  }

  static String get liveWithYou => _liveWithYou;

  static set liveWithYou(String value) {
    _liveWithYou = value;
    print("The Data is seted as" + value.toString());
  }
}
