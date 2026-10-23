using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper.APIItems
{
    public class TransmissionItem
    {
        public string EntityType { get; set; }
        public string SourceSystem { get; set; }
        public string SourceId { get; set; }
        public string DestinationSystem { get; set; }
        public string DestinationSystemId { get; set; }
        public string DestinationId { get; set; }
        public string iCIMSProviderId { get; set; }
        public string LocationId { get; set; }
    }

    public class MDMTransmissionItem
    {
        public string messageType { get; set; }
        public string messageContents { get; set; }
    }
}
