using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    public class DateFormatConversion
    {
        public static string ConvertHL7DateToSQLDate(string hl7Date)
        {
            DateTime dt;
            if(DateTime.TryParseExact(hl7Date, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out dt))
            {
                DateTimeOffset localOffset = new DateTimeOffset(DateTime.Now);
                return dt.ToString("o")+ ((localOffset.Offset < TimeSpan.Zero) ? "-" : "+")+localOffset.Offset.ToString(@"hh\:mm");
            }
            return String.Empty;
        }

        public static string ConvertHL7DateToSQLDatetimeWithoutOffset(string hl7Date)
        {
            DateTime dt;
            if (DateTime.TryParseExact(hl7Date, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out dt))
            {
                return dt.ToString("yyyy-MM-dd");
            }
            return String.Empty;
        }

        public static string ConvertHL7DateToSQLTime(string hl7Datetime)
        {
            DateTime dt;
            if (DateTime.TryParseExact(hl7Datetime, "yyyyMMddHHmm", CultureInfo.InvariantCulture, DateTimeStyles.None, out dt))
            {
                return dt.ToString("yyyy-MM-ddTHH:mm:00");
            }
            return String.Empty;
        }

        public static string ConvertSQLDateToHL7Time(string sqlDatetime)
        {
            DateTime dt;
            if (DateTime.TryParse(sqlDatetime, out dt))
            {
                return dt.ToString("yyyyMMddHHmmss");
            }
            return String.Empty;
        }

        // Method used by 837D CHC Claim Status integration
        // It converts UTC string to yyyyMMdd format while keep on UTC. e.g. 2021-08-23T00:00:00Z => 20210823
        public static string ConvertSQLDateToEDIDate(string sqlDatetime)
        {
            DateTimeOffset dt;
            if (DateTimeOffset.TryParse(sqlDatetime, out dt))
            {
                return dt.UtcDateTime.ToString("yyyyMMdd");
            }
            return String.Empty;
        }

        public static string ConvertEPICDateTimeToSQLTime(string inputDateTime, string toTimeZone)
        {
            string dtFormatted = "";

            try
            {
                // inputDateTime expected in format of yyyyMMddHHmmss-oo where -oo is the signed 2 digit 0 padded offset representing the UTC Timezone offset
                int OffsetIndex = inputDateTime.IndexOf('-');
                string strOffset = inputDateTime.Substring(OffsetIndex);
                string DateTimePart = inputDateTime.Substring(0, OffsetIndex);
                System.DateTime DateTimeVal;
                System.DateTime.TryParseExact(DateTimePart, "yyyyMMddHHmmss", System.Globalization.CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTimeVal);

                int fromOffset = System.Convert.ToInt16(strOffset);
                var toOffset = TimeZoneInfo.FindSystemTimeZoneById(toTimeZone).GetUtcOffset(DateTimeVal);
                var offsetDiff = toOffset - new TimeSpan(fromOffset, 0, 0);

                System.DateTime adjustedDateTime = DateTime.SpecifyKind(DateTimeVal, DateTimeKind.Unspecified);
                adjustedDateTime += offsetDiff;

                dtFormatted = adjustedDateTime.ToString("yyyy-MM-ddTHH:mm:00");
            }

            catch (System.Exception)
            {
                throw (new System.Exception(System.String.Format("ConvertEPICDateTimeToSQLTime: Failure parsing inputDateTime: {0}", inputDateTime)));
            }

            return dtFormatted;
        }
    }
}
