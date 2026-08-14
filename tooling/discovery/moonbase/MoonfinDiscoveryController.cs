using System.Net.Mime;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Moonfin.Server.Api;

/// <summary>
/// Discovery endpoints used by Moonfin clients.
/// </summary>
[ApiController]
[Route("Moonfin/Discovery")]
[Produces(MediaTypeNames.Application.Json)]
public sealed class MoonfinDiscoveryController : ControllerBase
{
    private const string CatalogueFileName = "discovery.catalogue.json";
    private readonly ILogger<MoonfinDiscoveryController> _logger;

    public MoonfinDiscoveryController(ILogger<MoonfinDiscoveryController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Returns same-origin Jellyfin server metadata for web discovery proxy mode.
    /// </summary>
    [HttpGet]
    [HttpGet("discover")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult Discover()
    {
        Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
        Response.Headers["Pragma"] = "no-cache";
        Response.Headers["Expires"] = "0";

        var address = $"{Request.Scheme}://{Request.Host}{Request.PathBase}";
        var servers = new[]
        {
            new
            {
                id = "jellyfin-local",
                name = "Jellyfin",
                address,
                type = "Jellyfin"
            }
        };

        return Ok(servers);
    }

    /// <summary>
    /// Returns the validated Home Lab deep-discovery catalogue.
    ///
    /// The catalogue is stored outside the plugin binary under Moonfin's
    /// configuration data folder. Once this endpoint exists, lanes, filters,
    /// rotation weights and curated-list definitions can be changed atomically
    /// without rebuilding Moonfin Web, Android or TV clients.
    /// </summary>
    [HttpGet("Catalogue")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status304NotModified)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> Catalogue(CancellationToken cancellationToken)
    {
        var plugin = MoonfinPlugin.Instance;
        if (plugin == null)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { error = "Moonfin plugin is not initialized" });
        }

        var path = Path.Combine(plugin.DataFolderPath, CatalogueFileName);
        if (!System.IO.File.Exists(path))
        {
            return NotFound(new
            {
                error = "Discovery catalogue is not configured",
                schemaVersion = 2
            });
        }

        try
        {
            var file = new FileInfo(path);
            var etag = $"\"{file.Length:x}-{file.LastWriteTimeUtc.Ticks:x}\"";
            if (Request.Headers.TryGetValue("If-None-Match", out var requestedEtags)
                && requestedEtags.Any(value => string.Equals(value, etag, StringComparison.Ordinal)))
            {
                return StatusCode(StatusCodes.Status304NotModified);
            }

            var json = await System.IO.File.ReadAllTextAsync(path, cancellationToken)
                .ConfigureAwait(false);
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object
                || !root.TryGetProperty("schemaVersion", out var schemaElement)
                || schemaElement.ValueKind != JsonValueKind.Number
                || !schemaElement.TryGetInt32(out var schemaVersion)
                || schemaVersion < 1
                || !root.TryGetProperty("tabs", out var tabsElement)
                || tabsElement.ValueKind != JsonValueKind.Array)
            {
                _logger.LogError(
                    "Discovery catalogue at {Path} failed structural validation",
                    path);
                return StatusCode(
                    StatusCodes.Status503ServiceUnavailable,
                    new { error = "Discovery catalogue failed validation" });
            }

            Response.Headers.ETag = etag;
            Response.Headers.LastModified = file.LastWriteTimeUtc.ToString("R");
            Response.Headers.CacheControl = "private, max-age=300, must-revalidate";
            Response.Headers["X-Moonfin-Discovery-Schema"] = schemaVersion.ToString();
            return Content(json, MediaTypeNames.Application.Json);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Discovery catalogue JSON is invalid at {Path}", path);
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { error = "Discovery catalogue JSON is invalid" });
        }
        catch (IOException ex)
        {
            _logger.LogWarning(ex, "Unable to read Discovery catalogue at {Path}", path);
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new { error = "Discovery catalogue is temporarily unavailable" });
        }
    }
}
