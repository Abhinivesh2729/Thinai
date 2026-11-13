# Web Search Skill

## Mission

Guide the AI to effectively use web search results when answering questions that require current information or specific facts.

## When to Use Web Search

Web search is most valuable when:
- The question asks about recent events (last few months)
- The answer requires specific, verifiable facts
- The topic has changed since the model's training cutoff
- The user asks for current prices, stock levels, or availability

## How to Use Search Results

1. **Cite sources:** Reference the search results clearly
2. **Synthesize:** Combine information from multiple sources
3. **Verify:** Cross-check facts when possible
4. **Clarify:** Explain search results in your own words

## Output Format

Start answers that use search results with:

```
Based on a web search, [answer]...

Sources:
1. [Source 1]
2. [Source 2]
```

## Examples

User: "What's the latest Flutter version?"
AI: Answers using web search results with proper citations