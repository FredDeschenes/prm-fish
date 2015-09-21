# prm-fish
Port of [prm](https://github.com/eivind88/prm) for the fish shell

## Installation
Add the following to your config.fish
```sh
# Load prm-fish
. /path/to/prm.fish
# Enable prm-fish completions
emit prm_setup
```
Although copying/symlinking ```prm.fish``` to ```~/.config/fish/functions/``` will work, autocompletions will not be available.

## Differences
- Works on fish (who would have thought?)
- Project files are saved in ```~/.prm-fish/``` instead of ```~/.prm/```
- Project scripts directory can be set with ```PRM_FISH_DIR``` instead of ```PRM_DIR``` (shell will need to be restarted for change to take effect)

Feel free to report any other differences in the [issue tracker](../../issues/).

## Warnings
- Any function declared in the project start script will need to be erased (with ```functions -e $function_name```) in the stop script, otherwise it will remain defined even after stopping the project

**This has only been tested on my machine and might break all the things (although it really shouldn't be able to). Use at your own risk and report [issues](../../issues/) you have!**
