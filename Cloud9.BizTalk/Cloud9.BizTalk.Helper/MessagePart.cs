using System;

namespace Cloud9.BizTalk.Helper
{
    [Serializable]
    public class MessagePart
    {
        public string Message { get; set; }

        public string MessagePartName { get; set; }

        public MessagePart(string message, string messagePartName)
        {
            Message = message;
            MessagePartName = messagePartName;
        }
    }
}
