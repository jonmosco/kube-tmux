# kube-tmux: Kubernetes context and namespace status for tmux

A script that lets you add the current Kubernetes context and namespace configured
on `kubectl` to your tmux status line.

Inspired by [kube-ps1](https://github.com/jonmosco/kube-ps1), this is a port
to tmux that includes all the features that make kube-ps1 efficient and brings
it to the tmux status line.

![plugin](img/screenshot4.png)

## Disclaimer

This is the first iteration of this plugin, so the updates will be very
frequent.  Track this repo for changes, and keep in mind some of them
might cause issues, although I will try to keep them at a minimum, and provide
fixes as soon as possible. Please be patient! 

If you have any bug reports, please feel free to submit a PR, or a bug report.

## Installing

Clone this repository to your `$HOME/.tmux` directory, and add the following line to your `~/.tmux.conf`:

```bash
set -g status-right "#(/bin/bash $HOME/.tmux/kube-tmux/kube.tmux 250 red cyan)"
```

250 is the color selection for the default foreground, red for the context,
and cyan for the namespace.

## Requirements

* tmux
* kubectl

## Plugin Structure

The default plugin layout is:

```
<symbol> <cluster>:<namespace>
```

If the current-context is not set, kube-tmux will return the following:

```
<symbol> N/A:N/A
```

## Customization
The default color for the context are red, and cyan for the namespace
Colors for the default text, context, and namespace can be changed:

```bash
#(/bin/bash $HOME/.tmux/kube-tmux/kube.tmux text context namespace)
```

## Contributors
