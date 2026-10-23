using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.ReportGenerator.ConsoleTest
{
    class Program
    {
        static void Main(string[] args)
        {
            var tcr = new TreatmentCardRender();

            string connectionString = @"data source=JJ-IA-LAPTOP\SQLSERVER2016;initial catalog=PracticaCarlsbad2-435;integrated security=True;MultipleActiveResultSets=True;"; // args[0];
            string tceGUID = "74436CFF-D1DE-46D2-8F2E-F6153E865844"; //args[1];

            string base64 = tcr.getBase64FromTreatmentCardPDF(connectionString, tceGUID);

            Console.WriteLine(base64);
        }
    }
}
