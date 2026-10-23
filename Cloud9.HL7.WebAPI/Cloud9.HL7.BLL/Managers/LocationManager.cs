using Cloud9.HL7.BLL.Items;
using Cloud9.HL7.DAL.BizTalkCloud9CommonEntities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.HL7.BLL.Managers
{
    public class LocationManager
    {
        public static bool LocationExists(string locationName)
        {
            try
            {
                using (var db = new BizTalkCloud9CommonEntities())
                {
                    return (from pc in db.PracticeConfig.AsNoTracking()
                            where pc.pcName == locationName
                            select pc).Any();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public static Guid GetLocationGuidByName(string locationName)
        {
            try
            {
                using (var db = new BizTalkCloud9CommonEntities())
                {
                    return (from pc in db.PracticeConfig.AsNoTracking()
                            where pc.pcName == locationName
                            select pc.pcGUID).SingleOrDefault();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public static string SaveLocation(string locationName)
        {
            try
            {
                using (var db = new BizTalkCloud9CommonEntities())
                {
                    var newPracticeConfig = new PracticeConfig
                    {
                        pcGUID = Guid.NewGuid(),
                        pcCreatedDate = DateTime.Now,
                        pcCreatedBy = "API",
                        pcLastModified = DateTime.Now,
                        pcLastModifiedBy = "API",
                        pcName = locationName,
                        pcsStatusID = 1
                    };

                    db.PracticeConfig.Add(newPracticeConfig);
                    db.SaveChanges();

                    return newPracticeConfig.pcGUID.ToString();
                }
               
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}
