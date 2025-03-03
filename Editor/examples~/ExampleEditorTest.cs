using NUnit.Framework;
using System;
using GauntletRunner.Hackathon;
using System.IO;

public class ExampleEditorTest
{
    private const string ValidJson = @"{
        ""description"": ""Test Step"",
        ""agents"": [""Agent1"", ""Agent2""],
        ""tasks"": [""Task1"", ""Task2""]
    }";

    private const string InvalidJson = @"{
        ""notAgents"": []
    }";

    [Test]
    public void ExtractAgents_WithValidJson_ReturnsAgents()
    {
        // Act
        var result = ExampleSystem.ExtractAgents(ValidJson);

        // Assert
        Assert.That(result, Is.EquivalentTo(new[] { "Agent1", "Agent2" }));
    }

    [Test]
    public void ExtractAgents_WithMissingField_ThrowsException()
    {
        // Act & Assert
        var ex = Assert.Throws<Exception>(() => ExampleSystem.ExtractAgents(InvalidJson));
        Assert.That(ex.Message, Does.Contain("does not contain 'agents' array"));
    }

    [Test]
    public void ExtractAgents_WithInvalidJson_ThrowsException()
    {
        // Arrange
        var invalidJson = "{ not valid json }";

        // Act & Assert
        Assert.Throws<Exception>(() => ExampleSystem.ExtractAgents(invalidJson));
    }
}
