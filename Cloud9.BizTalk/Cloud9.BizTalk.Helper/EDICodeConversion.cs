using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    public class EDICodeConversion
    {
        public static string ConvertGenderCodeFromC9ToEDI(string gender)
        {
            if (!string.IsNullOrEmpty(gender))
            {
                switch (gender)
                {
                    case "M":
                        return "M";
                    case "F":
                        return "F";
                    default:
                        return "U";
                }
            }
            return string.Empty;
        }
    }
}
