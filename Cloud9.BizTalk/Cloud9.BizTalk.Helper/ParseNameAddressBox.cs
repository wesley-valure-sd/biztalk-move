using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Cloud9.BizTalk.Helper
{
    /// <summary>
    /// Parse string in name box like 
    /// "Dr. Alex Bale
    /// 1234 Test Street
    /// Cumming, GA 30028"
    /// and return each name or address part for BizTalk mapping
    /// </summary>
    public class ParseNameAddressBox
    {
        public static string GetTitle(string input)
        {
            if (!string.IsNullOrEmpty(input))
            {
                List<string> titles = new List<string> { " ", "Drs.", "Ms", "Dr.", "Miss", "Mr.", "Mrs." };

                string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

                if (submitterLines.Length > 0)
                {
                    foreach (string title in titles)
                    {
                        if (title != null)
                        {
                            if (!string.IsNullOrEmpty(title))
                            {
                                if (submitterLines[0].StartsWith(title + " "))
                                {
                                    return title;
                                }
                            }
                        }
                    }
                }

                return string.Empty;

            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetName(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);
            if (submitterLines.Length > 0)
            {
                return submitterLines[0].Trim();
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetFirstname(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);
            if (submitterLines.Length > 0)
            {
                return GetPatientName(submitterLines[0].Trim(), PatientNameType.First);
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetLastname(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);
            if (submitterLines.Length > 0)
            {
                return GetPatientName(submitterLines[0].Trim(), PatientNameType.Last);
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetMiddlename(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);
            if (submitterLines.Length > 0)
            {
                return GetPatientName(submitterLines[0].Trim(), PatientNameType.Middle);
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetMiddleInitial(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);
            if (submitterLines.Length > 0)
            {
                string middleName = GetPatientName(submitterLines[0].Trim(), PatientNameType.Middle);
                if (middleName.Length > 0)
                {
                    return GetPatientName(submitterLines[0].Trim(), PatientNameType.Middle).Substring(0, 1);
                }
                else
                {
                    return string.Empty;
                }
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetAddress1(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

            if (submitterLines.Length > 1)
            {
                return submitterLines[1].Trim();
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetAddress2(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

            if (submitterLines.Length > 3)
            {
                return submitterLines[2].Trim();
            }
            else
            {
                return string.Empty;
            }
        }


        public static string GetCity(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

            if (submitterLines.Length > 2)
            {
                return GetAddressInfo(submitterLines[submitterLines.Length - 1], AddressInfoType.City);
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetState(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

            if (submitterLines.Length > 2)
            {
                return GetAddressInfo(submitterLines[submitterLines.Length - 1], AddressInfoType.State);
            }
            else
            {
                return string.Empty;
            }
        }

        public static string GetZipcode(string input)
        {
            string[] submitterLines = input.Split(new string[] { "\r" }, StringSplitOptions.None);

            if (submitterLines.Length > 2)
            {
                return GetAddressInfo(submitterLines[submitterLines.Length - 1], AddressInfoType.Zip);
            }
            else
            {
                return string.Empty;
            }
        }

        private enum PatientNameType
        {
            First, Middle, Last
        }

        private enum AddressInfoType
        {
            City, State, Zip
        }

        private static string GetPatientName(string lastFirstMiddle, PatientNameType whichName)
        {
            string firstName = string.Empty, middleName = string.Empty, lastName = string.Empty;

            int commaPoint = lastFirstMiddle.IndexOf(',');
            if (commaPoint > -1)
            {
                lastName = lastFirstMiddle.Substring(0, commaPoint).Trim();

                string firstMiddle = lastFirstMiddle.Substring(commaPoint + 1).Trim();
                int lastSpace = firstMiddle.LastIndexOf(' ');
                if (lastSpace > -1)
                {
                    middleName = firstMiddle.Substring(lastSpace + 1, 1);
                    firstName = firstMiddle.Substring(0, lastSpace).Trim();
                }
                else
                {
                    firstName = firstMiddle;
                    middleName = "";
                }
            }
            else
            {
                // The name must be in Title First Middle Last format

                // Remove any titles
                lastFirstMiddle = RemoveTitle(lastFirstMiddle);

                string[] splitName = lastFirstMiddle.Split(new string[] { " " }, StringSplitOptions.RemoveEmptyEntries);
                if (splitName.Length > 2)
                {
                    firstName = splitName[0];
                    middleName = splitName[1];
                    lastName = splitName[2];
                }
                else if (splitName.Length == 2)
                {
                    firstName = splitName[0];
                    lastName = splitName[1];
                }
                else if (splitName.Length == 1)
                {
                    lastName = splitName[0];
                }
            }

            switch (whichName)
            {
                case PatientNameType.First:
                    {
                        return firstName;
                    }
                case PatientNameType.Middle:
                    {
                        return middleName;
                    }
                case PatientNameType.Last:
                    {
                        return lastName;
                    }
                default:
                    {
                        return string.Empty;
                    }
            }

        }

        private static string GetAddressInfo(string cityStateZip, AddressInfoType whichInfo)
        {
            string city = "", state = "", zip = "";

            // This method expects the following format to work properly: “Woodstock, GA 30188” or “Woodstock, GA 30188-1234”
            // Space padding causes the zip code to be lost.
            cityStateZip = cityStateZip.Trim();

            if (!string.IsNullOrEmpty(cityStateZip))
            {
                string cityState = "";
                int lastSpace = cityStateZip.LastIndexOf(' ');
                if (lastSpace > -1)
                {
                    zip = cityStateZip.Substring(lastSpace + 1).Replace("-", "");
                    cityState = cityStateZip.Substring(0, lastSpace).Trim();

                    string[] cityStateParts = cityState.Split(',');
                    if (cityStateParts.Length > 0)
                    {
                        city = cityStateParts[0].Trim();

                        if (cityStateParts.Length > 1)
                        {
                            state = cityStateParts[1].Trim().Substring(0,2);
                        }
                    }
                }

                switch (whichInfo)
                {
                    case AddressInfoType.City:
                        {
                            return city;
                        }
                    case AddressInfoType.State:
                        {
                            return state;
                        }
                    case AddressInfoType.Zip:
                        {
                            return zip;
                        }
                    default:
                        {
                            return string.Empty;
                        }
                }
            }
            else
            {
                return string.Empty;
            }
        }

        private static string RemoveTitle(string value)
        {
            List<string> titles = new List<string> { " ", "Drs.", "Ms", "Dr.", "Miss", "Mr.", "Mrs." };

            string ret = value;

            foreach (string title in titles)
            {
                if (title != null)
                {
                    if (!string.IsNullOrEmpty(title))
                    {
                        if (ret.StartsWith(title + " "))
                        {
                            ret = ret.Replace(title + " ", "");

                            break;
                        }
                    }
                }
            }

            return ret;
        }
    }

    }

