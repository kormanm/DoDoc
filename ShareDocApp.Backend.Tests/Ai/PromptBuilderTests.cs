using ShareDocApp.Backend.Ai;
using Xunit;

namespace ShareDocApp.Backend.Tests.Ai;

public class PromptBuilderTests
{
    [Fact]
    public void SystemPrompt_RequiresSeparateMedicationActions()
    {
        Assert.Contains("every distinct real-world action", PromptBuilder.SystemPrompt);
        Assert.Contains("Purchase/obtain <medicine>", PromptBuilder.SystemPrompt);
        Assert.Contains("recurring \"Take <medicine>\"", PromptBuilder.SystemPrompt);
        Assert.Contains("Never hide multiple independent actions", PromptBuilder.SystemPrompt);
        Assert.Contains("2 to 4 words", PromptBuilder.SystemPrompt);
    }

    [Fact]
    public void BuildUserPrompt_IncludesStableTodayDate()
    {
        var prompt = PromptBuilder.BuildUserPrompt(
            "Take the medicine twice daily.",
            new DateOnly(2026, 6, 20));

        Assert.Contains("Today's date is 2026-06-20", prompt);
        Assert.Contains("Take the medicine twice daily.", prompt);
    }
}
