module p3;

import std::io;
import std::os::env;
import std::crypto::rc4;
import std::hash::sha1;
import std::core::mem;

fn void print_usage()
{
    io::eprintn("Usage: p3 [<subcommand>] [<arguments>]");
    io::eprintn("Subcommands:");
    io::eprintn("    new [<name>]        Creates a new password with the given name");
}

fn int main(String[] args)
{
    path::Path config_path = env::get_config_dir()!!;
    defer config_path.free();
    config_path = config_path.append("p3")!!;

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

    if (args.len < 2) {
        print_usage();
        return 1;
    }

    if (args[1] == "n" || args[1] == "new") {
        if (args.len != 3) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }
        path::Path file_path = config_path.append("passwords")!!;
        defer file_path.free();
        file_path = file_path.append(args[2])!!;

        io::print("Password: ");
        String password = io::readline()!!;
        io::print("Master password: ");
        String master_password = io::readline()!!;

        rc4::Rc4 encryptor;
        encryptor.init(master_password);
        char* buffer = mem::alloc_array(char, password.len);
        char[] out = buffer[0..password.len];
        encryptor.crypt(password, out);

        // TODO: Check that it doesnt exist
        io::File file = file::open_path(file_path, "w")!!;
        file.write(out)!!;

    } else if (args[1] == "l" || args[1] == "list") {
        path::PathList list = path::ls(passwords_path)!!;
        // TODO: Maybe print ~/... instead of the absolute path
        // TODO: Check if it's empty and change the message
        io::printfn("Contents of \"%s\":", passwords_path);
        foreach (item: list) {
            io::printn(item);
        }
    } else {
        print_usage();
        return 1;
    }

	return 0;
}
