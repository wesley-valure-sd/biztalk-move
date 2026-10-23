using System.Collections;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using Microsoft.BizTalk.Streaming;
using Microsoft.XLANGs.BaseTypes;
using Microsoft.XLANGs.Core;
using System;
using System.Xml.Linq;

namespace Cloud9.BizTalk.Helper
{
    public class SHelpers
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

        /// <summary>
        /// Create an HL7 XLANGMessage from a strings.
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
    }
}
