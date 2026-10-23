using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Cloud9.HL7.WebAPIClient
{
    [Serializable]
    [JsonObject]
    public class Request
    {

        [JsonProperty("messageType")]
        public string MessageType { get; set; }

        [JsonProperty("messageContents", Required = Required.Always)]
        public string MessagesContents { get; set; }
    }
}
