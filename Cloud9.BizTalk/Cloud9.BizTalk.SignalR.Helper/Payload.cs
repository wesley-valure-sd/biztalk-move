using System;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Web.Security;
using System.Web;
using System.IO;

namespace Cloud9.BizTalk.SignalR.Helper
{
    public static class Payload
    {
        /// <summary>
        /// This function invokes server signalr function for update-schedule
        /// </summary>
        /// <param name="apptGUID">guid for appointment</param>
        /// <param name="schvwGUID">guid for scheduled view</param>
        public static string GetAppointmentChanged(string apptGUID, string schvwGUID)
        {
            string PayloadHexEncoded = "";
            try
            {
                byte[] PayloadByteArray = null;

                using (var SignalRMemStream = new MemoryStream())
                {
                    string Source = "5b41d043-a3f2-42be-8b40-783d8b1ca64d";
                    string Key = "hg-c9Hub.ccdb0a0e-463e-44d8-b819-0579e492c567";
                    bool WaitForAck = false;
                    bool IsAck = false;
                    string Filter = "";
                    string CommandId = "";

                    string Message = "{\"H\":\"c9Hub\",\"M\":\"appointmentChanged\",\"A\":[\"<apptguid>\",\"<schvwGUID>\"]}";
                    // String.Format does not play well with the { in the base message. Using Replace instead
                    Message = Message.Replace("<apptguid>", apptGUID.ToLower());
                    Message = Message.Replace("<schvwGUID>", schvwGUID.ToLower());

                    var MessageByteArray = new ArraySegment<byte>(Encoding.ASCII.GetBytes(Message));

                    var SignalRBinaryWriter = new BinaryWriter(SignalRMemStream);
                    SignalRBinaryWriter.Write(1);
                    SignalRBinaryWriter.Write(Source);
                    SignalRBinaryWriter.Write(Key);
                    Int32 ByteLen = MessageByteArray.Count;
                    SignalRBinaryWriter.Write(ByteLen);
                    SignalRBinaryWriter.Write(MessageByteArray.Array, MessageByteArray.Offset, MessageByteArray.Count);
                    SignalRBinaryWriter.Write(CommandId ?? String.Empty);
                    SignalRBinaryWriter.Write(WaitForAck);
                    SignalRBinaryWriter.Write(IsAck);
                    SignalRBinaryWriter.Write(Filter ?? String.Empty);
                    DateTime ServerCreationTime = DateTime.UtcNow;
                    SignalRBinaryWriter.Write(ServerCreationTime.Ticks);

                    PayloadByteArray = SignalRMemStream.ToArray();
                    PayloadHexEncoded = "0x";

                    foreach (byte x in PayloadByteArray)
                    {
                        PayloadHexEncoded += x.ToString("X2");
                    }
                }
            }
            catch (Exception ex)
            {
                if (!EventLog.SourceExists("BizTalk SignalR Helper"))
                {
                    EventLog.CreateEventSource("BizTalk SignalR Helper", "Application");
                }

                EventLog myLog = new EventLog();
                myLog.Source = "BizTalk SignalR Helper";
                myLog.WriteEntry("Send Signalr exception: " + ex.Message, EventLogEntryType.Error);
                PayloadHexEncoded = "";
            }

            return PayloadHexEncoded;
        }
    }
}
