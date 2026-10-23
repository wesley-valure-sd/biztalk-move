using System;
using Telerik.Reporting;
using Telerik.Reporting.Drawing;

namespace Cloud9.BizTalk.Reports
{
    /// <summary>
    /// Summary description for _PatientTreatmentCard.
    /// </summary>
    public partial class _PatientTreatmentCard : Telerik.Reporting.Report
    {
        public _PatientTreatmentCard()
        {
            //
            // Required for telerik Reporting designer support
            //
            InitializeComponent();

            //
            // TODO: Add any constructor code after InitializeComponent call
            //
        }

        private void rptPatientTreatmentCard_ItemDataBound(object sender, EventArgs e)
        {

        }

        private void table1_ItemDataBound(object sender, EventArgs e)
        {
            Telerik.Reporting.Processing.Table table = (Telerik.Reporting.Processing.Table)sender;
            Unit xPosition = new Unit(1, UnitType.Inch);

            foreach (Telerik.Reporting.Processing.TableRow row in table.Rows)
            {
                Telerik.Reporting.Processing.ITableCell cellHeader = row.GetCell(0);
                Telerik.Reporting.Processing.ITableCell cellWidth = row.GetCell(2);
                Telerik.Reporting.Processing.ITableCell cellDBColumn = row.GetCell(3);

                string header = (string)((Telerik.Reporting.Processing.TextBox)cellHeader).Value;
                int    width = (int)((Telerik.Reporting.Processing.TextBox)cellWidth).Value;
                string dbColumn = (string)((Telerik.Reporting.Processing.TextBox)cellDBColumn).Value;

                if (dbColumn != "tceHugeCol1")
                {
                    Unit unitWidth = new Unit(width, UnitType.Pixel);

                    Telerik.Reporting.TextBox txtHeader = new Telerik.Reporting.TextBox();
                    txtHeader.Value = header;
                    txtHeader.Style.Font.Bold = true;
                    txtHeader.Height = new Unit(.2, UnitType.Inch);
                    txtHeader.Width = unitWidth;
                    txtHeader.Location = new PointU(xPosition, new Unit(0));
                    txtHeader.Style.VerticalAlign = VerticalAlign.Middle;
                    txtHeader.Style.Font.Size = new Unit(9, UnitType.Point);
                    txtHeader.Style.BackgroundColor = System.Drawing.Color.Silver;
                    txtHeader.Style.TextAlign = Telerik.Reporting.Drawing.HorizontalAlign.Center;
                    txtHeader.Style.BorderStyle.Bottom = Telerik.Reporting.Drawing.BorderType.None;
                    txtHeader.Style.BorderStyle.Default = Telerik.Reporting.Drawing.BorderType.Solid;
                    txtHeader.Style.BorderStyle.Top = Telerik.Reporting.Drawing.BorderType.None;
                    txtHeader.Style.BorderStyle.Left = Telerik.Reporting.Drawing.BorderType.None;
                    txtHeader.Style.BorderWidth.Default = Telerik.Reporting.Drawing.Unit.Pixel(1D);
                    txtHeader.Docking = DockingStyle.Left;
                    groupHeaderSection1.Items.Add(txtHeader);

                    Telerik.Reporting.TextBox txtDetail = new Telerik.Reporting.TextBox();
                    txtDetail.Value = "= Fields." + dbColumn;
                    txtDetail.Height = new Unit(.2, UnitType.Inch);
                    txtDetail.Width = unitWidth;
                    txtDetail.Location = new PointU(xPosition, new Unit(0));
                    txtDetail.Style.Font.Size = new Unit(9, UnitType.Point);
                    txtDetail.Style.BorderStyle.Bottom = Telerik.Reporting.Drawing.BorderType.None;
                    txtDetail.Style.BorderStyle.Default = Telerik.Reporting.Drawing.BorderType.Solid;
                    txtDetail.Style.BorderStyle.Top = Telerik.Reporting.Drawing.BorderType.None;
                    txtDetail.Style.BorderStyle.Left = Telerik.Reporting.Drawing.BorderType.None;
                    txtDetail.Style.BorderWidth.Default = Telerik.Reporting.Drawing.Unit.Pixel(1D);
                    txtDetail.Docking = DockingStyle.Left;
                    detail.Items.Add(txtDetail);

                    xPosition = xPosition.Add(unitWidth);
                }
            }
        }
    }
}