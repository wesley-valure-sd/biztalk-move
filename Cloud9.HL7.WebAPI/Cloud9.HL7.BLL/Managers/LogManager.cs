using Cloud9.HL7.DAL.BizTalkCloud9CommonEntities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.HL7.BLL.Managers
{
    public class LogManager
    {
        public static void LogException(string process, Exception ex, string request, string correlationId)
        {
            try
            {
                using (var db = new BizTalkCloud9CommonEntities())
                {
                    var exceptionLog = new Log
                    {
                        logGUID = Guid.NewGuid(),
                        logProcess = process,
                        logType = "Error",
                        logMessage = ex.Message,
                        logInternalEntityId = correlationId,
                        logRequest = request,
                        logStackTrace = ex.StackTrace,
                        logCreatedDate = DateTime.Now,
                        logCreatedBy = "API"
                    };

                    db.Log.Add(exceptionLog);
                    db.SaveChanges();

                }
            }
            catch (Exception)
            {

            }
        }
    }
}
