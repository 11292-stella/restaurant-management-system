using Microsoft.EntityFrameworkCore;
using BasedSecurityDotnet.Models;

namespace BasedSecurityDotnet.data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Categoria> Categorie { get; set; }
        public DbSet<Prodotto> Prodotti { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Ordine> Ordini { get; set; }
        public DbSet<OrdineRiga> OrdineRighe { get; set; }
        public DbSet<Scontrino> Scontrini { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Invece di @Column(unique = true) in Java:
            // Impostiamo l'indice unico su Username in EF Core
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            // Invece di @Enumerated(EnumType.STRING) in Java:
            // Convertiamo l'enum Role in stringa nel database
            modelBuilder.Entity<User>()
                .Property(u => u.Role)
                .HasConversion<string>();

            // Stesso trattamento per MetodoPagamento su Scontrino
            modelBuilder.Entity<Scontrino>()
                .Property(s => s.MetodoPagamento)
                .HasConversion<string>();

            // Vincolo "uno scontrino per ordine" garantito anche a livello DB
            modelBuilder.Entity<Scontrino>()
                .HasIndex(s => s.OrdineId)
                .IsUnique();
        }
    }
}
