namespace Cloud9.HL7.DAL
{
    using System;
    using System.Data.Entity;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Linq;

    public partial class HL7StagingModel : DbContext
    {
        public HL7StagingModel()
            : base("name=HL7StagingModel")
        {
        }

        public virtual DbSet<FileMessage> FileMessages { get; set; }
        public virtual DbSet<ProcessingError> ProcessingErrors { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FileMessage>()
                .Property(e => e.fmFileName)
                .IsUnicode(false);

            modelBuilder.Entity<FileMessage>()
                .Property(e => e.fmMessageId)
                .IsUnicode(false);

            modelBuilder.Entity<FileMessage>()
                .Property(e => e.fmMessageType)
                .IsUnicode(false);
        }
    }
}
