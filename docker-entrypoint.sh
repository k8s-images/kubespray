#!/usr/bin/env bash

set -eu

ANSIBLE_HOST_KEY_CHECKING=${ANSIBLE_HOST_KEY_CHECKING:-"False"}
export ANSIBLE_HOST_KEY_CHECKING

if [ -n "${PUBLIC_SSH_KEY:-}" ] && [ -n "${PRIVATE_SSH_KEY:-}" ]; then
    sshKeyDirectory="$HOME/.ssh"
    unknownKey="$sshKeyDirectory/id_unknown"
    unknownKeyPub="$sshKeyDirectory/id_unknown.pub"

    if [ ! -d "$sshKeyDirectory" ]; then
        mkdir -p "$sshKeyDirectory"
        chmod 0600 "$sshKeyDirectory"
    fi

    echo "$PUBLIC_SSH_KEY" > "$unknownKeyPub" && chmod 0600 "$unknownKeyPub"
    echo "$PRIVATE_SSH_KEY" > "$unknownKey" && chmod 0600 "$unknownKey"

    if grep -q '^ssh-rsa ' "$unknownKey.pub"; then
        mv -vf "$unknownKeyPub" "$HOME/.ssh/id_rsa.pub"
        mv -vf "$unknownKey" "$HOME/.ssh/id_rsa"
    elif grep -q '^ecdsa- ' "$unknownKey.pub"; then
        mv -vf "$unknownKeyPub" "$HOME/.ssh/id_ecdsa.pub"
        mv -vf "$unknownKey" "$HOME/.ssh/id_ecdsa"
    elif grep -q '^ssh-ed25519 ' "$unknownKey.pub"; then
        mv -vf "$unknownKeyPub" "$HOME/.ssh/id_ed25519.pub"
        mv -vf "$unknownKey" "$HOME/.ssh/id_ed25519"
    else
        echo "Unknown public SSH key format" >&2
    fi

    unset PRIVATE_SSH_KEY PUBLIC_SSH_KEY
fi

exec "$@"
