function prm --description "Simple project management tool"
    set -l func_to_call "__prm_$argv[1]"

    if functions -q $func_to_call
        if not set -q prm_fish_dir
            if set -q PRM_FISH_DIR
                set -g prm_fish_dir $PRM_FISH_DIR
            else
                set -g prm_fish_dir $HOME/.prm-fish
            end
        end

        if not test -d $prm_fish_dir
            mkdir -p $prm_fish_dir
        end

        if not test -d $prm_fish_dir/.common
            mkdir -p $prm_fish_dir/.common
        end

        set -l scargs

        if test (count $argv) -gt 1
            set scargs $argv[2..-1]
        end

        eval $func_to_call $scargs
    else
        prm help
    end
end

function __prmcleanup --on-event __prm_clean_process
    rm -f $prm_fish_dir/.active-$argv[1].tmp
    rm -f $prm_fish_dir/.path-$argv[1].tmp
end

function __prm_active --description "List active projects and shell process id"
    cd $prm_fish_dir
    for instance in (ls .active*)
        set -l pid (echo $instance | sed 's/.active-\([0-9]*\).tmp/\1/')
        ps cax | grep $pid > /dev/null

        if test $status -eq 0
            echo $pid (cat $instance)
        else
            emit __prm_clean_process $pid
        end
    end
    prevd
end

function __prm_add --description "Creates new project(s)"
    if test (count $argv) -lt 1
        echo "No name given"
        return 1
    end

    for project_name in $argv
        set -l project_dir "$prm_fish_dir/$project_name"

        if not test -d $project_dir
            mkdir -p $project_dir
        else
            echo "Project $argv[1] already exists."
        end

        printf "# This script will run when STARTING the project \"$project_name\"
# Here you might want to cd into your project directory, activate virtualenvs, etc.
# Don't forget that functions loaded here will NOT be removed until restarting the shell or explicitely deleting them.

" > $project_dir/start.fish

        printf "# This script will run when STOPPING the project \"$project_name\"
# Here you might want to deactivate virtualenvs, clean up temporary files, etc.
# Don't forget that functions loaded here will NOT be removed until restarting the shell or explicitely removing them with 'functions -e function_name'.

" > $project_dir/stop.fish

        eval $EDITOR $project_dir/start.fish; and eval $EDITOR $project_dir/stop.fish

        echo "Added project $project_name."
    end
end

function __prm_edit --description "Edit existing project(s)"
    if test (count $argv) -lt 1
        echo "No name given."
        return 1
    end

    for project_name in $argv
        set -l project_dir "$prm_fish_dir/$project_name"

        if test -d $project_dir
            eval $EDITOR $project_dir/start.fish; and eval $EDITOR $project_dir/stop.fish
            echo "Edited project $project_name."
        else
            echo "$project_name: No such project."
        end
    end
end

function __prm_list --description "List existing projects"
    if not test (find $prm_fish_dir -type d | wc -l) -gt 1
        echo "No projects exist."
    else
        # set -l pid (echo $instance | sed 's/.active-\([0-9]*\).tmp/\1/')
        for d in (ls -d $prm_fish_dir/*)
            echo (basename $d)
        end
    end
end

function __prm_remove --description "Remove existing project(s)"
    if test (count $argv) -lt 1
        echo "No name given."
        return 1
    end

    for project_name in $argv
        set -l project_dir "$prm_fish_dir/$project_name"

        set -l pid %self
        set -l project_dir "$prm_fish_dir/$project_name"

        set -l active_file "$prm_fish_dir/.active-$pid.tmp"

        if test -e $active_file
            if test (cat $active_file) = $project_name
                echo "Stop project $project_name before trying to remove it."
                return 2
            end
        end

        if test -d $project_dir
            rm -rf $project_dir
            echo "Removed project $project_name."
        else
            echo "$project_name: No such project."
        end
    end
end

function __prm_copy --description "Copies a project"
    if test (count $argv) -lt 1
        echo "No name given."
        return 1
    else if test (count $argv) -lt 2
        echo "No new name given."
        return 1
    end

    set -l old_project_name "$argv[1]"
    set -l old_project_dir "$prm_fish_dir/$old_project_name"

    if not test -d $old_project_dir
        echo "$old_project_name: No such project."
        return 2
    end

    set -l new_project_name "$argv[2]"
    set -l new_project_dir "$prm_fish_dir/$new_project_name"

    if test -d $new_project_dir
        echo "Project $new_project_name already exists."
        return 3
    end

    cp -r $old_project_dir $new_project_dir
    prm edit $new_project_name
end

function __prm_rename --description "Rename existing project"
    if test (count $argv) -lt 1
        echo "No name given."
        return 1
    else if test (count $argv) -lt 2
        echo "No new name given."
        return 1
    end

    set -l old_project_name "$argv[1]"
    set -l old_project_dir "$prm_fish_dir/$old_project_name"

    if not test -d $old_project_dir
        echo "$old_project_name: No such project."
        return 2
    end

    set -l new_project_name "$argv[2]"
    set -l new_project_dir "$prm_fish_dir/$new_project_name"

    if test -d $new_project_dir
        echo "Project $new_project_name already exists."
        return 3
    end

    set -l pid %self
    set -l project_name $argv[1]
    set -l project_dir "$prm_fish_dir/$project_name"

    set -l active_file "$prm_fish_dir/.active-$pid.tmp"

    if test -e $active_file
        if test (cat $active_file) = $project_name
            echo "Stop project $project_name before trying to rename it."
            return 4
        end
    end

    mv $old_project_dir $new_project_dir
end

function __prm_start --description "Start project"
    if test (count $argv) -lt 1
        echo "No name given."
        return 1
    end

    set -l pid %self
    set -l project_name $argv[1]
    set -l project_dir "$prm_fish_dir/$project_name"

    if not test -d $project_dir
        echo "$project_name: No such project."
        return 2
    end

    set -l active_file "$prm_fish_dir/.active-$pid.tmp"

    if test -e $active_file
        if test (cat $active_file) = $project_name
            echo "Project $project_name is already active."
            return 3
        end

        prm stop
    end

    if not test -e $prm_fish_dir/.path-$pid.tmp
        pwd > $prm_fish_dir/.path-$pid.tmp
    end

    echo $project_name > $active_file

    # Save fish_prompt as _old_fish_prompt
    # Technique found in virtualenv
    . ( begin
            printf "function _old_fish_prompt\n\t#"
            functions fish_prompt
        end | psub )

    # Replace with our own
    function fish_prompt
        set -l pid %self
        set -l active_file "$prm_fish_dir/.active-$pid.tmp"
        printf "[%s] %s" (cat $active_file) (_old_fish_prompt)
    end

    echo "Starting project $project_name."
    . $project_dir/start.fish
    set -g PRM_FISH_ACTIVE_PROJECT $project_name
end

function __prm_stop --description "Stop active project"
    set -l pid %self
    set -l active_file "$prm_fish_dir/.active-$pid.tmp"

    if not test -e $active_file
        echo "No active project."
        return 1
    end

    set project_name (cat $active_file)
    set -l project_dir "$prm_fish_dir/$project_name"

    echo "Stopping project $project_name."

    cd (cat $prm_fish_dir/.path-$pid.tmp)

    emit __prm_clean_process $pid

    # Reset old prompt
    . ( begin
                printf "function fish_prompt\n\t#"
                functions _old_fish_prompt
            end | psub )
    functions -e _old_fish_prompt

    . $project_dir/stop.fish
    set -e PRM_FISH_ACTIVE_PROJECT
    return 0 # No idea why this is needed
end

function __prm_load --description "Helper function to source common files from '~/.prm-fish/.common/'."
    if test (count $argv) -lt 1
        echo "No script specified."
        return 1
    end

    set -l script_file $prm_fish_dir/.common/$argv[1].fish

    if test -e $script_file
        . $script_file
    else
        echo "Could not load user script '$script_file'."
        return 2
    end
end

function __prm_help --description "Prints help message"
    echo "Usage: prm [options] ..."
    echo "Options:"
    echo "  active                   List active project instances."
    echo "  add <project name>...    Add project(s)."
    echo "  copy <old> <new>         Copies a project."
    echo "  edit <project name>...   Edit project(s)."
    echo "  list                     List all projects."
    echo "  load                     Helper function to source common files from '~/.prm-fish/.common/'."
    echo "  remove <project name>... Remove project(s)."
    echo "  rename <old> <new>       Rename project."
    echo "  start <project name>     Start project. Stops active project if any."
    echo "  stop                     Stop active project."
    echo "  -h --help                Display this information."
    # TODO: --version
    echo ""
    echo "Please report bugs at https://github.com/FredDeschenes/prm-fish"
    echo "Based on https://github.com/eivind88/prm"
    echo "Remember that prm MUST be sourced - not run in a subshell."
    echo "I.e. '. /path/to/prm', most likely in your config.fish"
end

function __prmshellexit --on-process %self
    emit __prm_clean_process %self
end

# Autocompletion setup
# Based on virtualfish https://github.com/adambrenecki/virtualfish
function __prmcompletion_setup --on-event prm_setup
    function __prmcompletion_needs_command
        set cmd (commandline -opc)
            if test (count $cmd) -eq 1 -a $cmd[1] = 'prm'
            return 0
        end
        return 1
    end

    function __prmcompletion_using_command
        echo "Using command $argv"
        set cmd (commandline -opc)
        if test (count $cmd) -gt 1
            if test $argv[1] = $cmd[2]
                return 0
            end
        end
        return 1
    end

    # add completion for subcommands
    for sc in (functions -a | sed -n '/__prm_/{s///g;p;}')
        if not test $sc = "load"
            # Skip 'load' in autocompletion
            set -l helptext (functions "__prm_$sc" | head -n 1 | sed -E "s|.*'(.*)'.*|\1|")
            complete -x -c prm -n '__prmcompletion_needs_command' -a $sc -d $helptext
        end
    end

    complete -x -c prm -n '__prmcompletion_using_command edit' -a "(prm list)"
    complete -x -c prm -n '__prmcompletion_using_command remove' -a "(prm list)"
    complete -x -c prm -n '__prmcompletion_using_command copy' -a "(prm list)"
    complete -x -c prm -n '__prmcompletion_using_command rename' -a "(prm list)"
    complete -x -c prm -n '__prmcompletion_using_command start' -a "(prm list)"
end
