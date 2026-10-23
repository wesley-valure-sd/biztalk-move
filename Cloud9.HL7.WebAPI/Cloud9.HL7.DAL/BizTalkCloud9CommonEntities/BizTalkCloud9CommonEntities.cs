namespace Cloud9.HL7.DAL.BizTalkCloud9CommonEntities
{
    using System;
    using System.Data.Entity;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Linq;

    public partial class BizTalkCloud9CommonEntities : DbContext
    {
        public BizTalkCloud9CommonEntities()
            : base("name=BizTalkCloud9CommonEntities")
        {
        }

        public virtual DbSet<IncomingMessage> IncomingMessage { get; set; }
        public virtual DbSet<Log> Log { get; set; }
        public virtual DbSet<PracticeConfig> PracticeConfig { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<IncomingMessage>()
                .Property(e => e.imCorrelationId)
                .IsUnicode(false);

            modelBuilder.Entity<IncomingMessage>()
                .Property(e => e.imMessageType)
                .IsUnicode(false);

            modelBuilder.Entity<IncomingMessage>()
                .Property(e => e.imMessageContents)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logProcess)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logType)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logMessage)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logInternalEntityId)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logExternalEntityId)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logRequest)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logStackTrace)
                .IsUnicode(false);

            modelBuilder.Entity<Log>()
                .Property(e => e.logCreatedBy)
                .IsUnicode(false);
        }
    }
}
