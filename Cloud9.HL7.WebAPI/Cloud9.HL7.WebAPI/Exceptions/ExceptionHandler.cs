using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Cloud9.HL7.DAL;

namespace Cloud9.HL7.WebAPI.Exceptions
{
    public class ExceptionHandler
    {
        public static void SaveDataExceptionHandler(Exception e)
        {
            HL7StagingModel db = new HL7StagingModel();

            ProcessingError error = new ProcessingError();

            error.peMessageID = "API Insert file";
            error.peMessageType = "Exception";
            error.peErrorMessage = e.Message;
            error.peCreatedDate = DateTime.Now;
            error.peCreatedBy = "Web API User";

            db.ProcessingErrors.Add(error);
            db.SaveChanges();
        }
    }
}