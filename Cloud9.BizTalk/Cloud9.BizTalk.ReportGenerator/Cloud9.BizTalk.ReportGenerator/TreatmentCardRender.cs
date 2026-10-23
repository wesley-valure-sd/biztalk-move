using Cloud9.BizTalk.Reports;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Telerik.Reporting;
using Telerik.Reporting.Processing;

namespace Cloud9.BizTalk.ReportGenerator
{
    public class TreatmentCardRender
    {

        private static ReportSource GetReportSource(string instanceConnectionString, string tceGUID)
        {
            List<KeyValuePair<string, object>> parameters = new List<KeyValuePair<string, object>>();

            KeyValuePair<string, object> param1 = new KeyValuePair<string, object>("tceGUID", tceGUID);

            parameters.Add(param1);

            Telerik.Reporting.Report rpt = new _PatientTreatmentCard();

            var instanceReportSource = new InstanceReportSource();
            instanceReportSource.ReportDocument = rpt;

            ReportConnectionStringManager rcsm = new ReportConnectionStringManager(instanceConnectionString);
            rcsm.UpdateReportSource(instanceReportSource);

            if (parameters != null)
            {
                var reportParameters = rpt.ReportParameters;
                var selectedParameters = GetAllParameters(reportParameters, parameters);
                foreach (var param in selectedParameters)
                {
                    instanceReportSource.Parameters.Add(new Telerik.Reporting.Parameter(param.Key, param.Value));
                }
            }

            return instanceReportSource;

        }

        private static List<KeyValuePair<string, object>> GetAllParameters(ReportParameterCollection reportParameters, List<KeyValuePair<string, object>> selectedValues)
        {
            // This will happen on reports like Contact Info Type, where a default is assumed.  HTML5 does not register the parameter unless it is checked.
            // This will make sure that we have the proper parameters.
            if (reportParameters.Count != selectedValues.Count())
            {
                for (int i = 0; i < reportParameters.Count; i++)
                {
                    var value = selectedValues.Where(v => v.Key == reportParameters[i].Name).FirstOrDefault();
                    if (value.Key == null)
                    {
                        selectedValues.Add(new KeyValuePair<string, object>(reportParameters[i].Name, reportParameters[i].Value));
                    }
                }
            }
            return selectedValues;
        }

        private static RenderingResult RenderReport(ReportSource reportSource)
        {
            ReportProcessor reportProcessor = new ReportProcessor();
            RenderingResult result = reportProcessor.RenderReport("PDF", reportSource, null);
            return result;
        }

        private static void createTreatmentCardPDF(string instanceConnectionString, string tceGUID)
        {

            var reportSource = GetReportSource(instanceConnectionString, tceGUID);

            // Render to PDF
            RenderingResult result = RenderReport(reportSource);


            using (MemoryStream outputStream = new MemoryStream(result.DocumentBytes))
            {

                string dataFilename = "_Patient Treatment Card_" + tceGUID + ".pdf";

                var dir = Directory.GetParent(System.Reflection.Assembly.GetExecutingAssembly().Location).ToString() + "\\pdfs";

                Directory.CreateDirectory(dir);

                using (FileStream fileStream = new FileStream(dir + "\\" + dataFilename, FileMode.OpenOrCreate))
                {
                    outputStream.Position = 0;
                    outputStream.CopyTo(fileStream);
                }
            }

        }

        public static string getBase64FromTreatmentCardPDF(string instanceConnectionString, string tceGUID)
        {

            var reportSource = GetReportSource(instanceConnectionString, tceGUID);

            // Render to PDF
            RenderingResult result = RenderReport(reportSource);

            using (MemoryStream outputStream = new MemoryStream(result.DocumentBytes))
            {
                return Convert.ToBase64String(outputStream.ToArray());
            }

        }

    }
}
