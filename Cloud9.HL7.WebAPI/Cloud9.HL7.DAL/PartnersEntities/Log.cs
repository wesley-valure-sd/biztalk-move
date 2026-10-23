namespace Cloud9.HL7.DAL.PartnersEntities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Log")]
    public partial class Log
    {
        public Guid LogID { get; set; }

        public Guid? ClientID { get; set; }

        public int? PartnerID { get; set; }

        public long? ResponseSize { get; set; }

        public string Request { get; set; }

        public DateTime? Date { get; set; }

        public string ErrorMessage { get; set; }

        public string StackTrace { get; set; }

        [StringLength(250)]
        public string Procedure { get; set; }

        public long? ExecutionTime { get; set; }
    }
}
