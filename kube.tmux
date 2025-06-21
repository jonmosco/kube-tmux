#!/usr/bin/env bash

# Kubernetes status line for tmux
# Displays current context and namespace

# Copyright 2025 Jon Mosco
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Default values for the plugin
KUBE_TMUX_BINARY="${KUBE_TMUX_BINARY:-kubectl}"
KUBE_TMUX_SYMBOL_ENABLE="${KUBE_TMUX_SYMBOL_ENABLE:-true}"
KUBE_TMUX_SYMBOL_DEFAULT="${KUBE_TMUX_SYMBOL_DEFAULT:-\u2388 }"
KUBE_TMUX_SYMBOL_USE_IMG="${KUBE_TMUX_SYMBOL_USE_IMG:-false}"
KUBE_TMUX_NS_ENABLE="${KUBE_TMUX_NS_ENABLE:-true}"
KUBE_TMUX_DIVIDER="${KUBE_TMUX_DIVIDER-:}"
KUBE_TMUX_SYMBOL_COLOR="${KUBE_TMUX_SYMBOL_COLOR-blue}"
KUBE_TMUX_CTX_COLOR="${KUBE_TMUX_CTX_COLOR-red}"
KUBE_TMUX_NS_COLOR="${KUBE_TMUX_NS_COLOR-cyan}"
KUBE_TMUX_KUBECONFIG_CACHE="${KUBECONFIG}"
KUBE_TMUX_LAST_TIME=0

_kube_tmux_binary_check() {
  command -v "$1" >/dev/null
}

# Determine our shell
_kube_tmux_shell_type() {
  local _KUBE_TMUX_SHELL_TYPE

  if [ "${ZSH_VERSION-}" ]; then
    _KUBE_TMUX_SHELL_TYPE="zsh"
  elif [ "${BASH_VERSION-}" ]; then
    _KUBE_TMUX_SHELL_TYPE="bash"
  fi
  echo $_KUBE_TMUX_SHELL_TYPE
}

_kube_tmux_symbol() {
  if ((BASH_VERSINFO[0] >= 4)) && [[ $'\u2388 ' != "\\u2388 " ]]; then
    KUBE_TMUX_SYMBOL=$'\u2388 '
    KUBE_TMUX_SYMBOL_IMG=$'\u2638 '
  else
    KUBE_TMUX_SYMBOL=$'\xE2\x8E\x88 '
    KUBE_TMUX_SYMBOL_IMG=$'\xE2\x98\xB8 '
  fi

  if [[ "${KUBE_TMUX_SYMBOL_USE_IMG}" == true ]]; then
    KUBE_TMUX_SYMBOL="${KUBE_TMUX_SYMBOL_IMG}"
  fi

  echo "${KUBE_TMUX_SYMBOL}"
}

_kube_tmux_split() {
  type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
  local IFS=$1
  echo $2
}

_kube_tmux_file_newer_than() {
  local mtime
  local file=$1
  local check_time=$2

  if [[ "$(_kube_tmux_shell_type)" == "zsh" ]]; then
    # Use zstat '-F %s.%s' to make it compatible with low zsh version (eg: 5.0.2)
    mtime=$(zstat +mtime -F %s.%s "${file}")
  elif stat -c "%s" /dev/null &> /dev/null; then
    # GNU stat
    mtime=$(stat -L -c %Y "${file}")
  else
    # BSD stat
    mtime=$(stat -L -f %m "$file")
  fi

  [[ "${mtime}" -gt "${check_time}" ]]
}

_kube_tmux_update_cache() {
  if ! _kube_tmux_binary_check "${KUBE_TMUX_BINARY}"; then
    # No ability to fetch context/namespace; display N/A.
    KUBE_TMUX_CONTEXT="BINARY-N/A"
    KUBE_TMUX_NAMESPACE="N/A"
    return
  fi

  if [[ "${KUBECONFIG}" != "${KUBE_TMUX_KUBECONFIG_CACHE}" ]]; then
    # User changed KUBECONFIG; unconditionally refetch.
    KUBE_TMUX_KUBECONFIG_CACHE=${KUBECONFIG}
    _kube_tmux_get_context_ns
    return
  fi

  # kubectl will read the environment variable $KUBECONFIG
  # otherwise set it to ~/.kube/config
  local conf
  for conf in $(_kube_tmux_split : "${KUBECONFIG:-${HOME}/.kube/config}"); do
    [[ -r "${conf}" ]] || continue
    if _kube_tmux_file_newer_than "${conf}" "${KUBE_TMUX_LAST_TIME}"; then
      _kube_tmux_get_context_ns
      return
    fi
  done
}

_kube_config_from_tmux_session() {
  KUBE_TMUX_CONFIG=""
  kube_context="$HOME/.kube/configs/$(tmux display-message -p '#S')"
  if [ -e $kube_context ]; then
    KUBE_TMUX_CONFIG="env KUBECONFIG=$kube_context"
  fi
}

_kube_tmux_get_context_ns() {
  _kube_config_from_tmux_session

  # Set the command time

  if [[ "${KUBE_TMUX_SHELL}" == "bash" ]]; then
    if ((BASH_VERSINFO[0] >= 4)); then
      KUBE_TMUX_LAST_TIME=$(printf '%(%s)T')
    else
      KUBE_TMUX_LAST_TIME=$(date +%s)
    fi
  fi

  KUBE_TMUX_CONTEXT="$(${KUBE_TMUX_CONFIG} ${KUBE_TMUX_BINARY} config current-context 2>/dev/null)"
  if [[ -z "${KUBE_TMUX_CONTEXT}" ]]; then
    KUBE_TMUX_CONTEXT="N/A"
    KUBE_TMUX_NAMESPACE="N/A"
    return
  elif [[ "${KUBE_TMUX_NS_ENABLE}" == true ]]; then
    KUBE_TMUX_NAMESPACE="$(${KUBE_TMUX_CONFIG} ${KUBE_TMUX_BINARY} config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)"
    # Set namespace to 'default' if it is not defined
    KUBE_TMUX_NAMESPACE="${KUBE_TMUX_NAMESPACE:-default}"
  fi
  _kube_tmux_format_context_ns
}

_kube_tmux_format_context_ns() {
  if [[ -n "${KUBE_TMUX_CLUSTER_FUNCTION}" ]]; then
    KUBE_TMUX_CONTEXT=$($KUBE_TMUX_CLUSTER_FUNCTION $KUBE_TMUX_CONTEXT)
  fi
  if [[ -n "${KUBE_TMUX_NAMESPACE_FUNCTION}" ]]; then
    KUBE_TMUX_CONTEXT=$($KUBE_TMUX_NAMESPACE_FUNCTION $KUBE_TMUX_NAMESPACE)
  fi
}

kube_tmux() {
  _kube_tmux_update_cache

  local KUBE_TMUX

  # Symbol
  if [[ "${KUBE_TMUX_SYMBOL_ENABLE}" == true ]]; then
    KUBE_TMUX+="#[fg=blue]$(_kube_tmux_symbol)#[fg=colour${1}]"
  fi

  # Context
  KUBE_TMUX+="#[fg=${2}]${KUBE_TMUX_CONTEXT}"

  # Namespace
  if [[ "${KUBE_TMUX_NS_ENABLE}" == true ]]; then
    if [[ -n "${KUBE_TMUX_DIVIDER}" ]]; then
      KUBE_TMUX+="#[fg=colour250]${KUBE_TMUX_DIVIDER}"
    fi
    KUBE_TMUX+="#[fg=${3}]${KUBE_TMUX_NAMESPACE}"
  fi

  echo "${KUBE_TMUX}"
}

kube_tmux "$@"
