# Implementation <> Validation Iteration
1. Review your implementation
   - Test all the workflows end-to-end
     - using backend api endpoints only
     - using frontend api endpoints only
     - using browser via Playwright only
2. Ensure that your review includes tests are written from the user workflow perspectives.
   - Workflows must be detailed step by step.
   - Generate the tests and metrics for each step, including the transitions between steps.
3. (If parity required)
   - Ensure that our new modifications are on par with the old one
   - Do not compare codebases using logic
   - Test run the old system via all required workflows and write down the output
     - Run multiple times to get a sense whether the outputs are
       - deterministic (e.g. labels, numbers)
       - natural language based
     - For all natural language based output:
       - DO NOT TEST VIA SIMPLE assertions using keywords and regex
         - You must use LLM to evaluate the output and output the confidence level + your rationale
         - The LLM keys are in .env, use gpt-5.2-nano
4. Give me a detailed checklist based on your tests so that I can validate it manually.
