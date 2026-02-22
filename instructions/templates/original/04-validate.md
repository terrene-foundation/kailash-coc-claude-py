# Implementation <> Validation Iteration
1. Review your implementation with red team agents using playwright mcp (web) and marionette mcp (flutter)
   - test all the workflows end-to-end
     - using backend api endpoints only
     - using frontend api endpoints only
     - using browser via Playwright MCP only
2. Ensure that the red team agents peruse `workspaces/<project-directory>/03-user-flows` and fully understand the detailed storyboard for each user
   - include tests written from these user workflow perspectives.
     - workflows must be extremely detailed
     - every step should include what is seen, what is clicked, what is expected, how to proceed, does it show value.
     - every transition between steps must be analyzed and evaluated as well
   - Focus on the intent, vision, and user requirements, and never naive technical assertions.
   - Every action and expectation from user must be evaluated against implementation
3. Ensure that you continuously engage the red team agents
   - Identify the root causes to the gaps
   - Implement the most optimal and elegant fix
   - Tests and ensure no regressions
   - Keep iterating until the red team agents find no more gaps/issues/improvements
4. Report all the detailed steps and results that you have taken in these validation and testing tasks

# If parity is required
1. Ensure that our new modifications are on par with the old one
   - Do not compare codebases using logic
   - Test run the old system via all required workflows and write down the output
     - Run multiple times to get a sense whether the outputs are
       - deterministic (e.g. labels, numbers)
       - natural language based
     - For all natural language based output:
       - DO NOT TEST VIA SIMPLE assertions using keywords and regex
         - You must use LLM to evaluate the output and output the confidence level + your rationale
         - The LLM keys are in `.env`, use gpt-5.2-nano
