#!/usr/bin/env bash

### ENVIRONMENT VARIABLES
# This file is sourced from ~/.zshrc.

### VERY FIRST THING: DECRYPT KEYS
# Decrypt once, then cache the secrets in the tmux server's global env so future
# panes inherit them for free.
# Refresh after editing secrets.env with: `tmux setenv -gu SECRETS_LOADED`
if [[ -z ${SECRETS_LOADED:-} ]]; then
  _sops_plain="$(sops --decrypt ~/dotfiles/secrets.env)"
  export $(print -r -- "$_sops_plain" | xargs)
  export SECRETS_LOADED=1
  if [[ -n ${TMUX:-} ]] && (( $+commands[tmux] )); then
    print -r -- "$_sops_plain" | while IFS= read -r _l; do
      [[ -z $_l || $_l == '#'* ]] && continue
      tmux setenv -g "${_l%%=*}" "${_l#*=}"
    done
    tmux setenv -g SECRETS_LOADED 1
  fi
  unset _sops_plain _l
fi

### PATHS
# Zsh/Oh-My-Zsh Paths
export ZSH="${XDG_CONFIG_HOME}/zsh/oh-my-zsh"
export ZSHRC="${XDG_CONFIG_HOME}/zsh/.zshrc"
export OMPY="${XDG_CONFIG_HOME}/oh-my-posh/.mytheme.omp.yaml"
export BOOKMARKS="${XDG_CONFIG_HOME}/zsh/.zsh_hashes"

# History
export HISTFILE="${XDG_CONFIG_HOME}/zsh/zsh_history"
export HIST_STAMPS='yyyy-mm-dd'
export HISTSIZE=10000000
export SAVEHIST=${HISTSIZE}

### TOOLS
# FZF
export FZF_BASE=/usr/bin/fzf
export FZF_DEFAULT_OPTS='--height 40% --tmux center,60%'

# Pagers and Editors
export MANPAGER='nvim +Man!'
export VISUAL="nvim"
export EDITOR="${VISUAL}"
export PAGER='less -r'
export LESS='--mouse --wheel-lines 4'
export LESSHISTFILE="${XDG_CONFIG_HOME}/.lesshst"

### SETTINGS
# Wandb
export WANDB_MODE='online'

# Locale
export LC_CTYPE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Standard Notes
export SN_USE_SESSION=yes

# Gemini
export GEMINI_SANDBOX=true

# LaTeX
export VIMTEX_OUTPUT_DIRECTORY='out'

# XCompose
export XCOMPOSEFILE='$XDG_CONFIG_HOME/XCompose'

# mbsync: macOS libsasl loads the XOAUTH2 plugin (cyrus-sasl-xoauth2) from here
export SASL_PATH="$HOME/.local/lib/sasl2"

# Google Cloud
export GOOGLE_CLOUD_PROJECT="see-far"

# Homebrew
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}"


### PATH
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${PATH}:${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin"
export PATH="${PATH}:${HOME}/.cache/lm-studio/bin"

# OS-specific PATH additions
if [[ "${OSTYPE}" == "darwin"* ]]; then
  # Use GNU tools instead of BSD tools on macOS
  export PATH="${HOME}/.local/gnubin:${PATH}"
  export PATH="${PATH}:/opt/homebrew/opt/coreutils/libexec/gnubin"
  # Prefer homebrew's man pages, as `man tar` for instance would otherwise open the bsd man page
  for d in $(brew --prefix)/opt/*/libexec/gnuman; do MANPATH="$d:$MANPATH"; done
  export MANPATH

  # Ignore .DS_Store when compressing
  export COPYFILE_DISABLE=1  # bsd tar
  export TAR_OPTIONS="--exclude=.DS_Store"  # gnu tar

  export OVPN_PROFILE="${HOME}/Library/Application Support/OpenVPN Connect/profiles/1728929973375.ovpn"

  # Android SDK. platform-tools is *prepended* on purpose: Gradle and Studio resolve adb
  # from sdk.dir by absolute path and ignore PATH entirely, so the CLI `adb` must be that
  # same binary — otherwise brew's android-platform-tools shadows it and you end up
  # debugging two different adbs. cmdline-tools/latest/bin provides sdkmanager/avdmanager.
  export ANDROID_HOME="${HOME}/Library/Android/sdk"
  export PATH="${ANDROID_HOME}/platform-tools:${PATH}"
  export PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
fi

### COMMENTED OUT EXPORTS

# CUDA
#export CUDA_HOME="/usr/local/cuda"
#export PATH="${PATH}:${CUDA_HOME}/bin"
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${CUDA_HOME}/lib64:/usr/lib64"
#export LIBRARY_PATH="${LIBRARY_PATH:+${LIBRARY_PATH}:}${LD_LIBRARY_PATH}"

# Jekyll/Ruby
#export PATH="/opt/homebrew/bin:$PATH"

# Mujoco
#export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
#export CC="/opt/homebrew/opt/llvm/bin/clang"
#export CXX="/opt/homebrew/opt/llvm/bin/clang++"
#export CXX11="/opt/homebrew/opt/llvm/bin/clang++"
#export CXX14="/opt/homebrew/opt/llvm/bin/clang++"
#export CXX17="/opt/homebrew/opt/llvm/bin/clang++"
#export CXX1X="/opt/homebrew/opt/llvm/bin/clang++"
#export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
#export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# NVM
# export NVM_DIR="$HOME/.nvm"

# Android Studio — now live in the darwin block above. JAVA_HOME is deliberately not set
# globally: Android projects pin their own (Juggluco's .mise.toml uses Studio's bundled JBR 21,
# since the system JDK is too new for its AGP).
