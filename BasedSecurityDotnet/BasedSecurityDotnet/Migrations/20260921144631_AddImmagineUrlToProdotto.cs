using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BasedSecurityDotnet.Migrations
{
    /// <inheritdoc />
    public partial class AddImmagineUrlToProdotto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ImmagineUrl",
                table: "Prodotti",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImmagineUrl",
                table: "Prodotti");
        }
    }
}
