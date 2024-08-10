module p3;

import std::io;
import std::os::env;

extern fn int sodium_init();
extern fn int crypto_secretbox_easy(char*, char*, ulong mlen, char*, char*);
extern fn int crypto_secretbox_open_easy(char*, char*, ulong clen, char*, char*);
extern fn void randombytes_buf(void*, usz size);
extern fn int crypto_hash_sha256(char*, char*, usz inlen);

const int CRYPTO_SECRETBOX_KEYBYTES = 32;
const int CRYPTO_SECRETBOX_NONCEBYTES = 24;
const int CRYPTO_SECRETBOX_MACBYTES = 16;
const int CRYPTO_HASH_SHA256_BYTES = 32;

fn int main(String[] args)
{
    path::Path config_path = env::get_config_dir()!!; defer config_path.free();
    config_path = config_path.append("p3")!!;

    path::Path passwords_path = config_path.append("passwords")!!; defer passwords_path.free();

    path::Path master_path = config_path.append("master.sha256")!!; defer master_path.free();

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

        if (sodium_init() < 0) {
            io::eprintn("Error: Sodium failed to init");
            return 1;
        }

        if (!path::exists(master_path)) {
            io::eprintfn("Error: \"%s\" does not exist", master_path);
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

        char[CRYPTO_HASH_SHA256_BYTES] input_hash;
        crypto_hash_sha256(&input_hash, master_password, master_password.len);

        char[CRYPTO_HASH_SHA256_BYTES] hash;
        io::File master_file = file::open_path(master_path, "r")!!; defer master_file.close()!!;
        master_file.read(&hash)!!;

        if (!builtin::equals(input_hash, hash)) {
            io::eprintn("Error: Master password hashes do not match");
            return 1;
        }

        // TODO: Use the master_password string to generate key, generate a nonce, encrypt, store nonce + ciphertext

    } else if (args[1] == "s" || args[1] == "set") {
        if (args.len != 2) {
            io::eprintn("Error: Bad usage");
            print_usage();
            return 1;
        }
        if (sodium_init() < 0) {
            io::eprintn("Error: Sodium failed to init");
            return 1;
        }

        if (path::exists(master_path)) {
            io::eprintfn("Error: \"%s\" already exists", master_path);
            return 1;
        }

        io::print("Set master password: ");
        String master_password = io::readline()!!;

        char[CRYPTO_HASH_SHA256_BYTES] hash;
        crypto_hash_sha256(&hash, master_password, master_password.len);

        io::File master_file = file::open_path(master_path, "w")!!; defer master_file.close()!!;
        master_file.write(&hash)!!;

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

fn void print_usage() // TODO
{
    io::eprintn("Usage: p3 [<subcommand>] [<arguments>]");
    io::eprintn("Subcommands:");
    io::eprintn("    list                Lists passwords");
    io::eprintn("    new [<name>]        Creates a new password with the given name");
}
