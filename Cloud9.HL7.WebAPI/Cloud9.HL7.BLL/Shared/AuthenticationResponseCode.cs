using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Cloud9.HL7.BLL.Shared
{
    public enum AuthenticationResponseCode
    {
        PartnerArchivedOrHasNoClients = -1,
        InvalidCredentials = 0,
        Authenticated = 1,
        NotWhitelisted = -4
    }
}