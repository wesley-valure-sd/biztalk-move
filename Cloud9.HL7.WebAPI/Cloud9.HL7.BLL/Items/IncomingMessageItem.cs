using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Cloud9.HL7.BLL.Items
{
    public class IncomingMessageItem
    {
        public string CorrelationId { get; set; }
        public string VendorUserName { get; set; }
        public string MessageType { get; set; }
        public string MessageContents { get; set; }
        public int Status { get; set; }
        public bool ProcessImmediately { get; set; }
        public DateTime ReceivedTime { get; set; }
        public Guid? PracticeGUID { get; set; }
        public Guid? PatientGUID { get; set; }
    }
}