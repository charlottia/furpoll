# furpoll

You will certainly not regret adding this NixOS module

```nix
services.furpoll = {
  enable = true;
  cookieFile = secrets.furpoll.path;
  from = "furpoll <furpoll@you.net>";
  to = "Nyonker <nyonker@aloha.wizzfizz>";
};
```
