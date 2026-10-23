using System;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using Cloud9.HL7.WebAPI.DTO;
using System.Text;
using Cloud9.HL7.BLL.Managers;
using Cloud9.HL7.BLL.Items;
using System.Net;
using Newtonsoft.Json;
using Cloud9.HL7.BLL.Shared;

namespace Cloud9.HL7.WebAPI.Controllers
{
    public class IncomingMessagesController : ApiController
    {
        private string _correlationId;

        // POST: api/IncomingMessages
        [ResponseType(typeof(string))]
        public IHttpActionResult PostIncomingMessage(IncomingMessageDTO data)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (!Request.Headers.Contains("X-Correlation-ID") || string.IsNullOrWhiteSpace(Request.Headers.GetValues("X-Correlation-Id").FirstOrDefault()))
                {
                    return Content(HttpStatusCode.BadRequest, "X-Correlation-ID is required.");
                }
                else if (String.IsNullOrWhiteSpace(data.MessageType) || String.IsNullOrWhiteSpace(data.MessageContents) || String.IsNullOrWhiteSpace(data.UserName) || String.IsNullOrWhiteSpace(data.Password))
                {
                    return Content(HttpStatusCode.BadRequest, "Message is incomplete.");
                }

                else
                {
                    _correlationId = Request.Headers.GetValues("X-Correlation-Id").FirstOrDefault();

                    var authenticationCode = PartnerAuthenticationManager.AuthenticateUser(data.UserName, data.Password);

                    if (authenticationCode == (int)AuthenticationResponseCode.Authenticated)
                    {
                        var incomingMessage = (new IncomingMessageItem
                        {
                            CorrelationId = _correlationId,
                            VendorUserName = data.UserName,
                            MessageType = data.MessageType,
                            MessageContents = data.MessageContents,
                            Status = 0,
                            ProcessImmediately = data.ProcessImmediately ?? false,
                            ReceivedTime = DateTime.Now,
                            PracticeGUID = data.PracticeGUID,
                            PatientGUID = data.PatientGUID
                        });

                        var incomingMessageId = IncomingMessageManager.SaveIncomingMessage(incomingMessage);

                        return Content(HttpStatusCode.OK, incomingMessageId);
                    }
                    else if ((authenticationCode == (int)AuthenticationResponseCode.InvalidCredentials) || (authenticationCode == (int)AuthenticationResponseCode.PartnerArchivedOrHasNoClients))
                    {
                        return Content(HttpStatusCode.Forbidden, "Invalid Credentials.");
                    }
                    else if (authenticationCode == (int)AuthenticationResponseCode.NotWhitelisted)
                    {
                        return Content(HttpStatusCode.Forbidden, "Request not permitted outside of allowance window.");
                    }
                    else
                    {
                        return Content(HttpStatusCode.Forbidden, "Could not authorize request. Response code:" + authenticationCode.ToString());
                    }
                }
            }
            catch(Exception ex)
            {
                string requestBody = JsonConvert.SerializeObject(data, Formatting.None, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
                LogManager.LogException("IncomingMessage", ex, Request.ToString() + requestBody, _correlationId);
                return Content(HttpStatusCode.InternalServerError, "An error occurred processing the message."); ;
            }
        }
    }
}