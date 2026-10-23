namespace Cloud9.HL7.DAL.BizTalkCloud9CommonEntities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("BTS.PracticeConfig")]
    public partial class PracticeConfig
    {
        [Key]
        public Guid pcGUID { get; set; }

        [StringLength(200)]
        public string pcInstanceAddress { get; set; }

        public DateTime pcCreatedDate { get; set; }

        [Required]
        [StringLength(50)]
        public string pcCreatedBy { get; set; }

        public DateTime pcLastModified { get; set; }

        [Required]
        [StringLength(50)]
        public string pcLastModifiedBy { get; set; }

        [StringLength(200)]
        public string pcInstanceConnectionString { get; set; }

        [Required]
        [StringLength(50)]
        public string pcName { get; set; }

        public short pcsStatusID { get; set; }
    }
}
