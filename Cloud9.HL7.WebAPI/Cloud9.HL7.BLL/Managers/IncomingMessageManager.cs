using Cloud9.HL7.BLL.Constants;
using Cloud9.HL7.BLL.Items;
using Cloud9.HL7.DAL.BizTalkCloud9CommonEntities;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.HL7.BLL.Managers
{
    public class IncomingMessageManager
    {

        public static string SaveIncomingMessage(IncomingMessageItem incomingMessage)
        {
            try
            {
                using (var db = new BizTalkCloud9CommonEntities())
                {
                    Guid newImGUID = Guid.NewGuid();
                    int msgStatus = incomingMessage.Status ;

                    if (incomingMessage.MessageType == MessageType.EligibilityResponse)
                    {
                        string outputPath = ConfigurationSettings.AppSettings[AppConfigKey.OutputPath271];
                        string outputFile = outputPath + newImGUID.ToString() + ".edi";
                        File.WriteAllText(outputFile, incomingMessage.MessageContents);
                        msgStatus = Status.Processed;
                    }

                    var newMessage = new IncomingMessage
                    {
                        imGUID = newImGUID,
                        imCorrelationId = incomingMessage.CorrelationId,
                        imVendorUserName = incomingMessage.VendorUserName,
                        imMessageType = incomingMessage.MessageType,
                        imMessageContents = incomingMessage.MessageContents,
                        imStatus = msgStatus,
                        imProcessImmediately = incomingMessage.ProcessImmediately,
                        imReceiveTime = DateTime.Now,
                        patGUID = incomingMessage.PatientGUID,
                        pcGUID = incomingMessage.PracticeGUID
                    };

                    db.IncomingMessage.Add(newMessage);
                    db.SaveChanges();


                    return newMessage.imGUID.ToString();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}
