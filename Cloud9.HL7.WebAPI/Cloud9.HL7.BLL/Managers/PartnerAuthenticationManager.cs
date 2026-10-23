using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Cloud9.HL7.DAL.PartnersEntities;
using Cloud9.HL7.BLL.Shared;
using Microsoft.AspNet.Identity;
using PartnersShared.Converters;

namespace Cloud9.HL7.BLL.Managers
{
    public static class PartnerAuthenticationManager
    {
        public static int AuthenticateUser(string userName, string password)
        {
            try
            {
                using (var db = new PartnersEntities())
                {

                    var partnerClient = (from p in db.Partner.AsNoTracking()
                                         join pc in db.PartnerClients.AsNoTracking()
                                         on p.PartnerID equals pc.PartnerID
                                         where p.UserName == userName && (p.PartnerArchived.Value != true)
                                         select pc).SingleOrDefault();

                    if (partnerClient != null)
                    {
                        PartnerPasswordHasher pph = new PartnerPasswordHasher();
                        var clientIDParam = new SqlParameter("@ClientID", partnerClient.ClientID);
                        var userNameParam = new SqlParameter("@UserName", userName);
                        var passwordParam = new SqlParameter("@Password", pph.HashPassword(password));
                        var procedureParam = new SqlParameter("@Procedure", "IncomingMessageAPI");
                        var startTimeParam = new SqlParameter("@StartTime", DateTime.UtcNow);

                        var result = db.Database.SqlQuery<int>("Authenticate @ClientID, @UserName, @Password, @Procedure, @StartTime", clientIDParam, userNameParam, passwordParam, procedureParam, startTimeParam).FirstOrDefault();

                        return result;
                    }
                    else
                    {
                        return (int)AuthenticationResponseCode.PartnerArchivedOrHasNoClients;
                    }
                    
                }
            }
            catch (Exception ex)
            {
                using (var db = new PartnersEntities())
                {
                    var exceptionLog = new Log
                    {
                        LogID = Guid.NewGuid(),
                        Procedure = "Authentication",
                        Date = DateTime.Now,
                        ErrorMessage = ex.Message,
                        StackTrace = ex.StackTrace
                    };

                    db.Log.Add(exceptionLog);
                    db.SaveChanges();
                }

                throw ex;
            }
        }

    }
}
