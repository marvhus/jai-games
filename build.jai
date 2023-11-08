#!/usr/bin/env jai

#run {
    set_build_options_dc(.{do_output=false});
    args := get_build_options().compile_time_command_line;

    if args.count <= 0 {
        log_error("Pass a path you want to build. Usage: ./build.jai - <path>\n");
        exit(1);
    }

    path := "bin";
    name := args[0]; // use the first argument as the binary name
    // @TODO: Implement checking for if the path in args[0] exists.

    build_success := build_project(path, name);

    if args.count > 1 && args[1] == "run" {
        if !build_success {
            log_error("Build failed so you should fix it before you run. Exiting.\n");
            exit(1); // Don't run if build failure.
        }
        run_args := args;
        run_args.count -= 2;
        run_args.data += 2;
        run_project(sprint("./%/%", path, name), run_args);
    }

}

run_project :: (path: string, args: []string) {
    new_args: [..]string;
    array_add(*new_args, path);
    array_add(*new_args, ..args);
    log("===== RUNNING: % =====\n", join(..new_args, separator=" "));
    run_command(..new_args);
}

build_project :: (path: string, name: string) -> bool{
    log("===== COMPILING =====");
    workspace := compiler_create_workspace("Template Workspace");
    if !workspace {
        log_error("Failed to create workspace.\n");
        return false;
    }

    // Create needed directories if it doesn't exist
    make_directory_if_it_does_not_exist(path);
    make_directory_if_it_does_not_exist("modules");

    // configure build options
    opts := get_build_options(workspace);
    opts.output_executable_name = name;
    opts.output_path = path;
    {
        import_path: [..]string;
        array_add(*import_path, "modules/");
        array_add(*import_path, ..opts.import_path);
        opts.import_path = import_path;
    }
    set_build_options(opts, workspace);

    compiler_begin_intercept(workspace);
    add_build_file(sprint("%/main.jai", name), workspace);
    // ^^ use binary name as directory name for project to build.

    success := true;
    while true {
        msg := compiler_wait_for_message();
        if !msg break;
        if msg.kind == {
            case .COMPLETE; break;
            case .ERROR; success = false;
        }
    }
    compiler_end_intercept(workspace);

    return success;
}

#import "File";
#import "Basic";
#import "String";
#import "Process";
#import "Compiler";
