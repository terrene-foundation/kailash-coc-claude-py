# These instructions are for the purpose of tracing an existing project with product focus

## Always be explicit about objectives and expectations
### Product idea for brainstorming
1. This is a ....
2. Document in details, your work in `workspaces/<project-directory>/01-analysis/01-research`.
   - Use as many subdirectories and files as required
   - Name them sequentially as 01-, 02-, etc, for easy referencing

### Ensuring the above technological idea has strong product focus
1. Keep this soft rule in mind for everything you do in this section
   - 80% of the codebase/features/efforts can be reused (agnostic)
   - 15% of the client specific requirements goes into consideration for self-service functionalities that can be reused (agnostic)
   - 5% customization
2. Research thoroughly and distill the value propositions and UNIQUE SELLING POINTS of our solution
   - Scrutinize and critique the intent and vision of this solution, with the focus of creating a product with perfect product market fit
   - Research widely on competing products, gaps, painpoints, and any other information that can help us build a solid base of value propositions
   - It is critical to define the unique selling points. Do not confuse value proposition with unique selling points.
     - Be extremely critical and scrutinize your unique selling points.
3. Evaluate it using platform model thinking
   - Seamless direct transactions between users (producers, consumers, partners)
     - Producers: Users who offer/deliver a product or service
     - Consumers: Users who consume a product or service
     - Partners: To facilitate the transaction between producers and consumers
4. Evaluate it using the AAA framework
   - Automate: Reduce operational costs
   - Augment: Reduce decision-making costs
   - Amplify: Reduce expertise costs (for scaling)
5. Features must sufficiently cover the following network behaviors to achieve strong network effects
   - Accessibility: Easy for users to complete a transaction
     - transaction is activity between producer and consumer, not necessarily monetary in nature
   - Engagement: Information that are useful to users for completing a transaction
   - Personalization: Information that are curated for an intended use
   - Connection: Information sources that are connected to the platform (one or two-way)
   - Collaboration: Producers and consumers can jointly work together seamlessly
6. Document in details, your analysis in `workspaces/<project-directory>/01-analysis`, and plans in `workspaces/<project-directory>/02-plans`, and user flows in `workspaces/<project-directory>/03-user-flows`.
   - Use as many subdirectories and files as required
   - Name them sequentially as 01-, 02-, etc, for easy referencing
7. Work with red team agents to scrutinize your analysis, plans and user flows
   - Identify any gaps, regardless how small
   - Always go back to first principles, identify the roots, and plan the most optimal and elegant implementations
   - analysis, user flows must flow into plans

### Create project specific agents and skills
1. Using as many subagents as required, peruse `docs`
   - Think step by step comprehensively and read beyond the docs into the intent of this project/product
   - Understand the roles and use of agents, skills, docs
     - Agents - What to do, how to think about this, what can it work with, following the procedural directives
     - Skills - Distilled knowledge that agents can achieve 100% situational aware with
     - `docs` - Full knowledge base
2. Create/Update agents in `.claude/agents/project`
   - please web research how Claude subagents should be written, what the best practices are, and how they should be used.
   - specialized agents whose combined expertise cover 100% of this codebase/project/product
   - use-case agents that can work across skills and guide the main agent in coordinating work that are best done by specialized agents.
3. Create the accompanying skills in `.claude/skills/project`
   - please web research how Claude skills should be written, what the best practices are, and how they should be used.
   - do not create any more subdirectories
   - ensure single entry point for skills (`SKILL.md)` that references multiple skills files in the same directory
     - skills must be as detailed as possible to the extent that the agents can deliver most of their work just by using them
     - do not treat skills as the knowledge base
       - it's supposed to contain the most critical information and logical links/frameworks between the information in the knowledge base
       - should REFERENCE instead of repeating the knowledge base in `docs`

