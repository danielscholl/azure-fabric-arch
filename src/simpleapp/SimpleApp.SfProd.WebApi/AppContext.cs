using Microsoft.EntityFrameworkCore;
using SimpleApp.SfProd.WebApi.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SimpleApp.SfProd.WebApi
{
  public class AppContext : DbContext
  {
    public AppContext(DbContextOptions<AppContext> options)
        : base(options)
    {
    }

    public DbSet<Pet> Pets { get; set; }
  }

}
