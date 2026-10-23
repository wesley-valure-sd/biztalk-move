using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Cloud9.HL7.WebAPI.DTO
{
    public class CredentialsDTO
    {
        [JsonProperty("userName", Required = Required.Always)]
        public string UserName { get; set; }

        [JsonProperty("password", Required = Required.Always)]
        public string Password { get; set; }
    }
}