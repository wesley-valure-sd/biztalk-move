namespace Cloud9.HL7.DAL.BizTalkCloud9CommonEntities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("BTS.Log")]
    public partial class Log
    {
        [Key]
        public Guid logGUID { get; set; }

        [StringLength(200)]
        public string pcInstanceAddress { get; set; }

        [StringLength(50)]
        public string logProcess { get; set; }

        [StringLength(50)]
        public string logType { get; set; }

        public string logMessage { get; set; }

        [StringLength(100)]
        public string logInternalEntityId { get; set; }

        [StringLength(100)]
        public string logExternalEntityId { get; set; }

        public string logRequest { get; set; }

        public string logStackTrace { get; set; }

        public DateTime logCreatedDate { get; set; }

        [StringLength(50)]
        public string logCreatedBy { get; set; }
    }
}
