using Cloud9.BizTalk.Helper.APIItems;
using RestSharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    public class OutboundAPI
    {
        private static string PDSUri = SSOClientHelper.getPDSUri();

        public static string SendPatientGUID(string xCorrelationId, Guid patGUID)
        {
            try
            {
                TransmissionItem patientTransmissionItem = new TransmissionItem
                {
                    EntityType = "Patienttest",
                    SourceSystem = "PDS",
                    SourceId = xCorrelationId,
                    DestinationSystem = "CLOUD9",
                    DestinationSystemId = patGUID.ToString(),
                    DestinationId = "PatientID"
                };

                var token = Authorization.GetOktaBearerToken();

                string returnValue = string.Empty;
                var client = new RestClient(PDSUri + "patient");
                client.AddDefaultHeader("Authorization", "Bearer " + token);
                client.AddDefaultHeader("Content-Type", "application/json");
                client.AddDefaultHeader("x_correlationid", xCorrelationId);
                var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
                request.AddJsonBody(patientTransmissionItem);
                var response = client.Execute(request);

                if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                    var message = json["ACK Message"];

                    return "X-Correlation-Id: " + xCorrelationId + Environment.NewLine + "PatGUID: " + patGUID.ToString() + Environment.NewLine + "API Response:" + Environment.NewLine + json.ToString();

                    //TODO: Handle different response messages

                }
                else
                {
                    return "Unexpected Response: " + response.StatusCode + " " + response.StatusDescription;
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public static string SendProviderInformation(string xCorrelationId, Guid providerGUID, string pICIMSProviderId, string locationId)
        {
            try
            {
                TransmissionItem patientTransmissionItem = new TransmissionItem
                {
                    EntityType = "ProviderTest",
                    SourceSystem = "PDS",
                    SourceId = xCorrelationId,
                    DestinationSystem = "CLOUD9",
                    DestinationSystemId = providerGUID.ToString(),
                    DestinationId = "ProviderID",
                    iCIMSProviderId = pICIMSProviderId,
                    LocationId = locationId
                };

                var token = Authorization.GetOktaBearerToken();

                string returnValue = string.Empty;
                var client = new RestClient(PDSUri + "provider");
                client.AddDefaultHeader("Authorization", "Bearer " + token);
                client.AddDefaultHeader("Content-Type", "application/json");
                client.AddDefaultHeader("x_correlationid", xCorrelationId);
                var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
                request.AddJsonBody(patientTransmissionItem);
                var response = client.Execute(request);

                if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                    var message = json["ACK Message"];

                    return "X-Correlation-Id: " + xCorrelationId + Environment.NewLine + "ProviderGUID: " + providerGUID.ToString() + Environment.NewLine + "API Response:" + Environment.NewLine + json.ToString();

                    //TODO: C9-27393 - PDS Outbound Failure Response Handling
                }
                else
                {
                    return "Unexpected Response: " + response.StatusCode + " " + response.StatusDescription;
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }

        public static string SendLocationGUID(string xCorrelationId, Guid locationGUID)
        {
            try
            {
                TransmissionItem patientTransmissionItem = new TransmissionItem
                {
                    EntityType = "LocationTest",
                    SourceSystem = "PDS",
                    SourceId = xCorrelationId,
                    DestinationSystem = "CLOUD9",
                    DestinationSystemId = locationGUID.ToString(),
                    DestinationId = "LocationID"
                };

                var token = Authorization.GetOktaBearerToken();

                string returnValue = string.Empty;
                var client = new RestClient(PDSUri + "location");
                client.AddDefaultHeader("Authorization", "Bearer " + token);
                client.AddDefaultHeader("Content-Type", "application/json");
                client.AddDefaultHeader("x_correlationid", xCorrelationId);
                var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
                request.AddJsonBody(patientTransmissionItem);
                var response = client.Execute(request);

                if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                    var message = json["ACK Message"];

                    return "X-Correlation-Id: " + xCorrelationId + Environment.NewLine + "LocationGUID: " + locationGUID.ToString() + Environment.NewLine + "API Response:" + Environment.NewLine + json.ToString();

                    //TODO: C9-27393 - PDS Outbound Failure Response Handling
                }
                else
                {
                    return "Unexpected Response: " + response.StatusCode + " " + response.StatusDescription;
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }

        public static string SendException(string xCorrelationId, string exception)
        {
            try
            {
                ExceptionItem patientTransmissionItem = new ExceptionItem
                {
                    EntityType = "PatientException",
                    SourceSystem = "PDS",
                    SourceId = xCorrelationId,
                    DestinationSystem = "CLOUD9",
                    //DestinationSystemId = patGUID,
                    DestinationId = "PatientID",
                    ExceptionMessage = exception
                };

                var token = Authorization.GetOktaBearerToken();

                string returnValue = string.Empty;
                var client = new RestClient(PDSUri + "exception");
                client.AddDefaultHeader("Authorization", "Bearer " + token);
                client.AddDefaultHeader("Content-Type", "application/json");
                client.AddDefaultHeader("x_correlationid", xCorrelationId);
                var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
                request.AddJsonBody(patientTransmissionItem);
                var response = client.Execute(request);

                if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                    var message = json["ACK Message"];

                    return "X-Correlation-Id: " + xCorrelationId + Environment.NewLine + "Exception: " + exception + Environment.NewLine + "API Response:" + Environment.NewLine + json.ToString();
                        
                    //TODO: C9-27393 - PDS Outbound Failure Response Handling
                }
                else
                {
                    return "Unexpected Response: " + response.StatusCode + " " + response.StatusDescription;
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }
        public static string SendMDMToPDS(string MDMMessage)
        {
            try
            {
                MDMTransmissionItem mdmTransmissionItem = new MDMTransmissionItem
                {
                    messageType = "MDM^T02",
                    messageContents = MDMMessage
                };

                var token = Authorization.GetOktaBearerToken();

                string returnValue = string.Empty;
                var uriStr = PDSUri + "hl7" ;
                var client = new RestClient(PDSUri + "hl7");
                client.AddDefaultHeader("Authorization", "Bearer " + token);
                client.AddDefaultHeader("Content-Type", "application/json");
                client.AddDefaultHeader("x_correlationid", System.Guid.NewGuid().ToString());

                var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
                request.AddJsonBody(mdmTransmissionItem);
                var response = client.Execute(request);

                if (response != null)
                {
                    dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                    if (response.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        var message = json["ACK Message"];

                        return "API Response:" + Environment.NewLine + json.ToString();
                    }
                    else
                    {
                        return "Unexpected Response: " + response.StatusCode + " " + response.StatusDescription + Environment.NewLine + json.ToString(); ;
                    }
                }
                else
                    return "NULL Response: SendMDMToPDS.";

            }
            catch (Exception ex)
            {
                throw ex;
            }

        }
    }
}
