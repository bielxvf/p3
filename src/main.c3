module p3;

import std::io;
import std::os::env;
import std::crypto::rc4;
import std::hash::sha1;
import std::core::mem;
import std::core::builtin;

fn void print_usage()
{
    io::eprintn("Usage: p3 [<subcommand>] [<arguments>]");
    io::eprintn("Subcommands:");
    io::eprintn("    list                Lists passwords");
    io::eprintn("    new [<name>]        Creates a new password with the given name");
}

fn int main(String[] args)
{
    path::Path config_path = env::get_config_dir()!!;
    defer config_path.free();
    config_path = config_path.append("p3")!!;

    path::Path passwords_path = config_path.append("passwords")!!;
    defer passwords_path.free();

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

        path::Path file_path = passwords_path.append(args[2])!!;
        if (path::exists(file_path)) {
            io::eprintfn("Error: \"%s\" already exists", file_path);
            return 1;
        }

        io::print("Password: ");
        String password = io::readline()!!;
        io::print("Master password: ");
        String master_password = io::readline()!!;

        sha1::Sha1 master_hash;
        master_hash.init();
        master_hash.update(master_password);
        char[20] master_hash_str = master_hash.final();

        path::Path master_path = config_path.append("master.sha1")!!;
        io::File master_file = file::open_path(master_path, "r")!!;
        defer master_file.close()!!;

        usz master_file_size = path::file_size(master_path)!!;
        char[] hash = mem::alloc_array(char, master_file_size);
        master_file.read(hash)!!;

        if (!builtin::equals(hash, &master_hash_str)) {
            io::eprintn("Error: Input does not match master hash");
            return 1;
        }

        rc4::Rc4 encryptor;
        encryptor.init(master_password);
        char* buffer = mem::alloc_array(char, password.len);
        char[] out = buffer[0..password.len];
        encryptor.crypt(password, out);
        encryptor.destroy();

        io::File enc_file = file::open_path(file_path, "w")!!;
        defer enc_file.close()!!;
        enc_file.write(out)!!;

    } else if (args[1] == "s" || args[1] == "set") {
        if (args.len != 2) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }

        path::Path master_path = config_path.append("master.sha1")!!;
        if (path::exists(master_path)) {
            io::eprintfn("Error: \"%s\" already exists", master_path);
            return 1;
        }

        io::print("Set master password: ");
        String master_password = io::readline()!!;

        sha1::Sha1 hash;
        hash.init();
        hash.update(master_password);
        char[20] hash_str = hash.final();
        io::File file = file::open_path(master_path, "w")!!;
        file.write(&hash_str)!!;

    } else if (args[1] == "p" || args[1] == "print") {
        if (args.len != 3) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }

        path::Path file_path = passwords_path.append(args[2])!!;
        if (!path::exists(file_path)) {
            io::eprintfn("Error: \"%s\" does not exist", file_path);
            return 1;
        }

        io::print("Master password: ");
        String master_password = io::readline()!!;

        sha1::Sha1 input_hash;
        input_hash.init();
        input_hash.update(master_password);
        char[20] input_hash_str = input_hash.final();

        io::File encrypted_file = file::open_path(file_path, "r")!!;
        usz encrypted_size = path::file_size(file_path)!!;
        char[] encrypted_str = mem::alloc_array(char, encrypted_size);
        defer mem::free(encrypted_str);
        encrypted_file.read(encrypted_str)!!;

        rc4::Rc4 encryptor;
        encryptor.init(master_password);
        char* buffer = mem::alloc_array(char, 2048);
        char[] out = &buffer;
        encryptor.decrypt(password, out);


    } else if (args[1] == "l" || args[1] == "list") {
        if (args.len != 2) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }

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
