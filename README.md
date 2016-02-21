# helm-clojuredocs

For people addicted both to Emacs and [clojuredocs](http://clojuredocs.org)

![animation](doc/helm-clojuredocs.gif "animation")


## How to install

Relax. ~~Soon in Melpa~~. It's on [Melpa](http://melpa.org/) now.

```package-install helm-clojuredocs```

## How to use

Two function are exposed:

- ```helm-clojuredocs```: opens helm session with no initial pattern. searching starts with minimal 3 characters entered.
- ```helm-clojuredocs-at-point```: opens helm session with initial pattern guessed from thing under current cursor position.
