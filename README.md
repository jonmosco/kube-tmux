# kube-tmux: Kubernetes context and namespace status for tmux

A script that lets you add the current Kubernetes context and namespace configured
on `kubectl` to your tmux status line.

Inspired by [kube-ps1](https://github.com/jonmosco/kube-ps1), this is a port
to tmux that includes all the features that make kube-ps1 efficient and brings
it to the tmux status line.

![plugin](img/screenshot4.png)

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

Colors for the default text, context, and namespace can be changed via positional arguments:

```sh
#(/bin/bash $HOME/.tmux/kube-tmux/kube.tmux text context namespace)
```

### Configuration Variables

The following environment variables can be used to customize the plugin:

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `KUBE_TMUX_BINARY` | `kubectl` | Binary to use for fetching context and namespace |
| `KUBE_TMUX_SYMBOL_ENABLE` | `true` | Show the Kubernetes symbol |
| `KUBE_TMUX_SYMBOL_USE_IMG` | `false` | Use the wheel of dharma symbol instead of the helm |
| `KUBE_TMUX_SYMBOL_COLOR` | `blue` | Color of the Kubernetes symbol |
| `KUBE_TMUX_CONTEXT_ENABLE` | `true` | Show the current context |
| `KUBE_TMUX_NAMESPACE_ENABLE` | `true` | Show the current namespace |
| `KUBE_TMUX_DIVIDER` | `:` | Separator between context and namespace |
| `KUBE_TMUX_CTX_COLOR` | `red` | Default color of the context |
| `KUBE_TMUX_NS_COLOR` | `cyan` | Default color of the namespace |

### Custom Functions

You can customize how the context and namespace are displayed by defining
shell functions and exporting them via environment variables.

| Variable | Meaning |
| :------- | ------- |
| `KUBE_TMUX_CONTEXT_FUNCTION` | Function to customize how the context is displayed |
| `KUBE_TMUX_NAMESPACE_FUNCTION` | Function to customize how the namespace is displayed |

Each function receives the current value as its first argument and should
echo the transformed value.

For example, if your cluster name is `sandbox.k8s.example.com` and you only
want to display `sandbox`:

```sh
function get_cluster_short() {
    echo "$1" | cut -d . -f1
}

export KUBE_TMUX_CONTEXT_FUNCTION=get_cluster_short
```

To display the namespace in uppercase:

```sh
function get_namespace_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

export KUBE_TMUX_NAMESPACE_FUNCTION=get_namespace_upper
```

These functions and variables must be defined and exported *before* tmux
starts. Set them in your shell profile (e.g., `.bashrc`, `.zshrc`).

You can also place custom functions in `~/.tmux/config/kube-func.sh`. This
file is automatically sourced by kube-tmux if it exists, making it a
convenient place to keep your customizations separate from your shell profile.
