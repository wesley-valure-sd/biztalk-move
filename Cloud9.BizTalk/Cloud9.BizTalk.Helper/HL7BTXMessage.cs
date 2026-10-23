using System;

using Microsoft.XLANGs.Core;
using Microsoft.BizTalk.XLANGs.BTXEngine;


namespace Cloud9.BizTalk.Helper
{
    [Serializable]
    internal sealed class HL7BTXMessage : BTXMessage
    {
        public HL7BTXMessage(string messageName, Context context)
            : base(messageName, context)
        {
            context.RefMessage(this);
        }
    }
}
