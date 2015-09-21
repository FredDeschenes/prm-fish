# prm-fish
Port of [prm](https://github.com/eivind88/prm) for the fish shell

## Differences
- Works on fish (who would have thought?)
- Needs to be sourced in your config.fish (```. /path/to/prm.fish```) or copied/moved/symlinked to ```~/.config/fish/functions/```
- Project files are saved in ```~/.prm-fish/``` instead of ```~/.prm/```
- Project scripts directory can be set with ```PRM_FISH_DIR``` instead of ```PRM_DIR``` (shell will need to be restarted for change to take effect)

Feel free to report any other differences in the [issue tracker](../../issues/).

## Warnings
- Any function declared in the project start script will need to be erased (with ```functions -e $function_name```) in the stop script, otherwise it will remain defined even after stopping the project

**This has only been tested on my machine and might break all the things (although it really shouldn't be able to). Use at your own risk and report [issues](../../issues/) you have!**
