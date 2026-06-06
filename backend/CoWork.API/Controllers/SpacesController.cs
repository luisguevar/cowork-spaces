using CoWork.Application.DTOs;
using CoWork.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace CoWork.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SpacesController : ControllerBase
{
    private readonly ISpaceService _spaceService;

    public SpacesController(ISpaceService spaceService)
    {
        _spaceService = spaceService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<SpaceResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] string? status)
    {
        var spaces = await _spaceService.GetAllAsync(status);
        return Ok(spaces);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(SpaceResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var space = await _spaceService.GetByIdAsync(id);
        return Ok(space);
    }

    [HttpPost]
    [ProducesResponseType(typeof(SpaceResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateSpaceRequest request)
    {
        var space = await _spaceService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = space.Id }, space);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(SpaceResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateSpaceRequest request)
    {
        var space = await _spaceService.UpdateAsync(id, request);
        return Ok(space);
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(SpaceResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Deactivate(int id)
    {
        var space = await _spaceService.DeactivateAsync(id);
        return Ok(space);
    }
}