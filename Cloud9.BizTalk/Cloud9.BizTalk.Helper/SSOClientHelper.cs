using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{

    public class SSOClientHelper
    {
        private static string appName = "Cloud9.BizTalk";

        /// <summary>
        /// Read method helps get configuration data
        /// </summary>        
        /// <param name="appName">The name of the affiliate application to represent the configuration container to access</param>
        /// <param name="propName">The property name to read</param>
        /// <returns>
        ///  The value of the property stored in the given affiliate application of this component.
        /// </returns>
        public static string Read(string appName, string propName)
        {
            try
            {
                object propertyValue = SSOSettingsFileReader.ReadString(appName, propName);
                return (string)propertyValue;
            }
            catch (Exception e)
            {
                System.Diagnostics.Trace.WriteLine(e.Message);
                throw;
            }
        }

        public static string getIssuer()
        {
            return Read(appName, "PDSAPI.Issuer");
        }

        public static string getClientId()
        {
            return Read(appName, "PDSAPI.ClientId");
        }

        public static string getClientSecret()
        {
            return Read(appName, "PDSAPI.ClientSecret");
        }

        public static string getUserName()
        {
            return Read(appName, "PDSAPI.UserName");
        }

        public static string getPassword()
        {
            return Read(appName, "PDSAPI.Password");
        }

        public static string getRedirectUri()
        {
            return Read(appName, "PDSAPI.RedirectUri");
        }

        public static string getState()
        {
            return Read(appName, "PDSAPI.State");
        }

        public static string getScope()
        {
            return Read(appName, "PDSAPI.Scope");
        }

        public static string getAudience()
        {
            return Read(appName, "PDSAPI.Audience");
        }

        public static string getPDSUri()
        {
            return Read(appName, "PDSAPI.Uri");
        }

        public static string getLogAPIResponseSetting()
        {
            return Read(appName, "PDSAPI.LogAPIResponse");
        }

    }
}
