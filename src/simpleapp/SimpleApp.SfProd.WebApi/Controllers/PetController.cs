using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SimpleApp.SfProd.WebApi.Models;
using SimpleApp.SfProd.WebApi.Repositories;

namespace SimpleApp.SfProd.WebApi.Controllers
{
    [Produces("application/json")]
    [Route("api/[controller]")]
    [ApiController]
    public class PetController : ControllerBase
    {
    private readonly PetsRepository _repository;

    public PetController(PetsRepository repository)
    {
      _repository = repository;
    }

    [HttpGet]
    public ActionResult<List<Pet>> Get()
    {
      return _repository.GetPets();
    }

    [HttpGet("{id}")]
    [ProducesResponseType(200)]
    [ProducesResponseType(404)]
    public ActionResult<Pet> GetById(int id)
    {
      if (!_repository.TryGetPet(id, out var pet))
      {
        return NotFound();
      }

      return pet;
    }

    [HttpPost]
    [ProducesResponseType(201)]
    [ProducesResponseType(400)]
    public async Task<ActionResult<Pet>> CreateAsync(Pet pet)
    {
      if (!ModelState.IsValid)
      {
        return BadRequest(ModelState);
      }

      await _repository.AddPetAsync(pet);

      return CreatedAtAction(nameof(GetById),
          new { id = pet.Id }, pet);
    }

  }
}
