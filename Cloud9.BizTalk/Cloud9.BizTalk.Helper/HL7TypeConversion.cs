using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Diagnostics;
using System.IO;

namespace Cloud9.BizTalk.Helper
{

    public class HL7TypeConversion
    {
        /// <summary>
        /// Convert HL7 communication Type to Cloud 9 contact type in table [dbo].[ContactInfoType]
        /// </summary>
        /// <param name="hl7type">HL7 communication type string</param>
        /// <returns>Cloud 9 contact type string</returns>
        public static string ConvertCommunicationTypeFromHL7ToCloud9(string hl7type)
        {
            switch (hl7type)
            {
                case "PHN":
                    return "Phone";
                case "FX":
                    return "Fax";
                case "INTERNET":
                    return "E-Mail";
            }
            return string.Empty;
        }
       

        public static string ConvertSIUMessageTypeToCloud9(string siuType)
        {
            switch (siuType)
            {
                case "SIU_S12":
                    return "CREATE";
                case "SIU_S13":
                    return "RESCHEDULE";
                case "SIU_S14":
                    return "UPDATE";
                case "SIU_S15":
                    return "CANCEL";
                case "SIU_S26":
                    return "NOSHOW";
            }
            return string.Empty;
        }

        public static string ConvertSIUAppointmentStatusToCloud9(string siuApptStatus)
        {
            switch (siuApptStatus)
            {
                case "Sch":
                    return "SCHD";
                case "Comp":
                    return "DISM";
                case "Can":
                    return "CANC";
                case "No Show":
                    return "NOSHOW";
                case "Left":
                    return "N-A";
                case "Arrived":
                    return "WAIT";
                case "Present":
                    return "WAIT";
                case "HH Inc":
                    return "N-A";
                case "No Appt Made":
                    return "DISM";
            }

            return string.Empty;
        }

    }
}
