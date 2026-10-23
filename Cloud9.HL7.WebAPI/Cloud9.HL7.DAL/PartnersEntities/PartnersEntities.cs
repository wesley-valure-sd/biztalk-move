namespace Cloud9.HL7.DAL.PartnersEntities
{
    using System;
    using System.Data.Entity;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Linq;

    public partial class PartnersEntities : DbContext
    {
        public PartnersEntities()
            : base("name=PartnersEntities")
        {
        }

        public virtual DbSet<Log> Log { get; set; }
        public virtual DbSet<Partner> Partner { get; set; }
        public virtual DbSet<PartnerClients> PartnerClients { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Partner>()
                .Property(e => e.Name)
                .IsUnicode(false);

            modelBuilder.Entity<Partner>()
                .Property(e => e.UserName)
                .IsUnicode(false);

            modelBuilder.Entity<Partner>()
                .Property(e => e.Password)
                .IsUnicode(false);

            modelBuilder.Entity<Partner>()
                .HasMany(e => e.PartnerClients)
                .WithRequired(e => e.Partner)
                .WillCascadeOnDelete(false);
        }
    }
}
