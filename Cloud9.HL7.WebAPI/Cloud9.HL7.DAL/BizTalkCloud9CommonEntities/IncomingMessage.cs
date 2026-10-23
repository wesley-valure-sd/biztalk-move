namespace Cloud9.HL7.DAL.BizTalkCloud9CommonEntities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("BTS.IncomingMessage")]
    public partial class IncomingMessage
    {
        [Key]
        public Guid imGUID { get; set; }

        [Required]
        [StringLength(150)]
        public string imCorrelationId { get; set; }

        [StringLength(25)]
        public string imVendorUserName { get; set; }

        [Required]
        [StringLength(12)]
        public string imMessageType { get; set; }

        [Required]
        public string imMessageContents { get; set; }

        public int imStatus { get; set; }

        public bool imProcessImmediately { get; set; }

        [Column(TypeName = "datetime2")]
        public DateTime imReceiveTime { get; set; }

        [Column(TypeName = "datetime2")]
        public DateTime? imProcessTime { get; set; }

        [Column(TypeName = "uniqueidentifier")]
        public Guid? patGUID { get; set; }

        [Column(TypeName = "uniqueidentifier")]
        public Guid? pcGUID { get; set; }
    }
}
