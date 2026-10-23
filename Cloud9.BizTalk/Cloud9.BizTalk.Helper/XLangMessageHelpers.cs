using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;
using Microsoft.BizTalk.Streaming;
using Microsoft.XLANGs.BaseTypes;
using Microsoft.XLANGs.Core;
using Microsoft.BizTalk.XLANGs.BTXEngine;

namespace Cloud9.BizTalk.Helper
{
    public class XLangMessageHelpers
    {
        /// <summary>
        /// remove empty nodes from XLANG message
        /// </summary>
        /// <param name="msg">message to be cleaned up for empty nodes</param>
        /// <param name="part">part number</param>
        public static void RemoveEmptyNodes(XLANGMessage msg, int part = 0)
        {
            VirtualStream vts = new VirtualStream();
            XDocument xd = XDocument.Load((Stream)msg[part].RetrieveAs(typeof(Stream)));

            xd.Descendants()
                .Where(e => (e.Attributes().All(a => a.IsNamespaceDeclaration))
                                && string.IsNullOrWhiteSpace(e.Value))
                .Remove();

            xd.Save(vts);
            msg[part].LoadFrom(vts);
        }

        public static string CreateStringFromXLANGMessage(XLANGMessage message, int index)
        {
            string toReturn;

            try
            {
                // Get the message part as a Stream and create a reader which will read in the stream 
                using (var reader = new StreamReader(message[index].RetrieveAs(typeof(Stream)) as Stream))
                {
                    toReturn = reader.ReadToEnd();
                }
            }
            finally
            {
                message.Dispose();
            }

            return toReturn;
        }

        /// <summary>
        /// Create an HL7 XLANGMessage from a string.
        /// </summary>
        public static XLANGMessage CreateHL7MessageFromString(string message, string messageName, string messagePartName)
        {
            // The BTX message used to create the XLANGMessage later on
            var hl7BTXMessage = CreateHL7MessagePart(message, messageName, messagePartName);

            // Return the XLANGMessage
            return hl7BTXMessage.GetMessageWrapperForUserCode();
        }

        /// <summary>
        /// Create a new message part in the supplied CustomBTXMessage.
        /// </summary>
        private static HL7BTXMessage CreateHL7MessagePart(string message, string messageName, string messagePartName)
        {
            var stream = new MemoryStream();

            HL7BTXMessage customBTXMessage = new HL7BTXMessage(messageName, Service.RootService.XlangStore.OwningContext);

            var writer = new StreamWriter(stream);
            writer.Write(message);
            writer.Flush();
            stream.Seek(0, SeekOrigin.Begin);

            // Add message part
            customBTXMessage.AddPart(string.Empty, messagePartName);

            // Load the message we just created
            customBTXMessage[0].LoadFrom(stream);

            return customBTXMessage;
        }

        /// <summary>
        /// Create an HL7 XLANGMessage from a string.
        /// </summary>
        public static XLANGMessage CreateCustomBTXMessageFromString(string message, string messageName, string messagePartName)
        {
            // The BTX message used to create the XLANGMessage later on
            var customBTXMessage = CreateCustomMessagePart(message, messageName, messagePartName);

            // Return the XLANGMessage
            return customBTXMessage.GetMessageWrapperForUserCode();
        }

        /// <summary>
        /// Create a new message part in the supplied CustomBTXMessage.
        /// </summary>
        private static BTXMessage CreateCustomMessagePart(string message, string messageName, string messagePartName)
        {
            var stream = new MemoryStream();

            CustomBTXMessage customBTXMessage = new CustomBTXMessage(messageName, Service.RootService.XlangStore.OwningContext);

            var writer = new StreamWriter(stream);
            writer.Write(message);
            writer.Flush();
            stream.Seek(0, SeekOrigin.Begin);

            // Add message part
            customBTXMessage.AddPart(string.Empty, messagePartName);

            // Load the message we just created
            customBTXMessage[0].LoadFrom(stream);

            return customBTXMessage;
        }

        public static string GetReceiveLocationName(XLANGMessage message)
        {
            string result = "";

            XMessage xMsg = GetXMessage(message);

            if (xMsg != null)
            {
                result = xMsg.GetReceiveLocationName();
            }
            return result;
        }

        private static XMessage GetXMessage(XLANGMessage message)
        {
            XMessage result = null;

            try
            {
                foreach (Segment segment in Service.RootService._segments)
                {
                    IDictionary fields = Context.FindFields(typeof(XLANGMessage), segment.ExceptionContext);

                    foreach (DictionaryEntry field in fields)
                    {
                        XMessage msg = (field.Value as XMessage);

                        if (msg != null && String.Compare(msg.Name, message.Name) == 0)
                        {
                            result = msg;
                            break;
                        }
                    }

                    if (result != null)
                        break;
                }
            }
            catch (Exception /* e */)
            {
                // do not provoke failure
             }

            return result;
        }
    }

    public static class XMessageExtensionMethods
    {
        public static string ns = @"http://schemas.microsoft.com/BizTalk/2003/system-properties";

        public static string GetReceiveLocationName(this XMessage @this)
        {
            string property = "";
            Microsoft.XLANGs.BaseTypes.XmlQName qName = new Microsoft.XLANGs.BaseTypes.XmlQName("ReceiveLocationName", ns);

            if (@this.GetContextProperties().ContainsKey(qName))
            {
                // get the property from GetContextProperties
                property = @this.GetContextProperties()[qName].ToString();
            }
            else if (@this.GetContentProperties().ContainsKey(qName))
            {
                // get the property from GetContentProperties
                property = @this.GetContentProperties()[qName].ToString();
            }
            return property;
        }
    }
}
