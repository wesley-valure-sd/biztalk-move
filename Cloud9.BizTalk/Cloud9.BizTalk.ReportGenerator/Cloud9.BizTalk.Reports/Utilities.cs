using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using Telerik.Reporting;

namespace Cloud9.BizTalk.Reports
{
    public static class Utilities
    {
        //public static string GetCommandTimeoutOverride()
        //{
        //    return WebConfigurationManager.AppSettings["ReportCommandTimeoutOverride"] ?? string.Empty;
        //}

        public static string StripXaml(string xamlText)
        {
            string plainText = "";

            if (!String.IsNullOrEmpty(xamlText))
            {
                // Get rid of newlines
                xamlText = xamlText.Replace("\r\n", " ");
                xamlText = xamlText.Replace("&amp;", "&");

                if (!String.IsNullOrEmpty(xamlText))
                {
                    // Use a RegEx to load the Text from the Run nodes
                    Regex validRegex = new Regex(@"<Section.*?>.*?</Section>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
                    Regex paraRegEx = new Regex(@"<Paragraph.*?>(.*?)</Paragraph>", RegexOptions.IgnoreCase | RegexOptions.Singleline);
                    Regex runRegEx = new Regex(@"(?:Text=(.*?)/>)|(?:<Run.*?>(.*?)</Run>)", RegexOptions.IgnoreCase | RegexOptions.Singleline);
                    var selfClosingTagRegex = new Regex(@"<\/?[^>]*>", RegexOptions.IgnoreCase | RegexOptions.Singleline);

                    if (validRegex.IsMatch(xamlText))
                    {
                        MatchCollection pmatches = paraRegEx.Matches(xamlText);
                        foreach (Match pmatch in pmatches)
                        {
                            if (pmatch != null && pmatch.Success)
                            {
                                if (!String.IsNullOrEmpty(plainText))
                                {
                                    plainText += "\r\n";
                                }

                                int paragraphIndex = 0;

                                MatchCollection rmatches = runRegEx.Matches(pmatch.Groups[1].Value);

                                if (rmatches.Count == 0)
                                {
                                    // Probably just a Paragraph tag with text from HTML5
                                    // Make sure to remove any self-closing tags (<Run/>, <LineBreak/>, etc)
                                    var value = selfClosingTagRegex.Replace(pmatch.Groups[1].Value, String.Empty);
                                    plainText += value;
                                }
                                else
                                {
                                    foreach (Match rmatch in rmatches)
                                    {
                                        if (paragraphIndex < rmatch.Index)
                                        {
                                            var lengthBeforeRun = rmatch.Index - paragraphIndex;
                                            var value = pmatch.Groups[1].Value.Substring(paragraphIndex, lengthBeforeRun);
                                            value = selfClosingTagRegex.Replace(value, " ");
                                            plainText += value;
                                            paragraphIndex = rmatch.Index + rmatch.Length;
                                        }
                                        else
                                        {
                                            paragraphIndex = rmatch.Index + rmatch.Length;
                                        }

                                        if (!String.IsNullOrEmpty(rmatch.Groups[1].Value))
                                        {
                                            plainText += rmatch.Groups[1].Value.Trim(new char[] { '\"', ' ' });
                                        }
                                        else
                                        {
                                            plainText += rmatch.Groups[2].Value;
                                        }
                                    }

                                    // Add any paragraph text after that isn't encapsulated in a run tag
                                    var endValue = pmatch.Groups[1].Value.Substring(paragraphIndex);
                                    endValue = selfClosingTagRegex.Replace(endValue, " ");
                                    plainText += endValue;
                                }
                            }
                        }
                    }
                    else
                    {
                        // It's probably just plain text.
                        plainText = xamlText;
                    }
                }
            }

            return plainText;
        }

    }
}
