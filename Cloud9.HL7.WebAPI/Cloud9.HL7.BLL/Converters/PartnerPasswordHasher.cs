using System.Security.Cryptography;
using System.Text;
using Cloud9.PartnersShared.ViewModels;
using Microsoft.AspNet.Identity;

namespace PartnersShared.Converters
{
    public class PartnerPasswordHasher : IPasswordHasher
    {
        private const string HASH = "P4RTN3R5!H@SH3R";

        public string HashPassword(string password)
        {
            Security.ComputeHashKey(HASH);

            var passwordHash = GetHash(password);
            var encryptedHashedPassword = Security.Encrypt(passwordHash);

            return encryptedHashedPassword;
        }

        public PasswordVerificationResult VerifyHashedPassword(string hashedPassword, string providedPassword)
        {
            Security.ComputeHashKey(HASH);
            var passwordHash = GetHash(providedPassword);
            var encryptedHashedPassword = Security.Encrypt(passwordHash);

            return hashedPassword.Equals(encryptedHashedPassword)
                ? PasswordVerificationResult.Success
                : PasswordVerificationResult.Failed;
        }

        private static string GetHash(string password)
        {
            var UE = new UnicodeEncoding();
            var passwordBytes = UE.GetBytes(password);

            var sha1 = new SHA1Managed();
            var passwordHash = sha1.ComputeHash(passwordBytes);

            return UE.GetString(passwordHash, 0, passwordHash.Length);
        }
    }
}