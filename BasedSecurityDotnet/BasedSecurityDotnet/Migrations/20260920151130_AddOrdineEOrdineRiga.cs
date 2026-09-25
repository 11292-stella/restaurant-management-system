using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace BasedSecurityDotnet.Migrations
{
    /// <inheritdoc />
    public partial class AddOrdineEOrdineRiga : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Ordini",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Cliente = table.Column<string>(type: "text", nullable: false),
                    DataOra = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Totale = table.Column<decimal>(type: "numeric", nullable: false),
                    StatoOrdine = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Ordini", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OrdineRighe",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    OrdineId = table.Column<int>(type: "integer", nullable: false),
                    ProdottoId = table.Column<int>(type: "integer", nullable: false),
                    Quantita = table.Column<int>(type: "integer", nullable: false),
                    PrezzoUnitario = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrdineRighe", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OrdineRighe_Ordini_OrdineId",
                        column: x => x.OrdineId,
                        principalTable: "Ordini",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_OrdineRighe_Prodotti_ProdottoId",
                        column: x => x.ProdottoId,
                        principalTable: "Prodotti",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_OrdineRighe_OrdineId",
                table: "OrdineRighe",
                column: "OrdineId");

            migrationBuilder.CreateIndex(
                name: "IX_OrdineRighe_ProdottoId",
                table: "OrdineRighe",
                column: "ProdottoId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OrdineRighe");

            migrationBuilder.DropTable(
                name: "Ordini");
        }
    }
}
