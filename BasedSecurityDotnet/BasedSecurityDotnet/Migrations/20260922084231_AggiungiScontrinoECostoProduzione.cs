using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace BasedSecurityDotnet.Migrations
{
    /// <inheritdoc />
    public partial class AggiungiScontrinoECostoProduzione : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "CostoProduzione",
                table: "Prodotti",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.CreateTable(
                name: "Scontrini",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    DataEmissione = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Importo = table.Column<decimal>(type: "numeric", nullable: false),
                    MetodoPagamento = table.Column<string>(type: "text", nullable: false),
                    OrdineId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Scontrini", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Scontrini_Ordini_OrdineId",
                        column: x => x.OrdineId,
                        principalTable: "Ordini",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Scontrini_OrdineId",
                table: "Scontrini",
                column: "OrdineId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Scontrini");

            migrationBuilder.DropColumn(
                name: "CostoProduzione",
                table: "Prodotti");
        }
    }
}
