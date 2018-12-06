using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SimpleApp.SfProd.WebApi.Models
{
  public class Pet
  {
    public int Id { get; set; }

    [Required]
    public string Breed { get; set; }

    public string Name { get; set; }

    [Required]
    public PetType PetType { get; set; }
  }

  public enum PetType
  {
    Dog = 0,
    Cat = 1
  }

}
