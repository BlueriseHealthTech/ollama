---
description: Operational guide for the BRH Ollama Backend Agent working on the brh-ollama-dev service to manage models and requests around the Ollama runtime on Google Cloud Run, following SAFe and SOLID, KISS and DRY principles.
---

## Scope and boundaries

- Focus only on backend and infrastructure pieces related to the Ollama service and its integration with BlueRise products.
- Do not change unrelated modules unless strictly necessary to keep the build or deployment working.
- Treat the repository as part of a larger multi service environment. Avoid assumptions that this service is the only backend.

## Cloud Run and infrastructure assumptions

- The service is deployed as a Cloud Run service named `brh-ollama-dev`.
- Container listens on port 8080 and exposes HTTP endpoints.
- Environment:
  - `OLLAMA_HOST=0.0.0.0:8080` for Ollama binding inside the container.
- Cloud Run configuration:
  - Concurrency: 80
  - Timeout: 300 seconds
  - Min instances: 1
  - Max instances: 3
- Never hardcode Cloud Run URLs. Use environment variables or configuration files for base URLs or external endpoints.
- When you need to add or change infrastructure settings, prefer doing it in the deployment or IaC files (YAML, Terraform, Cloud Build configs) instead of embedding them in code.

## Design principles for this service

- Treat the service as a clean backend facade around Ollama:
  - HTTP layer: request validation, authentication, response formatting.
  - Domain layer: orchestration of model selection, throttling, product level rules.
  - Infrastructure layer: Ollama client, logging, metrics, configuration.
- Apply SOLID:
  - Keep Ollama client in its own module.
  - Provide interfaces for model service and inference service so it is easy to change implementation.
- Apply KISS:
  - Start with minimal abstractions and extend only when really needed.
  - Prefer explicit and readable code over clever patterns.
- Apply DRY:
  - Centralize:
    - Error mapping to HTTP responses
    - Logging of requests and responses (with care to avoid sensitive data)
    - Model configuration and capabilities

## API design guidelines

When implementing or updating endpoints for the Ollama service:

- Use clear and consistent endpoint names, for example:
  - `GET /api/models` list available models
  - `POST /api/models/pull` pull a new model
  - `DELETE /api/models/{name}` remove a model
  - `POST /api/generate` text generation
  - `POST /api/chat` chat completion style interface
- Always validate:
  - Product identifier or tenant if present in headers or tokens
  - Model name against allowed or configured models
  - Prompt size and options to avoid excessive resource usage
- Handle long running requests:
  - Use streaming responses if supported in this codebase
  - Apply server side timeouts and cancellation when appropriate
- Use consistent response format:
  - A clear structure for success and error responses
  - Include diagnostic information that is safe to expose, not internal stack traces

## Observability and logging

- Ensure every request is:
  - Logged with a correlation or request ID
  - Tagged with model name and product or tenant identifier when available
- Avoid logging:
  - Full prompts or full responses, unless sanitized and explicitly required for debugging
- Add metrics hooks:
  - Request count per model
  - Latency per endpoint
  - Error rate per model and per product
- Prefer existing logging and metrics utilities in the project over introducing new ones.

## Security and configuration

- Use environment variables for:
  - Any Ollama host or port configuration
  - Model allow lists or product specific limits when feasible
- Enforce:
  - Authentication and authorization using existing middleware or utilities
  - Basic rate limiting or request size limits where needed
- Never:
  - Hardcode secrets or API keys
  - Expose internal Cloud Run URLs or infrastructure details in public responses

## Working with SAFe and stories

When the user provides an epic, feature or story:

- Read it as the source of truth for scope and acceptance criteria.
- If the story is broad, propose a small incremental slice that can be implemented safely in one or a few commits.
- For each story:
  - Identify new endpoints, changes to existing endpoints or internal modules.
  - Identify tests that need to be created or updated.
  - Consider potential impact on Cloud Run configuration, concurrency and timeout.

## Coding style and collaboration

- Use English for all identifiers, comments and documentation.
- Follow existing folder structure, naming conventions and patterns.
- Prefer small, cohesive pull requests that:
  - Change a limited number of modules
  - Include tests and clear descriptions
- When refactoring:
  - Preserve behavior unless the user explicitly requested a functional change.
  - Keep changes incremental so they are easy to review.

## Error handling

- Map internal errors to clear HTTP error codes:
  - 400 for invalid input
  - 401 or 403 for authentication or authorization problems
  - 404 for missing models or resources
  - 429 for rate limiting or resource exhaustion scenarios
  - 500 for unexpected internal errors
- Wrap calls to Ollama with:
  - Timeouts
  - Defensive checks against unbounded outputs
  - Clear error messages for logs and safe error messages for clients

By following these instructions, you help the user maintain a clean, scalable and production ready Ollama backend service on GCP Cloud Run that can support multiple BlueRise products reliably.