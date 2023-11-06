#!/usr/bin/env jai

#run {
    args := get_build_options().compile_time_command_line;
    path := "bin";
    name := "exec";

    build_project(path, name);

    if args.count > 0 && args[0] == "run" {
        run_args := args;
        run_args.count -= 1;
        run_args.data += 1;
        run_project(sprint("./%/%", path, name), run_args);
    }

    set_build_options_dc(.{do_output=false});
}

run_project :: (path: string, args: []string) {
    new_args: [..]string;
    array_add(*new_args, path);
    array_add(*new_args, ..args);
    log("===== RUNNING: % =====\n", join(..new_args, separator=" "));
    run_command(..new_args);
}

build_project :: (path: string, name: string) {
    log("===== COMPILING =====");
    workspace := compiler_create_workspace("Template Workspace");
    if !workspace {
        log_error("Failed to create workspace.\n");
        return;
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
    add_build_file("src/main.jai", workspace);
    while true {
        msg := compiler_wait_for_message();
        if !msg break;
        if msg.kind == .COMPLETE break;
    }
    compiler_end_intercept(workspace);
}

#import "File";
#import "Basic";
#import "String";
#import "Process";
#import "Compiler";
