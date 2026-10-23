using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace Cloud9.HL7.WebAPI.Handlers
{
    public class CorrelationIdHandler: DelegatingHandler
    {
        private const string key = "X-Correlation-ID";

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var response = await base.SendAsync(request, cancellationToken);
            //response.Headers.Add(key, request.GetCorrelationId().ToString());

            if (request.Headers.Contains("X-Correlation-ID"))
            {
                response.Headers.Add(key, request.Headers.GetValues("X-Correlation-Id").FirstOrDefault());
            }

            return response;
        }


    }
}