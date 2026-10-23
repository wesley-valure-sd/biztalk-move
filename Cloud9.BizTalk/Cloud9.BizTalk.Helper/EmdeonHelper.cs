using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

using ICSharpCode.SharpZipLib.Zip;

namespace Cloud9.BizTalk.Helper
{
    public class EmdeonConversion
    {
        private static byte[] DecompressBytes(byte[] data)
        {
            byte[] ret = null;
            using (MemoryStream ms = new MemoryStream(data))
            {
                ZipFile zf = new ZipFile(ms);
                ZipEntry entry = zf[0];
                //foreach (ZipEntry entry in zf)
                {
                    if (entry.IsFile)
                    {
                        Stream zipStream = zf.GetInputStream(entry);
                        using (MemoryStream msOut = new MemoryStream())
                        {
                            zipStream.CopyTo(msOut);
                            zipStream.Close();

                            ret = msOut.ToArray();
                        }
                    }
                }
            }

            return ret;
        }

        private static byte[] CompressBytes(string fileName, byte[] data)
        {
            using (MemoryStream msOut = new MemoryStream())
            {
                using (ZipOutputStream zipStream = new ZipOutputStream(msOut))
                {
                    ZipEntry entry = new ZipEntry(fileName);
                    entry.DateTime = DateTime.Now;
                    entry.Size = data.Length;

                    zipStream.PutNextEntry(entry);
                    zipStream.Write(data, 0, data.Length);
                    zipStream.CloseEntry();

                    zipStream.Close();
                }
                return msOut.ToArray();
            }
        }

        public static string DecodePayload(string file_compression, string file_encoding, string file_data)
        {
			string result = "" ;
            byte[] tempFileDataInBytes = null;
            byte[] fileDataInBytes = null;


			if (file_encoding.ToLower() == "base64")
                tempFileDataInBytes = Convert.FromBase64String(file_data);

            if (file_compression.ToLower() == "pkzip")
                fileDataInBytes = EmdeonConversion.DecompressBytes(tempFileDataInBytes);

            else
                fileDataInBytes = tempFileDataInBytes ;

            result = Encoding.UTF8.GetString(fileDataInBytes, 0, fileDataInBytes.Length); ;
            return result;
        }
    }
}
