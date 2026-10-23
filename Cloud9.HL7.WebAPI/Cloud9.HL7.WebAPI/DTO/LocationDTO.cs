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
    public class LocationDTO : CredentialsDTO
    {
        [JsonProperty("locationName", Required = Required.Always)]
        [MaxLength(50)]
        public string LocationName { get; set; }
    }
}