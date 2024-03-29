# ai-roguelite-nai

This is a small utility that allows you to use NovelAI's image generation or locally (or remote) running Automatic's Stable Diffusion WebUI in AI Roguelite.

Note:
For WebUI usage you must start your WebUI with `--api` argument like `./webui.sh --api`.


To run this tool:
1. Download the latest archive for your platform, extract in to folder.
2. Rename `config.toml.sample` to `config.toml` and edit it to your liking (adding NovelAI token, etc).
3. Open `C:\Windows\System32\drivers\etc\hosts` as admin (or `/etc/hosts` on Linux) and add the following line:
4. if there are issues with SSL/certificates, see https://github.com/Yardanico/ai-roguelite-nai/issues/1

To build from source:
1. Install nim toolset from https://nim-lang.org/
2. run `nimble install parsetoml prologue uuid4`
3. in the `src` folder, run `nim c proxier`
4. caddy will be an external tool, either from original repo releases or from https://caddyserver.com/

`127.0.0.1 paint.api.wombo.ai`

4) Open two command line windows (cmd.exe or terminal emulators on Linux), in both go to the folder with the extracted files and in one start the caddy binary, in another start the proxier one. On Windows caddy will ask you to add a certificate, agree on that. On Linux you must start Caddy as `sudo` because it binds to port 443 which is reserved to root by default.

Feel free to open an issue if you have any problems.
