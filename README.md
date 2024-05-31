# llm_chat_phx

LLM Chat is an Elixir Phoenix LiveView application providing an AI-driven chat interface. Users can engage in multi-turn conversations with LLMs and manage chat history. The UI is styled with DaisyUI, and is closely modeled on the Chat GPT UX.

Google OAuth 2.0 is supported via [elixir-auth-google](https://github.com/dwyl/elixir-auth-google). Persistence currently uses postgresdb, although the intent is to eventually support cassandra/scylladb as well.

This app has been built with significant support from Claude 3 Opus and ChatGPT 4o. Other than the HTML/CSS markup and some of the associated JS (which has been eyeballed but not examined in detail), every single line of code has been human curated (by me 😇).

Sample docker-compose deployment using the [dc-web-infra](https://github.com/restlessronin/dc-web-infra) repository as the base. See the [llm_chat subfolder](https://github.com/restlessronin/dc-web-infra/tree/main/llm_chat) for deployment details.
