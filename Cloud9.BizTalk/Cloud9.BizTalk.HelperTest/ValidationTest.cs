using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Cloud9.BizTalk.Helper;
using System.Xml;

namespace Cloud9.BizTalk.HelperTest
{
    [TestClass]
    public class ValidationTest
    {
        string xml;

        [TestInitialize]
        public void Setup()
        {
            xml = @"<StoredProcedureResultSet0 xmlns=""http://schemas.microsoft.com/Sql/2008/05/ProceduresResultSets/BTS/QueueClaims""><adaclaimGUID>d79ec66c-b115-4f72-b635-859383b256a9</adaclaimGUID><adaclaimStatus>New</adaclaimStatus><adaclaimDateTime>2019-05-03T00:00:00Z</adaclaimDateTime><adaclaimBox1TransactionTypeActualService>true</adaclaimBox1TransactionTypeActualService><adaclaimBox1TransactionTypePredetermination>false</adaclaimBox1TransactionTypePredetermination><adaclaimBox1TransactionTypeEPSDT>false</adaclaimBox1TransactionTypeEPSDT><adaclaimBox3InsuranceCompanyInformation>Alpha
78 Cemetery Street
Salinas, CA 93901</adaclaimBox3InsuranceCompanyInformation><adaclaimBox4OtherCoverageMedical>true</adaclaimBox4OtherCoverageMedical><adaclaimBox4OtherCoverageDental>true</adaclaimBox4OtherCoverageDental><adaclaimBox5OtherSubscriberName>Claimtest1, Rebeca M</adaclaimBox5OtherSubscriberName><adaclaimBox6OtherSubscriberDOB>1985-01-01T00:00:00Z</adaclaimBox6OtherSubscriberDOB><adaclaimBox8OtherSubscriberID>123-45-6789</adaclaimBox8OtherSubscriberID><adaclaimBox9OtherPlanGroupNumber>G0001</adaclaimBox9OtherPlanGroupNumber><adaclaimBox10OtherPatientRelationshipSelf>false</adaclaimBox10OtherPatientRelationshipSelf><adaclaimBox10OtherPatientRelationshipSpouse>false</adaclaimBox10OtherPatientRelationshipSpouse><adaclaimBox10OtherPatientRelationshipDependent>true</adaclaimBox10OtherPatientRelationshipDependent><adaclaimBox10OtherPatientRelationshipOther>false</adaclaimBox10OtherPatientRelationshipOther><adaclaimBox11OtherInsurancePlanInfo>Dental 1
1000 Elm Street
Bigcity, GA 10001</adaclaimBox11OtherInsurancePlanInfo><adaclaimBox12SubscriberInfo>Claimtest1, Fther B
1000 Main Street
Alpharetta, GA 30005</adaclaimBox12SubscriberInfo><adaclaimBox13SubscriberDOB>1980-05-03T00:00:00Z</adaclaimBox13SubscriberDOB><adaclaimBox14SubscriberGender>M</adaclaimBox14SubscriberGender><adaclaimBox15SubscriberID>T000000001</adaclaimBox15SubscriberID><adaclaimBox16PlanGroupNumber>IM1234</adaclaimBox16PlanGroupNumber><adaclaimBox17EmployerName /><adaclaimBox18PatientRelationshipSelf>false</adaclaimBox18PatientRelationshipSelf><adaclaimBox18PatientRelationshipSpouse>false</adaclaimBox18PatientRelationshipSpouse><adaclaimBox18PatientRelationshipDependent>true</adaclaimBox18PatientRelationshipDependent><adaclaimBox18PatientRelationshipOther>false</adaclaimBox18PatientRelationshipOther><adaclaimBox19PatientStudentStatusFT>false</adaclaimBox19PatientStudentStatusFT><adaclaimBox19PatientStudentStatusPT>false</adaclaimBox19PatientStudentStatusPT><adaclaimBox20PatientInfo>Claimtest1, Testclaim A
1000 Main Street
Alpharetta, GA 30005                                                                                                                                                                                           </adaclaimBox20PatientInfo><adaclaimBox7OtherSubscriberGenderMale>false</adaclaimBox7OtherSubscriberGenderMale><adaclaimBox7OtherSubscriberGenderFemale>true</adaclaimBox7OtherSubscriberGenderFemale><adaclaimBox14SubscriberGenderMale>true</adaclaimBox14SubscriberGenderMale><adaclaimBox14SubscriberGenderFemale>false</adaclaimBox14SubscriberGenderFemale><adaclaimBox21PatientDOB>2000-05-03T00:00:00Z</adaclaimBox21PatientDOB><adaclaimBox22PatientGenderMale>true</adaclaimBox22PatientGenderMale><adaclaimBox22PatientGenderFemale>false</adaclaimBox22PatientGenderFemale><adaclaimBox23PatientAccountID>1905301A</adaclaimBox23PatientAccountID><adaclaimBox31aOtherFee1>10.0000</adaclaimBox31aOtherFee1><adaclaimBox32TotalFee>125.0000</adaclaimBox32TotalFee><adaclaimBox34DiagnosisCodeListQualifier>AB</adaclaimBox34DiagnosisCodeListQualifier><adaclaimBox34aDiagonosisCodeA>D0101</adaclaimBox34aDiagonosisCodeA><adaclaimBox34aDiagonosisCodeB>D0102</adaclaimBox34aDiagonosisCodeB><adaclaimBox35Remarks>remarks in box 35</adaclaimBox35Remarks><adaclaimBox36Signature>SIGNATURE ON FILE</adaclaimBox36Signature><adaclaimBox36SignatureDate>2019-05-03T00:00:00Z</adaclaimBox36SignatureDate><adaclaimBox37Signature>SIGNATURE ON FILE</adaclaimBox37Signature><adaclaimBox37SignatureDate>2019-05-03T00:00:00Z</adaclaimBox37SignatureDate><adaclaimBox38PlaceOfTreatment>11</adaclaimBox38PlaceOfTreatment><adaclaimBox40TreatmentForOrthodonticsNo>false</adaclaimBox40TreatmentForOrthodonticsNo><adaclaimBox40TreatmentForOrthodonticsYes>true</adaclaimBox40TreatmentForOrthodonticsYes><adaclaimBox41DateAppliancesPlaced>2019-05-03T00:00:00Z</adaclaimBox41DateAppliancesPlaced><adaclaimBox42MonthsTreatmentRemaining>3</adaclaimBox42MonthsTreatmentRemaining><adaclaimBox43ReplacementOfProsthesisNo>false</adaclaimBox43ReplacementOfProsthesisNo><adaclaimBox43ReplacementOfProsthesisYes>true</adaclaimBox43ReplacementOfProsthesisYes><adaclaimBox45TreatmentResultingFromOccupationalInjury>false</adaclaimBox45TreatmentResultingFromOccupationalInjury><adaclaimBox45TreatmentResultingFromAutoAccident>false</adaclaimBox45TreatmentResultingFromAutoAccident><adaclaimBox45TreatmentResultingFromOtherAccident>false</adaclaimBox45TreatmentResultingFromOtherAccident><adaclaimBox48BillingDentistInfo>Dr.Alex Bale
1234 Test Street
Cumming, GA 30028</adaclaimBox48BillingDentistInfo><adaclaimBox49BillingDentistNPI /><adaclaimBox50BillingDentistLicenseNumber /><adaclaimBox52BillingDentistPhone>(404) 802-8884</adaclaimBox52BillingDentistPhone><adaclaimBox53TreatingDentistSignature>Dr.Alex Bale</adaclaimBox53TreatingDentistSignature><adaclaimBox53TreatingDentistSignatureDate>2019-05-03T00:00:00Z</adaclaimBox53TreatingDentistSignatureDate><adaclaimBox54TreatingDentistNPI /><adaclaimBox55TreatingDentistLicenseNumber /><adaclaimBox56TreatingDentistInfo>1234 Test Street
Cumming, GA 30028</adaclaimBox56TreatingDentistInfo><adaclaimBox56ATreatingDentistProviderSpecialtyCode>ORT</adaclaimBox56ATreatingDentistProviderSpecialtyCode><adaclaimBox57TreatingDentistPhone>(404) 802-8884</adaclaimBox57TreatingDentistPhone><adaclaimType>One-Time</adaclaimType><adaclaimTotal>125.0000</adaclaimTotal><adaclaimSelected>false</adaclaimSelected><adaclaimLastModified>2019-05-14T15:14:38.237Z</adaclaimLastModified><adaclaimNumber>2</adaclaimNumber><orgName>Amanda Mercer And Diana Do-Yabut Dental Corporation</orgName><pracEmdeonIsTest>1</pracEmdeonIsTest><pracIsBillingEntity>0</pracIsBillingEntity><pracTIN /><pracProviderNumber /><pracLicenseNumber /><persGender>Male</persGender><msCode>M</msCode></StoredProcedureResultSet0>";

        }

        [TestMethod]
        public void TestValidateClaimXML()
        {
            try
            {
                XmlDocument xmlDoc = new XmlDocument();
                xmlDoc.LoadXml(xml);

                XmlDocument result = Validation.ValidateClaimXML(xmlDoc);

                var resultString = result.InnerXml;
            }
            catch(Exception e)
            {
                Assert.Fail(e.Message);
            }
        }
    }
}
