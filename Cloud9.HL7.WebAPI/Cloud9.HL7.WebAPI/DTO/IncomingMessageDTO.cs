using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace Cloud9.HL7.WebAPI.DTO
{
    [Serializable]
    [JsonObject]
    public class IncomingMessageDTO : CredentialsDTO
    {
        [JsonProperty("messageType", Required = Required.Always)]
        [MaxLength(12)]
        public string MessageType { get; set; }

        [JsonProperty("messageContents", Required = Required.Always)]
        public string MessageContents { get; set; }

        [JsonProperty("processImmediately")]
        public bool? ProcessImmediately { get; set; }

        [JsonProperty("practiceGUID")]
        public Guid? PracticeGUID { get; set; }

        [JsonProperty("patientGUID")]
        public Guid? PatientGUID { get; set; }
    }
}