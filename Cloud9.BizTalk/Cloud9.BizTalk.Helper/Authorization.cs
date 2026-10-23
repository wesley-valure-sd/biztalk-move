using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using RestSharp;
using RestSharp.Authenticators;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Security.Claims;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    public static class Authorization
    {
        public static string GetOktaBearerToken()
        {
            //read values from sso
            string issuer = SSOClientHelper.getIssuer(); 
            string clientId = SSOClientHelper.getClientId(); 
            string clientSecret = SSOClientHelper.getClientSecret();
            string username = SSOClientHelper.getUserName();
            string password = SSOClientHelper.getPassword();
            string redirectUri = SSOClientHelper.getRedirectUri();
            string state = SSOClientHelper.getState();
            string scope = SSOClientHelper.getScope();
            string audience = SSOClientHelper.getAudience();

            string sessionToken = GetOktaSessionToken(username, password);
            string authorizationCode = GetOktaAuthorizationCode(issuer, clientId, redirectUri, scope, state, sessionToken);
            string token = GetOktaAccessToken(issuer, clientId, clientSecret, authorizationCode, redirectUri);
            //string userFromToken = GetUserInformationFromToken(issuer, audience, token);

            return token;

        }


        private static string GetOktaSessionToken(string username, string password)
        {
            string authUri = "https://pacificdental.okta.com/api/v1/authn";

            string returnValue = string.Empty;
            var client = new RestClient(authUri);
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            client.AddDefaultHeader("Accept", "application/json");
            client.AddDefaultHeader("Content-Type", "application/json");
            var request = new RestRequest(Method.POST) { RequestFormat = DataFormat.Json };
            request.AddJsonBody(new { username, password });
            var response = client.Execute(request);

            if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                var status = json.status;

                if (status == "SUCCESS")
                    returnValue = json.sessionToken;
            }

            return returnValue;
        }

        private static string GetOktaAuthorizationCode(string issuer, string clientId, string redirectUri, string scope, string state, string sessionToken)
        {
            string returnValue = string.Empty;
            var client = new RestClient(issuer);
            string endpoint = "v1/authorize";
            var request = new RestRequest(endpoint, Method.GET, DataFormat.None);
            request.AddQueryParameter("client_id", clientId, false);
            request.AddQueryParameter("response_type", "code", false);
            request.AddQueryParameter("scope", "openid", false);
            request.AddQueryParameter("redirect_uri", redirectUri, true);
            request.AddQueryParameter("state", state, false);
            request.AddQueryParameter("sessionToken", sessionToken, false);
            var response = client.Execute(request);

            if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                string query = response.ResponseUri.Query;

                if (!string.IsNullOrEmpty(query))
                {
                    int start = query.IndexOf("?code=") + 6;
                    int end = query.IndexOf("&", start);
                    returnValue = query.Substring(start, end - start);
                }
            }

            return returnValue;
        }

        private static string GetOktaAccessToken(string issuer, string clientId, string clientSecret, string authorizationCode, string redirectUri)
        {
            string returnValue = string.Empty;
            var client = new RestClient(issuer);
            string endpoint = "v1/token";
            client.AddDefaultHeader("Accept", "application/json");
            client.AddDefaultHeader("Content-Type", "application/x-www-form-urlencoded");
            client.Authenticator = new HttpBasicAuthenticator(clientId, clientSecret);
            var request = new RestRequest(endpoint, Method.POST, DataFormat.None);
            request.AddParameter("grant_type", "authorization_code", ParameterType.GetOrPost);
            request.AddParameter("redirect_uri", redirectUri, ParameterType.GetOrPost);
            request.AddParameter("code", authorizationCode, ParameterType.GetOrPost);
            var response = client.Execute(request);

            if (response != null && response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                dynamic json = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
                string access_token = json.access_token;

                if (!string.IsNullOrEmpty(access_token))
                    returnValue = access_token;
            }

            return returnValue;
        }

        private static string GetUserInformationFromToken(string issuer, string audience, string accessToken)
        {
            string returnValue = string.Empty;
            var configurationManager = new ConfigurationManager<OpenIdConnectConfiguration>($"{issuer}/.well-known/oauth-authorization-server", new OpenIdConnectConfigurationRetriever());
            OpenIdConnectConfiguration openIdConfig = configurationManager.GetConfigurationAsync(CancellationToken.None).Result;

            TokenValidationParameters validationParameters =
                new TokenValidationParameters
                {
                    ValidIssuer = issuer,
                    ValidAudiences = new[] { audience },
                    IssuerSigningKeys = openIdConfig.SigningKeys
                };

            JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();
            SecurityToken validatedAccessToken;
            var userInfo = handler.ValidateToken(accessToken, validationParameters, out validatedAccessToken);

            if (userInfo != null && userInfo.Identity.IsAuthenticated)
                returnValue = userInfo.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;

            return returnValue;
        }
    }
}
