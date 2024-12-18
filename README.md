# My dotfiles

This directory contains the dotfiles for my system. Currently geared towards macs

## Requirements

Ensure you have the following installed on your system

### Stow

```
pacman -S stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```
$ git clone git@github.com/thenomadlad/dotfiles
$ cd dotfiles
```

then use GNU stow to create symlinks

```
$ stow --adopt .
```
