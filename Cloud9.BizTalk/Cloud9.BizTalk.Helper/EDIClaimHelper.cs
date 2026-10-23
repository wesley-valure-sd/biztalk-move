using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace Cloud9.BizTalk.Helper
{
    public class EDIClaimHelper
    {
        private const int prefixLength = 6;

        public static string GetClaimNumberPrefix(string claimNumber)
        {
            int claimNumberLen = claimNumber.Length;
            string prefix = "" ;
            if (claimNumberLen > prefixLength)
            {
                prefix = claimNumber.Substring(0, prefixLength);
            }

            return prefix;
        }

        public static string GetClaimNumber(string claimNumber)
        {
            int claimNumberLen = claimNumber.Length;
            string claimNumberPart = claimNumber;
            if (claimNumberLen > prefixLength)
            {
                claimNumberPart = claimNumber.Substring(prefixLength, claimNumberLen - prefixLength);
            }

            return claimNumberPart;
        }

        public static string CleanPhoneNumber(string phoneNbrIn, int maxLen)
        {
            // This method removes non-digits from a phone number and truncates it
            // if it exceeds the specified maxLen to make it a valid alphanumeric for EDI
            // Potential incoming (770) 555 - 5555 becomes 7705555555
            string phoneNbrOut = Regex.Replace(phoneNbrIn, "[^0-9]", "");

            if (phoneNbrOut.Length > maxLen)
                phoneNbrOut = phoneNbrOut.Substring(0, maxLen);

            return phoneNbrOut;
        }

        public static string FormatDouble(string input)
        {
            // This proc expects a double of any precision and converts it to
            // format rounded to 2 decimal places.
            // 1000.9900 = 1000.99, 100.9999 = 101.00
            string FormattedVal = "0.00";
            if (false == System.String.IsNullOrWhiteSpace(input))
            {
                double val = System.Convert.ToDouble(input);
                FormattedVal = val.ToString("0.00");
            }

            return FormattedVal;
        }
    }
}
