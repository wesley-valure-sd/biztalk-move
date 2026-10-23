using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Cloud9.HL7.WebAPIClient
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Count() < 3)
            {
                Console.WriteLine("Usage: Cloud9.HL7.WebAPIClient.exe <URL> <HL7 type> <HL7 File Name>");
                return;
            }

            string url = args[0];
            string type = args[1];
            string filename = args[2];

            try
            {

                Request data = new Request();
                data.MessageType = type;
                data.MessagesContents = File.ReadAllText(filename);

                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "POST";

                UTF8Encoding encoding = new UTF8Encoding();
                Byte[] byteArray =  encoding.GetBytes(JsonConvert.SerializeObject(data));

                request.ContentLength = byteArray.Length;
                request.ContentType = @"application/json";

                using (Stream dataStream = request.GetRequestStream())
                {
                    dataStream.Write(byteArray, 0, byteArray.Length);
                }
            
                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                {
                    using (var reader = new StreamReader(response.GetResponseStream(), encoding))
                    {
                        string responseText = reader.ReadToEnd();
                        Console.WriteLine("    Status: " + response.StatusCode);
                        Console.WriteLine("Message ID: " + responseText);
                    }                 
                }
            }
            catch (WebException ex)
            {
                Console.WriteLine("API call failed: " + ex.Message);
            }
        }
    }
}
