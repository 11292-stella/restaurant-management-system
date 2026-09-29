using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BasedSecurityDotnet.Migrations
{
    /// <inheritdoc />
    public partial class RestrictDeleteCategoriaProdotto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrdineRighe_Prodotti_ProdottoId",
                table: "OrdineRighe");

            migrationBuilder.DropForeignKey(
                name: "FK_Prodotti_Categorie_CategoriaId",
                table: "Prodotti");

            migrationBuilder.AddForeignKey(
                name: "FK_OrdineRighe_Prodotti_ProdottoId",
                table: "OrdineRighe",
                column: "ProdottoId",
                principalTable: "Prodotti",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Prodotti_Categorie_CategoriaId",
                table: "Prodotti",
                column: "CategoriaId",
                principalTable: "Categorie",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrdineRighe_Prodotti_ProdottoId",
                table: "OrdineRighe");

            migrationBuilder.DropForeignKey(
                name: "FK_Prodotti_Categorie_CategoriaId",
                table: "Prodotti");

            migrationBuilder.AddForeignKey(
                name: "FK_OrdineRighe_Prodotti_ProdottoId",
                table: "OrdineRighe",
                column: "ProdottoId",
                principalTable: "Prodotti",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Prodotti_Categorie_CategoriaId",
                table: "Prodotti",
                column: "CategoriaId",
                principalTable: "Categorie",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
