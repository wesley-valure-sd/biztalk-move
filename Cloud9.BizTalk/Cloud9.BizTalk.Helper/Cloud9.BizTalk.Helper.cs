using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Microsoft.XLANGs.BaseTypes;
using System.Xml;
using System.Collections;
using System.Configuration;
using System.Collections.Specialized;

namespace Cloud9.BizTalk.Helper
{
    public partial class Conversion
    {
        public static string GetString(XLANGMessage msg)
        {
            StreamReader reader = new StreamReader((Stream)msg[0].RetrieveAs(typeof(Stream)));
            string retval = reader.ReadToEnd();

            return retval;
        }

        public static void SetXMLNode(System.Xml.XmlDocument outerMsg, System.String nodeXpath, System.String strInnerXmlStr)
        {
            try
            {
                XmlNode node = outerMsg.SelectSingleNode(nodeXpath);
                node.InnerXml = strInnerXmlStr;
            }
            catch (System.Exception exc)
            {
            }
        }
    }
    public partial class Configuration
    {
        public static string GetConfiguration(string section, string key)
        {
            string configVal = "" ;

            var configSection = ConfigurationManager.GetSection(section) as NameValueCollection;
            if (configSection != null)
            {
                configVal = configSection[key].ToString();
            }

            return configVal;
        }
    }
}
