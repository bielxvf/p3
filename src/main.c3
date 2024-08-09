module p3;

import std::io;
import std::os::env;

fn void print_usage()
{
    io::eprintn("Usage: p3 [<subcommand>] [<arguments>]");
    io::eprintn("Subcommands:");
    io::eprintn("    new [<name>]        Creates a new password with the given name");
}

fn int main(String[] args)
{
    String home_str = env::get_home_dir()!!;

    path::Path home_path = path::new(home_str)!!;
    defer home_path.free();

    path::Path config_path = home_path.append(".config/p3")!!;
    defer config_path.free();
    path::Path passwords_path = config_path.append("passwords")!!;
    defer passwords_path.free();

    // Make sure ~/.config/p3
    // and ~/.config/p3/passwords
    // both exist as directories
    if (!path::exists(config_path)) {
        io::eprintfn("INFO: Directory \"%s\" does not exist, creating...", config_path);
        io::eprintfn("INFO: Directory \"%s\" does not exist, creating...", passwords_path);
        path::mkdir(config_path)!!;
        path::mkdir(passwords_path)!!;
    } else if (!path::exists(passwords_path)) {
        io::eprintfn("INFO: Directory \"%s\" does not exist, creating...", passwords_path);
        path::mkdir(passwords_path)!!;
    } else if (path::is_file(config_path)) {
        io::eprintfn("Error: \"%s\" is not a directory", config_path);
        return 1;
    } else if (path::is_file(passwords_path)) {
        io::eprintfn("Error: \"%s\" is not a directory", passwords_path);
        return 1;
    }

    if (args[1] == "n" || args[1] == "new") {
        if (args.len != 3) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }
        // TODO
        String name = args[2];
    } else if (args[1] == "l" || args[1] == "list") {
        path::PathList list = path::ls(passwords_path)!!;
        io::printfn("Contents of \"%s\":", passwords_path); // TODO: Maybe print ~/... instead of the absolute path
        foreach (item: list) {
            io::printn(item);
        }
    } else {
        print_usage();
        return 1;
    }

	return 0;
}
