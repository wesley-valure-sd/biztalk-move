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
    public class LocationController : ApiController
    {
        // GET api/<controller>
        private string _correlationId;

        // POST: api/Location
        [ResponseType(typeof(string))]
        public IHttpActionResult PostLocation(LocationDTO data)
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
                else
                {
                    _correlationId = Request.Headers.GetValues("X-Correlation-Id").FirstOrDefault();

                    var authenticationCode = PartnerAuthenticationManager.AuthenticateUser(data.UserName, data.Password);

                    if (authenticationCode == (int)AuthenticationResponseCode.Authenticated)
                    {
                        if (!LocationManager.LocationExists(data.LocationName))
                        {
                            var locationId = LocationManager.SaveLocation(data.LocationName);

                            return Content(HttpStatusCode.OK, locationId);
                        }
                        else
                        {
                            return Content(HttpStatusCode.Conflict, "Location Name '" + data.LocationName + "' already in use.");
                        }
                        
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
            catch (Exception ex)
            {
                string requestBody = JsonConvert.SerializeObject(data, Formatting.None, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
                LogManager.LogException("Location", ex, Request.ToString() + requestBody, _correlationId);
                return Content(HttpStatusCode.InternalServerError, "An error occurred processing the message."); ;
            }
        }

        [ResponseType(typeof(string))]
        public IHttpActionResult GetLocationGuid(string locationName)
        {
            try
            {

                if (!Request.Headers.Contains("X-Correlation-ID") || string.IsNullOrWhiteSpace(Request.Headers.GetValues("X-Correlation-Id").FirstOrDefault()))
                {
                    return Content(HttpStatusCode.BadRequest, "X-Correlation-ID is required.");
                }
                else if (!Request.Headers.Contains("UserName") || !Request.Headers.Contains("Password"))
                {
                    return Content(HttpStatusCode.BadRequest, "Missing credentials.");
                }
                else
                {
                    _correlationId = Request.Headers.GetValues("X-Correlation-Id").FirstOrDefault();
                    var _userName = Request.Headers.GetValues("UserName").FirstOrDefault();
                    var _password = Request.Headers.GetValues("Password").FirstOrDefault();

                    var authenticationCode = PartnerAuthenticationManager.AuthenticateUser(_userName, _password);

                    if (authenticationCode == (int)AuthenticationResponseCode.Authenticated)
                    {
                        var locationId = LocationManager.GetLocationGuidByName(locationName);

                        if (locationId != Guid.Empty)
                        { 
                            return Content(HttpStatusCode.OK, locationId.ToString());
                        }
                        else
                        {
                            return Content(HttpStatusCode.BadRequest, "Location Name '" + locationName + "' not found.");
                        }

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
            catch (Exception ex)
            {
                LogManager.LogException("GetLocation", ex, Request.ToString(), _correlationId);
                return Content(HttpStatusCode.InternalServerError, "An error occurred processing the message."); ;
            }
        }
    }
}