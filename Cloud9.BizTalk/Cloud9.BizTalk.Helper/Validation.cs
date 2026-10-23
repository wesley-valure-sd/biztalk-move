using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Schema;

namespace Cloud9.BizTalk.Helper
{
    public static class Validation
    {
        public static XmlDocument ValidateClaimXML(XmlDocument xml)
        {
            const string ns0 = "http://schemas.microsoft.com/Sql/2008/05/TypedProcedures/BTS";
            const string ns1 = "http://schemas.microsoft.com/Sql/2008/05/Types/TableTypes/BTS";

            //create output structure
            XmlDocument errorList = new XmlDocument();
            XmlSchema ns0Schema = new XmlSchema();
            XmlSchema ns1Schema = new XmlSchema();
            ns0Schema.Namespaces.Add("ns0", ns0);
            ns1Schema.Namespaces.Add("ns1", ns1);
            errorList.Schemas.Add(ns0Schema);
            errorList.Schemas.Add(ns1Schema);

            XmlElement root = (XmlElement)errorList.AppendChild(errorList.CreateElement("ns0", "AddClaimErrors", ns0));
            XmlElement adaClaimNumber = (XmlElement)root.AppendChild(errorList.CreateElement("ns0", "adaclaimNumber", ns0));
            XmlElement messages = (XmlElement)root.AppendChild(errorList.CreateElement("ns0", "Messages", ns0));
            
            //parse input
            var nsmgr = new XmlNamespaceManager(xml.NameTable);
            nsmgr.AddNamespace("ns0", "http://schemas.microsoft.com/Sql/2008/05/ProceduresResultSets/BTS/QueueClaims");

            string claimNumber = xml.SelectSingleNode("//ns0:StoredProcedureResultSet0/ns0:adaclaimNumber", nsmgr).InnerText;
            adaClaimNumber.InnerText = claimNumber;
            string providerTaxId = "";

            var xmlNode = xml.SelectSingleNode("//ns0:StoredProcedureResultSet0/ns0:adaclaimBox51BillingDentistTIN", nsmgr);

            if (xmlNode != null)
                providerTaxId = xmlNode.InnerText;

            string patientBirthdate = "";
            xmlNode = xml.SelectSingleNode("//ns0:StoredProcedureResultSet0/ns0:adaclaimBox21PatientDOB", nsmgr);
            if (xmlNode != null)
                patientBirthdate = xmlNode.InnerText;

            string address = "";
            xmlNode = xml.SelectSingleNode("//ns0:StoredProcedureResultSet0/ns0:adaclaimBox48BillingDentistInfo", nsmgr);
            if (xmlNode != null)
                address = xmlNode.InnerText;

            string pracTIN = "";
            xmlNode = xml.SelectSingleNode("//ns0:StoredProcedureResultSet0/ns0:pracTIN", nsmgr);
            if (xmlNode != null)
                pracTIN = xmlNode.InnerText;

            string address1 = ParseNameAddressBox.GetAddress1(address);
            string city = ParseNameAddressBox.GetCity(address);
            string state = ParseNameAddressBox.GetState(address);
            string zipcode = ParseNameAddressBox.GetZipcode(address);

            List<Tuple<string,string>> errorCodeList = new List<Tuple<string,string>>();
            if (string.IsNullOrWhiteSpace(address1) || string.IsNullOrWhiteSpace(city) || string.IsNullOrWhiteSpace(state) || string.IsNullOrWhiteSpace(zipcode))
            {
                errorCodeList.Add(new Tuple<string, string>("0125", "PROVIDER MAILING ADDRESS IS INVALID / INCOMPLETE"));
            }

            if (string.IsNullOrWhiteSpace(providerTaxId))
            {
                errorCodeList.Add(new Tuple<string, string>("0103", "PROVIDER TAX ID NUMBER IS INVALID"));
            }

            if (string.IsNullOrWhiteSpace(patientBirthdate))
            {
                errorCodeList.Add(new Tuple<string, string>("0228", "INSURED''S BIRTHDATE INVALID"));
            }

            if (string.IsNullOrWhiteSpace(pracTIN))
            {
                errorCodeList.Add(new Tuple<string, string>("0431", "SUBMITTER TAX ID INVALID"));
            }

            if (errorCodeList.Any())
            {
                
                foreach (var errorCode in errorCodeList)
                {
                    XmlElement messageList = (XmlElement)messages.AppendChild(errorList.CreateElement("ns1", "MessageListTableType", ns1));
                    XmlElement code = (XmlElement)messageList.AppendChild(errorList.CreateElement("ns1", "Code", ns1));
                    XmlElement message = (XmlElement)messageList.AppendChild(errorList.CreateElement("ns1", "Message", ns1));
                    code.InnerText = errorCode.Item1;
                    message.InnerText = errorCode.Item2;
                }
                
            }
            
            return errorList;
        }
    }
}
