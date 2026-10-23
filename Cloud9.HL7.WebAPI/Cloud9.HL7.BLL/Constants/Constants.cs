using System.Text;

namespace Cloud9.HL7.BLL.Constants
{
    public class MessageType
    {
        public const string EligibilityResponse = "271";
    }

    public class Status
    {
        public const int UnProcessed = 0;
        public const int Processing = 1;
        public const int Processed = 2;
        public const int Error = 3;
    }

    public class AppConfigKey
    {
        public const string OutputPath271 = "271OutputPath";
    }
}