# From todos to implementation
## NOTE: Spam this repeatedly until all todos/active have been moved to todos/completed)
1. You MUST always use the todo-manager to create the detailed todos FOR EVERY SINGLE TODO in `todos/000-master.md`
   - Review with agents, before implementation.
   - Ensure that both FE and BE detailed todos exist, if applicable
2. Continue with the implementation of the next todo/phase using a team of agents, following our procedural directives.
   - Ensure that both FE and BE are implemented, if applicable
3. Always involve tdd-implementor, testing-specialists, value auditor, ai ui ux specialists, with any agents relevant to the work at hand.
   - Test for rigor, completeness, and quality of output from both value and technical user perspectives.
   - Pre-existing failures often hint that you are missing something obvious and critical.
     - Always address pre-existing failures, do not pass until all failures, warnings, hints, are resolved.
   - Always identify the root causes of issues, and implement optimal, elegant fixes.
4. At the end of each phase, work with the todo-manager and update the detailed todos in todos/active.
   - Ensure that every task is verified with evidence before you close them, then move completed ones to completed/.
   - Ensure that you test comprehensively as you implement, with all tests passing at 100%
     - No tests can be skipped (make sure docker is up and running).
     - Do not rewrite the tests just to get them passing but ensure that it's not infrastructure issues that is causing the errors.
     - Always tests according to the intent of what we are trying to achieve and against users' expectations
       - Do not write simple naive technical assertions.
       - Do not have stubs, hardcodes, simulations, naive fallbacks without informative logs.
     - If the tests involve LLMs and are too slow, check if you are using local LLMs and switch to OpenAI
     - If the tests involve LLMs and are failing, please check the following errors first before skipping or changing the logic:
       - Structured outputs are not coded properly
       - LLM agentic pipelines are not coded properly
       - Only after exhausting all the input/output and pipeline errors, should you try with a larger model
5. When writing and testing agents, always remember to utilize the LLM's capabilities instead of naive NLP approaches such as keywords, regex etc.
   - Use ollama or openai (if ollama is too slow)
   - always check .env for api keys and model names to use in development.
     - Always assume that the model names in your memory are outdated and perform a web check on our model names in .env before declaring them invalid.
6. At the end of each phase, create and update 
   - these docs
      - `docs` (complete detailed docs capturing every single details of the codebase)
        - This is the last resort document that agents try and find elusive and extremely deep documentation if agents and skills files can't resolve
      - `docs/00-authority`
        - This is the set of authoritative documents that developers and codegen always read first to gain full situational awareness
        - Ensure you create/update the `README.md` (navigating the authority documents) and the `CLAUDE.md` (preloaded instructions for developers and codegen)
      - Project agents and skills (do not touch the other agents and skills in .claude/)
        - `.claude/agents/project` (Claude Code agents following the `.claude/agents/_subagent-guide.md` and `.claude/guides/claude-code/05-the-agent-system.md`)
        - `.claude/skills/project` (Claude Code skills following the `.claude/guides/claude-code/06-the-skill-system.md`)
   - using as many subdirectories and files as required, and naming them sequentially 00-, 01- for easy referencing.
   - focus on capturing the essence and intent, the 'what it is' and 'how to use it', and not status/progress/reports and other irrelevant information that consumes context unnecessarily.
