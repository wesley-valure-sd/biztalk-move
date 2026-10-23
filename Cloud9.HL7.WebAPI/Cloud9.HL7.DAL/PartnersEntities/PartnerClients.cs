namespace Cloud9.HL7.DAL.PartnersEntities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class PartnerClients
    {
        [Key]
        [Column(Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int PartnerID { get; set; }

        [Key]
        [Column(Order = 1)]
        public Guid ClientID { get; set; }

        public DateTime? AllowanceWindowStartUtc { get; set; }

        public DateTime? AllowanceWindowDuration { get; set; }

        public virtual Partner Partner { get; set; }
    }
}
