# ai-roguelite-nai

This is a small utility to mimic wombo.art API used by AI Roguelite to make it use NovelAI's image generation instead.


To run it you need to add `paint.api.wombo.ai 127.0.0.1` to the hosts file, and also run Caddy to forward HTTPS request to the HTTP-only app.