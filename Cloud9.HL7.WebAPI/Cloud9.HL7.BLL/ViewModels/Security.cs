using System;
using System.Security.Cryptography;
using System.Text;


namespace Cloud9.PartnersShared.ViewModels
{
    public class Security
    {
        private static byte[] _HashKey;

        internal static void ComputeHashKey(string hashKey)
        {
            // Initialize
            UTF8Encoding encoder = new UTF8Encoding();

            // Get the salt
            string salt = "You are the salt of the earth.";
            byte[] saltBytes = encoder.GetBytes(salt);

            // Setup the hasher
            Rfc2898DeriveBytes rfc = new Rfc2898DeriveBytes(hashKey, saltBytes);

            // set the hash key
            _HashKey = rfc.GetBytes(16);
        }

        internal static string Encrypt(string dataToEncrypt)
        {
            // Initialize
            AesManaged encryptor = new AesManaged();

            // Set the key
            encryptor.Key = _HashKey;
            encryptor.IV = _HashKey;

            // create a memory stream
            using (System.IO.MemoryStream encryptionStream = new System.IO.MemoryStream())
            {
                // Create the crypto stream
                using (CryptoStream encrypt = new CryptoStream(encryptionStream, encryptor.CreateEncryptor(), CryptoStreamMode.Write))
                {
                    // Encrypt
                    byte[] utfD1 = UTF8Encoding.UTF8.GetBytes(dataToEncrypt);
                    encrypt.Write(utfD1, 0, utfD1.Length);
                    encrypt.FlushFinalBlock();
                    encrypt.Close();

                    // Return the encrypted data
                    return Convert.ToBase64String(encryptionStream.ToArray());
                }
            }
        }

        internal static string Decrypt(string encryptedString)
        {
            // Initialize
            AesManaged decryptor = new AesManaged();
            byte[] encryptedData = Convert.FromBase64String(encryptedString);

            // Set the key
            decryptor.Key = _HashKey;
            decryptor.IV = _HashKey;

            // create a memory stream
            using (System.IO.MemoryStream decryptionStream = new System.IO.MemoryStream())
            {
                // Create the crypto stream
                using (CryptoStream decrypt = new CryptoStream(decryptionStream, decryptor.CreateDecryptor(), CryptoStreamMode.Write))
                {
                    // Encrypt
                    decrypt.Write(encryptedData, 0, encryptedData.Length);
                    decrypt.Flush();
                    decrypt.Close();

                    // Return the unencrypted data
                    byte[] decryptedData = decryptionStream.ToArray();
                    return UTF8Encoding.UTF8.GetString(decryptedData, 0, decryptedData.Length);
                }
            }
        }
    }
}