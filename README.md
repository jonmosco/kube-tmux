# kube-tmux: Kubernetes context and namespace status for tmux

A script that lets you add the current Kubernetes context and namespace configured
on `kubectl` to your tmux status line.

Inspired by [kube-ps1](https://github.com/jonmosco/kube-ps1), this is a port
to tmux that includes all the features that make kube-ps1 efficient and brings
it to the tmux status line.

![plugin](img/screenshot4.png)

## Disclaimer

This plugin is actively under development, with lots of updates on the way — including a full restructure to work with TPM, tons of bug fixes, and style improvements. Expect frequent changes. Some updates might break things here and there, but I’ll be quick to patch them.

If you have any bug reports, please feel free to submit a PR, or a bug report.

## Installing

### Manual

Clone this repository to your `$HOME/.tmux` directory, and add the following line to your `~/.tmux.conf`:

```sh
set -g status-right "#(/bin/bash $HOME/.tmux/kube-tmux/kube.tmux 250 red cyan)"
```

250 is the color selection for the default foreground, red for the context,
and cyan for the namespace.

### TPM (Recommended)

```sh
set -g @plugin 'tmux-plugins/tpm' # mandatory
set -g @plugin 'jonmosco/kube-tmux'
```

## Requirements

* tmux
* kubectl and/or oc

## Plugin Structure

The default plugin layout is:

```sh
<symbol> <cluster>:<namespace>
```

If the current-context is not set, kube-tmux will return the following:

```sh
<symbol> N/A:N/A
```

## Customization

The default color for the context are red, and cyan for the namespace
Colors for the default text, context, and namespace can be changed:

```sh
#(/bin/bash $HOME/.tmux/kube-tmux/kube.tmux text context namespace)
```

## Customize display of cluster name and namespace

You can change how the cluster name and namespace are displayed using the
`KUBE_TMUX_CLUSTER_FUNCTION` and `KUBE_TMUX_NAMESPACE_FUNCTION` variables
respectively.

For the following examples let's assume the following:

cluster name: `sandbox.k8s.example.com`
namespace: `alpha`

If you're using domain style cluster names, your prompt will get quite long
very quickly. Let's say you only want to display the first portion of the
cluster name (`sandbox`), you could do that by adding the following:

```sh
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}

KUBE_TMUX_CLUSTER_FUNCTION=get_cluster_short
```

The same pattern can be followed to customize the display of the namespace.
Let's say you would prefer the namespace to be displayed in all uppercase
(`ALPHA`), here's one way you could do that:

```sh
function get_namespace_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

export KUBE_TMUX_NAMESPACE_FUNCTION=get_namespace_upper
```

In both cases, the variable is set to the name of the function, and you must have defined the function in your shell configuration before kube_ps1 is called. The function must accept a single parameter and echo out the final value.

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `KUBE_TMUX_CLUSTER_FUNCTION` | No default, must be user supplied | Function to customize how cluster is displayed |
| `KUBE_TMUX_NAMESPACE_FUNCTION` | No default, must be user supplied | Function to customize how namespace is displayed |
