using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    public class ClaimStatus
    {
        public static string ConvertEDIClaimStatus(string status)
        {
            switch (status)
            {
                case "1":
                case "65":
                case "66":
                case "72":
                case "73":
                case "104":
                case "105":
                    return "PAID";
                case "21":
                case "23":
                case "24":
                case "25":
                case "26":
                case "27":
                case "29":
                case "30":
                case "31":
                case "32":
                case "33":
                case "34":
                case "35":
                case "54":
                case "59":
                case "60":
                case "61":
                case "64":
                case "81":
                case "83":
                case "84":
                case "85":
                case "86":
                case "88":
                case "89":
                case "90":
                case "91":
                case "92":
                case "93":
                case "94":
                case "95":
                case "96":
                case "97":
                case "101":
                case "102":
                case "103":
                    return "REJECTED";
                case "6":
                case "98":
                case "100":
                    return "PARTIAL";
                default:
                    return "SUBMITTED";
            }
        }
    }
}
