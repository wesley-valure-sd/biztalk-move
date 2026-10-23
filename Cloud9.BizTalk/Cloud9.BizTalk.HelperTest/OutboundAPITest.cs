using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Cloud9.BizTalk.Helper;

namespace Cloud9.BizTalk.HelperTest
{
    /// <summary>
    /// This unit test class is not for auto builder, because it needs to access SSO database.
    /// For developers, please remove [Ignore] tag before running those tests.
    /// </summary>
    [TestClass]
    public class OutboundAPITest
    {
        string xCorrelationId;

        [TestInitialize]
        public void Setup()
        {
            xCorrelationId = Guid.NewGuid().ToString() + Guid.NewGuid().ToString();
        }


        [TestMethod]
        [Ignore]
        public void TestSendPatientGUID()
        {
            string s = OutboundAPI.SendPatientGUID(xCorrelationId, Guid.NewGuid());

            Assert.IsNotNull(s);
        }

        [TestMethod]
        [Ignore]
        public void TestSendProviderGUID()
        {
            string s = OutboundAPI.SendProviderInformation(xCorrelationId, Guid.NewGuid(), "ProviderId", Guid.NewGuid().ToString());

            Assert.IsNotNull(s);
        }

        [TestMethod]
        [Ignore]
        public void TestSendLocationGUID()
        {
            string s = OutboundAPI.SendLocationGUID(xCorrelationId, Guid.NewGuid());

            Assert.IsNotNull(s);
        }

        [TestMethod]
        [Ignore]
        public void TestSendException()
        {
            string s = OutboundAPI.SendException(xCorrelationId, "exception!");

            Assert.IsNotNull(s);
        }
    }
}
